import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';
import { PrismaService } from '../prisma/prisma.service';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';
import { UserService } from '../user/user.service';

@Injectable()
export class ChallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(ChallengeService.name);
  }

  async create(createChallengeInput: CreateChallengeInput, userId: string) {
    try {
      const user = await this.userService.findOneById(userId);

      if (!user) {
        throw new ForbiddenException('User not found');
      }

      this.logger.info(
        { userId: userId, input: createChallengeInput },
        'Creating challenge',
      );

      return this.prisma.challenge.create({
        data: {
          ...createChallengeInput,
          createdBy: userId,
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId: userId, input: createChallengeInput },
        'Error creating challenge',
      );
      throw error;
    }
  }

  async findOneByIdUser(id: string, userId: string) {
    try {
      const user = await this.userService.findOneById(userId);

      if (!user) {
        throw new ForbiddenException('User not found');
      }

      const challenge = await this.prisma.challenge.findUnique({
        where: { id },
      });

      if (!challenge) {
        throw new NotFoundException(`Challenge with ID ${id} not found`);
      }

      this.logger.info(
        { userId: userId, challengeId: id },
        'Fetching challenge for user',
      );

      return challenge;
    } catch (error) {
      this.logger.error(
        { error, userId: userId, challengeId: id },
        'Error fetching challenge for user',
      );
      throw error;
    }
  }

  async findOneById(id: string) {
    try {
      const challenge = await this.prisma.challenge.findUnique({
        where: { id },
        include: {
          creator: false, // optional
          userChallenges: false, // optional: include relations
          leagueChallenges: false, // optional
        },
      });

      if (!challenge) {
        throw new NotFoundException(`Challenge with id ${id} not found`);
      }

      this.logger.info({ challengeId: id }, 'Fetching challenge by ID');

      return challenge;
    } catch (error) {
      this.logger.error(
        { error, challengeId: id },
        'Error fetching challenge by ID',
      );
      throw error;
    }
  }

  async update(
    id: string,
    updateChallengeInput: UpdateChallengeInput,
    userId: string,
  ) {
    try {
      const user = await this.userService.findOneById(userId);

      if (!user) {
        throw new ForbiddenException('User not found');
      }

      const existing = await this.prisma.challenge.findUnique({
        where: { id },
      });

      if (!existing) {
        throw new NotFoundException(`Challenge with ID ${id} not found`);
      }

      if (existing.createdBy !== userId) {
        throw new ForbiddenException(`You cannot update this challenge`);
      }

      this.logger.info(
        { userId: userId, challengeId: id, input: updateChallengeInput },
        'Updating challenge',
      );

      return this.prisma.challenge.update({
        where: { id },
        data: updateChallengeInput,
      });
    } catch (error) {
      this.logger.error(
        { error, userId: userId, challengeId: id, input: updateChallengeInput },
        'Error updating challenge',
      );
      throw error;
    }
  }

  async remove(id: string, userId: string) {
    try {
      const user = await this.userService.findOneById(userId);

      if (!user) {
        throw new ForbiddenException('User not found');
      }

      const challenge = await this.prisma.challenge.findUnique({
        where: { id },
      });

      if (!challenge) {
        throw new NotFoundException(`Challenge with ID ${id} not found`);
      }

      if (challenge.createdBy !== userId) {
        throw new ForbiddenException('You cannot delete this challenge');
      }

      this.logger.info(
        { userId: userId, challengeId: id },
        'Deleting challenge',
      );

      return this.prisma.challenge.delete({
        where: { id },
      });
    } catch (error) {
      this.logger.error(
        { error, userId: userId, challengeId: id },
        'Error deleting challenge',
      );
      throw error;
    }
  }
}
