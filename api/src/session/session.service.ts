import { Injectable } from '@nestjs/common';
import { CreateSessionInput } from './dto/create-session.input';
// import { UpdateSessionInput } from './dto/update-session.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { randomBytes } from 'crypto';
import { Session as PrismaSession, User as PrismaUser } from '@prisma/client';

type SessionWithUser = PrismaSession & { user: PrismaUser };

@Injectable()
export class SessionService {
  constructor(
    private prisma: PrismaService,
    private userService: UserService,
  ) {}

  async create(
    createSessionInput: CreateSessionInput,
  ): Promise<SessionWithUser> {
    // Validate user exists
    const user = await this.userService.findOneByEmail(
      createSessionInput.email,
    );

    if (!user) {
      throw new Error('User not found');
    }

    return this.prisma.session.create({
      data: {
        refreshToken: createSessionInput.refreshToken,
        ipAddress: createSessionInput.ipAddress ?? null, // Optionally set if you track IP
        userAgent: createSessionInput.userAgent ?? null, // Optionally set if you track
        expiresAt: createSessionInput.expiresAt,
        user: {
          connect: { id: user.id },
        },
      },
      include: {
        user: true,
      },
    });
  }

  findUnique(refreshToken: string) {
    return this.prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });
  }

  // refreshes the session
  async update(refreshToken: string) {
    if (!refreshToken) {
      throw new Error('Refresh token is required for updating session');
    }
    // Ensure session exists before updating
    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
    });
    if (!session) {
      throw new Error('Session not found');
    }

    const newRefreshToken = this.generateSecureToken();

    return this.prisma.session.update({
      where: { refreshToken },
      data: {
        refreshToken: newRefreshToken,
        expiresAt: this.getExpiryDate(),
      },
      include: {
        user: true,
      },
    });
  }

  async remove(id: string) {
    // Ensure session exists before attempting to remove
    const session = await this.prisma.session.findUnique({ where: { id } });
    if (!session) {
      throw new Error('Session not found');
    }
    await this.prisma.session.delete({ where: { id } });

    // Optionally, you can return the deleted session or a success message
    return session;
  }

  async removeByRefeshToken(refreshToken: string) {
    // Ensure session exists before attempting to remove
    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
    });
    if (!session) {
      throw new Error('Session not found');
    }
    await this.prisma.session.delete({ where: { refreshToken } });

    // Optionally, you can return the deleted session or a success message
    return session;
  }

  async removeByUserId(userId: string): Promise<void> {
    await this.prisma.session.deleteMany({ where: { userId } });
  }

  generateSecureToken(): string {
    return randomBytes(32).toString('hex');
  }

  private getExpiryDate() {
    return new Date(Date.now() + 1000 * 60 * 60 * 24 * 90); // 3 months
  }
}
