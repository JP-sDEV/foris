import { Module } from '@nestjs/common';
import { LikeService } from './like.service';
import { LikeResolver } from './like.resolver';
import { PrismaService } from 'src/prisma/prisma.service';
import { AuthService } from 'src/auth/auth.service';

@Module({
  providers: [LikeResolver, LikeService, PrismaService, AuthService],
  exports: [LikeService],
})
export class LikeModule {}
