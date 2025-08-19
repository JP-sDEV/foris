import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { ChallengeService } from './challenge.service';
import { Challenge } from './entities/challenge.entity';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Resolver(() => Challenge)
export class ChallengeResolver {
  constructor(private readonly challengeService: ChallengeService) {}

  @Mutation(() => Challenge)
  @UseGuards(GqlAuthGuard)
  async createChallenge(
    @Args('createChallengeInput') createChallengeInput: CreateChallengeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.challengeService.create(createChallengeInput, user.sub);
    } catch (error) {
      console.error('Error creating challenge:', error);
      throw new InternalServerErrorException('Failed to create challenge');
    }
  }

  @Query(() => Challenge)
  @UseGuards(GqlAuthGuard)
  async challenge(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.challengeService.findOneByIdUser(id, user.sub);
    } catch (error) {
      console.error('Error fetching challenge:', error);
      throw new InternalServerErrorException('Failed to fetch challenge');
    }
  }

  @Query(() => Challenge)
  @UseGuards(GqlAuthGuard)
  async findOneById(@Args('id', { type: () => String }) id: string) {
    try {
      return await this.challengeService.findOneById(id);
    } catch (error) {
      console.error('Error fetching challenge by ID:', error);
      throw new InternalServerErrorException('Failed to fetch challenge by ID');
    }
  }

  // Optional: If you plan to implement findAll
  @Query(() => [Challenge])
  async challenges() {
    // Add implementation if you have a `findAll` method
    throw new Error('Not implemented');
  }

  @Mutation(() => Challenge)
  @UseGuards(GqlAuthGuard)
  async updateChallenge(
    @Args('updateChallengeInput') updateChallengeInput: UpdateChallengeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.challengeService.update(
        updateChallengeInput.id,
        updateChallengeInput,
        user.sub,
      );
    } catch (error) {
      console.error('Error updating challenge:', error);
      throw new InternalServerErrorException('Failed to update challenge');
    }
  }

  @Mutation(() => Challenge)
  @UseGuards(GqlAuthGuard)
  async removeChallenge(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.challengeService.remove(id, user.sub);
    } catch (error) {
      console.error('Error removing challenge:', error);
      throw new InternalServerErrorException('Failed to remove challenge');
    }
  }
}
