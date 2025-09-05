import {
  NotFoundException,
  Injectable,
  InternalServerErrorException,
  ForbiddenException,
} from '@nestjs/common';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import { PrismaService } from '../prisma/prisma.service';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class PostService {
  constructor(
    private prisma: PrismaService,
    private logger: PinoLogger,
  ) {
    this.logger.setContext(PostService.name);
  }

  async create(createPostInput: CreatePostInput, userId: string) {
    try {
      this.logger.info(
        { userId, title: createPostInput.title },
        'Creating post',
      );
      return await this.prisma.post.create({
        data: {
          title: createPostInput.title,
          content: createPostInput.content,
          author: { connect: { id: userId } },
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, title: createPostInput.title },
        'Error creating post',
      );
      throw new InternalServerErrorException('Failed to create post');
    }
  }

  async findAll() {
    try {
      this.logger.info('Fetching all posts');
      return await this.prisma.post.findMany({
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    } catch (error) {
      this.logger.error({ error }, 'Error fetching all posts');
      throw new InternalServerErrorException('Failed to fetch posts');
    }
  }

  async findOne(id: string) {
    try {
      this.logger.info({ postId: id }, 'Fetching post by ID');
      const post = await this.prisma.post.findUnique({
        where: { id },
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });

      if (!post) {
        this.logger.warn({ postId: id }, 'Post not found');
        throw new NotFoundException(`Post with ID ${id} not found`);
      }

      return post;
    } catch (error) {
      this.logger.error({ error, postId: id }, 'Error fetching post');
      if (error instanceof NotFoundException) throw error;
      throw new InternalServerErrorException('Failed to fetch post');
    }
  }

  async findUserPosts(userId: string) {
    try {
      this.logger.info({ userId }, 'Fetching posts for user');
      return await this.prisma.post.findMany({
        where: { authorId: userId },
        include: { author: true, comments: true, likes: true },
      });
    } catch (error) {
      this.logger.error({ error, userId }, 'Error fetching posts for user');
      throw new InternalServerErrorException('Failed to fetch posts for user');
    }
  }

  async update(updatePostInput: UpdatePostInput, userId: string) {
    try {
      this.logger.info({ userId, postId: updatePostInput.id }, 'Updating post');

      const existing = await this.prisma.post.findUnique({
        where: { id: updatePostInput.id },
      });

      if (!existing) {
        this.logger.warn({ postId: updatePostInput.id }, 'Post not found');
        throw new NotFoundException(
          `Post with ID ${updatePostInput.id} not found`,
        );
      }

      if (existing.authorId !== userId) {
        this.logger.warn(
          { userId, postId: updatePostInput.id },
          'Unauthorized update attempt',
        );
        throw new ForbiddenException(
          `You do not have permission to update this post`,
        );
      }

      return await this.prisma.post.update({
        where: { id: updatePostInput.id },
        data: updatePostInput,
      });
    } catch (error) {
      this.logger.error(
        { error, userId, postId: updatePostInput.id },
        'Error updating post',
      );
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      )
        throw error;
      throw new InternalServerErrorException('Failed to update post');
    }
  }

  async remove(id: string, userId: string) {
    try {
      this.logger.info({ userId, postId: id }, 'Removing post');
      const existing = await this.prisma.post.findUnique({ where: { id } });

      if (!existing) {
        this.logger.warn({ postId: id }, 'Post not found');
        throw new NotFoundException(`Post with ID ${id} not found`);
      }

      if (existing.authorId !== userId) {
        this.logger.warn({ userId, postId: id }, 'Unauthorized delete attempt');
        throw new ForbiddenException(
          `You do not have permission to update this post`,
        );
      }

      return await this.prisma.post.delete({ where: { id } });
    } catch (error) {
      this.logger.error({ error, userId, postId: id }, 'Error deleting post');
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      )
        throw error;
      throw new InternalServerErrorException('Failed to delete post');
    }
  }
}
