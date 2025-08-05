import { Module, forwardRef } from '@nestjs/common';
import { LikeService } from './like.service';
import { LikeResolver } from './like.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { PostModule } from '../post/post.module';
import { AuthModule } from '../auth/auth.module';
import { UserModule } from '../user/user.module';

@Module({
  imports: [
    PostModule,
    forwardRef(() => AuthModule),
    forwardRef(() => UserModule),
  ],
  providers: [LikeResolver, LikeService, PrismaService],
  exports: [LikeService],
})
export class LikeModule {}
