import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  // Create Users
  const user1 = await prisma.user.create({
    data: {
      name: 'Alice Smith',
      email: 'alice@example.com',
      bio: 'Loves challenges!',
      avatarUrl: 'https://example.com/avatar1.png',
    },
  });

  const user2 = await prisma.user.create({
    data: {
      name: 'Bob Johnson',
      email: 'bob@example.com',
    },
  });

  // OAuthAccounts
  const oauthAccount1 = await prisma.oAuthAccount.create({
    data: {
      provider: 'google',
      providerUserId: 'google-1234',
      accessToken: 'token123',
      refreshToken: 'refresh123',
      userId: user1.id,
    },
  });

  // Sessions
  const session1 = await prisma.session.create({
    data: {
      refreshToken: 'refreshToken1',
      ipAddress: '192.168.1.1',
      userAgent: 'Mozilla/5.0',
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24), // expires in 1 day
      userId: user1.id,
    },
  });

  // UserFollow (user1 follows user2)
  const follow = await prisma.userFollow.create({
    data: {
      followId: user1.id,
      followingId: user2.id,
    },
  });

  // Posts (by user1)
  const post1 = await prisma.post.create({
    data: {
      title: 'My First Post',
      content: 'Hello world!',
      authorId: user1.id,
    },
  });

  // Media (for post1 uploaded by user1)
  const media1 = await prisma.media.create({
    data: {
      postId: post1.id,
      uploaderId: user1.id,
      fileType: 'image/png',
      url: 'https://example.com/image.png',
    },
  });

  // Comments (user2 comments on post1)
  const comment1 = await prisma.comment.create({
    data: {
      content: 'Nice post!',
      postId: post1.id,
      userId: user2.id,
    },
  });

  // Likes (user2 likes post1)
  const like1 = await prisma.like.create({
    data: {
      postId: post1.id,
      userId: user2.id,
    },
  });

  // League created by user1
  const league1 = await prisma.league.create({
    data: {
      name: 'Pro League',
      description: 'Competitive league',
      createdBy: user1.id,
    },
  });

  // Challenge created by user1
  const challenge1 = await prisma.challenge.create({
    data: {
      name: '30 Day Fitness Challenge',
      description: 'Get fit in 30 days',
      createdBy: user1.id,
      approved: true,
      endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30), // 30 days from now
    },
  });

  // Link challenge to league
  const leagueChallenge = await prisma.leagueChallenge.create({
    data: {
      leagueId: league1.id,
      challengeId: challenge1.id,
    },
  });

  // UserChallenge - user2 joins challenge1
  const userChallenge = await prisma.userChallenge.create({
    data: {
      userId: user2.id,
      challengeId: challenge1.id,
      status: 'IN_PROGRESS',
      startedAt: new Date(),
    },
  });

  console.log('Seed data created successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
