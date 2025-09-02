import { Test, TestingModule } from '@nestjs/testing';
import { PostResolver } from './post.resolver';
import { PostService } from './post.service';
import {
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { JwtPayload } from '../auth/types/jwt-payload.type';
import { GqlAuthGuard } from '../auth/guards/auth.guard';

describe('PostResolver', () => {
  let resolver: PostResolver;

  const mockPostService = {
    create: jest.fn(),
    findOne: jest.fn(),
    findUserPosts: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
  };

  const mockUser: JwtPayload = {
    userId: 'user-123',
    email: 'test@example.com',
    name: 'Test User',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PostResolver,
        {
          provide: PostService,
          useValue: mockPostService,
        },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({
        canActivate: () => {
          return true;
        },
      })
      .compile();

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
      const input = { title: 'Test', content: 'Hello' };
      const result = { id: '1', ...input, authorId: mockUser.userId };

      mockPostService.create.mockResolvedValue(result);

      await expect(resolver.createPost(input, mockUser)).resolves.toEqual(
        result,
      );
      expect(mockPostService.create).toHaveBeenCalledWith(
        input,
        mockUser.userId,
      );
    });

    it('should throw InternalServerErrorException on failure', async () => {
      jest.spyOn(console, 'error').mockImplementation(() => {}); // silence error logs

      const input = { title: 'Test', content: 'Hello' };
      mockPostService.create.mockRejectedValue(
        new InternalServerErrorException(),
      );

      await expect(resolver.createPost(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOneById', () => {
    it('should return single post', async () => {
      const result = { id: '1', title: 'Hello', content: 'World' };
      mockPostService.findOne.mockResolvedValue(result);

      await expect(resolver.findOneById('1')).resolves.toEqual(result);
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPostService.findOne.mockRejectedValue(new NotFoundException());

      await expect(resolver.findOneById('99')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('findUserPosts', () => {
    it('should return all posts for a user', async () => {
      const posts = [{ id: '1', title: 'Post 1', authorId: mockUser.userId }];
      mockPostService.findUserPosts.mockResolvedValue(posts);

      await expect(resolver.findUserPosts(mockUser.userId)).resolves.toEqual(
        posts,
      );
      expect(mockPostService.findUserPosts).toHaveBeenCalledWith(
        mockUser.userId,
      );
    });
  });

  describe('updatePost', () => {
    it('should update and return post', async () => {
      const input = { id: '1', title: 'Updated', content: 'Changed' };
      const result = { ...input, authorId: mockUser.userId };

      mockPostService.update.mockResolvedValue(result);

      await expect(resolver.updatePost(input, mockUser)).resolves.toEqual(
        result,
      );
      expect(mockPostService.update).toHaveBeenCalledWith(
        input,
        mockUser.userId,
      );
    });

    it('should throw NotFoundException if post does not exist', async () => {
      const input = { id: '99', title: 'Updated', content: 'Changed' };
      mockPostService.update.mockRejectedValue(new NotFoundException());

      await expect(resolver.updatePost(input, mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('removePost', () => {
    it('should delete and return post', async () => {
      const result = { id: '1', title: 'Removed', content: 'Bye' };
      mockPostService.remove.mockResolvedValue(result);

      await expect(resolver.removePost('1', mockUser)).resolves.toEqual(result);
      expect(mockPostService.remove).toHaveBeenCalledWith('1', mockUser.userId);
    });

    it('should throw NotFoundException if post not found', async () => {
      mockPostService.remove.mockRejectedValue(new NotFoundException());

      await expect(resolver.removePost('404', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw InternalServerErrorException for unexpected errors', async () => {
      mockPostService.remove.mockRejectedValue(
        new InternalServerErrorException(),
      );

      await expect(resolver.removePost('1', mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });
});
