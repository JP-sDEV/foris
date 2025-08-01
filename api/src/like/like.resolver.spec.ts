import { Test, TestingModule } from '@nestjs/testing';
import { LikeResolver } from './like.resolver';
import { LikeService } from './like.service';
import { CreateLikeInput } from './dto/create-like.input';
import { InternalServerErrorException } from '@nestjs/common';
import { Like } from './entities/like.entity';
import { GqlAuthGuard } from '../auth/auth.guard';

describe('LikeResolver', () => {
  let resolver: LikeResolver;
  let service: LikeService;

  const mockUser = { sub: 'user-123' };

  const mockLike: Like = {
    postId: 'post-1',
    userId: 'user-123',
  };

  const mockLikeService = {
    create: jest.fn(),
    findOne: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    jest.spyOn(console, 'error').mockImplementation(() => {});

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LikeResolver,
        { provide: LikeService, useValue: mockLikeService },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({ canActivate: jest.fn().mockReturnValue(true) })
      .compile();

    resolver = module.get<LikeResolver>(LikeResolver);
    service = module.get<LikeService>(LikeService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createLike', () => {
    it('should create and return a like', async () => {
      const input: CreateLikeInput = { postId: 'post-1' };
      mockLikeService.create.mockResolvedValue(mockLike);

      const result = await resolver.createLike(input, mockUser);

      expect(service.create).toHaveBeenCalledWith(mockUser.sub, input);
      expect(result).toEqual(mockLike);
    });

    it('should throw InternalServerErrorException on failure', async () => {
      mockLikeService.create.mockRejectedValue(new Error('DB error'));

      await expect(
        resolver.createLike({ postId: 'post-1' }, mockUser),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });

  describe('findOne', () => {
    it('should return a like by ID', async () => {
      mockLikeService.findOne.mockResolvedValue(mockLike);

      const result = await resolver.findOne('like-1', mockUser);

      expect(service.findOne).toHaveBeenCalledWith(mockUser.sub, 'like-1');
      expect(result).toEqual(mockLike);
    });

    it('should throw InternalServerErrorException on failure', async () => {
      mockLikeService.findOne.mockRejectedValue(new Error('DB error'));

      await expect(resolver.findOne('like-1', mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('removeLike', () => {
    it('should remove and return the like', async () => {
      mockLikeService.remove.mockResolvedValue(mockLike);

      const result = await resolver.removeLike('like-1', mockUser);

      expect(service.remove).toHaveBeenCalledWith(mockUser.sub, 'like-1');
      expect(result).toEqual(mockLike);
    });

    it('should throw InternalServerErrorException on failure', async () => {
      mockLikeService.remove.mockRejectedValue(new Error('DB error'));

      await expect(resolver.removeLike('like-1', mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });
});
