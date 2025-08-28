import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, Logger } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';

describe('AuthResolver (Integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const gql = (query: string, variables?: Record<string, any>) =>
    request(app.getHttpServer())
      .post('/api/graphql')
      .send({ query, variables });

  const cleanDb = async () => {
    await prisma.oAuthAccount.deleteMany({});
    await prisma.user.deleteMany({});
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);

    await cleanDb();
  });

  afterAll(async () => {
    await cleanDb();
    await app.close();
  });

  it('should return 200 OK for health check', () =>
    request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok' }));

  describe('createAuth', () => {
    const CREATE_AUTH = `
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

    it('should create a user and oauth account', async () => {
      const email = `integration+${uuidv4()}@test.com`;
      const providerUserId = uuidv4();

      const variables = {
        input: {
          name: 'Integration Test',
          email,
          provider: 'mock',
          providerUserId,
        },
      };

      const res = await gql(CREATE_AUTH, variables);

      expect(res.status).toBe(200);
      expect(res.body.errors).toBeUndefined();

      const { data } = res.body;
      expect(data.createAuth.user.email).toBe(email);
      expect(data.createAuth.refreshToken).toBeDefined();

      const user = await prisma.user.findUnique({
        where: { email },
        include: { oauthAccounts: true },
      });

      expect(user).toBeTruthy();
      expect(user?.oauthAccounts[0]?.provider).toBe('mock');
      expect(user?.oauthAccounts[0]?.providerUserId).toBe(providerUserId);
    });

    it('should return error when user already exists', async () => {
      Logger.overrideLogger(false);
      jest.spyOn(console, 'error').mockImplementation(() => {});

      const email = 'integration@test.com';
      const providerUserId = uuidv4();

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

      const res = await gql(CREATE_AUTH, {
        input: {
          name: 'Duplicate Test',
          email,
          provider: 'mock',
          providerUserId,
        },
      });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
      expect(res.body.errors?.[0]?.message).toContain(
        `User with email ${email} already exists`,
      );
    });
  });

  describe('removeAuth', () => {
    const REMOVE_AUTH = `
      mutation RemoveOAuthAccount($id: String!) {
        removeAuth(id: $id)
      }
    `;

    it('should return 404 for non-existent OAuth account', async () => {
      const fakeId = '11111111-1111-1111-1111-111111111111';

      const res = await gql(REMOVE_AUTH, { id: fakeId });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
      expect(res.body.errors?.[0]?.message).toContain(
        `OAuthAccount with ID ${fakeId} not found`,
      );
      expect(res.body.errors?.[0]?.extensions?.status).toBe(404);
    });

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
      const res = await gql(REMOVE_AUTH, { id: oauthAccountId });

      expect(res.status).toBe(200);
      expect(res.body.errors).toBeUndefined();
      expect(res.body.data.removeAuth).toBe(true);
    });
  });

  describe('refreshToken', () => {
    const REFRESH_TOKEN = `
      mutation RefreshToken($token: String!) {
        refreshToken(refreshToken: $token) {
          refreshToken
          user {
            email
          }
        }
      }
    `;

    it('should return 404 error when refreshing with invalid token', async () => {
      const res = await gql(REFRESH_TOKEN, { token: 'invalid-token' });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
      expect(res.body.errors?.[0]?.message).toContain('Session not found');
      expect(res.body.errors?.[0]?.extensions?.status).toBe(404);
    });
  });
});
