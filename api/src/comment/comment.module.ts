import { Module } from '@nestjs/common';
import { CommentService } from './comment.service';
import { CommentResolver } from './comment.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { PostService } from '../post/post.service';

@Module({
  providers: [CommentResolver, CommentService, PrismaService, PostService],
  exports: [CommentService],
})
export class CommentModule {}
