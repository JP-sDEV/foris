import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { UserchallengeService } from './userchallenge.service';
import { Userchallenge } from './entities/userchallenge.entity';
import { JoinUserChallengeInput } from './dto/join-userchallenge.input';
import { UpdateUserChallengeInput } from './dto/update-userchallenge.input';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';

@Resolver(() => Userchallenge)
export class UserchallengeResolver {
  constructor(private readonly userchallengeService: UserchallengeService) {}

  @Mutation(() => Userchallenge)
  @UseGuards(GqlAuthGuard)
  async joinUserChallenge(
    @Args('joinUserChallengeInput')
    joinUserChallengeInput: JoinUserChallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return await this.userchallengeService.create(
        joinUserChallengeInput,
        payload.userId,
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
  @UseGuards(GqlAuthGuard)
  async updateUserChallenge(
    @Args('updateUserChallengeInput')
    updateUserChallengeInput: UpdateUserChallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return await this.userchallengeService.update(
        updateUserChallengeInput,
        payload.userId,
      );
    } catch (error) {
      console.error('Error updating user challenge:', error);
      throw new Error('Failed to update user challenge');
    }
  }

  @Query(() => Userchallenge, { name: 'userchallenge' })
  @UseGuards(GqlAuthGuard)
  async findOne(
    @Args('joinUserChallengeInput')
    joinUserChallengeInput: JoinUserChallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return await this.userchallengeService.findOne(
        payload.userId,
        joinUserChallengeInput.challengeId,
      );
    } catch (error) {
      console.error('Error finding user challenge:', error);
      throw new Error('Failed to find user challenge');
    }
  }

  @Mutation(() => Userchallenge)
  @UseGuards(GqlAuthGuard)
  async removeUserChallenge(
    @Args('joinUserChallengeInput')
    joinUserChallengeInput: JoinUserChallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return await this.userchallengeService.remove(
        joinUserChallengeInput,
        payload.userId,
      );
    } catch (error) {
      console.error('Error removing user challenge:', error);
      throw new Error('Failed to remove user challenge');
    }
  }
}
