import { Test, TestingModule } from '@nestjs/testing';
import { UserchallengeResolver } from './userchallenge.resolver';
import { UserchallengeService } from './userchallenge.service';
import { JoinUserChallengeInput } from './dto/join-userchallenge.input';
import { UpdateUserChallengeInput } from './dto/update-userchallenge.input';
import { GqlAuthGuard } from '../auth/auth.guard';
import { ExecutionContext } from '@nestjs/common';
import { ChallengeStatus } from '@prisma/client';

describe('UserchallengeResolver', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

  let resolver: UserchallengeResolver;
  let service: jest.Mocked<UserchallengeService>;

  const mockUser = { sub: 'user123' };

  beforeEach(async () => {
    const mockService: jest.Mocked<UserchallengeService> = {
      create: jest.fn(),
      update: jest.fn(),
      findOne: jest.fn(),
      remove: jest.fn(),
      findOneById: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserchallengeResolver,
        { provide: UserchallengeService, useValue: mockService },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          const ctx = context.getArgByIndex(2); // GraphQL context
          ctx.req = { user: mockUser }; // Inject mock user
          return true;
        },
      })
      .compile();

    resolver = module.get<UserchallengeResolver>(UserchallengeResolver);
    service = module.get(
      UserchallengeService,
    ) as jest.Mocked<UserchallengeService>;
    jest.clearAllMocks();
  });

  describe('joinUserChallenge', () => {
    it('should call service.create with correct args', async () => {
      const input: JoinUserChallengeInput = {
        challengeId: '123e4567-e89b-12d3-a456-426614174000',
      };
      const expected = {
        challengeId: input.challengeId,
        userId: mockUser.sub,
        status: ChallengeStatus.NOT_IN_PROGRESS,
        startedAt: new Date(),
        completedAt: new Date(),
      };

      service.create.mockResolvedValue(expected);

      const result = await resolver.joinUserChallenge(input, mockUser);

      expect(service.create).toHaveBeenCalledWith(input, mockUser.sub);
      expect(result).toEqual(expected);
    });

    it('should throw custom error on failure', async () => {
      service.create.mockRejectedValue(
        new Error('Failed to join user challenge'),
      );

      await expect(
        resolver.joinUserChallenge({ challengeId: 'c1' }, mockUser),
      ).rejects.toThrow('Failed to join user challenge');
    });
  });

  describe('updateUserChallenge', () => {
    it('should call service.update with correct args', async () => {
      const now = new Date(); // reuse same timestamp

      const input: UpdateUserChallengeInput = {
        challengeId: 'c1',
        status: ChallengeStatus.IN_PROGRESS,
        completedAt: now,
      };

      const expected = {
        completedAt: now,
        status: ChallengeStatus.IN_PROGRESS,
        challengeId: 'c1',
        userId: 'user1',
        startedAt: now,
      };

      service.update.mockResolvedValue(expected);

      const result = await resolver.updateUserChallenge(input, mockUser);

      expect(service.update).toHaveBeenCalledWith(input, mockUser.sub);
      expect(result).toEqual(expected);
    });

    it('should throw custom error on failure', async () => {
      service.update.mockRejectedValue(
        new Error('Failed to update user challenge'),
      );

      await expect(
        resolver.updateUserChallenge({ challengeId: 'c1' } as any, mockUser),
      ).rejects.toThrow('Failed to update user challenge');
    });
  });

  describe('findOne', () => {
    it('should call service.findOne with correct args', async () => {
      const now = new Date();
      const input: JoinUserChallengeInput = {
        challengeId: 'c1',
      };

      const expected = {
        completedAt: now,
        status: ChallengeStatus.IN_PROGRESS,
        challengeId: 'c1',
        userId: 'user1',
        startedAt: now,
      };

      service.findOne.mockResolvedValue(expected);

      const result = await resolver.findOne(input, mockUser);

      expect(service.findOne).toHaveBeenCalledWith(
        mockUser.sub,
        input.challengeId,
      );
      expect(result).toEqual(expected);
    });

    it('should throw custom error on failure', async () => {
      service.findOne.mockRejectedValue(
        new Error('Failed to find user challenge'),
      );

      await expect(
        resolver.findOne({ challengeId: 'c1' }, mockUser),
      ).rejects.toThrow('Failed to find user challenge');
    });
  });

  describe('removeUserChallenge', () => {
    it('should call service.remove with correct args', async () => {
      const now = new Date();
      const input: JoinUserChallengeInput = {
        challengeId: 'c1',
      };

      const expected = {
        completedAt: now,
        status: ChallengeStatus.IN_PROGRESS,
        challengeId: 'c1',
        userId: 'user1',
        startedAt: now,
      };

      service.remove.mockResolvedValue(expected);

      const result = await resolver.removeUserChallenge(input, mockUser);

      expect(service.remove).toHaveBeenCalledWith(input, mockUser.sub);
      expect(result).toEqual(expected);
    });

    it('should throw custom error on failure', async () => {
      service.remove.mockRejectedValue(
        new Error('Failed to remove user challenge'),
      );

      await expect(
        resolver.removeUserChallenge({ challengeId: 'c1' }, mockUser),
      ).rejects.toThrow('Failed to remove user challenge');
    });
  });
});
