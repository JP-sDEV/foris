import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import * as request from 'supertest';
import { JwtService } from '@nestjs/jwt';

import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.dev.local') });

describe('UserfollowModule (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;

  let userAId: string;
  let userBId: string;
  let tokenA: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    // Clean DB
    await prisma.userFollow.deleteMany();
    await prisma.user.deleteMany();

    // Create users
    const userA = await prisma.user.create({
      data: {
        id: uuidv4(),
        email: 'userA@example.com',
        name: 'User A',
      },
    });
    userAId = userA.id;

    const userB = await prisma.user.create({
      data: {
        id: uuidv4(),
        email: 'userB@example.com',
        name: 'User B',
      },
    });
    userBId = userB.id;

    // Generate JWT for userA
    tokenA = jwtService.sign(
      { userId: userAId, name: userA.name, email: userA.email },
      { secret: process.env.JWT_SECRET },
    );
  });

  afterAll(async () => {
    await prisma.userFollow.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should allow userA to follow userB via API', async () => {
    const mutation = `
      mutation FollowUser($targetUserId: String!) {
        followUser(targetUserId: $targetUserId)
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        query: mutation,
        variables: { targetUserId: userBId, currentUser: tokenA },
      });

    expect(response.status).toBe(200);
    expect(response.body.data.followUser).toBe(true);
  });

  it('should confirm userA is following userB via API', async () => {
    const query = `
      query IsFollowing($targetUserId: String!) {
        isFollowing(targetUserId: $targetUserId)
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        query,
        variables: { targetUserId: userBId, currentUser: tokenA },
      });

    expect(response.status).toBe(200);
    expect(response.body.data.isFollowing).toBe(true);
  });

  it('should retrieve followers of userB via API', async () => {
    const query = `
      query GetFollowers($userId: String!) {
        getFollowers(userId: $userId) {
          id
          email
          name
        }
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .send({ query, variables: { userId: userBId } });

    expect(response.status).toBe(200);
    expect(response.body.data.getFollowers).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: userAId,
          email: 'userA@example.com',
          name: 'User A',
        }),
      ]),
    );
  });

  it('should retrieve following of userA via API', async () => {
    const query = `
      query GetFollowing($userId: String!) {
        getFollowing(userId: $userId) {
          id
          email
          name
        }
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .send({ query, variables: { userId: userAId } });

    expect(response.status).toBe(200);
    expect(response.body.data.getFollowing).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: userBId,
          email: 'userB@example.com',
          name: 'User B',
        }),
      ]),
    );
  });

  it('should allow userA to unfollow userB via API', async () => {
    const mutation = `
      mutation UnfollowUser($targetUserId: String!) {
        unfollowUser(targetUserId: $targetUserId)
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ query: mutation, variables: { targetUserId: userBId } });

    expect(response.status).toBe(200);
    expect(response.body.data.unfollowUser).toBe(true);

    // Verify isFollowing returns false
    const check = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        query: `
        query IsFollowing($targetUserId: String!) {
          isFollowing(targetUserId: $targetUserId)
        }
      `,
        variables: { targetUserId: userBId },
      });

    expect(check.body.data.isFollowing).toBe(false);
  });

  it('should not allow following a user without auth', async () => {
    const mutation = `
      mutation FollowUser($targetUserId: String!) {
        followUser(targetUserId: $targetUserId)
      }
    `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .send({ query: mutation, variables: { targetUserId: userBId } });

    expect(response.status).toBe(200);
    expect(response.body.errors).toBeDefined();
    expect(response.body.errors[0].message).toBe('No authorization header');
    expect(response.body.data).toBeNull();
  });
});
