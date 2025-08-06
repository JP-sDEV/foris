import { Test, TestingModule } from '@nestjs/testing';
import { UserfollowResolver } from './userfollow.resolver';
import { UserfollowService } from './userfollow.service';
import { GqlAuthGuard } from '../auth/auth.guard';
import { ExecutionContext } from '@nestjs/common';

describe('UserfollowResolver', () => {
  let resolver: UserfollowResolver;
  let service: UserfollowService;

  const mockUser = { id: 'user-1', name: 'Test User', email: 'test@email.com' };
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
    expect(service.followUser).toHaveBeenCalledWith(mockUser.id, targetUserId);
  });

  it('should unfollow a user', async () => {
    await expect(resolver.unfollowUser(targetUserId, mockUser)).resolves.toBe(
      true,
    );
    expect(service.unfollowUser).toHaveBeenCalledWith(
      mockUser.id,
      targetUserId,
    );
  });

  it('should return followers list', async () => {
    await expect(resolver.getFollowers(mockUser.id)).resolves.toEqual([
      { id: 'user-2' },
    ]);
    expect(service.getFollowers).toHaveBeenCalledWith(mockUser.id);
  });

  it('should return following list', async () => {
    await expect(resolver.getFollowing(mockUser.id)).resolves.toEqual([
      { id: 'user-3' },
    ]);
    expect(service.getFollowing).toHaveBeenCalledWith(mockUser.id);
  });

  it('should return follower count', async () => {
    await expect(resolver.getFollowerCount(mockUser.id)).resolves.toBe(5);
    expect(service.getFollowerCount).toHaveBeenCalledWith(mockUser.id);
  });

  it('should return following count', async () => {
    await expect(resolver.getFollowingCount(mockUser.id)).resolves.toBe(7);
    expect(service.getFollowingCount).toHaveBeenCalledWith(mockUser.id);
  });

  it('should return true for isFollowing', async () => {
    await expect(resolver.isFollowing(targetUserId, mockUser)).resolves.toBe(
      true,
    );
    expect(service.isFollowing).toHaveBeenCalledWith(mockUser.id, targetUserId);
  });
});
