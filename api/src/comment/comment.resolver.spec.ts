import { Test, TestingModule } from '@nestjs/testing';
import { CommentResolver } from './comment.resolver';
import { CommentService } from './comment.service';
import { GqlAuthGuard } from '../auth/auth.guard';
import { InternalServerErrorException } from '@nestjs/common';

const mockCommentService = {
  create: jest.fn(),
  findOne: jest.fn(),
  update: jest.fn(),
  remove: jest.fn(),
};

const mockUser = { sub: 'user123' };

describe('CommentResolver', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

  let resolver: CommentResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentResolver,
        { provide: CommentService, useValue: mockCommentService },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({ canActivate: () => true }) // mock guard
      .compile();

    resolver = module.get<CommentResolver>(CommentResolver);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });

  describe('createComment', () => {
    it('should call commentService.create with user.sub and input', async () => {
      const input = { content: 'test comment', postId: 'post1' };
      const expected = { id: 'c1', ...input };
      mockCommentService.create.mockResolvedValue(expected);

      const result = await resolver.createComment(input, mockUser);
      expect(result).toEqual(expected);
      expect(mockCommentService.create).toHaveBeenCalledWith(
        mockUser.sub,
        input,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      const input = { content: 'test comment', postId: 'post1' };
      mockCommentService.create.mockRejectedValue(new Error('DB error'));

      await expect(resolver.createComment(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('findOne', () => {
    it('should return a comment by ID', async () => {
      const commentId = 'c1';
      const expected = { id: commentId, content: 'comment text' };
      mockCommentService.findOne.mockResolvedValue(expected);

      const result = await resolver.findOne(commentId);
      expect(result).toEqual(expected);
      expect(mockCommentService.findOne).toHaveBeenCalledWith(commentId);
    });

    it('should throw InternalServerErrorException on service error', async () => {
      mockCommentService.findOne.mockRejectedValue(new Error('DB error'));

      await expect(resolver.findOne('c1')).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('updateComment', () => {
    it('should call commentService.update with user.sub and input', async () => {
      const input = { id: 'c1', content: 'updated text' };
      const expected = { id: 'c1', content: 'updated text' };
      mockCommentService.update.mockResolvedValue(expected);

      const result = await resolver.updateComment(input, mockUser);
      expect(result).toEqual(expected);
      expect(mockCommentService.update).toHaveBeenCalledWith(
        mockUser.sub,
        input,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      const input = { id: 'c1', content: 'updated text' };
      mockCommentService.update.mockRejectedValue(new Error('DB error'));

      await expect(resolver.updateComment(input, mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('removeComment', () => {
    it('should call commentService.remove with user.sub and id', async () => {
      const commentId = 'c1';
      const expected = { id: commentId };
      mockCommentService.remove.mockResolvedValue(expected);

      const result = await resolver.removeComment(commentId, mockUser);
      expect(result).toEqual(expected);
      expect(mockCommentService.remove).toHaveBeenCalledWith(
        mockUser.sub,
        commentId,
      );
    });

    it('should throw InternalServerErrorException on service error', async () => {
      mockCommentService.remove.mockRejectedValue(new Error('DB error'));

      await expect(resolver.removeComment('c1', mockUser)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });
});
