import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { UserchallengeService } from './userchallenge.service';
import { Userchallenge } from './entities/userchallenge.entity';
import { JoinUserChallengeInput } from './dto/join-userchallenge.input';
import { UpdateUserChallengeInput } from './dto/update-userchallenge.input';
import { GqlAuthGuard } from '../auth/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Resolver(() => Userchallenge)
export class UserchallengeResolver {
  constructor(private readonly userchallengeService: UserchallengeService) {}

  @Mutation(() => Userchallenge)
  @UseGuards(GqlAuthGuard)
  async joinUserChallenge(
    @Args('joinUserChallengeInput')
    joinUserChallengeInput: JoinUserChallengeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.userchallengeService.create(
        joinUserChallengeInput,
        user.sub,
      );
    } catch (error) {
      console.error('Error joining user challenge:', error);
      throw new Error('Failed to join user challenge');
    }
  }

  // @Query(() => [Userchallenge], { name: 'userchallenge' })
  // findAll() {
  //   return this.userchallengeService.findAll();
  // }

  // Update challenge status
  @Mutation(() => Userchallenge)
  updateUserChallenge(
    @Args('updateUserChallengeInput')
    updateUserChallengeInput: UpdateUserChallengeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.userchallengeService.update(
        updateUserChallengeInput,
        user.sub,
      );
    } catch (error) {
      console.error('Error updating user challenge:', error);
      throw new Error('Failed to update user challenge');
    }
  }

  @Query(() => Userchallenge, { name: 'userchallenge' })
  findOne(
    @Args('joinUserChallengeInput')
    joinUserChallengeInput: JoinUserChallengeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.userchallengeService.findOne(
        user.sub,
        joinUserChallengeInput.challengeId,
      );
    } catch (error) {
      console.error('Error finding user challenge:', error);
      throw new Error('Failed to find user challenge');
    }
  }

  @Mutation(() => Userchallenge)
  @UseGuards(GqlAuthGuard)
  removeUserChallenge(
    @Args('joinUserChallengeInput')
    joinUserChallengeInput: JoinUserChallengeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.userchallengeService.remove(joinUserChallengeInput, user.sub);
    } catch (error) {
      console.error('Error removing user challenge:', error);
      throw new Error('Failed to remove user challenge');
    }
  }
}
