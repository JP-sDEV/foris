import { Module, forwardRef } from '@nestjs/common';
import { LeaguechallengeService } from './leaguechallenge.service';
import { LeaguechallengeResolver } from './leaguechallenge.resolver';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { ChallengeModule } from '../challenge/challenge.module';
import { LeagueModule } from 'src/league/league.module';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => AuthModule),
    forwardRef(() => ChallengeModule),
    forwardRef(() => LeagueModule),
  ],
  providers: [LeaguechallengeResolver, LeaguechallengeService],
  exports: [LeaguechallengeModule],
})
export class LeaguechallengeModule {}
