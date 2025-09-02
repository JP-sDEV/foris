import { Test, TestingModule } from '@nestjs/testing';
import { LeagueResolver } from './league.resolver';
import { LeagueService } from './league.service';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';
import { InternalServerErrorException } from '@nestjs/common';
import { ExecutionContext } from '@nestjs/common';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { JwtPayload } from '../auth/types/jwt-payload.type';

describe('LeagueResolver', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

  let resolver: LeagueResolver;
  let leagueService: jest.Mocked<LeagueService>;

  const mockPayload: JwtPayload = {
    userId: 'user-1',
    email: 'test@email.com',
    name: 'Test User',
  };

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
            findOneByIdUser: jest.fn(),
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
          ctx.req = { user: mockPayload }; // Inject mock payload
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

      const result = await resolver.createLeague(input, mockPayload);

      expect(leagueService.create).toHaveBeenCalledWith(
        input,
        mockPayload.userId,
      );
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      const input: CreateLeagueInput = { name: 'Test League' };
      leagueService.create.mockRejectedValue(new Error('DB error'));

      await expect(resolver.createLeague(input, mockPayload)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOneByIdUser', () => {
    it('should call leagueService.findOneByIdUser and return the result', async () => {
      leagueService.findOneByIdUser.mockResolvedValue(mockLeague);

      const result = await resolver.findOneByIdUser('league-1', mockPayload);

      expect(leagueService.findOneByIdUser).toHaveBeenCalledWith(
        'league-1',
        mockPayload.userId,
      );
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      leagueService.findOneByIdUser.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.findOneByIdUser('league-1', mockPayload),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });

  describe('findLeagueById', () => {
    it('should call leagueService.findOneById and return the result', async () => {
      leagueService.findOneById.mockResolvedValue(mockLeague);

      const result = await resolver.findLeagueById('league-1');

      expect(leagueService.findOneById).toHaveBeenCalledWith('league-1');
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      leagueService.findOneById.mockRejectedValue(new Error('DB error'));

      await expect(resolver.findLeagueById('league-1')).rejects.toThrow(
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
      const updated = { ...mockLeague, name: 'Updated League' };
      leagueService.update.mockResolvedValue(updated);

      const result = await resolver.updateLeague(input, mockPayload);

      expect(leagueService.update).toHaveBeenCalledWith(
        input,
        mockPayload.userId,
      );
      expect(result).toEqual(updated);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      const input: UpdateLeagueInput = {
        id: 'league-1',
        name: 'Updated League',
      };
      leagueService.update.mockRejectedValue(new Error('DB error'));

      await expect(resolver.updateLeague(input, mockPayload)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('removeLeague', () => {
    it('should call leagueService.remove and return the result', async () => {
      leagueService.remove.mockResolvedValue(mockLeague);

      const result = await resolver.removeLeague('league-1', mockPayload);

      expect(leagueService.remove).toHaveBeenCalledWith(
        'league-1',
        mockPayload.userId,
      );
      expect(result).toEqual(mockLeague);
    });

    it('should throw InternalServerErrorException on service failure', async () => {
      leagueService.remove.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.removeLeague('league-1', mockPayload),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });
});
