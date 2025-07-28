import {
  NotFoundException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PostService {
  constructor(private prisma: PrismaService) {}

  async create(createPostInput: CreatePostInput) {
    try {
      return await this.prisma.post.create({
        data: {
          title: createPostInput.title,
          content: createPostInput.content,
          author: {
            connect: { id: createPostInput.authorId },
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

  async update(id: string, updatePostInput: UpdatePostInput) {
    try {
      // Ensure post exists
      const existing = await this.prisma.post.findUnique({ where: { id } });
      if (!existing) {
        throw new NotFoundException(`Post with ID ${id} not found`);
      }

      return await this.prisma.post.update({
        where: { id },
        data: updatePostInput,
      });
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to update post');
    }
  }

  async remove(id: string) {
    try {
      // Ensure post exists
      const existing = await this.prisma.post.findUnique({ where: { id } });
      if (!existing) {
        throw new NotFoundException(`Post with ID ${id} not found`);
      }

      return await this.prisma.post.delete({
        where: { id },
      });
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
