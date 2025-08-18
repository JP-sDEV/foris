import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { LeaguechallengeService } from './leaguechallenge.service';
import { Leaguechallenge } from './entities/leaguechallenge.entity';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';

@Resolver(() => Leaguechallenge)
export class LeaguechallengeResolver {
  constructor(private readonly leaguechallengeService: LeaguechallengeService) {}

  @Mutation(() => Leaguechallenge)
  createLeaguechallenge(@Args('createLeaguechallengeInput') createLeaguechallengeInput: CreateLeaguechallengeInput) {
    return this.leaguechallengeService.create(createLeaguechallengeInput);
  }

  @Query(() => [Leaguechallenge], { name: 'leaguechallenge' })
  findAll() {
    return this.leaguechallengeService.findAll();
  }

  @Query(() => Leaguechallenge, { name: 'leaguechallenge' })
  findOne(@Args('id', { type: () => Int }) id: number) {
    return this.leaguechallengeService.findOne(id);
  }

  @Mutation(() => Leaguechallenge)
  updateLeaguechallenge(@Args('updateLeaguechallengeInput') updateLeaguechallengeInput: UpdateLeaguechallengeInput) {
    return this.leaguechallengeService.update(updateLeaguechallengeInput.id, updateLeaguechallengeInput);
  }

  @Mutation(() => Leaguechallenge)
  removeLeaguechallenge(@Args('id', { type: () => Int }) id: number) {
    return this.leaguechallengeService.remove(id);
  }
}
