import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { LeagueService } from './league.service';
import { League } from './entities/league.entity';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';

@Resolver(() => League)
export class LeagueResolver {
  constructor(private readonly leagueService: LeagueService) {}

  @Mutation(() => League)
  createLeague(@Args('createLeagueInput') createLeagueInput: CreateLeagueInput) {
    return this.leagueService.create(createLeagueInput);
  }

  @Query(() => [League], { name: 'league' })
  findAll() {
    return this.leagueService.findAll();
  }

  @Query(() => League, { name: 'league' })
  findOne(@Args('id', { type: () => Int }) id: number) {
    return this.leagueService.findOne(id);
  }

  @Mutation(() => League)
  updateLeague(@Args('updateLeagueInput') updateLeagueInput: UpdateLeagueInput) {
    return this.leagueService.update(updateLeagueInput.id, updateLeagueInput);
  }

  @Mutation(() => League)
  removeLeague(@Args('id', { type: () => Int }) id: number) {
    return this.leagueService.remove(id);
  }
}
