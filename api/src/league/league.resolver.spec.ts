import { Test, TestingModule } from '@nestjs/testing';
import { LeagueResolver } from './league.resolver';
import { LeagueService } from './league.service';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';
import { InternalServerErrorException } from '@nestjs/common';
import { ExecutionContext } from '@nestjs/common';

import { GqlAuthGuard } from '../auth/auth.guard';

describe('LeagueResolver', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

  let resolver: LeagueResolver;
  let leagueService: jest.Mocked<LeagueService>;

  const mockUser = { sub: 'user-1' };
  const mockLeague = {
    id: 'league-1',
    name: 'Test League',
    createdBy: 'user-1',
  } as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeagueResolver,
        {
          provide: LeagueService,
          useValue: {
            create: jest.fn(),
            findOneById: jest.fn(),
            update: jest.fn(),
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

    resolver = module.get<LeagueResolver>(LeagueResolver);
    leagueService = module.get(LeagueService) as jest.Mocked<LeagueService>;
    jest.clearAllMocks();
  });

  describe('createLeague', () => {
    it('should call leagueService.create and return the result', async () => {
      const input: CreateLeagueInput = { name: 'Test League' };
      leagueService.create.mockResolvedValue(mockLeague);

      const result = await resolver.createLeague(input, mockUser);
      expect(leagueService.create).toHaveBeenCalledWith(input, mockUser.sub); // adjust if order is different
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      const input: CreateLeagueInput = { name: 'Test League' };
      leagueService.create.mockRejectedValue(
        new InternalServerErrorException('DB error'),
      );

      await expect(resolver.createLeague(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOneById', () => {
    it('should call leagueService.findOneById and return the result', async () => {
      leagueService.findOneById.mockResolvedValue(mockLeague);

      const result = await resolver.findOneById('league-1', mockUser);
      expect(leagueService.findOneById).toHaveBeenCalledWith(
        'league-1',
        mockUser.sub,
      );
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      leagueService.findOneById.mockRejectedValue(
        new InternalServerErrorException('DB error'),
      );

      await expect(resolver.findOneById('league-1', mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('updateLeague', () => {
    it('should call leagueService.update and return the result', async () => {
      const input: UpdateLeagueInput = {
        id: 'league-1',
        name: 'Updated League',
      };
      leagueService.update.mockResolvedValue({
        ...mockLeague,
        name: 'Updated League',
      });

      const result = await resolver.updateLeague(input, mockUser);
      expect(leagueService.update).toHaveBeenCalledWith(input, mockUser.sub);
      expect(result).toEqual({ ...mockLeague, name: 'Updated League' });
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      const input: UpdateLeagueInput = {
        id: 'league-1',
        name: 'Updated League',
      };
      leagueService.update.mockRejectedValue(
        new InternalServerErrorException('DB error'),
      );

      await expect(resolver.updateLeague(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('removeLeague', () => {
    it('should call leagueService.remove and return the result', async () => {
      leagueService.remove.mockResolvedValue(mockLeague);

      const result = await resolver.removeLeague('league-1', mockUser);
      expect(leagueService.remove).toHaveBeenCalledWith(
        'league-1',
        mockUser.sub,
      );
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      leagueService.remove.mockRejectedValue(
        new InternalServerErrorException('DB error'),
      );

      await expect(resolver.removeLeague('league-1', mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });
});
