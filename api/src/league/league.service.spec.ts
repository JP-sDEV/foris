import { Test, TestingModule } from '@nestjs/testing';
import { LeagueService } from './league.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { ChallengeService } from '../challenge/challenge.service';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';

describe('LeagueService', () => {
  let service: LeagueService;
  let prisma: jest.Mocked<PrismaService>;
  let userService: jest.Mocked<UserService>;

  const mockPrisma = {
    league: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  } as any;

  const mockUserService = {
    findOneById: jest.fn(),
  } as any;

  const mockChallengeService = {} as any; // not directly used in tests

  const userId = uuidv4();
  const leagueId = uuidv4();

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeagueService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: UserService, useValue: mockUserService },
        { provide: ChallengeService, useValue: mockChallengeService },
      ],
    }).compile();

    service = module.get<LeagueService>(LeagueService);
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;
    userService = module.get(UserService) as jest.Mocked<UserService>;

    jest.clearAllMocks();
  });

  describe('create', () => {
    it('should throw if user does not exist', async () => {
      userService.findOneById.mockResolvedValue(null);

      await expect(
        service.create({ name: 'Test League' } as any, userId),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should create a league if user exists', async () => {
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      const leagueData = {
        id: leagueId,
        name: 'Test League',
        createdBy: userId,
      };
      mockPrisma.league.create.mockResolvedValue(leagueData);

      const result = await service.create(
        { name: 'Test League' } as any,
        userId,
      );

      expect(result).toEqual(leagueData);
      expect(prisma.league.create).toHaveBeenCalledWith({
        data: { name: 'Test League', createdBy: userId },
      });
    });
  });

  describe('findOneById', () => {
    it('should throw if user does not exist', async () => {
      userService.findOneById.mockResolvedValue(null);

      await expect(service.findOneById(leagueId, userId)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw if league not found', async () => {
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      mockPrisma.league.findUnique.mockResolvedValue(null);

      await expect(service.findOneById(leagueId, userId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should return the league if found', async () => {
      const league = { id: leagueId, name: 'Found League', createdBy: userId };
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      mockPrisma.league.findUnique.mockResolvedValue(league);

      const result = await service.findOneById(leagueId, userId);
      expect(result).toEqual(league);
    });
  });

  describe('update', () => {
    it('should throw if league not found', async () => {
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      jest.spyOn(service, 'findOneById').mockResolvedValue(null);

      await expect(
        service.update({ id: leagueId, name: 'Updated' } as any, userId),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw if user is not the owner', async () => {
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      jest
        .spyOn(service, 'findOneById')
        .mockResolvedValue({ id: leagueId, createdBy: 'other-user' } as any);

      await expect(
        service.update({ id: leagueId, name: 'Updated' } as any, userId),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should update the league if user is owner', async () => {
      const updated = { id: leagueId, name: 'Updated', createdBy: userId };
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      jest
        .spyOn(service, 'findOneById')
        .mockResolvedValue({ id: leagueId, createdBy: userId } as any);
      mockPrisma.league.update.mockResolvedValue(updated);

      const result = await service.update(
        { id: leagueId, name: 'Updated' } as any,
        userId,
      );

      expect(result).toEqual(updated);
    });
  });

  describe('remove', () => {
    it('should throw if league not found', async () => {
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      jest.spyOn(service, 'findOneById').mockResolvedValue(null);

      await expect(service.remove(leagueId, userId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw if user is not the owner', async () => {
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      jest
        .spyOn(service, 'findOneById')
        .mockResolvedValue({ id: leagueId, createdBy: 'someone-else' } as any);

      await expect(service.remove(leagueId, userId)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should delete and return the league if user is owner', async () => {
      const deleted = { id: leagueId, name: 'Deleted', createdBy: userId };
      userService.findOneById.mockResolvedValue({
        id: userId,
        createdAt: new Date(),
        name: 'Test User',
        email: 'test@example.com',
        bio: 'Test bio',
        avatarUrl: 'http://example.com/avatar.png',
      });
      jest
        .spyOn(service, 'findOneById')
        .mockResolvedValue({ id: leagueId, createdBy: userId } as any);
      mockPrisma.league.delete.mockResolvedValue(deleted);

      const result = await service.remove(leagueId, userId);
      expect(result).toEqual(deleted);
    });
  });
});
