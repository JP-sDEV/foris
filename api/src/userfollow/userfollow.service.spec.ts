import { Test, TestingModule } from '@nestjs/testing';
import { UserfollowService } from './userfollow.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import {
  SelfFollowException,
  UserNotFoundException,
} from './exceptions/userfollow.exceptions';

const mockPrismaService = {
  userFollow: {
    findUnique: jest.fn(),
    create: jest.fn(),
    deleteMany: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
  },
};

const mockUserService = {
  findOneById: jest.fn(),
};

describe('UserfollowService', () => {
  let service: UserfollowService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserfollowService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: UserService, useValue: mockUserService },
      ],
    }).compile();

    service = module.get<UserfollowService>(UserfollowService);
    jest.clearAllMocks();
  });

  describe('followUser', () => {
    const currentUserId = 'user-1';
    const targetUserId = 'user-2';

    it('should throw SelfFollowException when following self', async () => {
      await expect(
        service.followUser(currentUserId, currentUserId),
      ).rejects.toThrow(SelfFollowException);
    });

    it('should throw UserNotFoundException if either user does not exist', async () => {
      mockUserService.findOneById.mockResolvedValueOnce(null);
      await expect(
        service.followUser(currentUserId, targetUserId),
      ).rejects.toThrow(UserNotFoundException);
    });

    it('should return true if already following', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.findUnique.mockResolvedValue({});
      const result = await service.followUser(currentUserId, targetUserId);
      expect(result).toBe(true);
    });

    it('should create follow relationship and return true', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.findUnique.mockResolvedValue(null);
      mockPrismaService.userFollow.create.mockResolvedValue({});
      const result = await service.followUser(currentUserId, targetUserId);
      expect(result).toBe(true);
    });
  });

  describe('unfollowUser', () => {
    it('should call deleteMany and return true', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.deleteMany.mockResolvedValue({});
      const result = await service.unfollowUser('user-1', 'user-2');
      expect(result).toBe(true);
    });
  });

  describe('getFollowers', () => {
    it('should return followers list', async () => {
      const mockFollowers = [
        { follower: { id: '1', name: 'Alice' } },
        { follower: { id: '2', name: 'Bob' } },
      ];
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.findMany.mockResolvedValue(mockFollowers);

      const result = await service.getFollowers('user-2');
      expect(result).toEqual(mockFollowers.map((f) => f.follower));
    });
  });

  describe('getFollowing', () => {
    it('should return following list', async () => {
      const mockFollowing = [
        { following: { id: '3', name: 'Charlie' } },
        { following: { id: '4', name: 'Dave' } },
      ];
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.findMany.mockResolvedValue(mockFollowing);

      const result = await service.getFollowing('user-1');
      expect(result).toEqual(mockFollowing.map((f) => f.following));
    });
  });

  describe('getFollowerCount', () => {
    it('should return follower count', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.count.mockResolvedValue(5);
      const result = await service.getFollowerCount('user-1');
      expect(result).toBe(5);
    });
  });

  describe('getFollowingCount', () => {
    it('should return following count', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.count.mockResolvedValue(3);
      const result = await service.getFollowingCount('user-1');
      expect(result).toBe(3);
    });
  });

  describe('isFollowing', () => {
    it('should return true if following exists', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.findUnique.mockResolvedValue({});
      const result = await service.isFollowing('user-1', 'user-2');
      expect(result).toBe(true);
    });

    it('should return false if not following', async () => {
      mockUserService.findOneById.mockResolvedValue({});
      mockPrismaService.userFollow.findUnique.mockResolvedValue(null);
      const result = await service.isFollowing('user-1', 'user-2');
      expect(result).toBe(false);
    });
  });
});
