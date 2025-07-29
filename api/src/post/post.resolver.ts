import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { PostService } from './post.service';
import { Post } from './entities/post.entity';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import {
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';

@Resolver(() => Post)
export class PostResolver {
  constructor(private readonly postService: PostService) {}

  @Mutation(() => Post)
  async createPost(
    @Args('createPostInput') createPostInput: CreatePostInput,
  ): Promise<Post> {
    try {
      return await this.postService.create(createPostInput);
    } catch (error) {
      console.error('Error creating post:', error);
      throw new InternalServerErrorException('Failed to create post');
    }
  }

  @Query(() => Post, { name: 'post' })
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
  async findUserPosts(@Args('userId', { type: () => String }) userId: string) {
    return this.postService.findUserPosts(userId);
  }

  @Mutation(() => Post, { name: 'updatePost' })
  async updatePost(@Args('updatePostInput') updatePostInput: UpdatePostInput) {
    try {
      return await this.postService.update(updatePostInput.id, updatePostInput);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to update post');
    }
  }

  @Mutation(() => Post)
  async removePost(@Args('id', { type: () => String }) id: string) {
    try {
      return await this.postService.remove(id);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
