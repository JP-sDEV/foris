import { Module, forwardRef } from '@nestjs/common';
import { UserchallengeService } from './userchallenge.service';
import { UserchallengeResolver } from './userchallenge.resolver';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { PrismaService } from '../prisma/prisma.service';
import { ChallengeModule } from '../challenge/challenge.module';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => AuthModule),
    forwardRef(() => ChallengeModule),
  ],
  providers: [UserchallengeResolver, UserchallengeService, PrismaService],
  exports: [UserchallengeService],
})
export class UserchallengeModule {}
