import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { LeagueuserService } from './leagueuser.service';
import { Leagueuser } from './entities/leagueuser.entity';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { RemoveLeagueuserResponse } from './entities/remove-leagueuser.response';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';
import { PinoLogger } from 'nestjs-pino';

@Resolver(() => Leagueuser)
export class LeagueuserResolver {
  constructor(
    private readonly leagueuserService: LeagueuserService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(LeagueuserResolver.name);
  }

  @Mutation(() => Leagueuser)
  @UseGuards(GqlAuthGuard)
  createLeagueuser(
    @Args('createLeagueuserInput') createLeagueuserInput: CreateLeagueuserInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, input: createLeagueuserInput },
        'User joining league',
      );
      return this.leagueuserService.create(
        createLeagueuserInput,
        payload.userId,
      );
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, input: createLeagueuserInput },
        'Error joining league',
      );
      throw error;
    }
  }

  @Query(() => [Leagueuser], { name: 'leagueusers' })
  @UseGuards(GqlAuthGuard)
  findAll(
    @Args('createLeagueuserInput') createLeagueuserInput: CreateLeagueuserInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, leagueId: createLeagueuserInput.leagueId },
        'Finding users in league',
      );
      return this.leagueuserService.findAll(
        createLeagueuserInput,
        payload.userId,
      );
    } catch (error) {
      this.logger.error(
        {
          error,
          userId: payload.userId,
          leagueId: createLeagueuserInput.leagueId,
        },
        'Error finding users in league',
      );
      throw error;
    }
  }

  @Query(() => Leagueuser, { name: 'leagueuser' })
  @UseGuards(GqlAuthGuard)
  findOne(
    @Args('leagueId', { type: () => String }) leagueId: string,
    @Args('userId', { type: () => String }) userId: string,
  ) {
    try {
      this.logger.info({ leagueId, userId }, 'Finding league user');
      return this.leagueuserService.findOne(leagueId, userId);
    } catch (error) {
      this.logger.error(
        { error, leagueId, userId },
        'Error finding league user',
      );
      throw error;
    }
  }

  @Mutation(() => RemoveLeagueuserResponse)
  @UseGuards(GqlAuthGuard)
  removeLeagueuser(
    @Args('leagueId', { type: () => String }) leagueId: string,
    @Args('userId', { type: () => String }) userId: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, removeUserId: userId, leagueId },
        'Removing user from league',
      );
      return this.leagueuserService.remove(leagueId, payload.userId, userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, removeUserId: userId, leagueId },
        'Error removing user from league',
      );
      throw error;
    }
  }
}
