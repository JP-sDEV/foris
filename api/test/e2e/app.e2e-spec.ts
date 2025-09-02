import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../../src/prisma/prisma.service';

import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.dev.local') });

describe('E2E Tests (GraphQL)', () => {
  let app: INestApplication;
  let httpServer: any;
  let token: string;
  let refreshToken: string;
  let userId: string;
  let postId: string;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    httpServer = app.getHttpServer();
  });

  afterAll(async () => {
    const prisma = app.get(PrismaService);

    await prisma.userFollow.deleteMany({});
    await prisma.post.deleteMany({});
    await prisma.comment.deleteMany({});
    await prisma.session.deleteMany({});
    await prisma.oAuthAccount.deleteMany({});
    await prisma.user.deleteMany({});

    await app.close();
  });

  const graphql = (query: string, variables?: any, authToken?: string) => {
    const req = request(httpServer)
      .post('/api/graphql')
      .send({ query, variables });

    if (authToken) {
      req.set('authorization', `Bearer ${authToken}`);
    }

    return req;
  };

  const EMAIL = `test+${Date.now()}@example.com`;
  const EMAIL2 = `test2+${Date.now()}@example.com`;

  // ---------------------------
  // 1. Register → login → logout
  // ---------------------------
  it('should register a new user via API', async () => {
    const mutation = `
    mutation CreateAuth($input: CreateAuthInput!) {
      createAuth(createAuthInput: $input) {
        user {
          id
          email
          name
        }
        refreshToken
      }
    }
  `;

    const variables = {
      input: {
        name: 'TestUser',
        email: EMAIL,
        provider: 'mock',
        providerUserId: uuidv4(),
      },
    };

    const res = await request(app.getHttpServer())
      .post('/api/graphql')
      .send({ query: mutation, variables });

    expect(res.status).toBe(200);
    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.createAuth.user.email).toBe(variables.input.email);
    expect(res.body.data.createAuth.user.name).toBe('TestUser');
    expect(res.body.data.createAuth.refreshToken).toBeDefined();
  });

  it('should login and return JWT token', async () => {
    const mutation = `
        mutation {
          login(email: "${EMAIL}") {
            accessToken
            refreshToken
            user {
              id
              email
            }
          }
        }
        `;

    const res = await graphql(mutation);

    expect(res.status).toBe(200);
    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.login.accessToken).toBeDefined();
    expect(res.body.data.login.user.email).toBe(EMAIL);

    // save token for future authenticated requests
    token = res.body.data.login.accessToken;
    refreshToken = res.body.data.login.refreshToken;
    userId = res.body.data.login.user.id;
  });

  it('should logout user', async () => {
    const res = await graphql(
      `
        mutation {
          logout
        }
      `,
      {},
      token,
    );

    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.logout).toBe(true);
  });

  // ---------------------------------------------
  // 2. Login → create post → like post → comment
  // ---------------------------------------------
  it('should login again to create a post', async () => {
    const res = await graphql(`
    mutation {
      login(email: "${EMAIL}") {
        accessToken
        refreshToken
        user {
          id
          email
        }
      }
    }
  `);
    token = res.body.data.login.accessToken;
    expect(token).toBeDefined();
  });

  it('should create a post', async () => {
    const res = await graphql(
      `
        mutation {
          createPost(
            createPostInput: { title: "Test Title", content: "Hello world!" }
          ) {
            id
            content
          }
        }
      `,
      {},
      token,
    );

    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.createPost.content).toBe('Hello world!');
    postId = res.body.data.createPost.id;
  });

  it('should like the created post', async () => {
    const res = await graphql(
      `
      mutation {
        createLike(
          createLikeInput: {
            postId: "${postId}"
          }
        ) {
          postId
          userId
        }
      }
    `,
      {},
      token,
    );

    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.createLike).toBeDefined();
    expect(res.body.data.createLike.postId).toBe(postId);
    expect(res.body.data.createLike.userId).toBeDefined();
  });

  it('should comment on the created post', async () => {
    const res = await graphql(
      `
      mutation {
        createComment(
          createCommentInput: {
            postId: "${postId}"
            content: "Nice post!"
          }
        ) {
          id
          content
        }
      }
    `,
      {},
      token,
    );

    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.createComment).toBeDefined();
    expect(res.body.data.createComment.content).toBe('Nice post!');
  });

  // -------------------------------
  // 3. Follow → unfollow user flow
  // -------------------------------
  let secondUserId: string;
  let secondUserToken: string;

  it('should register a second user via API', async () => {
    const mutation = `
    mutation CreateAuth($input: CreateAuthInput!) {
      createAuth(createAuthInput: $input) {
        user {
          id
          email
          name
        }
        refreshToken
      }
    }
  `;

    const variables = {
      input: {
        name: 'TestUser2',
        email: EMAIL2,
        provider: 'mock',
        providerUserId: uuidv4(),
      },
    };

    const res = await graphql(mutation, variables);

    expect(res.status).toBe(200);
    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.createAuth.user.email).toBe(EMAIL2);
    expect(res.body.data.createAuth.user.name).toBe('TestUser2');
    expect(res.body.data.createAuth.refreshToken).toBeDefined();

    secondUserId = res.body.data.createAuth.user.id;
    secondUserToken = res.body.data.createAuth.refreshToken;
  });

  it('should follow another user', async () => {
    const resFollow = await graphql(
      `
      mutation {
        followUser(targetUserId: "${secondUserId}")
        }
    `,
      {},
      token,
    );

    expect(resFollow.body.errors).toBeUndefined();
    expect(resFollow.body.data.followUser).toBe(true);
  });
});
