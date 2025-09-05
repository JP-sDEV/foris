import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { PinoLogger } from 'nestjs-pino';
import { CommentService } from './comment.service';
import { Comment } from './entities/comment.entity';
import { CreateCommentInput } from './dto/create-comment.input';
import { UpdateCommentInput } from './dto/update-comment.input';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { JwtPayload } from '../auth/types/jwt-payload.type';

@Resolver(() => Comment)
export class CommentResolver {
  constructor(
    private readonly commentService: CommentService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(CommentResolver.name);
  }

  @Mutation(() => Comment)
  @UseGuards(GqlAuthGuard)
  async createComment(
    @Args('createCommentInput') createCommentInput: CreateCommentInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, postId: createCommentInput.postId },
        'Creating comment',
      );

      return await this.commentService.create(
        payload.userId,
        createCommentInput,
      );
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, postId: createCommentInput.postId },
        'Error creating comment',
      );

      throw new InternalServerErrorException('Failed to create comment');
    }
  }

  @Query(() => Comment, { name: 'comment' })
  @UseGuards(GqlAuthGuard)
  async findOne(@Args('id', { type: () => String }) id: string) {
    try {
      this.logger.info({ id }, 'Finding comment by id');
      return await this.commentService.findOne(id);
    } catch (error) {
      this.logger.error({ error, id }, 'Error finding comment');
      throw new InternalServerErrorException('Failed to find comment');
    }
  }

  @Mutation(() => Comment)
  @UseGuards(GqlAuthGuard)
  async updateComment(
    @Args('updateCommentInput') updateCommentInput: UpdateCommentInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, id: updateCommentInput.id },
        'Updating comment',
      );
      return await this.commentService.update(
        payload.userId,
        updateCommentInput,
      );
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, id: updateCommentInput.id },
        'Error updating comment',
      );
      throw new InternalServerErrorException('Failed to update comment');
    }
  }

  @Mutation(() => Comment)
  @UseGuards(GqlAuthGuard)
  async removeComment(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info({ userId: payload.userId, id }, 'Removing comment');
      return await this.commentService.remove(payload.userId, id);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, id },
        'Error removing comment',
      );
      throw new InternalServerErrorException('Failed to remove comment');
    }
  }
}
