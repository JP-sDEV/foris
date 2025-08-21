import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { JwtService } from '@nestjs/jwt';

describe('LeagueuserModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let jwtService: JwtService;
  let userId: string;
  let leagueId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    // Clean DB
    await prisma.leagueUser.deleteMany();
    await prisma.league.deleteMany();
    await prisma.user.deleteMany();

    // Create user and league
    const user = await prisma.user.create({
      data: {
        id: uuidv4(),
        email: 'test@example.com',
        name: 'Test User',
      },
    });
    userId = user.id;

    const league = await prisma.league.create({
      data: {
        id: uuidv4(),
        name: 'Test League',
        description: 'Integration test league',
        creator: {
          connect: { id: user.id },
        },
      },
    });
    leagueId = league.id;

    token = jwtService.sign(
      { sub: userId },
      { secret: process.env.JWT_SECRET },
    );
  });

  afterAll(async () => {
    await prisma.leagueUser.deleteMany();
    await prisma.league.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should allow a user to join a league', async () => {
    const mutation = `
      mutation CreateLeagueuser($input: CreateLeagueuserInput!) {
        createLeagueuser(createLeagueuserInput: $input) {
          leagueId
          userId
        }
      }
    `;
    const variables = { input: { leagueId } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.createLeagueuser).toMatchObject({
      leagueId,
      userId,
    });
  });

  it('should fetch all users in a league', async () => {
    const query = `
      query FindAllLeagueusers($input: CreateLeagueuserInput!) {
        leagueusers(createLeagueuserInput: $input) {
          leagueId
          userId
          user {
            id
            email
            name
          }
        }
      }
    `;
    const variables = { input: { leagueId } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.leagueusers[0]).toMatchObject({
      leagueId,
      userId,
      user: {
        id: userId,
        email: 'test@example.com',
        name: 'Test User',
      },
    });
  });

  it('should fetch a single league user', async () => {
    const query = `
      query FindLeagueuser($leagueId: String!, $userId: String!) {
        leagueuser(leagueId: $leagueId, userId: $userId) {
          leagueId
          userId
        }
      }
    `;
    const variables = { leagueId, userId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.leagueuser).toMatchObject({
      leagueId,
      userId,
    });
  });

  it('should remove a user from a league', async () => {
    const mutation = `
      mutation RemoveLeagueuser($leagueId: String!, $userId: String!) {
        removeLeagueuser(leagueId: $leagueId, userId: $userId) {
          message
          leagueId
          userId
        }
      }
    `;
    const variables = { leagueId, userId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.removeLeagueuser).toMatchObject({
      leagueId,
      userId,
    });
    expect(response.body.data.removeLeagueuser.message).toContain(
      `removed from leagueId=${leagueId}`,
    );
  });

  describe('Unauthorized requests', () => {
    it('should not allow joining a league without auth', async () => {
      const mutation = `
        mutation CreateLeagueuser($input: CreateLeagueuserInput!) {
          createLeagueuser(createLeagueuserInput: $input) {
            leagueId
            userId
          }
        }
      `;
      const variables = { input: { leagueId } };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });
  });
});
