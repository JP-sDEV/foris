import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { LeagueService } from './league.service';
import { League } from './entities/league.entity';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Resolver(() => League)
export class LeagueResolver {
  constructor(private readonly leagueService: LeagueService) {}

  @Mutation(() => League)
  @UseGuards(GqlAuthGuard)
  createLeague(
    @Args('createLeagueInput') createLeagueInput: CreateLeagueInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueService.create(createLeagueInput, user.sub);
    } catch (error) {
      console.error('Error creating league:', error);
      throw new InternalServerErrorException('Failed to create league');
    }
  }

  // @Query(() => [League], { name: 'league' })
  // findAll() {
  //   return this.leagueService.findAll();
  // }

  @Query(() => League, { name: 'league' })
  @UseGuards(GqlAuthGuard)
  findOneByIdUser(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueService.findOneByIdUser(id, user.sub);
    } catch (error) {
      console.error('Error finding league:', error);
      throw new InternalServerErrorException('Failed to find league');
    }
  }

  @Query(() => League)
  @UseGuards(GqlAuthGuard)
  async findLeagueById(@Args('id', { type: () => String }) id: string) {
    try {
      return this.leagueService.findOneById(id);
    } catch (error) {
      console.error('Error finding league:', error);
      throw new InternalServerErrorException('Failed to find league');
    }
  }

  @Mutation(() => League)
  @UseGuards(GqlAuthGuard)
  updateLeague(
    @Args('updateLeagueInput') updateLeagueInput: UpdateLeagueInput,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueService.update(updateLeagueInput, user.sub);
    } catch (error) {
      console.error('Error updating league:', error);
      throw new InternalServerErrorException('Failed to update league');
    }
  }

  @Mutation(() => League)
  @UseGuards(GqlAuthGuard)
  removeLeague(
    @Args('id', { type: () => Int }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return this.leagueService.remove(id, user.sub);
    } catch (error) {
      console.error('Error deleting league:', error);
      throw new InternalServerErrorException('Failed to delete league');
    }
  }
}
