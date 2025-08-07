import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';

@Injectable()
export class ChallengeService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createChallengeInput: CreateChallengeInput, userId: string) {
    // Optionally verify that the user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.challenge.create({
      data: {
        ...createChallengeInput,
        createdBy: userId,
      },
    });
  }

  async findOne(id: string) {
    const challenge = await this.prisma.challenge.findUnique({
      where: { id },
    });

    if (!challenge) {
      throw new NotFoundException(`Challenge with ID ${id} not found`);
    }

    return challenge;
  }

  async update(
    id: string,
    updateChallengeInput: UpdateChallengeInput,
    userId: string,
  ) {
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
