import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import * as request from 'supertest';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { JwtService } from '@nestjs/jwt';

import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.dev.local') });

describe('PostModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let userId: string;
  let token: string;
  let jwtService: JwtService;
  let postId: string;
  const nonExistentId = uuidv4(); // Generate a random ID that doesn't exist

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    // Clear and seed the test DB
    await prisma.post.deleteMany();
    await prisma.user.deleteMany();

    // Create user
    const user = await prisma.user.create({
      data: {
        id: uuidv4(),
        email: 'challenge-test@example.com',
        name: 'Challenge Tester',
      },
    });
    userId = user.id;

    // Create JWT
    token = jwtService.sign(
      { userId: userId, name: user.name, email: user.email },
      { secret: process.env.JWT_SECRET },
    );

    const post = await prisma.post.create({
      data: {
        id: uuidv4(),
        title: 'Test Post',
        content: 'Test content',
        authorId: userId,
      },
    });

    postId = post.id;
  });

  afterAll(async () => {
    await prisma.post.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should fetch a post by id', async () => {
    const query = `
        query {
          post(id: "${postId}") {
            id
            title
            content
            authorId
          }
        }
      `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query });

    expect(response.status).toBe(200);
    expect(response.body.data.post).toMatchObject({
      id: postId,
      title: 'Test Post',
      content: 'Test content',
      authorId: userId,
    });
  });

  it('should fetch posts by user id', async () => {
    // jest.spyOn(console, 'error').mockImplementation(() => {});
    const query = `
        query GetUserPosts($userId: String!) {
            userPosts(userId: $userId) {
            id
            title
            content
            }
        }
`;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({
        query,
        variables: { userId },
      });

    // console.error(response.body.errors);

    expect(response.status).toBe(200);
    expect(response.body.data.userPosts).toHaveLength(1);
    expect(response.body.data.userPosts[0]).toMatchObject({
      id: postId,
      title: 'Test Post',
      content: 'Test content',
    });
  });

  it('should update a post by id', async () => {
    const mutation = `
  mutation UpdatePost($updatePostInput: UpdatePostInput!) {
    updatePost(updatePostInput: $updatePostInput) {
      id
      title
      content
    }
  }
`;

    const variables = {
      updatePostInput: {
        id: postId,
        title: 'Updated Title',
        content: 'Updated content',
      },
    };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    // console.error(response.body.errors);

    expect(response.status).toBe(200);
    expect(response.body.data.updatePost).toMatchObject({
      id: postId,
      title: 'Updated Title',
      content: 'Updated content',
    });
  });

  it('should remove a post by id', async () => {
    const mutation = `
    mutation RemovePost($id: String!) {
      removePost(id: $id) {
        id
      }
    }
  `;

    // Remove the post
    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables: { id: postId } });

    expect(response.status).toBe(200);
    expect(response.body.data.removePost.id).toBe(postId);

    // Try to fetch the deleted post — expect 404 error in GraphQL errors
    const confirmQuery = `
    query {
      post(id: "${postId}") {
        id
      }
    }
  `;

    const confirmResponse = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: confirmQuery });

    expect(confirmResponse.status).toBe(200);
    expect(confirmResponse.body.data).toBeNull(); // data is null because of error
    expect(confirmResponse.body.errors).toBeDefined();
    expect(confirmResponse.body.errors[0].message).toContain('not found');
    expect(confirmResponse.body.errors[0].extensions.status).toBe(404);
  });

  it('should return 404 error when fetching a non-existent post', async () => {
    const query = `
      query {
        post(id: "${nonExistentId}") {
          id
          title
          content
          authorId
        }
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query });

    expect(response.status).toBe(200);
    expect(response.body.data).toBeNull();
    expect(response.body.errors).toBeDefined();
    expect(response.body.errors[0].message).toContain(
      `Post with ID ${nonExistentId} not found`,
    );
    expect(response.body.errors[0].extensions.status).toBe(404);
  });

  it('should return 404 error when updating a non-existent post', async () => {
    const mutation = `
      mutation UpdatePost($updatePostInput: UpdatePostInput!) {
        updatePost(updatePostInput: $updatePostInput) {
          id
          title
          content
        }
      }
    `;

    const variables = {
      updatePostInput: {
        id: nonExistentId,
        title: 'Will not update',
        content: 'Will not update',
      },
    };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data).toBeNull();
    expect(response.body.errors).toBeDefined();
    expect(response.body.errors[0].message).toContain(
      `Post with ID ${nonExistentId} not found`,
    );
    expect(response.body.errors[0].extensions.status).toBe(404);
  });

  it('should return 404 error when removing a non-existent post', async () => {
    const mutation = `
      mutation RemovePost($id: String!) {
        removePost(id: $id) {
          id
        }
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables: { id: nonExistentId } });

    expect(response.status).toBe(200);
    expect(response.body.data).toBeNull();
    expect(response.body.errors).toBeDefined();
    expect(response.body.errors[0].message).toContain(
      `Post with ID ${nonExistentId} not found`,
    );
    expect(response.body.errors[0].extensions.status).toBe(404);
  });
});
