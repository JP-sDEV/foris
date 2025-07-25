import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('AuthService Integration (OAuth)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    try {
      const moduleFixture: TestingModule = await Test.createTestingModule({
        imports: [AppModule],
      }).compile();

      app = moduleFixture.createNestApplication();
      await app.init();

      prisma = app.get(PrismaService);

      // Clear test data before tests
      await prisma.oAuthAccount.deleteMany({});
      await prisma.user.deleteMany({});
    } catch (error) {
      console.error('Failed to initialize app in beforeAll:', error);
    }
  });

  afterAll(async () => {
    await app.close();
  });

  it('should return 200 OK for health check', () => {
    return request('http://localhost:8080')
      .get('/health')
      .expect(200)
      .expect({ status: 'ok' });
  });

  it('should create a user and oauth account via AuthService', async () => {
    // Simulate getting a token from the mock OAuth server
    await request('http://localhost:8080')
      .post('/token')
      .send({
        sub: 'mock-oauth-id-123',
        email: 'integration@test.com',
        name: 'Integration Test',
      })
      .expect(200);

    // Call the GraphQL mutation to createAuth
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
        email: 'integration@test.com',
        provider: 'mock',
        providerUserId: 'mock-oauth-id-123',
      },
    };

    const res = await request(app.getHttpServer())
      .post('/graphql')
      .send({ query: mutation, variables });

    // Log errors for debugging
    if (res.body.errors) {
      console.error('GraphQL errors:', res.body.errors);
    }

    expect(res.status).toBe(200);
    expect(res.body.errors).toBeUndefined();

    // console.log('GraphQL response:', res.body);
    // console.log('User data:', res.body.data.createAuth.user);

    const { data } = res.body;
    expect(data.createAuth.user.email).toBe('integration@test.com');
    expect(data.createAuth.user.name).toBe('Integration Test');
    expect(data.createAuth.refreshToken).toBeDefined();

    // Check in the database
    const user = await prisma.user.findUnique({
      where: { email: 'integration@test.com' },
      include: { oauthAccounts: true },
    });
    expect(user).toBeTruthy();
    expect(user?.oauthAccounts[0].provider).toBe('mock');
    expect(user?.oauthAccounts[0].providerUserId).toBe('mock-oauth-id-123');
  });
});
