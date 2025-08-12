import { Injectable, NotFoundException } from '@nestjs/common';
import { JoinUserChallengeInput } from './dto/join-userchallenge.input';
import { UpdateUserChallengeInput } from './dto/update-userchallenge.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';

@Injectable()
export class UserchallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private userService: UserService,
  ) {}

  async create(joinUserChallenge: JoinUserChallengeInput, userId: string) {
    // Optionally verify that the user exists
    const user = await this.userService.findOneById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.userChallenge.create({
      data: {
        userId: userId,
        challengeId: joinUserChallenge.challengeId,
      },
    });
  }

  // findAll() {
  //   return `This action returns all userchallenge`;
  // }

  async update(
    updateUserChallengeInput: UpdateUserChallengeInput,
    userId: string,
  ) {
    try {
      const user = await this.userService.findOneById(userId);

      if (!user) {
        throw new NotFoundException('User not found');
      }
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
      console.error('Error updating user challenge:', error);
      throw new NotFoundException('Failed to update user challenge');
    }
  }

  async findOne(userId: string, challengeId: string) {
    const user = await this.userService.findOneById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.userChallenge.findUnique({
      where: {
        userId_challengeId: {
          userId,
          challengeId,
        },
      },
    });
  }

  async remove(joinUserChallenge: JoinUserChallengeInput, userId: string) {
    // Optionally verify that the user exists
    const user = await this.userService.findOneById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.userChallenge.delete({
      where: {
        userId_challengeId: {
          userId: userId,
          challengeId: joinUserChallenge.challengeId,
        },
      },
    });
  }
}
