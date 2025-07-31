import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
  ForbiddenException,
} from '@nestjs/common';
import { CreateCommentInput } from './dto/create-comment.input';
import { UpdateCommentInput } from './dto/update-comment.input';
import { PostService } from '../post/post.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CommentService {
  constructor(
    private postService: PostService,
    private prisma: PrismaService,
  ) {}
  async create(userId: string, createCommentInput: CreateCommentInput) {
    try {
      await this.postService.findOne(createCommentInput.postId);
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
      console.error('Error creating comment:', error);
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
        throw new NotFoundException(`Comment with ID ${id} not found`);
      }

      return comment;
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      console.error('Error finding comment:', error);
      throw new InternalServerErrorException('Failed to fetch comment');
    }
  }

  async update(userId: string, updateCommentInput: UpdateCommentInput) {
    try {
      const existingComment = await this.prisma.comment.findUnique({
        where: { id: updateCommentInput.id },
      });

      if (!existingComment) {
        throw new NotFoundException(
          `Comment with ID ${updateCommentInput.id} not found`,
        );
      }

      if (existingComment.userId !== userId) {
        throw new ForbiddenException(
          `You are not authorized to update this comment`,
        );
      }

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
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }

      console.error('Error updating comment:', error);
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

      return await this.prisma.comment.delete({
        where: { id },
      });
    } catch (error) {
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
