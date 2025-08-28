import { Test, TestingModule } from '@nestjs/testing';
import { UserfollowResolver } from './userfollow.resolver';
import { UserfollowService } from './userfollow.service';
import { GqlAuthGuard } from '../auth/guards/auth.guard';
import { ExecutionContext } from '@nestjs/common';
import { JwtPayload } from '../auth/types/jwt-payload.type';

describe('UserfollowResolver', () => {
  let resolver: UserfollowResolver;
  let service: UserfollowService;

  const mockUser: JwtPayload = {
    userId: 'user-123',
    email: 'test@example.com',
    name: 'Test User',
  };
  const targetUserId = 'user-2';

  const mockService = {
    followUser: jest.fn().mockResolvedValue(true),
    unfollowUser: jest.fn().mockResolvedValue(true),
    getFollowers: jest.fn().mockResolvedValue([{ id: 'user-2' }]),
    getFollowing: jest.fn().mockResolvedValue([{ id: 'user-3' }]),
    getFollowerCount: jest.fn().mockResolvedValue(5),
    getFollowingCount: jest.fn().mockResolvedValue(7),
    isFollowing: jest.fn().mockResolvedValue(true),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserfollowResolver,
        {
          provide: UserfollowService,
          useValue: mockService,
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

    resolver = module.get<UserfollowResolver>(UserfollowResolver);
    service = module.get<UserfollowService>(UserfollowService);
  });

  it('should follow a user', async () => {
    await expect(resolver.followUser(targetUserId, mockUser)).resolves.toBe(
      true,
    );
    expect(service.followUser).toHaveBeenCalledWith(
      mockUser.userId,
      targetUserId,
    );
  });

  it('should unfollow a user', async () => {
    await expect(resolver.unfollowUser(targetUserId, mockUser)).resolves.toBe(
      true,
    );
    expect(service.unfollowUser).toHaveBeenCalledWith(
      mockUser.userId,
      targetUserId,
    );
  });

  it('should return followers list', async () => {
    await expect(resolver.getFollowers(mockUser.userId)).resolves.toEqual([
      { id: 'user-2' },
    ]);
    expect(service.getFollowers).toHaveBeenCalledWith(mockUser.userId);
  });

  it('should return following list', async () => {
    await expect(resolver.getFollowing(mockUser.userId)).resolves.toEqual([
      { id: 'user-3' },
    ]);
    expect(service.getFollowing).toHaveBeenCalledWith(mockUser.userId);
  });

  it('should return follower count', async () => {
    await expect(resolver.getFollowerCount(mockUser.userId)).resolves.toBe(5);
    expect(service.getFollowerCount).toHaveBeenCalledWith(mockUser.userId);
  });

  it('should return following count', async () => {
    await expect(resolver.getFollowingCount(mockUser.userId)).resolves.toBe(7);
    expect(service.getFollowingCount).toHaveBeenCalledWith(mockUser.userId);
  });

  it('should return true for isFollowing', async () => {
    await expect(resolver.isFollowing(targetUserId, mockUser)).resolves.toBe(
      true,
    );
    expect(service.isFollowing).toHaveBeenCalledWith(
      mockUser.userId,
      targetUserId,
    );
  });
});
