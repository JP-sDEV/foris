import { Test, TestingModule } from '@nestjs/testing';
import { LeaguechallengeResolver } from './leaguechallenge.resolver';
import { LeaguechallengeService } from './leaguechallenge.service';

describe('LeaguechallengeResolver', () => {
  let resolver: LeaguechallengeResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [LeaguechallengeResolver, LeaguechallengeService],
    }).compile();

    resolver = module.get<LeaguechallengeResolver>(LeaguechallengeResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
