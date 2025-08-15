import { Module } from '@nestjs/common';
import { LeagueService } from './league.service';
import { LeagueResolver } from './league.resolver';

@Module({
  providers: [LeagueResolver, LeagueService],
})
export class LeagueModule {}
