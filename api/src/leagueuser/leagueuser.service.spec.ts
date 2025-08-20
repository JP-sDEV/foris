import { Test, TestingModule } from '@nestjs/testing';
import { LeagueuserService } from './leagueuser.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { LeagueService } from '../league/league.service';
import { NotFoundException, ForbiddenException } from '@nestjs/common';

describe('LeagueuserService', () => {
  let service: LeagueuserService;
  let prisma: PrismaService;
  let userService: UserService;
  let leagueService: LeagueService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeagueuserService,
        {
          provide: PrismaService,
          useValue: {
            leagueUser: {
              create: jest.fn(),
              findMany: jest.fn(),
              findUnique: jest.fn(),
              delete: jest.fn(),
            },
          },
        },
        { provide: UserService, useValue: { findOneById: jest.fn() } },
        { provide: LeagueService, useValue: { findOneById: jest.fn() } },
      ],
    }).compile();

    service = module.get<LeagueuserService>(LeagueuserService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);
    leagueService = module.get<LeagueService>(LeagueService);
  });

  describe('create', () => {
    it('should create a leagueUser successfully', async () => {
      const mockInput = { leagueId: 'league1' };
      const userId = 'user1';

      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({
        id: mockInput.leagueId,
      });
      (prisma.leagueUser.create as jest.Mock).mockResolvedValue({
        leagueId: mockInput.leagueId,
        userId,
      });

      const result = await service.create(mockInput, userId);

      expect(result).toEqual({ leagueId: mockInput.leagueId, userId });
      expect(prisma.leagueUser.create).toHaveBeenCalledWith({
        data: { userId, leagueId: mockInput.leagueId },
      });
    });

    it('should throw if user not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.create({ leagueId: 'l1' }, 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw if league not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: 'u1' });
      (leagueService.findOneById as jest.Mock).mockResolvedValue(null);

      await expect(service.create({ leagueId: 'l1' }, 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('findAll', () => {
    it('should return all leagueUsers for a league', async () => {
      const mockInput = { leagueId: 'league1' };
      const userId = 'user1';
      const mockResult = [
        { leagueId: 'league1', userId: 'user1', user: { id: 'user1' } },
      ];

      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({
        id: mockInput.leagueId,
      });
      (prisma.leagueUser.findMany as jest.Mock).mockResolvedValue(mockResult);

      const result = await service.findAll(mockInput, userId);
      expect(result).toEqual(mockResult);
      expect(prisma.leagueUser.findMany).toHaveBeenCalledWith({
        where: { leagueId: mockInput.leagueId },
        include: { user: true },
      });
    });

    it('should throw if user not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.findAll({ leagueId: 'l1' }, 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw if league not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: 'u1' });
      (leagueService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.findAll({ leagueId: 'l1' }, 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('findOne', () => {
    it('should return leagueUser', async () => {
      const leagueId = 'league1';
      const userId = 'user1';
      const mockResult = { leagueId, userId };

      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({
        id: leagueId,
      });
      (prisma.leagueUser.findUnique as jest.Mock).mockResolvedValue(mockResult);

      const result = await service.findOne(leagueId, userId);
      expect(result).toEqual(mockResult);
      expect(prisma.leagueUser.findUnique).toHaveBeenCalledWith({
        where: { leagueId_userId: { leagueId, userId } },
      });
    });

    it('should throw if user not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.findOne('l1', 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw if league not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: 'u1' });
      (leagueService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.findOne('l1', 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('remove', () => {
    const leagueId = 'league1';
    const userId = 'user1';

    it('should remove leagueUser if authorized', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({
        id: leagueId,
      });
      (prisma.leagueUser.findUnique as jest.Mock).mockResolvedValue({
        leagueId,
        userId,
      });
      (prisma.leagueUser.delete as jest.Mock).mockResolvedValue({
        leagueId,
        userId,
      });

      const result = await service.remove(leagueId, userId, userId);

      expect(result).toEqual({
        message: `League user with userId=${userId} removed from leagueId=${leagueId}`,
        leagueId,
        userId,
      });
      expect(prisma.leagueUser.delete).toHaveBeenCalledWith({
        where: { leagueId_userId: { leagueId, userId } },
      });
    });

    it('should throw ForbiddenException if currentUser !== userId', async () => {
      await expect(
        service.remove(leagueId, 'otherUser', userId),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if user not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.remove(leagueId, userId, userId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException if league not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue(null);
      await expect(service.remove(leagueId, userId, userId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException if leagueUser not found', async () => {
      (userService.findOneById as jest.Mock).mockResolvedValue({ id: userId });
      (leagueService.findOneById as jest.Mock).mockResolvedValue({
        id: leagueId,
      });
      (prisma.leagueUser.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(service.remove(leagueId, userId, userId)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
