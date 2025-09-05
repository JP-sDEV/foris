// userchallenge.service.ts
import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { JoinUserChallengeInput } from './dto/join-userchallenge.input';
import { UpdateUserChallengeInput } from './dto/update-userchallenge.input';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class UserchallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(UserchallengeService.name);
  }

  async create(joinUserChallenge: JoinUserChallengeInput, userId: string) {
    this.logger.info(
      { userId, challengeId: joinUserChallenge.challengeId },
      'Joining user challenge',
    );

    const user = await this.userService.findOneById(userId);
    if (!user) {
      this.logger.warn({ userId }, 'User not found');
      throw new NotFoundException('User not found');
    }

    try {
      return await this.prisma.userChallenge.create({
        data: {
          userId,
          challengeId: joinUserChallenge.challengeId,
        },
      });
    } catch (error) {
      this.logger.error({ error }, 'Failed to create user challenge');
      throw new InternalServerErrorException('Failed to join user challenge');
    }
  }

  async update(
    updateUserChallengeInput: UpdateUserChallengeInput,
    userId: string,
  ) {
    this.logger.info(
      { userId, challengeId: updateUserChallengeInput.challengeId },
      'Updating user challenge',
    );

    const user = await this.userService.findOneById(userId);
    if (!user) {
      this.logger.warn({ userId }, 'User not found');
      throw new NotFoundException('User not found');
    }

    try {
      return await this.prisma.userChallenge.update({
        where: {
          userId_challengeId: {
            userId,
            challengeId: updateUserChallengeInput.challengeId,
          },
        },
        data: {
          ...(updateUserChallengeInput.status && {
            status: updateUserChallengeInput.status,
          }),
          ...(updateUserChallengeInput.completedAt && {
            completedAt: updateUserChallengeInput.completedAt,
          }),
        },
      });
    } catch (error) {
      this.logger.error({ error }, 'Failed to update user challenge');
      throw new InternalServerErrorException('Failed to update user challenge');
    }
  }

  async findOne(userId: string, challengeId: string) {
    const user = await this.userService.findOneById(userId);
    if (!user) {
      this.logger.warn({ userId }, 'User not found');
      throw new NotFoundException('User not found');
    }

    return this.prisma.userChallenge.findUnique({
      where: { userId_challengeId: { userId, challengeId } },
    });
  }

  async remove(joinUserChallenge: JoinUserChallengeInput, userId: string) {
    this.logger.info(
      { userId, challengeId: joinUserChallenge.challengeId },
      'Removing user challenge',
    );

    const user = await this.userService.findOneById(userId);
    if (!user) {
      this.logger.warn({ userId }, 'User not found');
      throw new NotFoundException('User not found');
    }

    try {
      return await this.prisma.userChallenge.delete({
        where: {
          userId_challengeId: {
            userId,
            challengeId: joinUserChallenge.challengeId,
          },
        },
      });
    } catch (error) {
      this.logger.error({ error }, 'Failed to remove user challenge');
      throw new InternalServerErrorException('Failed to remove user challenge');
    }
  }
}
