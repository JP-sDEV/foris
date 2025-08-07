import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeService } from './challenge.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';

describe('ChallengeService', () => {
  let service: ChallengeService;
  let prisma: PrismaService;

  const mockPrisma = {
    user: {
      findUnique: jest.fn(),
    },
    challenge: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChallengeService,
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
      ],
    }).compile();

    service = module.get<ChallengeService>(ChallengeService);
    prisma = module.get<PrismaService>(PrismaService);

    jest.clearAllMocks();
  });

  const userId = uuidv4();
  const challengeId = uuidv4();

  describe('create', () => {
    it('should throw if user does not exist', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.create({ title: 'Test Challenge' } as any, userId),
      ).rejects.toThrow(NotFoundException);
    });

    it('should create a challenge if user exists', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: userId });
      const challengeData = { id: challengeId, title: 'Test Challenge' };
      mockPrisma.challenge.create.mockResolvedValue(challengeData);

      const result = await service.create(
        { title: 'Test Challenge' } as any,
        userId,
      );

      expect(result).toEqual(challengeData);
      expect(mockPrisma.challenge.create).toHaveBeenCalledWith({
        data: { title: 'Test Challenge', createdBy: userId },
      });
    });
  });

  describe('findOne', () => {
    it('should throw if challenge not found', async () => {
      mockPrisma.challenge.findUnique.mockResolvedValue(null);

      await expect(service.findOne(challengeId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should return the challenge if found', async () => {
      const challenge = { id: challengeId, title: 'Found Challenge' };
      mockPrisma.challenge.findUnique.mockResolvedValue(challenge);

      const result = await service.findOne(challengeId);

      expect(result).toEqual(challenge);
    });
  });

  describe('update', () => {
    it('should throw if challenge not found', async () => {
      mockPrisma.challenge.findUnique.mockResolvedValue(null);

      await expect(
        service.update(challengeId, { title: 'New Title' } as any, userId),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw if user is not the owner', async () => {
      mockPrisma.challenge.findUnique.mockResolvedValue({
        id: challengeId,
        createdBy: 'another-user',
      });

      await expect(
        service.update(challengeId, { title: 'New Title' } as any, userId),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should update and return the challenge if user is the owner', async () => {
      const updated = { id: challengeId, title: 'Updated Title' };
      mockPrisma.challenge.findUnique.mockResolvedValue({
        id: challengeId,
        createdBy: userId,
      });
      mockPrisma.challenge.update.mockResolvedValue(updated);

      const result = await service.update(
        challengeId,
        { title: 'Updated Title' } as any,
        userId,
      );

      expect(result).toEqual(updated);
    });
  });

  describe('remove', () => {
    it('should throw if challenge not found', async () => {
      mockPrisma.challenge.findUnique.mockResolvedValue(null);

      await expect(service.remove(challengeId, userId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw if user is not the owner', async () => {
      mockPrisma.challenge.findUnique.mockResolvedValue({
        id: challengeId,
        createdBy: 'someone-else',
      });

      await expect(service.remove(challengeId, userId)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should delete and return the challenge if user is the owner', async () => {
      const deleted = { id: challengeId, title: 'Deleted' };
      mockPrisma.challenge.findUnique.mockResolvedValue({
        id: challengeId,
        createdBy: userId,
      });
      mockPrisma.challenge.delete.mockResolvedValue(deleted);

      const result = await service.remove(challengeId, userId);

      expect(result).toEqual(deleted);
    });
  });
});
