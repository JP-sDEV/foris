import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { ChallengeStatus } from '@prisma/client';
import { JwtService } from '@nestjs/jwt';

import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.dev.local') });

describe('UserchallengeModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let jwtService: JwtService;
  let userId: string;
  let challengeId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();

    await app.init();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    // Clean DB
    await prisma.userChallenge.deleteMany();
    await prisma.challenge.deleteMany();
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

    const challenge = await prisma.challenge.create({
      data: {
        id: uuidv4(),
        name: 'Test Challenge',
        createdBy: userId,
      },
    });
    challengeId = challenge.id;
  });

  afterAll(async () => {
    await prisma.userChallenge.deleteMany();
    await prisma.challenge.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should join a user challenge', async () => {
    const mutation = `
      mutation JoinUserChallenge($input: JoinUserChallengeInput!) {
        joinUserChallenge(joinUserChallengeInput: $input) {
          userId
          challengeId
          status
        }
      }
    `;

    const variables = { input: { challengeId } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.joinUserChallenge).toMatchObject({
      userId,
      challengeId,
      status: ChallengeStatus.IN_PROGRESS,
    });
  });

  it('should fetch the user challenge', async () => {
    const query = `
        query FindUserChallenge($input: JoinUserChallengeInput!) {
          userchallenge(joinUserChallengeInput: $input) {
            userId
            challengeId
            status
          }
        }
      `;

    const variables = { input: { challengeId } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.userchallenge).toMatchObject({
      userId,
      challengeId,
      status: ChallengeStatus.IN_PROGRESS,
    });
  });

  it('should update the user challenge', async () => {
    const mutation = `
        mutation UpdateUserChallenge($input: UpdateUserChallengeInput!) {
          updateUserChallenge(updateUserChallengeInput: $input) {
            userId
            challengeId
            status
            completedAt
          }
        }
      `;
    const completedAt = new Date().toISOString();
    const variables = {
      input: { challengeId, status: ChallengeStatus.COMPLETED, completedAt },
    };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.updateUserChallenge).toMatchObject({
      userId,
      challengeId,
      status: ChallengeStatus.COMPLETED,
    });
    expect(
      new Date(
        response.body.data.updateUserChallenge.completedAt,
      ).toISOString(),
    ).toBe(completedAt);
  });

  it('should remove the user challenge', async () => {
    const mutation = `
        mutation RemoveUserChallenge($input: JoinUserChallengeInput!) {
          removeUserChallenge(joinUserChallengeInput: $input) {
            userId
            challengeId
          }
        }
      `;
    const variables = { input: { challengeId } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.removeUserChallenge).toMatchObject({
      userId,
      challengeId,
    });
  });

  describe('Unauthorized requests', () => {
    it('should not allow joining a user challenge without auth', async () => {
      const mutation = `
        mutation JoinUserChallenge($input: JoinUserChallengeInput!) {
          joinUserChallenge(joinUserChallengeInput: $input) {
            userId
            challengeId
            status
          }
        }
      `;
      const variables = { input: { challengeId } };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables });

      expect(response.status).toBe(200); // GraphQL always returns 200
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });

    it('should not allow fetching a user challenge without auth', async () => {
      const query = `
        query FindUserChallenge($input: JoinUserChallengeInput!) {
          userchallenge(joinUserChallengeInput: $input) {
            userId
            challengeId
            status
          }
        }
      `;
      const variables = { input: { challengeId } };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query, variables });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });

    it('should not allow updating a user challenge without auth', async () => {
      const mutation = `
        mutation UpdateUserChallenge($input: UpdateUserChallengeInput!) {
          updateUserChallenge(updateUserChallengeInput: $input) {
            userId
            challengeId
            status
          }
        }
      `;
      const variables = {
        input: { challengeId, status: ChallengeStatus.COMPLETED },
      };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });

    it('should not allow removing a user challenge without auth', async () => {
      const mutation = `
        mutation RemoveUserChallenge($input: JoinUserChallengeInput!) {
          removeUserChallenge(joinUserChallengeInput: $input) {
            userId
            challengeId
          }
        }
      `;
      const variables = { input: { challengeId } };

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
