import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UserfollowService } from './userfollow.service';
import { Userfollow } from './entities/userfollow.entity';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../user/entities/user.entity';

@Resolver(() => Userfollow)
export class UserfollowResolver {
  constructor(private readonly userfollowService: UserfollowService) {}

  @Mutation(() => Boolean)
  @UseGuards(GqlAuthGuard)
  async followUser(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() currentUser: any,
  ): Promise<boolean> {
    try {
      return await this.userfollowService.followUser(
        currentUser.sub,
        targetUserId,
      );
    } catch (error) {
      console.error('Error following user:', error);
      throw new InternalServerErrorException('Failed to follow user');
    }
  }

  @Mutation(() => Boolean)
  @UseGuards(GqlAuthGuard)
  async unfollowUser(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() currentUser: any,
  ): Promise<boolean> {
    try {
      return await this.userfollowService.unfollowUser(
        currentUser.sub,
        targetUserId,
      );
    } catch (error) {
      console.error('Error unfollowing user:', error);
      throw new InternalServerErrorException('Failed to unfollow user');
    }
  }

  @Query(() => [User])
  async getFollowers(@Args('userId') userId: string): Promise<User[]> {
    try {
      return await this.userfollowService.getFollowers(userId);
    } catch (error) {
      console.error('Error fetching followers:', error);
      throw new InternalServerErrorException('Failed to get followers');
    }
  }

  @Query(() => [User])
  async getFollowing(@Args('userId') userId: string): Promise<User[]> {
    try {
      return await this.userfollowService.getFollowing(userId);
    } catch (error) {
      console.error('Error fetching following:', error);
      throw new InternalServerErrorException('Failed to get following');
    }
  }

  @Query(() => Int)
  async getFollowerCount(@Args('userId') userId: string): Promise<number> {
    try {
      return await this.userfollowService.getFollowerCount(userId);
    } catch (error) {
      console.error('Error getting follower count:', error);
      throw new InternalServerErrorException('Failed to get follower count');
    }
  }

  @Query(() => Int)
  async getFollowingCount(@Args('userId') userId: string): Promise<number> {
    try {
      return await this.userfollowService.getFollowingCount(userId);
    } catch (error) {
      console.error('Error getting following count:', error);
      throw new InternalServerErrorException('Failed to get following count');
    }
  }

  @Query(() => Boolean)
  @UseGuards(GqlAuthGuard)
  async isFollowing(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() currentUser: any,
  ): Promise<boolean> {
    try {
      return await this.userfollowService.isFollowing(
        currentUser.sub,
        targetUserId,
      );
    } catch (error) {
      console.error('Error checking follow status:', error);
      throw new InternalServerErrorException('Failed to check follow status');
    }
  }
}
