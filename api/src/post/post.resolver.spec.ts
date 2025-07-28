import { Test, TestingModule } from '@nestjs/testing';
import { PostResolver } from './post.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { PostService } from './post.service';
import {
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';

describe('PostResolver', () => {
  let resolver: PostResolver;

  const mockPostService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PostResolver,
        {
          provide: PostService,
          useValue: mockPostService,
        },
        {
          provide: PrismaService,
          useValue: {}, // Not used directly
        },
      ],
    }).compile();

    resolver = module.get<PostResolver>(PostResolver);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });

  describe('createPost', () => {
    it('should return created post', async () => {
      const input = { title: 'Test', content: 'Hello', authorId: '1' };
      const result = { id: '1', ...input };
      mockPostService.create.mockResolvedValue(result);

      await expect(resolver.createPost(input)).resolves.toEqual(result);
    });

    it('should throw InternalServerErrorException on failure', async () => {
      // Silence console.error for this test
      jest.spyOn(console, 'error').mockImplementation(() => {});

      const input = { title: 'Test', content: 'Hello', authorId: '1' };
      mockPostService.create.mockRejectedValue(
        new InternalServerErrorException(),
      );

      await expect(resolver.createPost(input)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOne', () => {
    it('should return single post', async () => {
      const result = { id: '1', title: 'Hello', content: 'World' };
      mockPostService.findOne.mockResolvedValue(result);

      await expect(resolver.findOne('1')).resolves.toEqual(result);
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPostService.findOne.mockRejectedValue(
        new NotFoundException('Not found'),
      );

      await expect(resolver.findOne('99')).rejects.toThrow(NotFoundException);
    });
  });

  describe('updatePost', () => {
    it('should update and return post', async () => {
      const input = { id: '1', title: 'Updated', content: 'Changed' };
      const result = { ...input };
      mockPostService.update.mockResolvedValue(result);

      await expect(resolver.updatePost(input)).resolves.toEqual(result);
    });

    it('should throw NotFoundException if post does not exist', async () => {
      const input = { id: '99', title: 'Updated', content: 'Changed' };
      mockPostService.update.mockRejectedValue(new NotFoundException());

      await expect(resolver.updatePost(input)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('removePost', () => {
    it('should delete and return post', async () => {
      const result = { id: '1', title: 'Removed', content: 'Bye' };
      mockPostService.remove.mockResolvedValue(result);

      await expect(resolver.removePost('1')).resolves.toEqual(result);
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPostService.remove.mockRejectedValue(new NotFoundException());

      await expect(resolver.removePost('404')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw InternalServerErrorException for unexpected errors', async () => {
      mockPostService.remove.mockRejectedValue(
        new InternalServerErrorException(),
      );

      await expect(resolver.removePost('1')).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });
});
