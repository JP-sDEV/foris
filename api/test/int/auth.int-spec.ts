import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, Logger } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { JwtService } from '@nestjs/jwt';
import { RefreshTokenGuard } from '../../src/auth/guards/refresh-token.guard';
import { ExecutionContext } from '@nestjs/common';
import { GqlExecutionContext } from '@nestjs/graphql';

import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.dev.local') });

describe('AuthResolver (Integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;

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
    })
      .overrideGuard(RefreshTokenGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          const ctx = GqlExecutionContext.create(context);
          const req = ctx.getContext().req;

          // Set a fake payload on the request
          req.user = {
            payload: {
              userId: user.id, // set this to the test user's ID
              email: user.email, // optional, whatever you need
            },
          };

          return true;
        },
      })

      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);

    await cleanDb();

    // Create a user directly in DB
    const email = `auth+${uuidv4()}@test.com`;
    const providerUserId = uuidv4();

    const user = await prisma.user.create({
      data: {
        name: 'Auth Test',
        email,
        oauthAccounts: {
          create: {
            provider: 'mock',
            providerUserId,
            expiresAt: new Date(),
          },
        },
      },
    });

    // Generate JWT manually for GqlAuthGuard
    const jwtService = new JwtService({
      secret: process.env.JWT_SECRET || 'test-secret',
    });
    token = await jwtService.signAsync({
      userId: user.id,
      email: user.email,
      name: user.name,
    });
  });

  afterAll(async () => {
    await cleanDb();
    await app.close();
  });

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

      const email = `duplicate+${uuidv4()}@test.com`;
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
    it('should return "Invalid or expired token" for non-existent OAuth account', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/graphql')
        .set('Authorization', `Bearer ${token}+fake`)
        .send({
          query: `
            mutation {
              removeAuth
            }
          `,
        });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
      expect(res.body.errors[0].message).toMatch('Invalid or expired token');
    });

    it('should remove an existing OAuth account successfully', async () => {
      const email = `remove+${uuidv4()}@test.com`;
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

      // Generate a fresh token for this user
      const jwtService = new JwtService({
        secret: process.env.JWT_SECRET,
      });
      const userToken = await jwtService.signAsync({
        userId: user.id,
        email: user.email,
        name: user.name,
      });

      const res = await request(app.getHttpServer())
        .post('/api/graphql')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          query: `
            mutation {
              removeAuth
            }
          `,
        });

      expect(res.status).toBe(200);
      expect(res.body.errors).toBeUndefined();
      expect(res.body.data.removeAuth).toBe(true);
    });
  });

  describe('login and logout', () => {
    let userEmail: string;
    let providerUserId: string;
    let refreshToken: string;
    let token: string;

    beforeAll(async () => {
      // Create a user in the DB to test login
      userEmail = `login+${uuidv4()}@test.com`;
      providerUserId = uuidv4();

      await prisma.user.create({
        data: {
          name: 'Login Test',
          email: userEmail,
          oauthAccounts: {
            create: {
              provider: 'mock',
              providerUserId,
              expiresAt: new Date(),
            },
          },
        },
      });
    });

    it('should login successfully', async () => {
      const LOGIN = `
      mutation Login($email: String!) {
        login(email: $email) {
          accessToken
          refreshToken
          user {
            email
            name
          }
        }
      }
    `;

      const res = await gql(LOGIN, { email: userEmail });

      expect(res.status).toBe(200);
      expect(res.body.errors).toBeUndefined();

      const data = res.body.data.login;
      expect(data.user.email).toBe(userEmail);
      expect(data.accessToken).toBeDefined();
      expect(data.refreshToken).toBeDefined();

      // Save refreshToken for logout test
      refreshToken = data.refreshToken;
      token = data.accessToken;
    });

    it('should logout successfully', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/graphql')
        .set('Authorization', `Bearer ${token}`)
        .send({
          query: `
      mutation {
        logout
      }
    `,
        });

      expect(res.status).toBe(200);
      expect(res.body.errors).toBeUndefined();
      expect(res.body.data.logout).toBe(true);

      // Verify session is deleted
      const session = await prisma.session.findUnique({
        where: { refreshToken },
      });
      expect(session).toBeNull();
    });

    it('should return error when logging out with invalid token', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/graphql')
        .set('Authorization', `Bearer ${token}-invalid`)
        .send({
          query: `
      mutation {
        logout
      }
    `,
        });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
      expect(res.body.errors?.[0]?.message).toBeDefined();
    });
  });

  describe('refreshToken', () => {
    let app: INestApplication;
    let prisma: PrismaService;
    let userEmail: string;
    let userId: string;
    let refreshToken: string;

    const REFRESH_TOKEN_MUTATION = `
    mutation RefreshToken($token: String!) {
      payload(refreshToken: $token) {
        refreshToken
        user { email }
      }
    }
  `;

    beforeAll(async () => {
      prisma = new PrismaService();

      // 1️⃣ Create test user first
      userEmail = `refreshtoken+${uuidv4()}@test.com`;
      const user = await prisma.user.create({
        data: {
          name: 'Refresh Token Test',
          email: userEmail,
          oauthAccounts: {
            create: {
              provider: 'mock',
              providerUserId: uuidv4(),
              expiresAt: new Date(),
            },
          },
        },
      });
      userId = user.id;

      // 2️⃣ Create a session with a refresh token
      refreshToken = `refresh-${uuidv4()}`;
      await prisma.session.create({
        data: {
          userId,
          refreshToken,
          expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24),
          ipAddress: null,
          userAgent: null,
        },
      });

      // 3️⃣ Compile the app AFTER creating user/session
      const moduleFixture = await Test.createTestingModule({
        imports: [AppModule],
      })
        .overrideGuard(RefreshTokenGuard)
        .useValue({
          canActivate: (context: ExecutionContext) => {
            const ctx = GqlExecutionContext.create(context);
            ctx.getContext().req.user = { userId, email: userEmail };
            return true;
          },
        })
        .compile();

      app = moduleFixture.createNestApplication();
      await app.init();
    });

    afterAll(async () => {
      await prisma.session.deleteMany({});
      await prisma.user.deleteMany({});
      await app.close();
    });

    it('should refresh token successfully with a valid refresh token', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({
          query: REFRESH_TOKEN_MUTATION,
          variables: { token: refreshToken },
        });

      expect(res.status).toBe(200);
      expect(res.body.errors).toBeUndefined();

      const data = res.body.data.payload;
      expect(data.user.email).toBe(userEmail);
      expect(data.refreshToken).toBeDefined();
    });
  });
});
