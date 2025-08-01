import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { CommentService } from './comment.service';
import { Comment } from './entities/comment.entity';
import { CreateCommentInput } from './dto/create-comment.input';
import { UpdateCommentInput } from './dto/update-comment.input';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';

@Resolver(() => Comment)
export class CommentResolver {
  constructor(private readonly commentService: CommentService) {}

  @Mutation(() => Comment)
  @UseGuards(GqlAuthGuard)
  async createComment(
    @Args('createCommentInput') createCommentInput: CreateCommentInput,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.commentService.create(user.sub, createCommentInput);
    } catch (error) {
      console.error('Error creating comment:', error);
      throw new InternalServerErrorException('Failed to create comment');
    }
  }

  @Query(() => Comment, { name: 'comment' })
  @UseGuards(GqlAuthGuard)
  async findOne(@Args('id', { type: () => String }) id: string) {
    try {
      return await this.commentService.findOne(id);
    } catch (error) {
      console.error('Error finding comment:', error);
      throw new InternalServerErrorException('Failed to find comment');
    }
  }

  @Mutation(() => Comment)
  @UseGuards(GqlAuthGuard)
  async updateComment(
    @Args('updateCommentInput') updateCommentInput: UpdateCommentInput,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.commentService.update(user.sub, updateCommentInput);
    } catch (error) {
      console.error('Error updating comment:', error);
      throw new InternalServerErrorException('Failed to update comment');
    }
  }

  @Mutation(() => Comment)
  @UseGuards(GqlAuthGuard)
  async removeComment(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() user: any,
  ) {
    try {
      return await this.commentService.remove(user.sub, id);
    } catch (error) {
      console.error('Error removing comment:', error);
      throw new InternalServerErrorException('Failed to remove comment');
    }
  }
}
