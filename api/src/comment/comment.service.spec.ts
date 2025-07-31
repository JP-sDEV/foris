import { Test, TestingModule } from '@nestjs/testing';
import { CommentService } from './comment.service';
import { PostService } from '../post/post.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  NotFoundException,
  ForbiddenException,
  // InternalServerErrorException,
} from '@nestjs/common';

describe('CommentService', () => {
  let commentService: CommentService;
  let prismaMock: any;
  let postService: any;

  beforeEach(async () => {
    prismaMock = {
      comment: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      } as any,
    };

    postService = {
      findOne: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentService,
        { provide: PostService, useValue: postService },
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    commentService = module.get<CommentService>(CommentService);
  });

  it('should be defined', () => {
    expect(commentService).toBeDefined();
  });

  describe('create', () => {
    it('should create a comment', async () => {
      (postService.findOne as jest.Mock).mockResolvedValue({ id: 'post123' });
      (prismaMock.comment.create as jest.Mock).mockResolvedValue({
        id: 'c1',
        content: 'test comment',
      });

      const result = await commentService.create('user1', {
        postId: 'post123',
        content: 'test comment',
      });

      expect(result).toEqual({ id: 'c1', content: 'test comment' });
    });

    it('should throw NotFoundException if post not found', async () => {
      (postService.findOne as jest.Mock).mockRejectedValue(
        new NotFoundException('Post not found'),
      );

      await expect(
        commentService.create('user1', {
          postId: 'missing',
          content: 'test comment',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('findOne', () => {
    it('should return a comment', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue({
        id: 'c1',
        content: 'comment',
      });

      const result = await commentService.findOne('c1');
      expect(result).toEqual({ id: 'c1', content: 'comment' });
    });

    it('should throw NotFoundException if comment not found', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(commentService.findOne('missing')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    it('should update a comment', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue({
        id: 'c1',
        userId: 'user1',
      });
      (prismaMock.comment.update as jest.Mock).mockResolvedValue({
        id: 'c1',
        content: 'updated',
      });

      const result = await commentService.update('user1', {
        id: 'c1',
        content: 'updated',
      });

      expect(result).toEqual({ id: 'c1', content: 'updated' });
    });

    it('should throw NotFoundException if comment not found', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(
        commentService.update('user1', { id: 'c1', content: 'updated' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException if not owner', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue({
        id: 'c1',
        userId: 'other',
      });

      await expect(
        commentService.update('user1', { id: 'c1', content: 'updated' }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('remove', () => {
    it('should delete a comment', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue({
        id: 'c1',
        userId: 'user1',
      });
      (prismaMock.comment.delete as jest.Mock).mockResolvedValue({ id: 'c1' });

      const result = await commentService.remove('user1', 'c1');
      expect(result).toEqual({ id: 'c1' });
    });

    it('should throw NotFoundException if comment not found', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(commentService.remove('user1', 'missing')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException if not owner', async () => {
      (prismaMock.comment.findUnique as jest.Mock).mockResolvedValue({
        id: 'c1',
        userId: 'other',
      });

      await expect(commentService.remove('user1', 'c1')).rejects.toThrow(
        ForbiddenException,
      );
    });
  });
});
