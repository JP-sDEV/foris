import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { ChallengeService } from './challenge.service';
import { Challenge } from './entities/challenge.entity';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';

@Resolver(() => Challenge)
export class ChallengeResolver {
  constructor(private readonly challengeService: ChallengeService) {}

  @Mutation(() => Challenge)
  createChallenge(@Args('createChallengeInput') createChallengeInput: CreateChallengeInput) {
    return this.challengeService.create(createChallengeInput);
  }

  @Query(() => [Challenge], { name: 'challenge' })
  findAll() {
    return this.challengeService.findAll();
  }

  @Query(() => Challenge, { name: 'challenge' })
  findOne(@Args('id', { type: () => Int }) id: number) {
    return this.challengeService.findOne(id);
  }

  @Mutation(() => Challenge)
  updateChallenge(@Args('updateChallengeInput') updateChallengeInput: UpdateChallengeInput) {
    return this.challengeService.update(updateChallengeInput.id, updateChallengeInput);
  }

  @Mutation(() => Challenge)
  removeChallenge(@Args('id', { type: () => Int }) id: number) {
    return this.challengeService.remove(id);
  }
}
