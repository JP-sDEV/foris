import {
  NotFoundException,
  Injectable,
  InternalServerErrorException,
  ForbiddenException,
} from '@nestjs/common';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PostService {
  constructor(private prisma: PrismaService) {}

  async create(createPostInput: CreatePostInput, userId: string) {
    try {
      return await this.prisma.post.create({
        data: {
          title: createPostInput.title,
          content: createPostInput.content,
          author: {
            connect: { id: userId },
          },
        },
      });
    } catch (error) {
      console.error('Error creating post:', error);
      throw new InternalServerErrorException('Failed to create post');
    }
  }

  async findAll() {
    try {
      return await this.prisma.post.findMany({
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    } catch (error) {
      console.error('Error creating post:', error);
      throw new InternalServerErrorException('Failed to fetch posts');
    }
  }

  async findOne(id: string) {
    try {
      const post = await this.prisma.post.findUnique({
        where: { id },
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });

      if (!post) {
        throw new NotFoundException(`Post with ID ${id} not found`);
      }

      return post;
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to fetch post');
    }
  }

  // Gets all posts that belong to a specific user
  async findUserPosts(userId: string) {
    try {
      const posts = await this.prisma.post.findMany({
        where: { authorId: userId },
        // Optionally include related data
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });

      return posts;
    } catch (error) {
      console.error('Error fetching posts for user:', error);
      throw new InternalServerErrorException(
        'Failed to fetch posts for the user',
      );
    }
  }

  async update(updatePostInput: UpdatePostInput, userId: string) {
    try {
      // Ensure post exists
      const existing = await this.prisma.post.findUnique({
        where: { id: updatePostInput.id },
      });

      if (!existing) {
        throw new NotFoundException(
          `Post with ID ${updatePostInput.id} not found`,
        );
      }

      // Check ownership
      if (existing.authorId !== userId) {
        throw new ForbiddenException(
          `You do not have permission to update this post`,
        );
      }

      return await this.prisma.post.update({
        where: { id: updatePostInput.id },
        data: updatePostInput,
      });
    } catch (error) {
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to update post');
    }
  }

  async remove(id: string, userId: string) {
    try {
      const existing = await this.prisma.post.findUnique({ where: { id } });

      if (!existing) {
        throw new NotFoundException(`Post with ID ${id} not found`);
      }

      if (existing.authorId !== userId) {
        throw new ForbiddenException(
          `You do not have permission to update this post`,
        );
      }

      return await this.prisma.post.delete({
        where: { id },
      });
    } catch (error) {
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error; // let these bubble up
      }
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
