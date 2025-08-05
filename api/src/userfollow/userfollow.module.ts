import { Module } from '@nestjs/common';
import { UserfollowService } from './userfollow.service';
import { UserfollowResolver } from './userfollow.resolver';

@Module({
  providers: [UserfollowResolver, UserfollowService],
})
export class UserfollowModule {}
