import { Test, TestingModule } from '@nestjs/testing';
import { LeagueuserService } from './leagueuser.service';

describe('LeagueuserService', () => {
  let service: LeagueuserService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [LeagueuserService],
    }).compile();

    service = module.get<LeagueuserService>(LeagueuserService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
