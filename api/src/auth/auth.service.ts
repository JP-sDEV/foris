import { Injectable, NotFoundException } from '@nestjs/common';
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
  ) {}

  async create(createAuthInput: CreateAuthInput) {
    // Replace with UserService to find user by email
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

    const payload = { sub: newUser.id, name: newUser.name };
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
  }

  async findOneByEmail(email: string) {
    const user = await this.userService.findOneByEmail(email);
    console.log('AuthService.findOneByEmail called');

    if (!user) {
      throw new NotFoundException(`User with email ${email} not found`);
    }

    return user;
  }

  async remove(id: string) {
    const oauthAccount = await this.prisma.oAuthAccount.findUnique({
      where: { id },
    });

    if (!oauthAccount) {
      throw new NotFoundException(`OAuthAccount with ID ${id} not found`);
    }

    await this.prisma.oAuthAccount.delete({ where: { id } });

    return true;
  }

  async refreshToken(refreshToken: string) {
    const session = await this.sessionService.findUnique(refreshToken);

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    const newSession = await this.sessionService.update(refreshToken);

    return {
      user: session.user,
      refreshToken: newSession.refreshToken,
    };
  }
}
