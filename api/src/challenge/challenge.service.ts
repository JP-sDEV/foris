import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';

import { UserService } from '../user/user.service';

@Injectable()
export class ChallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
  ) {}

  async create(createChallengeInput: CreateChallengeInput, userId: string) {
    const user = await this.userService.findOneById(userId);

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    return this.prisma.challenge.create({
      data: {
        ...createChallengeInput,
        createdBy: userId,
      },
    });
  }

  async findOne(id: string, userId: string) {
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

    return challenge;
  }

  async findOneById(id: string) {
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

    return challenge;
  }

  async update(
    id: string,
    updateChallengeInput: UpdateChallengeInput,
    userId: string,
  ) {
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

    return this.prisma.challenge.update({
      where: { id },
      data: updateChallengeInput,
    });
  }

  async remove(id: string, userId: string) {
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

    return this.prisma.challenge.delete({
      where: { id },
    });
  }
}
