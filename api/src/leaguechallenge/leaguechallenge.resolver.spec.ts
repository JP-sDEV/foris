import { Test, TestingModule } from '@nestjs/testing';
import { LeaguechallengeResolver } from './leaguechallenge.resolver';
import { LeaguechallengeService } from './leaguechallenge.service';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';
import { InternalServerErrorException, ExecutionContext } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/auth.guard';

describe('LeaguechallengeResolver', () => {
  let resolver: LeaguechallengeResolver;
  let service: jest.Mocked<LeaguechallengeService>;

  const mockUser = { sub: 'user-1' };
  const mockResult = {
    leagueId: 'league-1',
    challengeId: 'challenge-1',
    league: { id: 'league-1', name: 'League 1', createdBy: 'user-1' },
    challenge: { id: 'challenge-1', name: 'Challenge 1' },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeaguechallengeResolver,
        {
          provide: LeaguechallengeService,
          useValue: {
            create: jest.fn(),
            remove: jest.fn(),
          },
        },
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

    resolver = module.get<LeaguechallengeResolver>(LeaguechallengeResolver);
    service = module.get(
      LeaguechallengeService,
    ) as jest.Mocked<LeaguechallengeService>;
    jest.clearAllMocks();
  });

  describe('addLeaguechallenge', () => {
    it('should call service.create and return the result', async () => {
      service.create.mockResolvedValue(mockResult as any);

      const input: CreateLeaguechallengeInput = {
        leagueId: 'league-1',
        challengeId: 'challenge-1',
      };

      const result = await resolver.addLeaguechallenge(input, mockUser);
      expect(service.create).toHaveBeenCalledWith(input, mockUser.sub);
      expect(result).toEqual(mockResult);
    });

    it('should throw error on service failure', async () => {
      service.create.mockRejectedValue(
        new InternalServerErrorException('DB error'),
      );

      const input: CreateLeaguechallengeInput = {
        leagueId: 'league-1',
        challengeId: 'challenge-1',
      };

      await expect(
        resolver.addLeaguechallenge(input, mockUser),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });

  describe('removeLeaguechallenge', () => {
    it('should call service.remove and return the result', async () => {
      service.remove.mockResolvedValue(mockResult as any);

      const input: UpdateLeaguechallengeInput = {
        leagueId: 'league-1',
        challengeId: 'challenge-1',
      };

      const result = await resolver.removeLeaguechallenge(input, mockUser);
      expect(service.remove).toHaveBeenCalledWith(input, mockUser.sub);
      expect(result).toEqual(mockResult);
    });

    it('should throw error on service failure', async () => {
      service.remove.mockRejectedValue(
        new InternalServerErrorException('DB error'),
      );

      const input: UpdateLeaguechallengeInput = {
        leagueId: 'league-1',
        challengeId: 'challenge-1',
      };

      await expect(
        resolver.removeLeaguechallenge(input, mockUser),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });
});
