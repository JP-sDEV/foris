import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { PinoLogger } from 'nestjs-pino';
import { LeagueService } from './league.service';
import { League } from './entities/league.entity';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';
import { UseGuards, InternalServerErrorException } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';

@Resolver(() => League)
export class LeagueResolver {
  constructor(
    private readonly leagueService: LeagueService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(LeagueResolver.name);
  }

  @Mutation(() => League)
  @UseGuards(GqlAuthGuard)
  async createLeague(
    @Args('createLeagueInput') createLeagueInput: CreateLeagueInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, input: createLeagueInput },
        'Creating league',
      );
      return await this.leagueService.create(createLeagueInput, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, input: createLeagueInput },
        'Error creating league',
      );
      throw new InternalServerErrorException('Failed to create league');
    }
  }

  @Query(() => League, { name: 'league' })
  @UseGuards(GqlAuthGuard)
  async findOneByIdUser(
    @Args('id', { type: () => String }) id: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, leagueId: id },
        'Finding league by ID for user',
      );
      return await this.leagueService.findOneByIdUser(id, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, leagueId: id },
        'Error finding league',
      );
      throw new InternalServerErrorException('Failed to find league');
    }
  }

  @Query(() => League)
  @UseGuards(GqlAuthGuard)
  async findLeagueById(@Args('id', { type: () => String }) id: string) {
    try {
      this.logger.info({ leagueId: id }, 'Finding league by ID');
      return this.leagueService.findOneById(id);
    } catch (error) {
      this.logger.error({ error, leagueId: id }, 'Error finding league');
      throw new InternalServerErrorException('Failed to find league');
    }
  }

  @Mutation(() => League)
  @UseGuards(GqlAuthGuard)
  async updateLeague(
    @Args('updateLeagueInput') updateLeagueInput: UpdateLeagueInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, input: updateLeagueInput },
        'Updating league',
      );
      return await this.leagueService.update(updateLeagueInput, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, input: updateLeagueInput },
        'Error updating league',
      );
      throw new InternalServerErrorException('Failed to update league');
    }
  }

  @Mutation(() => League)
  @UseGuards(GqlAuthGuard)
  async removeLeague(
    @Args('id', { type: () => ID }) id: string,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, leagueId: id },
        'Removing league',
      );
      return await this.leagueService.remove(id, payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, leagueId: id },
        'Error removing league',
      );
      throw new InternalServerErrorException('Failed to delete league');
    }
  }
}
