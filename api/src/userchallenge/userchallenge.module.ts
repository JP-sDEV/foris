import { Module } from '@nestjs/common';
import { UserchallengeService } from './userchallenge.service';
import { UserchallengeResolver } from './userchallenge.resolver';

@Module({
  providers: [UserchallengeResolver, UserchallengeService],
})
export class UserchallengeModule {}
