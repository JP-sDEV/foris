import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { LikeService } from './like.service';
import { Like } from './entities/like.entity';
import { CreateLikeInput } from './dto/create-like.input';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';
import { PinoLogger } from 'nestjs-pino';

@Resolver(() => Like)
export class LikeResolver {
  constructor(
    private readonly likeService: LikeService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(LikeResolver.name);
  }

  @Mutation(() => Like)
  @UseGuards(GqlAuthGuard)
  async createLike(
    @Args('createLikeInput') createLikeInput: CreateLikeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, postId: createLikeInput.postId },
        'Creating like',
      );
      return await this.likeService.create(payload.userId, createLikeInput);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, postId: createLikeInput.postId },
        'Error creating like',
      );
      throw new InternalServerErrorException('Failed to create like');
    }
  }

  @Query(() => Like, { name: 'like', nullable: true })
  @UseGuards(GqlAuthGuard)
  async findOne(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info({ userId: payload.userId, postId: id }, 'Finding like');
      return await this.likeService.findOne(payload.userId, id);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, postId: id },
        'Error finding like',
      );
      throw new InternalServerErrorException('Failed to find like');
    }
  }

  @Mutation(() => Like)
  @UseGuards(GqlAuthGuard)
  async removeLike(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info({ userId: payload.userId, postId: id }, 'Removing like');
      return await this.likeService.remove(payload.userId, id);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, postId: id },
        'Error removing like',
      );
      throw new InternalServerErrorException('Failed to remove like');
    }
  }
}
