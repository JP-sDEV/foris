import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { LeaguechallengeService } from './leaguechallenge.service';
import { Leaguechallenge } from './entities/leaguechallenge.entity';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload.type';

@Resolver(() => Leaguechallenge)
export class LeaguechallengeResolver {
  constructor(
    private readonly leaguechallengeService: LeaguechallengeService,
  ) {}

  // add challenge to a league
  @Mutation(() => Leaguechallenge)
  @UseGuards(GqlAuthGuard)
  addLeaguechallenge(
    @Args('createLeaguechallengeInput')
    createLeaguechallengeInput: CreateLeaguechallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return this.leaguechallengeService.create(
        createLeaguechallengeInput,
        payload.userId,
      );
    } catch (error) {
      console.error('Error adding challenge to league:', error);
      throw new Error('Failed adding challenge to league');
    }
  }

  @Mutation(() => Leaguechallenge)
  @UseGuards(GqlAuthGuard)
  removeLeaguechallenge(
    @Args('updateLeaguechallengeInput')
    createLeaguechallengeInput: UpdateLeaguechallengeInput,
    @CurrentUser() payload: JwtPayload,
  ) {
    try {
      return this.leaguechallengeService.remove(
        createLeaguechallengeInput,
        payload.userId,
      );
    } catch (error) {
      console.error('Error removing challenge from league:', error);
      throw new Error('Failed removing challenge from league');
    }
  }
}
