import { Module, forwardRef } from '@nestjs/common';
import { LeagueuserService } from './leagueuser.service';
import { LeagueuserResolver } from './leagueuser.resolver';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { PrismaService } from '../prisma/prisma.service';
import { LeagueModule } from '../league/league.module';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => AuthModule),
    forwardRef(() => LeagueModule),
  ],

  providers: [LeagueuserResolver, LeagueuserService, PrismaService],
  exports: [LeagueuserService],
})
export class LeagueuserModule {}
