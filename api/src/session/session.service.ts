import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { CreateSessionInput } from './dto/create-session.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { randomBytes } from 'crypto';
import { Session as PrismaSession, User as PrismaUser } from '@prisma/client';
import { PinoLogger } from 'nestjs-pino';

type SessionWithUser = PrismaSession & { user: PrismaUser };

@Injectable()
export class SessionService {
  constructor(
    private prisma: PrismaService,
    private userService: UserService,
    private logger: PinoLogger,
  ) {
    this.logger.setContext(SessionService.name);
  }

  async create(
    createSessionInput: CreateSessionInput,
  ): Promise<SessionWithUser> {
    try {
      this.logger.info({ email: createSessionInput.email }, 'Creating session');
      const user = await this.userService.findOneByEmail(
        createSessionInput.email,
      );

      if (!user) {
        this.logger.warn(
          { email: createSessionInput.email },
          'User not found for session creation',
        );
        throw new NotFoundException('User not found');
      }

      const session = await this.prisma.session.create({
        data: {
          refreshToken: createSessionInput.refreshToken,
          ipAddress: createSessionInput.ipAddress ?? null,
          userAgent: createSessionInput.userAgent ?? null,
          expiresAt: createSessionInput.expiresAt,
          user: { connect: { id: user.id } },
        },
        include: { user: true },
      });

      this.logger.info(
        { sessionId: session.id },
        'Session created successfully',
      );
      return session;
    } catch (error) {
      this.logger.error(
        { error, email: createSessionInput.email },
        'Error creating session',
      );
      throw error;
    }
  }

  async findUnique(refreshToken: string) {
    this.logger.info({ refreshToken }, 'Finding session by refresh token');
    return this.prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });
  }

  async update(refreshToken: string) {
    if (!refreshToken) {
      this.logger.warn('Refresh token missing for session update');
      throw new BadRequestException('Refresh token is required');
    }

    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
    });
    if (!session) {
      this.logger.warn({ refreshToken }, 'Session not found for update');
      throw new NotFoundException('Session not found');
    }

    const newRefreshToken = this.generateSecureToken();
    this.logger.info(
      { oldSessionId: session.id },
      'Updating session with new token',
    );

    return this.prisma.session.update({
      where: { refreshToken },
      data: {
        refreshToken: newRefreshToken,
        expiresAt: this.getExpiryDate(),
      },
      include: { user: true },
    });
  }

  async remove(id: string) {
    const session = await this.prisma.session.findUnique({ where: { id } });
    if (!session) {
      this.logger.warn({ sessionId: id }, 'Session not found for deletion');
      throw new NotFoundException('Session not found');
    }

    await this.prisma.session.delete({ where: { id } });
    this.logger.info({ sessionId: id }, 'Session removed successfully');
    return session;
  }

  async removeByRefreshToken(refreshToken: string) {
    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
    });
    if (!session) {
      this.logger.warn(
        { refreshToken },
        'Session not found for deletion by token',
      );
      throw new NotFoundException('Session not found');
    }

    await this.prisma.session.delete({ where: { refreshToken } });
    this.logger.info(
      { sessionId: session.id },
      'Session removed successfully by token',
    );
    return session;
  }

  async removeByUserId(userId: string): Promise<void> {
    this.logger.info({ userId }, 'Removing all sessions for user');
    await this.prisma.session.deleteMany({ where: { userId } });
  }

  generateSecureToken(): string {
    return randomBytes(32).toString('hex');
  }

  private getExpiryDate(): Date {
    return new Date(Date.now() + 1000 * 60 * 60 * 24 * 90); // 3 months
  }
}
