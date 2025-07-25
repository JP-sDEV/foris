import { Module, forwardRef } from '@nestjs/common';
import { UserService } from './user.service';
import { UserResolver } from './user.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { SessionService } from '../session/session.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [forwardRef(() => AuthModule)],
  providers: [UserResolver, UserService, PrismaService, SessionService],
  exports: [UserService, PrismaService],
})
export class UserModule {}
