import { Test, TestingModule } from '@nestjs/testing';
import { LeagueuserResolver } from './leagueuser.resolver';
import { LeagueuserService } from './leagueuser.service';

describe('LeagueuserResolver', () => {
  let resolver: LeagueuserResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [LeagueuserResolver, LeagueuserService],
    }).compile();

    resolver = module.get<LeagueuserResolver>(LeagueuserResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
