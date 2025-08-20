import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { LikeService } from './like.service';
import { Like } from './entities/like.entity';
import { CreateLikeInput } from './dto/create-like.input';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Resolver(() => Like)
export class LikeResolver {
  constructor(private readonly likeService: LikeService) {}

  @Mutation(() => Like)
  @UseGuards(GqlAuthGuard)
  async createLike(
    @Args('createLikeInput') createLikeInput: CreateLikeInput,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.likeService.create(user.sub, createLikeInput);
    } catch (error) {
      console.error('Error creating like:', error);
      throw new InternalServerErrorException('Failed to create like');
    }
  }

  @Query(() => Like, { name: 'like', nullable: true })
  @UseGuards(GqlAuthGuard)
  async findOne(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.likeService.findOne(user.sub, id);
    } catch (error) {
      console.error('Error finding like:', error);
      throw new InternalServerErrorException('Failed to find like');
    }
  }

  @Mutation(() => Like)
  @UseGuards(GqlAuthGuard)
  async removeLike(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.likeService.remove(user.sub, id);
    } catch (error) {
      console.error('Error removing like:', error);
      throw new InternalServerErrorException('Failed to remove like');
    }
  }
}
