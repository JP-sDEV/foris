import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { JwtService } from '@nestjs/jwt';

describe('ChallengeModule (integration)', () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});

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
      { sub: userId },
      { secret: process.env.JWT_SECRET },
    );
  });

  afterAll(async () => {
    await prisma.challenge.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  it('should create a challenge', async () => {
    const mutation = `
    mutation CreateChallenge($input: CreateChallengeInput!) {
      createChallenge(createChallengeInput: $input) {
        id
        name
        createdBy
      }
    }
  `;

    const variables = { input: { name: 'Integration Test Challenge' } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.createChallenge).toMatchObject({
      name: 'Integration Test Challenge',
      createdBy: userId,
    });

    challengeId = response.body.data.createChallenge.id;
  });

  it('should find a challenge by id', async () => {
    const query = `
        query FindChallenge($id: String!) {
          challenge(id: $id) {
            id
            name
            createdBy
          }
        }
      `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables: { id: challengeId } });

    expect(response.status).toBe(200);
    expect(response.body.data.challenge).toMatchObject({
      id: challengeId,
      createdBy: userId,
    });
  });

  it('should update a challenge', async () => {
    const mutation = `
        mutation UpdateChallenge($input: UpdateChallengeInput!) {
          updateChallenge(updateChallengeInput: $input) {
            id
            name
            createdBy
          }
        }
      `;

    const variables = { input: { id: challengeId, name: 'Updated Challenge' } };

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables });

    expect(response.status).toBe(200);
    expect(response.body.data.updateChallenge).toMatchObject({
      id: challengeId,
      name: 'Updated Challenge',
      createdBy: userId,
    });
  });

  it('should remove a challenge', async () => {
    const mutation = `
        mutation RemoveChallenge($id: String!) {
          removeChallenge(id: $id) {
            id
            name
          }
        }
      `;

    const response = await request(app.getHttpServer())
      .post('/api/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query: mutation, variables: { id: challengeId } });

    expect(response.status).toBe(200);
    expect(response.body.data.removeChallenge.id).toBe(challengeId);

    const check = await prisma.challenge.findUnique({
      where: { id: challengeId },
    });
    expect(check).toBeNull();
  });

  describe('Unauthorized requests', () => {
    it('should not allow creating a challenge without auth', async () => {
      const mutation = `
          mutation CreateChallenge($input: CreateChallengeInput!) {
            createChallenge(createChallengeInput: $input) {
              id
            }
          }
        `;
      const variables = { input: { name: 'Unauthorized Challenge' } };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
    });

    it('should not allow deleting a challenge without auth', async () => {
      const mutation = `
        mutation RemoveChallenge($id: String!) {
          removeChallenge(id: $id) {
            id
          }
        }
      `;
      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables: { id: challengeId } });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });

    it('should not allow updating a challenge without auth', async () => {
      const mutation = `
      mutation UpdateChallenge($input: UpdateChallengeInput!) {
        updateChallenge(updateChallengeInput: $input) { id }
      }
    `;

      const variables = { input: { id: challengeId, name: 'Hacked Name' } };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .send({ query: mutation, variables });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe('No authorization header');
      expect(response.body.data).toBeNull();
    });

    it('should not allow deleting someone else’s challenge', async () => {
      // Create another user
      const otherUser = await prisma.user.create({
        data: { id: uuidv4(), email: 'other@example.com', name: 'Other User' },
      });
      const otherToken = jwtService.sign(
        { sub: otherUser.id },
        { secret: process.env.JWT_SECRET },
      );

      const mutation = `
      mutation RemoveChallenge($id: String!) {
        removeChallenge(id: $id) { id }
      }
    `;

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .set('Authorization', `Bearer ${otherToken}`)
        .send({ query: mutation, variables: { id: challengeId } });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe(
        'Failed to remove challenge',
      );
      expect(response.body.data).toBeNull();
    });

    it('should not allow updating someone else’s challenge', async () => {
      const otherUser = await prisma.user.findFirst({
        where: { email: 'other@example.com' },
      });
      const otherToken = jwtService.sign(
        { sub: otherUser.id },
        { secret: process.env.JWT_SECRET },
      );

      const mutation = `
      mutation UpdateChallenge($input: UpdateChallengeInput!) {
        updateChallenge(updateChallengeInput: $input) { id }
      }
    `;

      const variables = { input: { id: challengeId, name: 'Hacked Name' } };

      const response = await request(app.getHttpServer())
        .post('/api/graphql')
        .set('Authorization', `Bearer ${otherToken}`)
        .send({ query: mutation, variables });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toBe(
        'Failed to update challenge',
      );
      expect(response.body.data).toBeNull();
    });
  });
});
