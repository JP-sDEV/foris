import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeResolver } from './challenge.resolver';
import { ChallengeService } from './challenge.service';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { InternalServerErrorException } from '@nestjs/common';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';
import { JwtPayload } from 'jsonwebtoken';

const mockChallengeService = {
  create: jest.fn(),
  findOneById: jest.fn(),
  findOneByIdUser: jest.fn(),
  update: jest.fn(),
  remove: jest.fn(),
  findAll: jest.fn(),
};

const mockPayload: JwtPayload = {
  id: '123',
  email: 'test@email.com',
  name: 'Test User',
  iat: 0,
  exp: 0,
};

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
      .useValue({ canActivate: () => true }) // mock auth guard
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
    it('should call challengeService.create with input and payload.id', async () => {
      const input: CreateChallengeInput = { name: 'New Challenge' };
      const expected = { id: 'ch1', ...input };
      mockChallengeService.create.mockResolvedValue(expected);

      const result = await resolver.createChallenge(input, mockPayload);

      expect(result).toEqual(expected);
      expect(mockChallengeService.create).toHaveBeenCalledWith(
        input,
        mockPayload.id,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      const input: CreateChallengeInput = { name: 'Test' };
      mockChallengeService.create.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.createChallenge(input, mockPayload),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });

  describe('challenge', () => {
    it('should call challengeService.findOneByIdUser with id and payload.id', async () => {
      const id = 'uuid-123';
      const expected = { id, name: 'Challenge Name' };
      mockChallengeService.findOneByIdUser.mockResolvedValue(expected);

      const result = await resolver.challenge(id, mockPayload);

      expect(result).toEqual(expected);
      expect(mockChallengeService.findOneByIdUser).toHaveBeenCalledWith(
        id,
        mockPayload.id,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      mockChallengeService.findOneByIdUser.mockRejectedValue(
        new Error('DB error'),
      );
      await expect(resolver.challenge('uuid-123', mockPayload)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOneById', () => {
    it('should call challengeService.findOneById with id', async () => {
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
    it('should call challengeService.update with id, input, and payload.id', async () => {
      const input: UpdateChallengeInput = {
        id: 'uuid-123',
        name: 'Updated Challenge',
      };
      const expected = { ...input };

      mockChallengeService.update.mockResolvedValue(expected);

      const result = await resolver.updateChallenge(input, mockPayload);

      expect(result).toEqual(expected);
      expect(mockChallengeService.update).toHaveBeenCalledWith(
        input.id,
        input,
        mockPayload.id,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      const input: UpdateChallengeInput = { id: 'uuid-123', name: 'Fail' };
      mockChallengeService.update.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.updateChallenge(input, mockPayload),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });

  describe('removeChallenge', () => {
    it('should call challengeService.remove with id and payload.id', async () => {
      const id = 'uuid-123';
      const expected = { id };

      mockChallengeService.remove.mockResolvedValue(expected);

      const result = await resolver.removeChallenge(id, mockPayload);

      expect(result).toEqual(expected);
      expect(mockChallengeService.remove).toHaveBeenCalledWith(
        id,
        mockPayload.id,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      mockChallengeService.remove.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.removeChallenge('uuid-123', mockPayload),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });
});
