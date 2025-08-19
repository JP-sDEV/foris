import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { LeagueService } from '../league/league.service';
import { ChallengeService } from '../challenge/challenge.service';

@Injectable()
export class LeaguechallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private userService: UserService,
    private leagueService: LeagueService,
    private challengeService: ChallengeService,
  ) {}

  async create(
    createLeaguechallengeInput: CreateLeaguechallengeInput,
    userId: string,
  ) {
    const user = await this.userService.findOneById(userId);
    const league = await this.leagueService.findOneById(
      createLeaguechallengeInput.leagueId,
    );
    const challenge = await this.challengeService.findOneById(
      createLeaguechallengeInput.challengeId,
    );

    if (!user) {
      throw new NotFoundException('Cannot find user');
    }
    if (!league) {
      throw new NotFoundException('Cannot find league');
    }
    if (!challenge) {
      throw new NotFoundException('Cannot find challenge');
    }

    return this.prisma.leagueChallenge.create({
      data: {
        leagueId: league.id,
        challengeId: challenge.id,
      },
      include: {
        league: true,
        challenge: true,
      },
    });
  }

  async remove(
    updateLeaguechallengeInput: UpdateLeaguechallengeInput,
    userId: string,
  ) {
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
      throw new NotFoundException(
        `LeagueChallenge not found for league ${leagueId} and challenge ${challengeId}`,
      );
    }

    // Check if the current user is the creator of the league
    if (existing.league.createdBy !== userId) {
      throw new ForbiddenException(
        'You are not allowed to remove a challenge from this league',
      );
    }

    // Delete the LeagueChallenge
    return this.prisma.leagueChallenge.delete({
      where: {
        leagueId_challengeId: { leagueId, challengeId },
      },
    });
  }
}
