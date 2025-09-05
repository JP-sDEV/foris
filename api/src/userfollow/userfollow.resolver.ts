// userfollow.resolver.ts
import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UserfollowService } from './userfollow.service';
import { Userfollow } from './entities/userfollow.entity';
import { User } from '../user/entities/user.entity';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';

@Resolver(() => Userfollow)
export class UserfollowResolver {
  constructor(private readonly userfollowService: UserfollowService) {}

  @Mutation(() => Boolean)
  @UseGuards(GqlAuthGuard)
  async followUser(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() payload: JwtPayload,
  ): Promise<boolean> {
    try {
      return await this.userfollowService.followUser(
        payload.userId,
        targetUserId,
      );
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to follow user');
    }
  }

  @Mutation(() => Boolean)
  @UseGuards(GqlAuthGuard)
  async unfollowUser(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() payload: JwtPayload,
  ): Promise<boolean> {
    try {
      return await this.userfollowService.unfollowUser(
        payload.userId,
        targetUserId,
      );
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to unfollow user');
    }
  }

  @Query(() => [User])
  async getFollowers(@Args('userId') userId: string): Promise<User[]> {
    try {
      return await this.userfollowService.getFollowers(userId);
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to get followers');
    }
  }

  @Query(() => [User])
  async getFollowing(@Args('userId') userId: string): Promise<User[]> {
    try {
      return await this.userfollowService.getFollowing(userId);
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to get following');
    }
  }

  @Query(() => Int)
  async getFollowerCount(@Args('userId') userId: string): Promise<number> {
    try {
      return await this.userfollowService.getFollowerCount(userId);
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to get follower count');
    }
  }

  @Query(() => Int)
  async getFollowingCount(@Args('userId') userId: string): Promise<number> {
    try {
      return await this.userfollowService.getFollowingCount(userId);
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to get following count');
    }
  }

  @Query(() => Boolean)
  @UseGuards(GqlAuthGuard)
  async isFollowing(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() payload: JwtPayload,
  ): Promise<boolean> {
    try {
      return await this.userfollowService.isFollowing(
        payload.userId,
        targetUserId,
      );
    } catch (error) {
      console.error(error);
      throw new InternalServerErrorException('Failed to check follow status');
    }
  }
}
