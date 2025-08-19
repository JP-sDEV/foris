import { Test, TestingModule } from '@nestjs/testing';
import { LeaguechallengeService } from './leaguechallenge.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { LeagueService } from '../league/league.service';
import { ChallengeService } from '../challenge/challenge.service';
import { NotFoundException, ForbiddenException } from '@nestjs/common';

describe('LeaguechallengeService', () => {
  let service: LeaguechallengeService;
  let prisma: PrismaService;
  let userService: UserService;
  let leagueService: LeagueService;
  let challengeService: ChallengeService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeaguechallengeService,
        {
          provide: PrismaService,
          useValue: {
            leagueChallenge: {
              create: jest.fn(),
              findUnique: jest.fn(),
              delete: jest.fn(),
            },
          },
        },
        { provide: UserService, useValue: { findOneById: jest.fn() } },
        { provide: LeagueService, useValue: { findOneById: jest.fn() } },
        { provide: ChallengeService, useValue: { findOneById: jest.fn() } },
      ],
    }).compile();

    service = module.get<LeaguechallengeService>(LeaguechallengeService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);
    leagueService = module.get<LeagueService>(LeagueService);
    challengeService = module.get<ChallengeService>(ChallengeService);
  });

  describe('create', () => {
    it('should create a leagueChallenge successfully', async () => {
      const mockInput = { leagueId: 'league1', challengeId: 'challenge1' };
      const userId = 'user1';

      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({
        id: mockInput.leagueId,
      });
      (challengeService.findOneById as jest.Mock).mockResolvedValue({
        id: mockInput.challengeId,
      });
      (prisma.leagueChallenge.create as jest.Mock).mockResolvedValue({
        leagueId: mockInput.leagueId,
        challengeId: mockInput.challengeId,
        league: {},
        challenge: {},
      });

      const result = await service.create(mockInput, userId);

      expect(result).toEqual({
        leagueId: mockInput.leagueId,
        challengeId: mockInput.challengeId,
        league: {},
        challenge: {},
      });
      expect(prisma.leagueChallenge.create).toHaveBeenCalledWith({
        data: {
          leagueId: mockInput.leagueId,
          challengeId: mockInput.challengeId,
        },
        include: { league: true, challenge: true },
      });
    });

    it('should throw NotFoundException if user not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(
        service.create({ leagueId: 'l1', challengeId: 'c1' }, 'user1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException if league not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: 'user1' });
      (leagueService.findOneById as jest.Mock).mockResolvedValue(null);

      await expect(
        service.create({ leagueId: 'l1', challengeId: 'c1' }, 'user1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException if challenge not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: 'user1' });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({ id: 'l1' });
      (challengeService.findOneById as jest.Mock).mockResolvedValue(null);

      await expect(
        service.create({ leagueId: 'l1', challengeId: 'c1' }, 'user1'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    const input = { leagueId: 'league1', challengeId: 'challenge1' };
    const userId = 'user1';

    it('should remove leagueChallenge if user is creator', async () => {
      (prisma.leagueChallenge.findUnique as jest.Mock).mockResolvedValue({
        league: { createdBy: userId },
        leagueId: input.leagueId,
        challengeId: input.challengeId,
      });
      (prisma.leagueChallenge.delete as jest.Mock).mockResolvedValue(input);

      const result = await service.remove(input, userId);
      expect(result).toEqual(input);
      expect(prisma.leagueChallenge.delete).toHaveBeenCalledWith({
        where: { leagueId_challengeId: input },
      });
    });

    it('should throw ForbiddenException if user is not creator', async () => {
      (prisma.leagueChallenge.findUnique as jest.Mock).mockResolvedValue({
        league: { createdBy: 'otherUser' },
      });

      await expect(service.remove(input, userId)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw NotFoundException if leagueChallenge does not exist', async () => {
      (prisma.leagueChallenge.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(service.remove(input, userId)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
