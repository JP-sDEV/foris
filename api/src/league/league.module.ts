import { Module, forwardRef } from '@nestjs/common';
import { LeagueService } from './league.service';
import { LeagueResolver } from './league.resolver';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [forwardRef(() => UserModule), forwardRef(() => AuthModule)],
  providers: [LeagueResolver, LeagueService],
  exports: [LeagueService],
})
export class LeagueModule {}
