import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { LeagueuserService } from './leagueuser.service';
import { Leagueuser } from './entities/leagueuser.entity';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { RemoveLeagueuserResponse } from './entities/remove-leagueuser.response';
import { GqlAuthGuard } from '../auth/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Resolver(() => Leagueuser)
export class LeagueuserResolver {
  constructor(private readonly leagueuserService: LeagueuserService) {}

  // User joins league
  @Mutation(() => Leagueuser)
  @UseGuards(GqlAuthGuard)
  createLeagueuser(
    @Args('createLeagueuserInput') createLeagueuserInput: CreateLeagueuserInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueuserService.create(createLeagueuserInput, user.sub);
    } catch (error) {
      console.error('Error joining league:', error);
      throw new Error('Failed to join league user');
    }
  }

  @Query(() => [Leagueuser], { name: 'leagueusers' }) // Changed name to plural
  @UseGuards(GqlAuthGuard)
  findAll(
    @Args('createLeagueuserInput') createLeagueuserInput: CreateLeagueuserInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueuserService.findAll(createLeagueuserInput, user.sub);
    } catch (error) {
      console.error('Error finding users in league:', error);
      throw new Error('Failed to find users in league');
    }
  }

  @Query(() => Leagueuser, { name: 'leagueuser' })
  @UseGuards(GqlAuthGuard)
  findOne(
    @Args('leagueId', { type: () => String }) leagueId: string,
    @Args('userId', { type: () => String }) userId: string, // Added @Args decorator
  ) {
    try {
      return this.leagueuserService.findOne(leagueId, userId);
    } catch (error) {
      console.error('Error finding league user:', error);
      throw new Error('Failed to find league user');
    }
  }
  @Mutation(() => RemoveLeagueuserResponse)
  @UseGuards(GqlAuthGuard)
  removeLeagueuser(
    @Args('leagueId', { type: () => String }) leagueId: string,
    @Args('userId', { type: () => String }) userId: string,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueuserService.remove(leagueId, user.sub, userId);
    } catch (error) {
      console.error('Error removing user from league:', error);
      throw new Error('Failed to remove user from league');
    }
  }
}
