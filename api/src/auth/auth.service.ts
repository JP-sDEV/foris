import { Injectable, NotFoundException } from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';
import { JwtService } from '@nestjs/jwt';
import { CreateAuthInput } from './dto/create-auth.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { SessionService } from '../session/session.service';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private userService: UserService,
    private sessionService: SessionService,
    private readonly jwtService: JwtService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(AuthService.name);
  }

  async create(createAuthInput: CreateAuthInput) {
    try {
      const user = await this.userService.findOneByEmail(createAuthInput.email);

      if (user) {
        throw new Error(
          `User with email ${createAuthInput.email} already exists`,
        );
      }

      const newUser = await this.prisma.user.create({
        data: {
          name: createAuthInput.name,
          email: createAuthInput.email,
          oauthAccounts: {
            create: {
              provider: createAuthInput.provider,
              providerUserId: createAuthInput.providerUserId,
              expiresAt: new Date(Date.now() + 3600 * 1000),
            },
          },
        },
      });

      const payload = {
        userId: newUser.id,
        name: newUser.name,
        email: newUser.email,
      };
      const accessToken = this.jwtService.sign(payload);

      // Generate your own refresh token for the session (recommended)
      const appRefreshToken = this.sessionService.generateSecureToken();
      const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 90); // 3 months

      const session = await this.sessionService.create({
        refreshToken: appRefreshToken,
        userAgent: null, // Optionally set if you track user agent
        ipAddress: null, // Optionally set if you track IP
        userId: newUser.id,
        email: newUser.email,
        expiresAt: expiresAt,
      });

      if (!session) {
        throw new Error('Failed to create session');
      }

      return {
        user: newUser,
        accessToken,
        refreshToken: session.refreshToken,
      };
    } catch (error) {
      this.logger.error(
        { error, email: createAuthInput.email },
        'Error creating auth',
      );
      throw error;
    }
  }

  async findOneByEmail(email: string) {
    try {
      const user = await this.userService.findOneByEmail(email);

      if (!user) {
        this.logger.error({ email: email }, 'User not found');
        throw new NotFoundException(`User with email ${email} not found`);
      }

      return user;
    } catch (error) {
      this.logger.error({ error, email: email }, 'Error finding auth by email');
      throw error;
    }
  }

  async remove(id: string) {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id },
      });

      if (!user) {
        throw new NotFoundException(`User with ID ${id} not found`);
      }

      await this.prisma.user.delete({ where: { id } });

      return true;
    } catch (error) {
      this.logger.error({ error, userId: id }, 'Error removing auth');
      throw error;
    }
  }

  async refreshToken(userId: string, refreshToken: string) {
    try {
      const user = await this.userService.findOneById(userId);
      const session = await this.sessionService.findUnique(refreshToken);

      if (!session) {
        throw new NotFoundException('Session not found');
      }

      if (session.userId !== user.id) {
        throw new NotFoundException('Session not found for this user');
      }

      const newSession = await this.sessionService.update(refreshToken);

      return {
        user: newSession.user,
        refreshToken: newSession.refreshToken,
      };
    } catch (error) {
      this.logger.error({ error, userId: userId }, 'Error refreshing token');
      throw error;
    }
  }

  async login(email: string) {
    try {
      const user = await this.userService.findOneByEmail(email);
      if (!user) {
        throw new NotFoundException(`User with email ${email} not found`);
      }
      // console.log('Login User Auth Service: ', user);

      // verify password if using local auth
      // const valid = await bcrypt.compare(input.password, user.passwordHash);

      const payload = {
        userId: user.id,
        name: user.name,
        email: user.email,
      };
      const accessToken = this.jwtService.sign(payload);

      const refreshToken = this.sessionService.generateSecureToken();
      await this.sessionService.create({
        refreshToken,
        userId: user.id,
        email: user.email,
        userAgent: null,
        ipAddress: null,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 90),
      });

      return { user, accessToken, refreshToken };
    } catch (error) {
      this.logger.error({ error, email: email }, 'Error logging in user');
      throw error;
    }
  }

  async logoutByUserId(userId: string): Promise<boolean> {
    try {
      // Remove all sessions for this user
      await this.sessionService.removeByUserId(userId);
      return true;
    } catch (error) {
      this.logger.error({ error, userId: userId }, 'Error logging out user');
      throw error;
    }
  }
}
