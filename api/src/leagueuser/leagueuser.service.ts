import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  InternalServerErrorException,
} from '@nestjs/common';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { RemoveLeagueuserResponse } from './entities/remove-leagueuser.response';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { LeagueService } from '../league/league.service';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class LeagueuserService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
    private readonly leagueService: LeagueService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(LeagueuserService.name);
  }

  async create(createLeagueuserInput: CreateLeagueuserInput, userId: string) {
    try {
      this.logger.info(
        { userId, input: createLeagueuserInput },
        'Creating league user',
      );

      const user = await this.userService.findOneById(userId);
      const league = await this.leagueService.findOneById(
        createLeagueuserInput.leagueId,
      );

      if (!user) {
        this.logger.warn({ userId }, 'User not found');
        throw new NotFoundException('User not found');
      }
      if (!league) {
        this.logger.warn(
          { leagueId: createLeagueuserInput.leagueId },
          'League not found',
        );
        throw new NotFoundException('League not found');
      }

      return await this.prisma.leagueUser.create({
        data: {
          userId,
          leagueId: createLeagueuserInput.leagueId,
        },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, input: createLeagueuserInput },
        'Error creating league user',
      );
      throw new InternalServerErrorException('Failed to join league user');
    }
  }

  async findAll(createLeagueuserInput: CreateLeagueuserInput, userId: string) {
    try {
      this.logger.info(
        { userId, leagueId: createLeagueuserInput.leagueId },
        'Finding all users in league',
      );

      const user = await this.userService.findOneById(userId);
      const league = await this.leagueService.findOneById(
        createLeagueuserInput.leagueId,
      );

      if (!user) throw new NotFoundException('User not found');
      if (!league) throw new NotFoundException('League not found');

      return await this.prisma.leagueUser.findMany({
        where: { leagueId: createLeagueuserInput.leagueId },
        include: { user: true },
      });
    } catch (error) {
      this.logger.error(
        { error, userId, input: createLeagueuserInput },
        'Error finding users in league',
      );
      throw new InternalServerErrorException('Failed to find users in league');
    }
  }

  async findOne(leagueId: string, userId: string) {
    try {
      this.logger.info({ leagueId, userId }, 'Finding league user');

      const user = await this.userService.findOneById(userId);
      const league = await this.leagueService.findOneById(leagueId);

      if (!user) throw new NotFoundException('User not found');
      if (!league) throw new NotFoundException('League not found');

      return await this.prisma.leagueUser.findUnique({
        where: { leagueId_userId: { leagueId, userId } },
      });
    } catch (error) {
      this.logger.error(
        { error, leagueId, userId },
        'Error finding league user',
      );
      throw new InternalServerErrorException('Failed to find league user');
    }
  }

  async remove(
    leagueId: string,
    currentUser: string,
    userId: string,
  ): Promise<RemoveLeagueuserResponse> {
    try {
      this.logger.info(
        { currentUser, removeUserId: userId, leagueId },
        'Removing league user',
      );

      if (currentUser !== userId) {
        this.logger.warn(
          { currentUser, removeUserId: userId },
          'Unauthorized removal attempt',
        );
        throw new ForbiddenException(
          'You are not authorized to remove this league user',
        );
      }

      const user = await this.userService.findOneById(userId);
      const league = await this.leagueService.findOneById(leagueId);

      if (!user) throw new NotFoundException('User not found');
      if (!league) throw new NotFoundException('League not found');

      const leagueuser = await this.prisma.leagueUser.findUnique({
        where: { leagueId_userId: { leagueId, userId } },
      });

      if (!leagueuser) throw new NotFoundException('League user not found');

      await this.prisma.leagueUser.delete({
        where: { leagueId_userId: { leagueId, userId } },
      });

      return {
        message: `League user with userId=${userId} removed from leagueId=${leagueId}`,
        leagueId,
        userId,
      };
    } catch (error) {
      this.logger.error(
        { error, currentUser, removeUserId: userId, leagueId },
        'Error removing league user',
      );
      throw new InternalServerErrorException('Failed to remove league user');
    }
  }
}
