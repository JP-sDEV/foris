import { Module, forwardRef } from '@nestjs/common';
import { ChallengeService } from './challenge.service';
import { ChallengeResolver } from './challenge.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { LeagueModule } from '../league/league.module';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => AuthModule),
    forwardRef(() => LeagueModule),
  ],
  providers: [ChallengeResolver, ChallengeService, PrismaService],
  exports: [ChallengeService],
})
export class ChallengeModule {}
