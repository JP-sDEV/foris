import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { PostService } from './post.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';

describe('PostService', () => {
  let service: PostService;

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
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a new post WITHOUT Media', async () => {
      const input: CreatePostInput = {
        title: 'Test Title',
        content: 'Test Content',
        authorId: 'author123',
      };

      const createdPost = {
        id: 'post1',
        title: input.title,
        content: input.content,
        authorId: input.authorId,
      };

      mockPrismaService.post.create.mockResolvedValue(createdPost);

      const result = await service.create(input);

      expect(result).toEqual(createdPost);
      expect(mockPrismaService.post.create).toHaveBeenCalledWith({
        data: {
          title: input.title,
          content: input.content,
          author: {
            connect: { id: input.authorId },
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
      expect(mockPrismaService.post.findMany).toHaveBeenCalledWith({
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    });
  });

  describe('findOne', () => {
    it('should return a single post by ID with relations', async () => {
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
      expect(mockPrismaService.post.findUnique).toHaveBeenCalledWith({
        where: { id: '123' },
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    });
  });

  describe('update', () => {
    it('should update a post by ID', async () => {
      const id = 'abc123';
      const updateData: UpdatePostInput = {
        id: id,
        title: 'Updated Title',
        content: 'Updated Content',
        authorId: 'author456',
      };

      const updatedPost = {
        id,
        ...updateData,
      };

      mockPrismaService.post.update.mockResolvedValue(updatedPost);

      const result = await service.update(id, updateData);

      expect(result).toEqual(updatedPost);
      expect(mockPrismaService.post.update).toHaveBeenCalledWith({
        where: { id },
        data: updateData,
      });
    });
  });

  describe('remove', () => {
    it('should delete a post by ID', async () => {
      const id = 'xyz789';
      const deletedPost = {
        id,
        title: 'Deleted Post',
        content: '...',
      };

      mockPrismaService.post.delete.mockResolvedValue(deletedPost);

      const result = await service.remove(id);

      expect(result).toEqual(deletedPost);
      expect(mockPrismaService.post.delete).toHaveBeenCalledWith({
        where: { id },
      });
    });
  });

  describe('findOne - Error Handling', () => {
    it('should throw NotFoundException if post not found', async () => {
      mockPrismaService.post.findUnique.mockResolvedValue(null);

      await expect(service.findOne('nonexistent-id')).rejects.toThrow(
        NotFoundException,
      );
      expect(mockPrismaService.post.findUnique).toHaveBeenCalledWith({
        where: { id: 'nonexistent-id' },
        include: {
          author: true,
          comments: true,
          likes: true,
        },
      });
    });
  });

  describe('update - Error Handling', () => {
    it('should throw NotFoundException if update fails (post not found)', async () => {
      const id = 'invalid-id';
      const updateData: UpdatePostInput = {
        id: 'invalid-id',
        title: 'Does not matter',
        content: '...',
        authorId: 'authorX',
      };

      // Mock findUnique to return null → simulate not found
      mockPrismaService.post.findUnique.mockResolvedValue(null);

      await expect(service.update(id, updateData)).rejects.toThrow(
        NotFoundException,
      );

      expect(mockPrismaService.post.findUnique).toHaveBeenCalledWith({
        where: { id },
      });

      // Optional: ensure update was never called
      expect(mockPrismaService.post.update).not.toHaveBeenCalled();
    });
  });

  describe('remove - Error Handling', () => {
    it('should throw NotFoundException if delete fails (post not found)', async () => {
      const id = 'missing-id';

      // Mock findUnique to return null → simulate not found
      mockPrismaService.post.findUnique.mockResolvedValue(null);

      await expect(service.remove(id)).rejects.toThrow(NotFoundException);

      expect(mockPrismaService.post.findUnique).toHaveBeenCalledWith({
        where: { id },
      });

      expect(mockPrismaService.post.delete).not.toHaveBeenCalled();
    });
  });
});
