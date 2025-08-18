import { Module } from '@nestjs/common';
import { LeaguechallengeService } from './leaguechallenge.service';
import { LeaguechallengeResolver } from './leaguechallenge.resolver';

@Module({
  providers: [LeaguechallengeResolver, LeaguechallengeService],
})
export class LeaguechallengeModule {}
