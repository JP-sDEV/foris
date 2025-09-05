import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { PostService } from './post.service';
import { Post } from './entities/post.entity';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import {
  NotFoundException,
  InternalServerErrorException,
  ForbiddenException,
} from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';
import { PinoLogger } from 'nestjs-pino';

@Resolver(() => Post)
export class PostResolver {
  constructor(
    private readonly postService: PostService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(PostResolver.name);
  }

  @Mutation(() => Post)
  @UseGuards(GqlAuthGuard)
  async createPost(
    @Args('createPostInput') createPostInput: CreatePostInput,
    @CurrentUser() payload: JwtPayload,
  ): Promise<Post> {
    try {
      this.logger.info(
        { userId: payload.userId, title: createPostInput.title },
        'Creating post',
      );
      return await this.postService.create(createPostInput, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, title: createPostInput.title },
        'Error creating post',
      );
      throw new InternalServerErrorException('Failed to create post');
    }
  }

  @Query(() => Post, { name: 'post' })
  @UseGuards(GqlAuthGuard)
  async findOneById(@Args('id', { type: () => String }) id: string) {
    try {
      this.logger.info({ postId: id }, 'Fetching post by ID');
      return await this.postService.findOne(id);
    } catch (error) {
      this.logger.error({ error, postId: id }, 'Error fetching post by ID');
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to fetch post');
    }
  }

  @Query(() => [Post], { name: 'userPosts' })
  @UseGuards(GqlAuthGuard)
  async findUserPosts(@Args('userId', { type: () => String }) userId: string) {
    try {
      this.logger.info({ userId }, 'Fetching posts for user');
      return await this.postService.findUserPosts(userId);
    } catch (error) {
      this.logger.error({ error, userId }, 'Error fetching posts for user');
      throw new InternalServerErrorException('Failed to fetch posts for user');
    }
  }

  @Mutation(() => Post, { name: 'updatePost' })
  @UseGuards(GqlAuthGuard)
  async updatePost(
    @Args('updatePostInput') updatePostInput: UpdatePostInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, postId: updatePostInput.id },
        'Updating post',
      );
      return await this.postService.update(updatePostInput, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, postId: updatePostInput.id },
        'Error updating post',
      );
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to update post');
    }
  }

  @Mutation(() => Post)
  @UseGuards(GqlAuthGuard)
  async removePost(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info({ userId: payload.userId, postId: id }, 'Removing post');
      return await this.postService.remove(id, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, postId: id },
        'Error removing post',
      );
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
