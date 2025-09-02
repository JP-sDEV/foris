import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PostService } from './post.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';

describe('PostService', () => {
  let service: PostService;
  let prisma: jest.Mocked<PrismaService>;

  const mockPrismaService = {
    post: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PostService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    service = module.get<PostService>(PostService);
    prisma = module.get(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a new post', async () => {
      const input: CreatePostInput = {
        title: 'Test Title',
        content: 'Test Content',
      };
      const userId = 'user-123';

      const createdPost = {
        id: 'post1',
        title: input.title,
        content: input.content,
        authorId: userId,
      };

      mockPrismaService.post.create.mockResolvedValue(createdPost);

      const result = await service.create(input, userId);

      expect(result).toEqual(createdPost);
      expect(prisma.post.create).toHaveBeenCalledWith({
        data: {
          title: input.title,
          content: input.content,
          author: {
            connect: { id: userId },
          },
        },
      });
    });
  });

  describe('findAll', () => {
    it('should return all posts with relations', async () => {
      const posts = [
        { id: '1', title: 'Post 1', author: {}, comments: [], likes: [] },
        { id: '2', title: 'Post 2', author: {}, comments: [], likes: [] },
      ];
      mockPrismaService.post.findMany.mockResolvedValue(posts);

      const result = await service.findAll();

      expect(result).toEqual(posts);
      expect(prisma.post.findMany).toHaveBeenCalledWith({
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    });
  });

  describe('findOne', () => {
    it('should return a single post by ID', async () => {
      const post = {
        id: '123',
        title: 'Sample',
        author: {},
        comments: [],
        likes: [],
      };

      mockPrismaService.post.findUnique.mockResolvedValue(post);

      const result = await service.findOne('123');

      expect(result).toEqual(post);
      expect(prisma.post.findUnique).toHaveBeenCalledWith({
        where: { id: '123' },
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPrismaService.post.findUnique.mockResolvedValue(null);

      await expect(service.findOne('missing')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('findUserPosts', () => {
    it('should return all posts for a user', async () => {
      const posts = [
        {
          id: 'p1',
          title: 'Post 1',
          authorId: 'u1',
          author: {},
          comments: [],
          likes: [],
        },
      ];
      mockPrismaService.post.findMany.mockResolvedValue(posts);

      const result = await service.findUserPosts('u1');

      expect(result).toEqual(posts);
      expect(prisma.post.findMany).toHaveBeenCalledWith({
        where: { authorId: 'u1' },
        include: { author: true, comments: true, likes: true },
      });
    });
  });

  describe('update', () => {
    it('should update a post if user is the owner', async () => {
      const input: UpdatePostInput = {
        id: 'p1',
        title: 'Updated',
        content: 'Updated Content',
      };
      const userId = 'u1';
      const existing = { id: 'p1', authorId: 'u1' };
      const updated = { ...existing, ...input };

      mockPrismaService.post.findUnique.mockResolvedValue(existing);
      mockPrismaService.post.update.mockResolvedValue(updated);

      const result = await service.update(input, userId);

      expect(result).toEqual(updated);
      expect(prisma.post.update).toHaveBeenCalledWith({
        where: { id: input.id },
        data: input,
      });
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPrismaService.post.findUnique.mockResolvedValue(null);

      await expect(
        service.update({ id: 'missing' } as UpdatePostInput, 'u1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException if user is not the owner', async () => {
      const input: UpdatePostInput = { id: 'p1', title: 'New', content: 'New' };
      const existing = { id: 'p1', authorId: 'other' };

      mockPrismaService.post.findUnique.mockResolvedValue(existing);

      await expect(service.update(input, 'u1')).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('remove', () => {
    it('should delete a post if user is the owner', async () => {
      const id = 'p1';
      const userId = 'u1';
      const existing = { id, authorId: userId };
      const deleted = { id, title: 'Deleted', content: '...' };

      mockPrismaService.post.findUnique.mockResolvedValue(existing);
      mockPrismaService.post.delete.mockResolvedValue(deleted);

      const result = await service.remove(id, userId);

      expect(result).toEqual(deleted);
      expect(prisma.post.delete).toHaveBeenCalledWith({ where: { id } });
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPrismaService.post.findUnique.mockResolvedValue(null);

      await expect(service.remove('missing', 'u1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException if user is not the owner', async () => {
      mockPrismaService.post.findUnique.mockResolvedValue({
        id: 'p1',
        authorId: 'other',
      });

      await expect(service.remove('p1', 'u1')).rejects.toThrow(
        ForbiddenException,
      );
    });
  });
});
