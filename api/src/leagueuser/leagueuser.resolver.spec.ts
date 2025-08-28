import { Test, TestingModule } from '@nestjs/testing';
import { LeagueuserResolver } from './leagueuser.resolver';
import { LeagueuserService } from './leagueuser.service';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { ExecutionContext } from '@nestjs/common';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { LeagueRole } from '@prisma/client';

describe('LeagueuserResolver', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

  let resolver: LeagueuserResolver;
  let leagueuserService: jest.Mocked<LeagueuserService>;

  const mockUser = {
    userId: 'user-1',
    email: 'test@email.com',
    name: 'Test User',
  };
  const mockLeagueUser = {
    leagueId: 'league-1',
    userId: 'user-1',
    joinedAt: new Date(),
    role: LeagueRole.MEMBER, // or LeagueRole.ADMIN depending on test
  };
  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeagueuserResolver,
        {
          provide: LeagueuserService,
          useValue: {
            create: jest.fn(),
            findAll: jest.fn(),
            findOne: jest.fn(),
            remove: jest.fn(),
          },
        },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          const ctx = context.getArgByIndex(2); // GraphQL context
          ctx.req = { user: mockUser }; // inject mock user
          return true;
        },
      })
      .compile();

    resolver = module.get<LeagueuserResolver>(LeagueuserResolver);
    leagueuserService = module.get(
      LeagueuserService,
    ) as jest.Mocked<LeagueuserService>;
    jest.clearAllMocks();
  });

  describe('createLeagueuser', () => {
    it('should call service.create and return result', async () => {
      const input: CreateLeagueuserInput = { leagueId: 'league-1' };
      leagueuserService.create.mockResolvedValue(mockLeagueUser);

      const result = await resolver.createLeagueuser(input, mockUser);

      expect(leagueuserService.create).toHaveBeenCalledWith(
        input,
        mockUser.userId,
      );
      expect(result).toEqual(mockLeagueUser);
    });

    it('should throw error if service.create fails', async () => {
      const input: CreateLeagueuserInput = { leagueId: 'league-1' };
      leagueuserService.create.mockRejectedValue(new Error('DB error'));

      await expect(resolver.createLeagueuser(input, mockUser)).rejects.toThrow(
        Error,
      );
    });
  });

  describe('findAll', () => {
    it('should call service.findAll and return result', async () => {
      const input: CreateLeagueuserInput = { leagueId: 'league-1' };

      const mockResult = [
        {
          leagueId: 'league-1',
          userId: 'user-1',
          joinedAt: new Date(),
          role: LeagueRole.MEMBER,
          user: {
            id: 'user-1',
            name: 'Test User',
            email: 'test@example.com',
            bio: 'Test bio',
            avatarUrl: 'http://example.com/avatar.png',
            createdAt: new Date(),
          },
        },
      ];

      leagueuserService.findAll.mockResolvedValue(mockResult);

      const result = await resolver.findAll(input, mockUser);

      expect(leagueuserService.findAll).toHaveBeenCalledWith(
        input,
        mockUser.userId,
      );
      expect(result).toEqual(mockResult);
    });

    it('should throw error if service.findAll fails', async () => {
      leagueuserService.findAll.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.findAll({ leagueId: 'l1' }, mockUser),
      ).rejects.toThrow(Error);
    });
  });

  describe('findOne', () => {
    it('should call service.findOne and return result', async () => {
      leagueuserService.findOne.mockResolvedValue(mockLeagueUser);

      const result = await resolver.findOne('league-1', 'user-1');

      expect(leagueuserService.findOne).toHaveBeenCalledWith(
        'league-1',
        'user-1',
      );
      expect(result).toEqual(mockLeagueUser);
    });

    it('should throw error if service.findOne fails', async () => {
      leagueuserService.findOne.mockRejectedValue(new Error('DB error'));

      await expect(resolver.findOne('l1', 'u1')).rejects.toThrow(Error);
    });
  });

  describe('removeLeagueuser', () => {
    it('should call service.remove and return result', async () => {
      const mockResponse = {
        message: `League user with userId=${mockUser.userId} removed from leagueId=league-1`,
        leagueId: 'league-1',
        userId: mockUser.userId,
      };
      leagueuserService.remove.mockResolvedValue(mockResponse);

      const result = await resolver.removeLeagueuser(
        'league-1',
        mockUser.userId,
        mockUser,
      );

      expect(leagueuserService.remove).toHaveBeenCalledWith(
        'league-1',
        mockUser.userId,
        mockUser.userId,
      );
      expect(result).toEqual(mockResponse);
    });

    it('should throw error if service.remove fails', async () => {
      leagueuserService.remove.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.removeLeagueuser('l1', 'u1', mockUser),
      ).rejects.toThrow(Error);
    });
  });
});
