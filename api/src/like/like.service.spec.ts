import { Test, TestingModule } from '@nestjs/testing';
import { LikeService } from './like.service';
import { PrismaService } from '../prisma/prisma.service';
import { PostService } from '../post/post.service';
import { InternalServerErrorException } from '@nestjs/common';

describe('LikeService', () => {
  let service: LikeService;
  let prisma: PrismaService;
  let postService: PostService;

  const mockPrismaService = {
    like: {
      create: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
  };

  const mockPostService = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LikeService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: PostService, useValue: mockPostService },
      ],
    }).compile();

    service = module.get<LikeService>(LikeService);
    prisma = module.get<PrismaService>(PrismaService);
    postService = module.get<PostService>(PostService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a like successfully', async () => {
      const userId = 'user-123';
      const postId = 'post-456';
      const mockLike = { postId, userId, post: {}, user: {} };

      mockPostService.findOne.mockResolvedValue({});
      mockPrismaService.like.create.mockResolvedValue(mockLike);

      const result = await service.create(userId, { postId });

      expect(postService.findOne).toHaveBeenCalledWith(postId);
      expect(prisma.like.create).toHaveBeenCalled();
      expect(result).toEqual(mockLike);
    });

    it('should throw InternalServerErrorException on create failure', async () => {
      const userId = 'user-123';
      const postId = 'post-456';

      mockPostService.findOne.mockResolvedValue({});
      mockPrismaService.like.create.mockRejectedValue(new Error('DB error'));

      await expect(service.create(userId, { postId })).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOne', () => {
    it('should return a like', async () => {
      const userId = 'user-123';
      const postId = 'post-456';
      const mockLike = { postId, userId };

      mockPrismaService.like.findUnique.mockResolvedValue(mockLike);

      const result = await service.findOne(userId, postId);

      expect(prisma.like.findUnique).toHaveBeenCalledWith({
        where: {
          userId_postId: { userId, postId },
        },
      });
      expect(result).toEqual(mockLike);
    });

    it('should throw InternalServerErrorException on find failure', async () => {
      mockPrismaService.like.findUnique.mockRejectedValue(
        new Error('DB error'),
      );

      await expect(service.findOne('user-123', 'post-456')).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('remove', () => {
    it('should remove a like', async () => {
      const userId = 'user-123';
      const postId = 'post-456';
      const mockDeletedLike = { postId, userId };

      mockPrismaService.like.delete.mockResolvedValue(mockDeletedLike);

      const result = await service.remove(userId, postId);

      expect(prisma.like.delete).toHaveBeenCalledWith({
        where: {
          userId_postId: { userId, postId },
        },
      });
      expect(result).toEqual(mockDeletedLike);
    });

    it('should throw InternalServerErrorException on remove failure', async () => {
      mockPrismaService.like.delete.mockRejectedValue(new Error('DB error'));

      await expect(service.remove('user-123', 'post-456')).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });
});
