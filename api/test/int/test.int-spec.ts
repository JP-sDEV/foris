import { Test, TestingModule } from '@nestjs/testing';
import { LikeService } from '../../src/like/like.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { PostService } from '../../src/post/post.service';
import { AppModule } from '../../src/app.module';
import { InternalServerErrorException } from '@nestjs/common';

describe('LikeService Integration', () => {
  let app;
  let likeService: LikeService;
  let prisma: PrismaService;
  let postService: PostService;

  let userId: string;
  let postId: string;

  beforeAll(async () => {
    jest.spyOn(console, 'error').mockImplementation(() => {}); // suppress logs

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    likeService = app.get(LikeService);
    prisma = app.get(PrismaService);
    postService = app.get(PostService);

    // Clean up likes, posts, users
    await prisma.like.deleteMany({});
    await prisma.post.deleteMany({});
    await prisma.user.deleteMany({});

    // Seed a user
    const user = await prisma.user.create({
      data: { email: 'test@example.com', name: 'Test User' },
    });
    userId = user.id;

    // Seed a post
    const post = await postService.create({
      title: 'Test Post',
      content: 'Post content',
      authorId: userId,
    });
    postId = post.id;
  });

  afterAll(async () => {
    await prisma.like.deleteMany({});
    await prisma.post.deleteMany({});
    await prisma.user.deleteMany({});
    await app.close();
  });

  describe('create', () => {
    console.log('Prisma: ', prisma);
    it('should create and return a like', async () => {
      const like = await likeService.create(userId, { postId });

      expect(like).toBeDefined();
      expect(like.userId).toBe(userId);
      expect(like.postId).toBe(postId);
      expect(like.user).toBeDefined();
      expect(like.post).toBeDefined();
    });

    it('should throw InternalServerErrorException if post does not exist', async () => {
      await expect(
        likeService.create(userId, { postId: 'nonexistent-post' }),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });
});
