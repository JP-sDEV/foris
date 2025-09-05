import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { CreateLikeInput } from './dto/create-like.input';
import { PostService } from '../post/post.service';
import { PrismaService } from '../prisma/prisma.service';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class LikeService {
  constructor(
    private postService: PostService,
    private prisma: PrismaService,
    private logger: PinoLogger,
  ) {
    this.logger.setContext(LikeService.name);
  }

  async create(userId: string, createLikeInput: CreateLikeInput) {
    try {
      this.logger.info(
        { userId, postId: createLikeInput.postId },
        'Creating like',
      );

      await this.postService.findOne(createLikeInput.postId);

      return await this.prisma.like.create({
        data: {
          post: { connect: { id: createLikeInput.postId } },
          user: { connect: { id: userId } },
        },
        include: {
          user: true,
          post: true,
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, postId: createLikeInput.postId },
        'Error creating like',
      );
      throw new InternalServerErrorException('Failed to create like');
    }
  }

  async findOne(userId: string, postId: string) {
    try {
      this.logger.info({ userId, postId }, 'Finding like');

      return await this.prisma.like.findUnique({
        where: { userId_postId: { userId, postId } },
      });
    } catch (error) {
      this.logger.error({ error, userId, postId }, 'Error finding like');
      throw new InternalServerErrorException('Failed to find like');
    }
  }

  async remove(userId: string, postId: string) {
    try {
      this.logger.info({ userId, postId }, 'Removing like');

      return await this.prisma.like.delete({
        where: { userId_postId: { userId, postId } },
      });
    } catch (error) {
      this.logger.error({ error, userId, postId }, 'Error removing like');
      throw new InternalServerErrorException('Failed to remove like');
    }
  }
}
