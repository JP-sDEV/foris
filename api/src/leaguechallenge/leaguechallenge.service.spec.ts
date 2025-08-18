import { Test, TestingModule } from '@nestjs/testing';
import { LeaguechallengeService } from './leaguechallenge.service';

describe('LeaguechallengeService', () => {
  let service: LeaguechallengeService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [LeaguechallengeService],
    }).compile();

    service = module.get<LeaguechallengeService>(LeaguechallengeService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
