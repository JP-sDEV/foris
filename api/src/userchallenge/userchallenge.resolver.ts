// userchallenge.resolver.ts
import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { UserchallengeService } from './userchallenge.service';
import { Userchallenge } from './entities/userchallenge.entity';
import { JoinUserChallengeInput } from './dto/join-userchallenge.input';
import { UpdateUserChallengeInput } from './dto/update-userchallenge.input';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
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
      console.error(error);
      throw new InternalServerErrorException('Failed to join user challenge');
    }
  }

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
      console.error(error);
      throw new InternalServerErrorException('Failed to update user challenge');
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
      console.error(error);
      throw new InternalServerErrorException('Failed to find user challenge');
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
      console.error(error);
      throw new InternalServerErrorException('Failed to remove user challenge');
    }
  }
}
