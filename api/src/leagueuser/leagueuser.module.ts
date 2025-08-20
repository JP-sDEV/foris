import { Module } from '@nestjs/common';
import { LeagueuserService } from './leagueuser.service';
import { LeagueuserResolver } from './leagueuser.resolver';

@Module({
  providers: [LeagueuserResolver, LeagueuserService],
})
export class LeagueuserModule {}
