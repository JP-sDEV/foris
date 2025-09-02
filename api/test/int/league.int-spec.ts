import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { v4 as uuidv4 } from 'uuid';

import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.dev.local') });

describe('LeagueModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;
  let token: string;
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
    await prisma.league.deleteMany();
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
  });

  afterAll(async () => {
    await prisma.league.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should create a league', async () => {
    const mutation = `
      mutation CreateLeague($input: CreateLeagueInput!) {
        createLeague(createLeagueInput: $input) {
          id
          name
          createdBy
        }
      }
    `;
    const variables = { input: { name: 'My Test League' } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.createLeague).toMatchObject({
      name: 'My Test League',
      createdBy: userId,
    });
    leagueId = response.body.data.createLeague.id;
  });

  it('should fetch a league by id', async () => {
    const query = `
      query FindLeagueById($id: String!) {
        findLeagueById(id: $id) {
          id
          name
          createdBy
        }
      }
    `;
    const variables = { id: leagueId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.findLeagueById).toMatchObject({
      id: leagueId,
      name: 'My Test League',
      createdBy: userId,
    });
  });

  it('should fetch a league by id for a user', async () => {
    const query = `
      query League($id: String!) {
        league(id: $id) {
          id
          name
          createdBy
        }
      }
    `;
    const variables = { id: leagueId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.league).toMatchObject({
      id: leagueId,
      name: 'My Test League',
      createdBy: userId,
    });
  });

  it('should update a league', async () => {
    const mutation = `
      mutation UpdateLeague($input: UpdateLeagueInput!) {
        updateLeague(updateLeagueInput: $input) {
          id
          name
          createdBy
        }
      }
    `;
    const variables = { input: { id: leagueId, name: 'Updated League Name' } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.updateLeague).toMatchObject({
      id: leagueId,
      name: 'Updated League Name',
      createdBy: userId,
    });
  });

  it('should delete a league', async () => {
    const mutation = `
    mutation RemoveLeague($id: ID!) {
      removeLeague(id: $id) {
        id
        name
        createdBy
      }
    }
  `;

    const variables = { id: leagueId };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.removeLeague).toMatchObject({
      id: leagueId,
      createdBy: userId,
    });
  });

  describe('Unauthorized requests', () => {
    it('should not allow creating a league without auth', async () => {
      const mutation = `
        mutation CreateLeague($input: CreateLeagueInput!) {
          createLeague(createLeagueInput: $input) {
            id
          }
        }
      `;
      const variables = { input: { name: 'NoAuth League' } };

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
