import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeResolver } from './challenge.resolver';
import { ChallengeService } from './challenge.service';
import { GqlAuthGuard } from '../auth/auth.guard';
import { InternalServerErrorException } from '@nestjs/common';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';

const mockChallengeService = {
  create: jest.fn(),
  findOneById: jest.fn(),
  update: jest.fn(),
  remove: jest.fn(),
  findAll: jest.fn(),
};

const mockUser = { sub: 'user123' };

describe('ChallengeResolver', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

  let resolver: ChallengeResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChallengeResolver,
        { provide: ChallengeService, useValue: mockChallengeService },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({ canActivate: () => true }) // Mock guard
      .compile();

    resolver = module.get<ChallengeResolver>(ChallengeResolver);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });

  describe('createChallenge', () => {
    it('should call challengeService.create with input and user.sub', async () => {
      const input: CreateChallengeInput = { name: 'New Challenge' };
      const expected = { id: 'ch1', ...input };
      mockChallengeService.create.mockResolvedValue(expected);

      const result = await resolver.createChallenge(input, mockUser);

      expect(result).toEqual(expected);
      expect(mockChallengeService.create).toHaveBeenCalledWith(
        input,
        mockUser.sub,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      const input: CreateChallengeInput = { name: 'Test' };
      mockChallengeService.create.mockRejectedValue(new Error('DB error'));

      await expect(resolver.createChallenge(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOneById', () => {
    it('should return a challenge by ID', async () => {
      const id = 'uuid-123';
      const expected = { id, name: 'Challenge Name' };
      mockChallengeService.findOneById.mockResolvedValue(expected);

      const result = await resolver.findOneById(id);
      expect(result).toEqual(expected);
      expect(mockChallengeService.findOneById).toHaveBeenCalledWith(id);
    });

    it('should throw InternalServerErrorException on service error', async () => {
      mockChallengeService.findOneById.mockRejectedValue(new Error('DB error'));
      await expect(resolver.findOneById('uuid-123')).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('updateChallenge', () => {
    it('should call challengeService.update with id, input and user.sub', async () => {
      const input: UpdateChallengeInput = {
        id: 'uuid-123',
        name: 'Updated Challenge',
      };
      const expected = { id: 'uuid-123', name: 'Updated Challenge' };

      mockChallengeService.update.mockResolvedValue(expected);

      const result = await resolver.updateChallenge(input, mockUser);

      expect(result).toEqual(expected);
      expect(mockChallengeService.update).toHaveBeenCalledWith(
        input.id,
        input,
        mockUser.sub,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      const input: UpdateChallengeInput = { id: 'uuid-123', name: 'Fail' };
      mockChallengeService.update.mockRejectedValue(new Error('DB error'));

      await expect(resolver.updateChallenge(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('removeChallenge', () => {
    it('should call challengeService.remove with id and user.sub', async () => {
      const id = 'uuid-123';
      const expected = { id };

      mockChallengeService.remove.mockResolvedValue(expected);

      const result = await resolver.removeChallenge(id, mockUser);

      expect(result).toEqual(expected);
      expect(mockChallengeService.remove).toHaveBeenCalledWith(
        id,
        mockUser.sub,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      mockChallengeService.remove.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.removeChallenge('uuid-123', mockUser),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });
});
