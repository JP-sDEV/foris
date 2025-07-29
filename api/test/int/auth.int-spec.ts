import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { Logger } from '@nestjs/common';

describe('AuthService Integration (OAuth)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);

    await prisma.oAuthAccount.deleteMany({});
    await prisma.user.deleteMany({});
  });

  afterAll(async () => {
    await prisma.oAuthAccount.deleteMany({});
    await prisma.user.deleteMany({});
    await app.close();
  });

  it('should return 200 OK for health check', () => {
    return request('http://localhost:8080')
      .get('/health')
      .expect(200)
      .expect({ status: 'ok' });
  });

  it('should create a user and oauth account via AuthService', async () => {
    const email = `integration+${uuidv4()}@test.com`;
    const providerUserId = uuidv4();

    // Simulate token
    await request('http://localhost:8080')
      .post('/token')
      .send({
        sub: providerUserId,
        email,
        name: 'Integration Test',
      })
      .expect(200);

    const mutation = `
      mutation CreateAuth($input: CreateAuthInput!) {
        createAuth(createAuthInput: $input) {
          user {
            email
            name
          }
          refreshToken
        }
      }
    `;

    const variables = {
      input: {
        name: 'Integration Test',
        email,
        provider: 'mock',
        providerUserId,
      },
    };

    const res = await request(app.getHttpServer())
      .post('/graphql')
      .send({ query: mutation, variables });

    expect(res.status).toBe(200);
    expect(res.body.errors).toBeUndefined();

    const { data } = res.body;
    expect(data.createAuth.user.email).toBe(email);
    expect(data.createAuth.user.name).toBe('Integration Test');
    expect(data.createAuth.refreshToken).toBeDefined();

    const user = await prisma.user.findUnique({
      where: { email },
      include: { oauthAccounts: true },
    });

    expect(user).toBeTruthy();
    expect(user?.oauthAccounts[0]?.provider).toBe('mock');
    expect(user?.oauthAccounts[0]?.providerUserId).toBe(providerUserId);
  });

  it('should return 400 error when creating a user that already exists', async () => {
    // Silence console.error for this test
    Logger.overrideLogger(false);
    jest.spyOn(console, 'error').mockImplementation(() => {});

    const email = 'integration@test.com';
    const providerUserId = uuidv4();

    // Create user manually
    await prisma.user.create({
      data: {
        name: 'Duplicate Test',
        email,
        oauthAccounts: {
          create: {
            provider: 'mock',
            providerUserId,
            expiresAt: new Date(Date.now() + 3600 * 1000),
          },
        },
      },
    });

    const mutation = `
      mutation CreateAuth($input: CreateAuthInput!) {
        createAuth(createAuthInput: $input) {
          user {
            email
            name
          }
          refreshToken
        }
      }
    `;

    const res = await request(app.getHttpServer())
      .post('/graphql')
      .send({
        query: mutation,
        variables: {
          input: {
            name: 'Duplicate Test',
            email,
            provider: 'mock',
            providerUserId,
          },
        },
      });

    expect(res.status).toBe(200);
    expect(res.body.data).toBeNull();
    expect(res.body.errors?.[0]?.message).toContain(
      `User with email ${email} already exists`,
    );
  });

  // Remove non-existent OAuth account
  it('should return 404 when removing a non-existent OAuth account', async () => {
    const mutation = `
    mutation RemoveOAuthAccount($id: String!) {
      removeAuth(id: $id)
    }
  `;

    const fakeId = '11111111-1111-1111-1111-111111111111'; // valid UUID format

    const res = await request(app.getHttpServer())
      .post('/graphql')
      .send({ query: mutation, variables: { id: fakeId } });

    expect(res.status).toBe(200);
    expect(res.body.data).toBeNull();
    expect(res.body.errors?.[0]?.message).toContain(
      `OAuthAccount with ID ${fakeId} not found`,
    );
    expect(res.body.errors?.[0]?.extensions?.status).toBe(404);
  });

  // Remove existing OAuth account successfully
  it('should remove an existing OAuth account successfully', async () => {
    const email = `integration+${uuidv4()}@test.com`;
    const providerUserId = uuidv4();

    const user = await prisma.user.create({
      data: {
        name: 'Remove Test',
        email,
        oauthAccounts: {
          create: {
            provider: 'mock',
            providerUserId,
            expiresAt: new Date(),
          },
        },
      },
      include: { oauthAccounts: true },
    });

    const oauthAccountId = user.oauthAccounts[0].id;

    const mutation = `
    mutation RemoveOAuthAccount($id: String!) {
      removeAuth(id: $id)
    }
  `;

    const res = await request(app.getHttpServer())
      .post('/graphql')
      .send({ query: mutation, variables: { id: oauthAccountId } });

    // console.error(res.body);

    expect(res.status).toBe(200);
    expect(res.body.errors).toBeUndefined();
    expect(res.body.data.removeAuth).toBe(true);
  });

  it('should return 404 error when refreshing with invalid token', async () => {
    const mutation = `
      mutation RefreshToken($token: String!) {
        refreshToken(refreshToken: $token) {
          refreshToken
          user {
            email
          }
        }
      }
    `;

    const res = await request(app.getHttpServer())
      .post('/graphql')
      .send({ query: mutation, variables: { token: 'invalid-token' } });

    expect(res.status).toBe(200);
    expect(res.body.data).toBeNull();
    expect(res.body.errors?.[0]?.message).toContain('Session not found');
    expect(res.body.errors?.[0]?.extensions?.status).toBe(404);
  });
});
