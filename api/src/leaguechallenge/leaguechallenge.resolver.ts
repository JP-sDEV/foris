import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { LeaguechallengeService } from './leaguechallenge.service';
import { Leaguechallenge } from './entities/leaguechallenge.entity';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';
import { PinoLogger } from 'nestjs-pino';
import { InternalServerErrorException } from '@nestjs/common';

@Resolver(() => Leaguechallenge)
export class LeaguechallengeResolver {
  constructor(
    private readonly leaguechallengeService: LeaguechallengeService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(LeaguechallengeResolver.name);
  }

  @Mutation(() => Leaguechallenge)
  @UseGuards(GqlAuthGuard)
  async addLeaguechallenge(
    @Args('createLeaguechallengeInput')
    createLeaguechallengeInput: CreateLeaguechallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, input: createLeaguechallengeInput },
        'Adding challenge to league',
      );
      return await this.leaguechallengeService.create(
        createLeaguechallengeInput,
        payload.userId,
      );
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, input: createLeaguechallengeInput },
        'Error adding challenge to league',
      );
      throw new InternalServerErrorException(
        'Failed adding challenge to league',
      );
    }
  }

  @Mutation(() => Leaguechallenge)
  @UseGuards(GqlAuthGuard)
  async removeLeaguechallenge(
    @Args('updateLeaguechallengeInput')
    updateLeaguechallengeInput: UpdateLeaguechallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      this.logger.info(
        { userId: payload.userId, input: updateLeaguechallengeInput },
        'Removing challenge from league',
      );
      return await this.leaguechallengeService.remove(
        updateLeaguechallengeInput,
        payload.userId,
      );
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId, input: updateLeaguechallengeInput },
        'Error removing challenge from league',
      );
      throw new InternalServerErrorException(
        'Failed removing challenge from league',
      );
    }
  }
}
