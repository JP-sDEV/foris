import { Module, forwardRef } from '@nestjs/common';
import { PostService } from './post.service';
import { PostResolver } from './post.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { AuthModule } from '../auth/auth.module';
import { UserModule } from '../user/user.module';

@Module({
  imports: [forwardRef(() => AuthModule), forwardRef(() => UserModule)],
  providers: [PostResolver, PostService, PrismaService],
  exports: [PostService],
})
export class PostModule {}
