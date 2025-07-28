import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
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
  async createPost(@Args('createPostInput') createPostInput: CreatePostInput) {
    try {
      return await this.postService.create(createPostInput);
    } catch (error) {
      console.error('Error creating post:', error);
      throw new InternalServerErrorException('Failed to create post');
    }
  }

  // @Query(() => [Post], { name: 'post' })
  // async findAll() {
  //   try {
  //     return await this.postService.findAll();
  //   } catch (error) {
  //     console.error('Error creating post:', error);
  //     throw new InternalServerErrorException('Failed to fetch posts');
  //   }
  // }

  @Query(() => Post, { name: 'post' })
  async findOne(@Args('id', { type: () => Int }) id: string) {
    try {
      return await this.postService.findOne(id);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to fetch post');
    }
  }

  @Mutation(() => Post)
  async updatePost(@Args('updatePostInput') updatePostInput: UpdatePostInput) {
    try {
      return await this.postService.update(updatePostInput.id, updatePostInput);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to update post');
    }
  }

  @Mutation(() => Post)
  async removePost(@Args('id', { type: () => Int }) id: string) {
    try {
      return await this.postService.remove(id);
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
