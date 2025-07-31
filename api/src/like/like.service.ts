import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { CreateLikeInput } from './dto/create-like.input';
import { PostService } from '../post/post.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class LikeService {
  constructor(
    private postService: PostService,
    private prisma: PrismaService,
  ) {}
  async create(userId: string, createLikeInput: CreateLikeInput) {
    await this.postService.findOne(createLikeInput.postId);

    try {
      return await this.prisma.like.create({
        data: {
          post: {
            connect: { id: createLikeInput.postId },
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
      console.error('Error creating like:', error);
      throw new InternalServerErrorException('Failed to create like');
    }
  }

  async findOne(userId: string, postId: string) {
    try {
      const like = await this.prisma.like.findUnique({
        where: {
          userId_postId: {
            userId,
            postId,
          },
        },
      });

      return like;
    } catch (error) {
      console.error('Error finding like:', error);
      throw new InternalServerErrorException('Failed to find like');
    }
  }

  async remove(userId: string, id: string) {
    try {
      return await this.prisma.like.delete({
        where: {
          userId_postId: {
            userId,
            postId: id,
          },
        },
      });
    } catch (error) {
      console.error('Error removing like:', error);
      throw new InternalServerErrorException('Failed to remove like');
    }
  }
}
