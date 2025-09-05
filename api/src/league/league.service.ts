import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { ChallengeService } from '../challenge/challenge.service';

@Injectable()
export class LeagueService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
    private readonly challengeService: ChallengeService,
    private readonly logger: PinoLogger,
  ) {}

  async create(createLeagueInput: CreateLeagueInput, userId: string) {
    try {
      this.logger.info({ userId, input: createLeagueInput }, 'Creating league');

      const user = await this.userService.findOneById(userId);
      if (!user) {
        this.logger.warn({ userId }, 'User not found while creating league');
        throw new ForbiddenException('User not found');
      }

      const league = await this.prisma.league.create({
        data: {
          ...createLeagueInput,
          createdBy: userId,
        },
      });

      this.logger.info(
        { leagueId: league.id, userId },
        'League created successfully',
      );
      return league;
    } catch (error) {
      this.logger.error(
        { error, userId, input: createLeagueInput },
        'Error creating league',
      );
      throw error;
    }
  }

  async findOneByIdUser(id: string, userId: string) {
    try {
      this.logger.info({ id, userId }, 'Finding league by ID and user');

      const user = await this.userService.findOneById(userId);
      if (!user) {
        this.logger.warn({ userId }, 'User not found while fetching league');
        throw new ForbiddenException('User not found');
      }

      const league = await this.prisma.league.findUnique({ where: { id } });
      if (!league) {
        this.logger.warn({ id }, 'League not found');
        throw new NotFoundException('League not found');
      }

      this.logger.info({ id, userId }, 'League found for user');
      return league;
    } catch (error) {
      this.logger.error(
        { error, id, userId },
        'Error finding league by userId',
      );
      throw error;
    }
  }

  async findOneById(id: string) {
    try {
      this.logger.info({ id }, 'Finding league by ID');

      const league = await this.prisma.league.findUnique({
        where: { id },
        include: {
          creator: false,
          leagueChallenges: false,
          LeagueUser: false,
        },
      });

      if (!league) {
        this.logger.warn({ id }, 'League not found by ID');
        throw new NotFoundException(`League with ID ${id} not found`);
      }

      this.logger.info({ id }, 'League found by ID');
      return league;
    } catch (error) {
      this.logger.error({ error, id }, 'Error finding league by ID');
      throw error;
    }
  }

  async update(updateLeagueInput: UpdateLeagueInput, userId: string) {
    try {
      this.logger.info({ userId, input: updateLeagueInput }, 'Updating league');

      const user = await this.userService.findOneById(userId);
      const league = await this.findOneByIdUser(updateLeagueInput.id, userId);

      if (!league) {
        this.logger.warn(
          { id: updateLeagueInput.id },
          'League not found for update',
        );
        throw new NotFoundException('League not found');
      }

      if (league.createdBy !== userId || !user) {
        this.logger.warn(
          { leagueId: league.id, userId },
          'Unauthorized update attempt',
        );
        throw new ForbiddenException('Unauthorized update');
      }

      const updatedLeague = await this.prisma.league.update({
        where: { id: updateLeagueInput.id },
        data: updateLeagueInput,
      });

      this.logger.info(
        { leagueId: updatedLeague.id, userId },
        'League updated successfully',
      );
      return updatedLeague;
    } catch (error) {
      this.logger.error(
        { error, input: updateLeagueInput, userId },
        'Error updating league',
      );
      throw error;
    }
  }

  async remove(id: string, userId: string) {
    try {
      this.logger.info({ id, userId }, 'Removing league');

      const user = await this.userService.findOneById(userId);
      const league = await this.findOneByIdUser(id, userId);

      if (!league) {
        this.logger.warn({ id }, 'League not found for removal');
        throw new NotFoundException('League not found');
      }

      if (league.createdBy !== userId || !user) {
        this.logger.warn(
          { leagueId: id, userId },
          'Unauthorized delete attempt',
        );
        throw new ForbiddenException('Unauthorized update');
      }

      const deletedLeague = await this.prisma.league.delete({ where: { id } });
      this.logger.info(
        { leagueId: deletedLeague.id, userId },
        'League removed successfully',
      );
      return deletedLeague;
    } catch (error) {
      this.logger.error({ error, id, userId }, 'Error removing league');
      throw error;
    }
  }
}
