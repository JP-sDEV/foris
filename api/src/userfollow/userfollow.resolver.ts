import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UserfollowService } from './userfollow.service';
import { Userfollow } from './entities/userfollow.entity';
import { CreateUserfollowInput } from './dto/create-userfollow.input';
import { UpdateUserfollowInput } from './dto/update-userfollow.input';
import { UseGuards } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../user/entities/user.entity';

@Resolver(() => Userfollow)
export class UserfollowResolver {
  constructor(private readonly userfollowService: UserfollowService) {}

  @Mutation(() => Boolean)
  @UseGuards(GqlAuthGuard)
  followUser(
    @Args('targetUserId') targetUserId: string,
    @CurrentUser() currentUser: User,
  ): Promise<boolean> {
    return this.userfollowService.followUser(currentUser.id: string, targetUserId);
  }

  // @Mutation(() => Boolean)
  // unfollowUser(
  //   @Args('targetUserId') targetUserId: string,
  //   @CurrentUser() currentUser: User,
  // ): Promise<boolean>

  // @Query(() => [User])
  // getFollowers(
  //   @Args('userId') userId: string,
  // ): Promise<User[]>

  // @Query(() => [User])
  // getFollowing(
  //   @Args('userId') userId: string,
  // ): Promise<User[]>

  // @Query(() => Int)
  // getFollowerCount(
  //   @Args('userId') userId: string,
  // ): Promise<number>

  // @Query(() => Int)
  // getFollowingCount(
  //   @Args('userId') userId: string,
  // ): Promise<number>

  // @Query(() => Boolean)
  // isFollowing(
  //   @Args('targetUserId') targetUserId: string,
  //   @CurrentUser() currentUser: User,
  // ): Promise<boolean>
}
