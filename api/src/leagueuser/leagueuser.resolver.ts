import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { LeagueuserService } from './leagueuser.service';
import { Leagueuser } from './entities/leagueuser.entity';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { UpdateLeagueuserInput } from './dto/update-leagueuser.input';

@Resolver(() => Leagueuser)
export class LeagueuserResolver {
  constructor(private readonly leagueuserService: LeagueuserService) {}

  @Mutation(() => Leagueuser)
  createLeagueuser(@Args('createLeagueuserInput') createLeagueuserInput: CreateLeagueuserInput) {
    return this.leagueuserService.create(createLeagueuserInput);
  }

  @Query(() => [Leagueuser], { name: 'leagueuser' })
  findAll() {
    return this.leagueuserService.findAll();
  }

  @Query(() => Leagueuser, { name: 'leagueuser' })
  findOne(@Args('id', { type: () => Int }) id: number) {
    return this.leagueuserService.findOne(id);
  }

  @Mutation(() => Leagueuser)
  updateLeagueuser(@Args('updateLeagueuserInput') updateLeagueuserInput: UpdateLeagueuserInput) {
    return this.leagueuserService.update(updateLeagueuserInput.id, updateLeagueuserInput);
  }

  @Mutation(() => Leagueuser)
  removeLeagueuser(@Args('id', { type: () => Int }) id: number) {
    return this.leagueuserService.remove(id);
  }
}
