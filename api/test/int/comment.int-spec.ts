import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';

describe('CommentModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;
  let token: string;
  let userId: string;
  let postId: string;
  let commentId: string;

  beforeAll(async () => {
    jest.spyOn(console, 'error').mockImplementation(() => {});

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();

    await app.init();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    // Seed user and post
    const user = await prisma.user.create({
      data: { email: 'test@example.com', name: 'Test User' },
    });
    userId = user.id;

    // console.log('User ID:', userId);

    const post = await prisma.post.create({
      data: {
        title: 'Test Post',
        content: 'Post content',
        authorId: userId,
      },
    });
    postId = post.id;

    token = jwtService.sign({ sub: userId });
  });

  it('creates a comment', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
          mutation {
            createComment(createCommentInput: {
              postId: "${postId}",
              content: "Nice post!"
            }) {
              id
              content
              user { id }
              post { id }
            }
          }
        `,
      });

    expect(res.body.data.createComment.content).toBe('Nice post!');
    commentId = res.body.data.createComment.id;
  });

  it('fetches the created comment', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
            query {
              comment(id: "${commentId}") {
                id
                content
                user { id }
                post { id }
              }
            }
          `,
      });

    expect(res.body.data.comment.id).toBe(commentId);
    expect(res.body.data.comment.user.id).toBe(userId);
  });

  it('updates the comment', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
            mutation {
              updateComment(updateCommentInput: {
                id: "${commentId}",
                content: "Updated comment"
              }) {
                id
                content
              }
            }
          `,
      });

    expect(res.body.data.updateComment.content).toBe('Updated comment');
  });

  it('deletes the comment', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
            mutation {
              removeComment(id: "${commentId}") {
                id
              }
            }
          `,
      });

    expect(res.body.data.removeComment.id).toBe(commentId);
  });

  it('throws error when creating a comment on a non-existent post', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
          mutation {
            createComment(createCommentInput: {
              postId: "non-existent-post-id",
              content: "Invalid comment"
            }) {
              id
            }
          }
        `,
      });

    expect(res.body.errors).toBeDefined();
    expect(res.body.errors.length).toBeGreaterThan(0);
    expect(res.body.data).toBeNull();
  });

  it('throws error when updating a non-existent comment', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
          mutation {
            updateComment(updateCommentInput: {
              id: "non-existent-comment-id",
              content: "Trying to update"
            }) {
              id
            }
          }
        `,
      });

    expect(res.body.errors).toBeDefined();
    expect(res.body.errors.length).toBeGreaterThan(0);
    expect(res.body.data).toBeNull();
  });

  it('throws error when unauthorized user tries to update a comment', async () => {
    // Create a second user and token
    const otherUser = await prisma.user.create({
      data: { email: 'other@example.com', name: 'Other User' },
    });

    const otherToken = jwtService.sign({ sub: otherUser.id });

    // Recreate a comment under the original user
    const comment = await prisma.comment.create({
      data: {
        content: 'Original Comment',
        userId: userId,
        postId: postId,
      },
    });

    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${otherToken}`)
      .send({
        query: `
          mutation {
            updateComment(updateCommentInput: {
              id: "${comment.id}",
              content: "Hacked"
            }) {
              id
            }
          }
        `,
      });

    expect(res.body.errors).toBeDefined();
    expect(res.body.errors.length).toBeGreaterThan(0);
    expect(res.body.errors[0].message).toBeDefined();
    expect(res.body.data).toBeNull();
  });

  it('throws error when deleting a non-existent comment', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
          mutation {
            removeComment(id: "non-existent-comment-id") {
              id
            }
          }
        `,
      });

    expect(res.body.errors).toBeDefined();
    expect(res.body.errors.length).toBeGreaterThan(0);
    expect(res.body.data).toBeNull();
  });

  it('throws error when unauthorized user tries to delete a comment', async () => {
    const anotherComment = await prisma.comment.create({
      data: {
        content: "Someone else's comment",
        userId: userId,
        postId: postId,
      },
    });

    const otherUser = await prisma.user.findFirst({
      where: { email: 'other@example.com' },
    });

    const otherToken = jwtService.sign({ sub: otherUser.id });

    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${otherToken}`)
      .send({
        query: `
          mutation {
            removeComment(id: "${anotherComment.id}") {
              id
            }
          }
        `,
      });

    expect(res.body.errors).toBeDefined();
    expect(res.body.errors.length).toBeGreaterThan(0);
    expect(res.body.data).toBeNull();
  });

  afterAll(async () => {
    await prisma.comment.deleteMany();
    await prisma.post.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });
});
