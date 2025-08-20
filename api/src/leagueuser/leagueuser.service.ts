import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { RemoveLeagueuserResponse } from './entities/remove-leagueuser.response';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { LeagueService } from '../league/league.service';

@Injectable()
export class LeagueuserService {
  constructor(
    private readonly prisma: PrismaService,
    private userService: UserService,
    private leagueService: LeagueService,
  ) {}

  async create(createLeagueuserInput: CreateLeagueuserInput, userId: string) {
    const user = await this.userService.findOneById(userId);
    const league = await this.leagueService.findOneById(
      createLeagueuserInput.leagueId,
    );

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!league) {
      throw new NotFoundException('League not found');
    }

    return await this.prisma.leagueUser.create({
      data: {
        userId: userId,
        leagueId: createLeagueuserInput.leagueId,
      },
    });
  }

  async findAll(createLeagueuserInput: CreateLeagueuserInput, userId: string) {
    const user = await this.userService.findOneById(userId);
    const league = await this.leagueService.findOneById(
      createLeagueuserInput.leagueId,
    );

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!league) {
      throw new NotFoundException('League not found');
    }

    return await this.prisma.leagueUser.findMany({
      where: {
        leagueId: createLeagueuserInput.leagueId,
      },
      include: {
        user: true, // Include user details
      },
    });
  }

  async findOne(leagueId: string, userId: string) {
    const user = await this.userService.findOneById(userId);
    const league = await this.leagueService.findOneById(leagueId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!league) {
      throw new NotFoundException('League not found');
    }

    return await this.prisma.leagueUser.findUnique({
      where: {
        leagueId_userId: {
          leagueId,
          userId,
        },
      },
    });
  }

  async remove(
    leagueId: string,
    currentUser: string,
    userId: string,
  ): Promise<RemoveLeagueuserResponse> {
    if (currentUser !== userId) {
      throw new ForbiddenException(
        'You are not authorized to remove this league user',
      );
    }

    const user = await this.userService.findOneById(userId);
    const league = await this.leagueService.findOneById(leagueId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!league) {
      throw new NotFoundException('League not found');
    }

    const leagueuser = await this.prisma.leagueUser.findUnique({
      where: {
        leagueId_userId: { leagueId, userId },
      },
    });

    if (!leagueuser) {
      throw new NotFoundException('League user not found');
    }

    await this.prisma.leagueUser.delete({
      where: {
        leagueId_userId: { leagueId, userId },
      },
    });

    return {
      message: `League user with userId=${userId} removed from leagueId=${leagueId}`,
      leagueId,
      userId,
    };
  }
}
