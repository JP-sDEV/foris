import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateAuthInput } from './dto/create-auth.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { randomBytes } from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private userService: UserService,
  ) {}

  private generateSecureToken(): string {
    return randomBytes(32).toString('hex');
  }

  async create(createAuthInput: CreateAuthInput) {
    const user = await this.userService.findOneByEmail(createAuthInput.email);

    if (user) {
      // User exists — find their session (if any)
      const oldSession = await this.prisma.session.findFirst({
        where: { userId: user.id },
        orderBy: { createdAt: 'desc' },
      });

      // Revoke old refresh token if exists
      if (oldSession) {
        await this.prisma.session.delete({ where: { id: oldSession.id } });
      }

      // Create new session with new refresh token
      const newRefreshToken = this.generateSecureToken();
      const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 7); // 7 days

      await this.prisma.session.create({
        data: {
          userId: user.id,
          refreshToken: newRefreshToken,
          expiresAt,
          // Optionally add ipAddress and userAgent if you track them
        },
      });

      // Return user info and the new refresh token together
      return {
        user,
        refreshToken: newRefreshToken,
      };
    }

    const newRefreshToken = this.generateSecureToken();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 7);

    const newUser = await this.prisma.user.create({
      data: {
        name: createAuthInput.name,
        email: createAuthInput.email,
        oauthAccounts: {
          create: {
            provider: createAuthInput.provider,
            providerUserId: createAuthInput.providerUserId,
            accessToken: createAuthInput.accessToken,
            refreshToken: createAuthInput.refreshToken,
            expiresAt: new Date(Date.now() + 3600 * 1000),
          },
        },
        sessions: {
          create: {
            refreshToken: newRefreshToken,
            expiresAt,
          },
        },
      },
    });
    // Return new user and refresh token
    return {
      user: newUser,
      refreshToken: newRefreshToken,
    };
  }

  async findOneByEmail(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: {
        oauthAccounts: true,
      },
    });

    if (!user) {
      throw new NotFoundException(`User with email ${email} not found`);
    }

    return user;
  }

  async refreshToken(refreshToken: string) {
    // Find the session by refresh token, include the user relation
    const oldSession = await this.prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });

    if (!oldSession) {
      throw new Error('Session not found');
    }

    const user = oldSession.user; // Get the user from the session

    // Delete the old session
    await this.prisma.session.delete({ where: { id: oldSession.id } });

    // Create new session with new refresh token
    const newRefreshToken = this.generateSecureToken();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 7); // 7 days

    await this.prisma.session.create({
      data: {
        userId: user.id,
        refreshToken: newRefreshToken,
        expiresAt,
        // Optionally add ipAddress and userAgent if you track them
      },
    });

    // Return user info and the new refresh token together
    return {
      user,
      refreshToken: newRefreshToken,
    };
  }

  async remove(id: string) {
    const oauthAccount = await this.prisma.oAuthAccount.findUnique({
      where: { id },
    });

    if (!oauthAccount) {
      throw new NotFoundException(`OAuthAccount with ID ${id} not found`);
    }

    const deleted = await this.prisma.oAuthAccount.delete({ where: { id } });

    return deleted;
  }
}
