import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UserfollowService } from './userfollow.service';
import { Userfollow } from './entities/userfollow.entity';
import { CreateUserfollowInput } from './dto/create-userfollow.input';
import { UpdateUserfollowInput } from './dto/update-userfollow.input';

@Resolver(() => Userfollow)
export class UserfollowResolver {
  constructor(private readonly userfollowService: UserfollowService) {}

  @Mutation(() => Userfollow)
  createUserfollow(@Args('createUserfollowInput') createUserfollowInput: CreateUserfollowInput) {
    return this.userfollowService.create(createUserfollowInput);
  }

  @Query(() => [Userfollow], { name: 'userfollow' })
  findAll() {
    return this.userfollowService.findAll();
  }

  @Query(() => Userfollow, { name: 'userfollow' })
  findOne(@Args('id', { type: () => Int }) id: number) {
    return this.userfollowService.findOne(id);
  }

  @Mutation(() => Userfollow)
  updateUserfollow(@Args('updateUserfollowInput') updateUserfollowInput: UpdateUserfollowInput) {
    return this.userfollowService.update(updateUserfollowInput.id, updateUserfollowInput);
  }

  @Mutation(() => Userfollow)
  removeUserfollow(@Args('id', { type: () => Int }) id: number) {
    return this.userfollowService.remove(id);
  }
}
