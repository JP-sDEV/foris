import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { UserchallengeService } from './userchallenge.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { ChallengeStatus } from '@prisma/client';

describe('UserchallengeService', () => {
  let service: UserchallengeService;
  let prisma: PrismaService;
  let userService: UserService;

  // Mock Prisma client methods your service uses
  const mockPrismaService = {
    userChallenge: {
      create: jest.fn(),
      update: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
  };

  // Mock UserService with findOneById method
  const mockUserService = {
    findOneById: jest.fn(),
  };

  beforeEach(async () => {
    jest.spyOn(console, 'error').mockImplementation(() => {});

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserchallengeService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: UserService, useValue: mockUserService },
      ],
    }).compile();

    service = module.get<UserchallengeService>(UserchallengeService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    const joinInput = { challengeId: 'challenge1' };
    const userId = 'user1';

    it('should create a user challenge when user exists', async () => {
      mockUserService.findOneById.mockResolvedValue({ id: userId });
      mockPrismaService.userChallenge.create.mockResolvedValue({
        id: 'uc1',
        userId,
        challengeId: 'challenge1',
      });

      const result = await service.create(joinInput, userId);

      expect(userService.findOneById).toHaveBeenCalledWith(userId);
      expect(prisma.userChallenge.create).toHaveBeenCalledWith({
        data: { userId, challengeId: joinInput.challengeId },
      });
      expect(result).toEqual({ id: 'uc1', userId, challengeId: 'challenge1' });
    });

    it('should throw NotFoundException if user not found', async () => {
      mockUserService.findOneById.mockResolvedValue(null);

      await expect(service.create(joinInput, userId)).rejects.toThrow(
        NotFoundException,
      );

      expect(userService.findOneById).toHaveBeenCalledWith(userId);
      expect(prisma.userChallenge.create).not.toHaveBeenCalled();
    });
  });

  describe('update', () => {
    const updateInput = {
      challengeId: 'challenge1',
      status: ChallengeStatus.COMPLETED,
      completedAt: new Date(),
    };
    const userId = 'user1';

    it('should update user challenge when user exists', async () => {
      mockUserService.findOneById.mockResolvedValue({ id: userId });
      mockPrismaService.userChallenge.update.mockResolvedValue({
        userId,
        challengeId: 'challenge1',
        ...updateInput,
      });

      const result = await service.update(updateInput, userId);

      expect(userService.findOneById).toHaveBeenCalledWith(userId);
      expect(prisma.userChallenge.update).toHaveBeenCalledWith({
        where: {
          userId_challengeId: {
            userId,
            challengeId: updateInput.challengeId,
          },
        },
        data: {
          status: updateInput.status,
          completedAt: updateInput.completedAt,
        },
      });
      expect(result).toEqual({
        userId,
        challengeId: 'challenge1',
        ...updateInput,
      });
    });

    it('should throw NotFoundException if user not found', async () => {
      mockUserService.findOneById.mockResolvedValue(null);

      await expect(service.update(updateInput, userId)).rejects.toThrow(
        NotFoundException,
      );

      expect(prisma.userChallenge.update).not.toHaveBeenCalled();
    });

    it('should throw error if prisma update throws', async () => {
      mockUserService.findOneById.mockResolvedValue({ id: userId });
      mockPrismaService.userChallenge.update.mockRejectedValue(
        new Error('DB error'),
      );

      await expect(service.update(updateInput, userId)).rejects.toThrow(
        'Failed to update user challenge',
      );
    });
  });

  describe('findOne', () => {
    const userId = 'user1';
    const challengeId = 'challenge1';

    it('should return user challenge when user exists', async () => {
      mockUserService.findOneById.mockResolvedValue({ id: userId });
      mockPrismaService.userChallenge.findUnique.mockResolvedValue({
        userId,
        challengeId,
      });

      const result = await service.findOne(userId, challengeId);

      expect(mockUserService.findOneById).toHaveBeenCalledWith(userId);
      expect(mockPrismaService.userChallenge.findUnique).toHaveBeenCalledWith({
        where: {
          userId_challengeId: { userId, challengeId },
        },
      });
      expect(result).toEqual({ userId, challengeId });
    });

    it('should throw NotFoundException if user not found', async () => {
      mockUserService.findOneById.mockResolvedValue(null);

      await expect(service.findOne(userId, challengeId)).rejects.toThrow(
        NotFoundException,
      );

      expect(prisma.userChallenge.findUnique).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    const joinInput = { challengeId: 'challenge1' };
    const userId = 'user1';

    it('should delete user challenge when user exists', async () => {
      mockUserService.findOneById.mockResolvedValue({ id: userId });
      mockPrismaService.userChallenge.delete.mockResolvedValue({
        userId,
        challengeId: joinInput.challengeId,
      });

      const result = await service.remove(joinInput, userId);

      expect(mockUserService.findOneById).toHaveBeenCalledWith(userId);
      expect(prisma.userChallenge.delete).toHaveBeenCalledWith({
        where: {
          userId_challengeId: {
            userId,
            challengeId: joinInput.challengeId,
          },
        },
      });
      expect(result).toEqual({ userId, challengeId: joinInput.challengeId });
    });

    it('should throw NotFoundException if user not found', async () => {
      mockUserService.findOneById.mockResolvedValue(null);

      await expect(service.remove(joinInput, userId)).rejects.toThrow(
        NotFoundException,
      );

      expect(prisma.userChallenge.delete).not.toHaveBeenCalled();
    });
  });
});
