import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
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
  ) {}

  async create(createLeagueInput: CreateLeagueInput, userId: string) {
    const user = await this.userService.findOneById(userId);

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    return await this.prisma.league.create({
      data: {
        ...createLeagueInput,
        createdBy: userId,
      },
    });
  }

  // findAll() {
  //   return `This action returns all league`;
  // }

  async findOneById(id: string, userId: string) {
    const user = await this.userService.findOneById(userId);

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    const league = await this.prisma.league.findUnique({
      where: { id },
    });

    if (!league) {
      throw new NotFoundException('User not found');
    }

    return league;
  }

  async update(updateLeagueInput: UpdateLeagueInput, userId: string) {
    const user = await this.userService.findOneById(userId);
    const league = await this.findOneById(updateLeagueInput.id, userId);

    if (!league) {
      throw new NotFoundException('League not found');
    }

    if (league.createdBy != userId || !user) {
      throw new ForbiddenException('Unauthorized update');
    }

    return await this.prisma.league.update({
      where: { id: updateLeagueInput.id },
      data: updateLeagueInput,
    });
  }

  async remove(id: string, userId: string) {
    const user = await this.userService.findOneById(userId);
    const league = await this.findOneById(id, userId);

    if (!league) {
      throw new NotFoundException('League not found');
    }

    if (league.createdBy != userId || !user) {
      throw new ForbiddenException('Unauthorized update');
    }

    return this.prisma.league.delete({
      where: { id: id },
    });
  }
}
