import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { PostService } from './post.service';
import { Post } from './entities/post.entity';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import {
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';

@Resolver(() => Post)
export class PostResolver {
  constructor(private readonly postService: PostService) {}

  @Mutation(() => Post)
  @UseGuards(GqlAuthGuard)
  async createPost(
    @Args('createPostInput') createPostInput: CreatePostInput,
    @CurrentUser() payload: JwtPayload,
  ): Promise<Post> {
    try {
      return await this.postService.create(createPostInput, payload.userId);
    } catch (error) {
      console.error('Error creating post:', error);
      throw new InternalServerErrorException('Failed to create post');
    }
  }

  @Query(() => Post, { name: 'post' })
  @UseGuards(GqlAuthGuard)
  async findOneById(@Args('id', { type: () => String }) id: string) {
    try {
      return await this.postService.findOne(id);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to fetch post');
    }
  }

  // Gets all posts that belong to a specific user
  @Query(() => [Post], { name: 'userPosts' })
  @UseGuards(GqlAuthGuard)
  async findUserPosts(@Args('userId', { type: () => String }) userId: string) {
    return this.postService.findUserPosts(userId);
  }

  @Mutation(() => Post, { name: 'updatePost' })
  @UseGuards(GqlAuthGuard)
  async updatePost(
    @Args('updatePostInput') updatePostInput: UpdatePostInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return await this.postService.update(updatePostInput, payload.userId);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
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
      return await this.postService.remove(id, payload.userId);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
