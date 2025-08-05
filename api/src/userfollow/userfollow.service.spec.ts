import { Test, TestingModule } from '@nestjs/testing';
import { UserfollowService } from './userfollow.service';

describe('UserfollowService', () => {
  let service: UserfollowService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UserfollowService],
    }).compile();

    service = module.get<UserfollowService>(UserfollowService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
