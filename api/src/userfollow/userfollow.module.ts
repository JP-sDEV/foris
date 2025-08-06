import { forwardRef, Module } from '@nestjs/common';
import { UserfollowService } from './userfollow.service';
import { UserfollowResolver } from './userfollow.resolver';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { PostModule } from '../post/post.module';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => AuthModule),
    forwardRef(() => PostModule),
  ],
  providers: [UserfollowResolver, UserfollowService],
  exports: [UserfollowService],
})
export class UserfollowModule {}
