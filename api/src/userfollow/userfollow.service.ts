// userfollow.service.ts
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { User } from '../user/entities/user.entity';

@Injectable()
export class UserfollowService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
  ) {}

  private async validateUserExists(userId: string) {
    const user = await this.userService.findOneById(userId);
    if (!user) {
      throw new InternalServerErrorException(
        `User with ID ${userId} not found`,
      );
    }
  }

  async followUser(
    currentUserId: string,
    targetUserId: string,
  ): Promise<boolean> {
    if (currentUserId === targetUserId) {
      throw new InternalServerErrorException('Cannot follow yourself');
    }

    await this.validateUserExists(currentUserId);
    await this.validateUserExists(targetUserId);

    const existingFollow = await this.prisma.userFollow.findUnique({
      where: {
        followId_followingId: {
          followId: currentUserId,
          followingId: targetUserId,
        },
      },
    });

    if (existingFollow) return true;

    await this.prisma.userFollow.create({
      data: { followId: currentUserId, followingId: targetUserId },
    });

    return true;
  }

  async unfollowUser(
    currentUserId: string,
    targetUserId: string,
  ): Promise<boolean> {
    await this.validateUserExists(currentUserId);
    await this.validateUserExists(targetUserId);

    await this.prisma.userFollow.deleteMany({
      where: { followId: currentUserId, followingId: targetUserId },
    });

    return true;
  }

  async getFollowers(userId: string): Promise<User[]> {
    await this.validateUserExists(userId);

    const followers = await this.prisma.userFollow.findMany({
      where: { followingId: userId },
      include: {
        follower: {
          select: {
            id: true,
            name: true,
            email: true,
            bio: true,
            avatarUrl: true,
          },
        },
      },
    });

    return followers.map((f) => f.follower);
  }

  async getFollowing(userId: string): Promise<User[]> {
    await this.validateUserExists(userId);

    const following = await this.prisma.userFollow.findMany({
      where: { followId: userId },
      include: {
        following: {
          select: {
            id: true,
            name: true,
            email: true,
            bio: true,
            avatarUrl: true,
          },
        },
      },
    });

    return following.map((f) => f.following);
  }

  async getFollowerCount(userId: string): Promise<number> {
    await this.validateUserExists(userId);
    return this.prisma.userFollow.count({ where: { followingId: userId } });
  }

  async getFollowingCount(userId: string): Promise<number> {
    await this.validateUserExists(userId);
    return this.prisma.userFollow.count({ where: { followId: userId } });
  }

  async isFollowing(
    currentUserId: string,
    targetUserId: string,
  ): Promise<boolean> {
    await this.validateUserExists(currentUserId);
    await this.validateUserExists(targetUserId);

    const follow = await this.prisma.userFollow.findUnique({
      where: {
        followId_followingId: {
          followId: currentUserId,
          followingId: targetUserId,
        },
      },
    });

    return !!follow;
  }
}
