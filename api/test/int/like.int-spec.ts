import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { JwtService } from '@nestjs/jwt';

describe('LikeModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;
  let userId: string;
  let postId: string;
  let token: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    // Clean database
    await prisma.like.deleteMany();
    await prisma.post.deleteMany();
    await prisma.user.deleteMany();

    // Seed user
    const user = await prisma.user.create({
      data: { id: uuidv4(), email: 'test@example.com', name: 'Test User' },
    });
    userId = user.id;

    // Seed post
    const post = await prisma.post.create({
      data: {
        id: uuidv4(),
        title: 'Test Post',
        content: 'Test content',
        authorId: userId,
      },
    });
    postId = post.id;

    // Create JWT token
    token = jwtService.sign(
      { sub: userId },
      { secret: process.env.JWT_SECRET },
    );
  });

  afterAll(async () => {
    await prisma.like.deleteMany();
    await prisma.post.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should create a like', async () => {
    const mutation = `
      mutation CreateLike($input: CreateLikeInput!) {
        createLike(createLikeInput: $input) {
          userId
          postId
          user { id email }
          post { id title }
        }
      }
    `;

    const variables = { input: { postId } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.createLike).toMatchObject({
      userId,
      postId,
    });
    expect(response.body.data.createLike.user).toBeDefined();
    expect(response.body.data.createLike.post).toBeDefined();
  });

  it('should find a like', async () => {
    const query = `
      query FindLike($id: String!) {
        like(id: $id) {
          userId
          postId
        }
      }
    `;

    const variables = { id: postId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.like).toMatchObject({
      userId,
      postId,
    });
  });

  it('should remove a like', async () => {
    const mutation = `
      mutation RemoveLike($id: String!) {
        removeLike(id: $id) {
          userId
          postId
        }
      }
    `;

    const variables = { id: postId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.removeLike).toMatchObject({
      userId,
      postId,
    });

    // Confirm deletion
    const findResponse = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query: `
            query FindLike($id: String!) {
              like(id: $id) { userId postId }
            }
          `,
        variables: { id: postId },
      });

    console.log('Find Response: ', findResponse.body);

    expect(findResponse.status).toBe(200);
    expect(findResponse.body.data.like).toBeNull();
  });

  describe('Unauthorized requests', () => {
    it('should reject createLike without auth', async () => {
      const mutation = `
        mutation CreateLike($input: CreateLikeInput!) {
          createLike(createLikeInput: $input) {
            userId
            postId
          }
        }
      `;
      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables: { input: { postId } } });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });

    it('should reject findOne without auth', async () => {
      const query = `
        query FindLike($id: String!) {
          like(id: $id) { userId postId }
        }
      `;
      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query, variables: { id: postId } });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data.like).toBeNull();
    });

    it('should reject removeLike without auth', async () => {
      const mutation = `
        mutation RemoveLike($id: String!) {
          removeLike(id: $id) { userId postId }
        }
      `;
      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables: { id: postId } });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });
  });
});
