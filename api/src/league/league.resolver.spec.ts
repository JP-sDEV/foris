import { Test, TestingModule } from '@nestjs/testing';
import { LeagueResolver } from './league.resolver';
import { LeagueService } from './league.service';

describe('LeagueResolver', () => {
  let resolver: LeagueResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [LeagueResolver, LeagueService],
    }).compile();

    resolver = module.get<LeagueResolver>(LeagueResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
