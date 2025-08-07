import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UserchallengeService } from './userchallenge.service';
import { Userchallenge } from './entities/userchallenge.entity';
import { CreateUserchallengeInput } from './dto/create-userchallenge.input';
import { UpdateUserchallengeInput } from './dto/update-userchallenge.input';

@Resolver(() => Userchallenge)
export class UserchallengeResolver {
  constructor(private readonly userchallengeService: UserchallengeService) {}

  @Mutation(() => Userchallenge)
  createUserchallenge(@Args('createUserchallengeInput') createUserchallengeInput: CreateUserchallengeInput) {
    return this.userchallengeService.create(createUserchallengeInput);
  }

  @Query(() => [Userchallenge], { name: 'userchallenge' })
  findAll() {
    return this.userchallengeService.findAll();
  }

  @Query(() => Userchallenge, { name: 'userchallenge' })
  findOne(@Args('id', { type: () => Int }) id: number) {
    return this.userchallengeService.findOne(id);
  }

  @Mutation(() => Userchallenge)
  updateUserchallenge(@Args('updateUserchallengeInput') updateUserchallengeInput: UpdateUserchallengeInput) {
    return this.userchallengeService.update(updateUserchallengeInput.id, updateUserchallengeInput);
  }

  @Mutation(() => Userchallenge)
  removeUserchallenge(@Args('id', { type: () => Int }) id: number) {
    return this.userchallengeService.remove(id);
  }
}
