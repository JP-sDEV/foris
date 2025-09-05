import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
  ForbiddenException,
} from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';
import { CreateCommentInput } from './dto/create-comment.input';
import { UpdateCommentInput } from './dto/update-comment.input';
import { PostService } from '../post/post.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CommentService {
  constructor(
    private postService: PostService,
    private prisma: PrismaService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(CommentService.name);
  }
  async create(userId: string, createCommentInput: CreateCommentInput) {
    try {
      // throws error if not found
      await this.postService.findOne(createCommentInput.postId);

      this.logger.info(
        { userId, postId: createCommentInput.postId },
        'Creating comment',
      );

      return await this.prisma.comment.create({
        data: {
          content: createCommentInput.content,
          post: {
            connect: { id: createCommentInput.postId },
          },
          user: {
            connect: { id: userId },
          },
        },
        include: {
          user: true,
          post: true,
        },
      });
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      this.logger.error(
        { error, userId, postId: createCommentInput.postId },
        'Error creating comment',
      );
      throw new InternalServerErrorException('Failed to create comment');
    }
  }

  async findOne(id: string) {
    try {
      const comment = await this.prisma.comment.findUnique({
        where: { id },
        include: {
          post: true,
          user: true,
        },
      });

      if (!comment) {
        this.logger.error({ id }, 'Comment not found');
        throw new NotFoundException(`Comment with ID ${id} not found`);
      }

      this.logger.info({ id }, 'Comment fetched successfully');

      return comment;
    } catch (error) {
      this.logger.error({ error, id }, 'Error fetching comment');
      throw new InternalServerErrorException('Failed to fetch comment');
    }
  }

  async update(userId: string, updateCommentInput: UpdateCommentInput) {
    try {
      const existingComment = await this.prisma.comment.findUnique({
        where: { id: updateCommentInput.id },
      });

      if (!existingComment) {
        this.logger.error(
          { id: updateCommentInput.id },
          'Comment to update not found',
        );
        throw new NotFoundException(
          `Comment with ID ${updateCommentInput.id} not found`,
        );
      }

      if (existingComment.userId !== userId) {
        this.logger.error(
          { userId, id: updateCommentInput.id },
          'Unauthorized update attempt',
        );
        throw new ForbiddenException(
          this.logger.error(
            { userId, id: updateCommentInput.id },
            'Unauthorized update attempt',
          ),
          `You are not authorized to update this comment`,
        );
      }

      this.logger.info(
        { userId, id: updateCommentInput.id },
        'Updating comment',
      );

      return await this.prisma.comment.update({
        where: { id: updateCommentInput.id },
        data: {
          content: updateCommentInput.content,
        },
        include: {
          post: true,
          user: true,
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, id: updateCommentInput.id },
        'Error updating comment',
      );

      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }

      throw new InternalServerErrorException('Failed to update comment');
    }
  }

  async remove(userId: string, id: string) {
    try {
      const existingComment = await this.prisma.comment.findUnique({
        where: { id },
      });

      if (!existingComment) {
        throw new NotFoundException(`Comment with ID ${id} not found`);
      }

      if (existingComment.userId !== userId) {
        throw new ForbiddenException(
          `You are not authorized to delete this comment`,
        );
      }

      this.logger.info({ userId, id }, 'Deleting comment');

      return await this.prisma.comment.delete({
        where: { id },
      });
    } catch (error) {
      this.logger.error({ error, userId, id: id }, 'Error updating comment');

      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }

      console.error('Error deleting comment:', error);
      throw new InternalServerErrorException('Failed to delete comment');
    }
  }
}
