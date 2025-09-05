import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  InternalServerErrorException,
} from '@nestjs/common';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { LeagueService } from '../league/league.service';
import { ChallengeService } from '../challenge/challenge.service';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class LeaguechallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
    private readonly leagueService: LeagueService,
    private readonly challengeService: ChallengeService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(LeaguechallengeService.name);
  }

  async create(
    createLeaguechallengeInput: CreateLeaguechallengeInput,
    userId: string,
  ) {
    try {
      this.logger.info(
        { userId, input: createLeaguechallengeInput },
        'Creating league challenge',
      );

      const user = await this.userService.findOneById(userId);
      const league = await this.leagueService.findOneById(
        createLeaguechallengeInput.leagueId,
      );
      const challenge = await this.challengeService.findOneById(
        createLeaguechallengeInput.challengeId,
      );

      if (!user) {
        this.logger.warn({ userId }, 'Cannot find user');
        throw new NotFoundException('Cannot find user');
      }
      if (!league) {
        this.logger.warn(
          { leagueId: createLeaguechallengeInput.leagueId },
          'Cannot find league',
        );
        throw new NotFoundException('Cannot find league');
      }
      if (!challenge) {
        this.logger.warn(
          { challengeId: createLeaguechallengeInput.challengeId },
          'Cannot find challenge',
        );
        throw new NotFoundException('Cannot find challenge');
      }

      return await this.prisma.leagueChallenge.create({
        data: {
          leagueId: league.id,
          challengeId: challenge.id,
        },
        include: {
          league: true,
          challenge: true,
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, input: createLeaguechallengeInput },
        'Error creating league challenge',
      );
      throw new InternalServerErrorException(
        'Failed to create league challenge',
      );
    }
  }

  async remove(
    updateLeaguechallengeInput: UpdateLeaguechallengeInput,
    userId: string,
  ) {
    try {
      this.logger.info(
        { userId, input: updateLeaguechallengeInput },
        'Removing league challenge',
      );

      const { leagueId, challengeId } = updateLeaguechallengeInput;

      // Fetch the LeagueChallenge
      const existing = await this.prisma.leagueChallenge.findUnique({
        where: {
          leagueId_challengeId: { leagueId, challengeId },
        },
        include: {
          league: true, // Include the league to access createdBy
        },
      });

      if (!existing) {
        this.logger.warn(
          { leagueId, challengeId },
          'LeagueChallenge not found',
        );
        throw new NotFoundException(
          `LeagueChallenge not found for league ${leagueId} and challenge ${challengeId}`,
        );
      }

      if (existing.league.createdBy !== userId) {
        this.logger.warn(
          { userId, leagueId },
          'Unauthorized to remove challenge',
        );
        throw new ForbiddenException(
          'You are not allowed to remove a challenge from this league',
        );
      }

      return await this.prisma.leagueChallenge.delete({
        where: {
          leagueId_challengeId: { leagueId, challengeId },
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, input: updateLeaguechallengeInput },
        'Error removing league challenge',
      );
      throw new InternalServerErrorException(
        'Failed to remove league challenge',
      );
    }
  }
}
