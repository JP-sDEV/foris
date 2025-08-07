import { Test, TestingModule } from '@nestjs/testing';
import { UserchallengeResolver } from './userchallenge.resolver';
import { UserchallengeService } from './userchallenge.service';

describe('UserchallengeResolver', () => {
  let resolver: UserchallengeResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UserchallengeResolver, UserchallengeService],
    }).compile();

    resolver = module.get<UserchallengeResolver>(UserchallengeResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
