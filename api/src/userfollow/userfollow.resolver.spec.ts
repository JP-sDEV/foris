import { Test, TestingModule } from '@nestjs/testing';
import { UserfollowResolver } from './userfollow.resolver';
import { UserfollowService } from './userfollow.service';

describe('UserfollowResolver', () => {
  let resolver: UserfollowResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UserfollowResolver, UserfollowService],
    }).compile();

    resolver = module.get<UserfollowResolver>(UserfollowResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
