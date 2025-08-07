import { Test, TestingModule } from '@nestjs/testing';
import { UserchallengeService } from './userchallenge.service';

describe('UserchallengeService', () => {
  let service: UserchallengeService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UserchallengeService],
    }).compile();

    service = module.get<UserchallengeService>(UserchallengeService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
