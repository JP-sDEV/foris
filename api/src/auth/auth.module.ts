import { Module, forwardRef } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { AuthResolver } from './auth.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { UserModule } from '../user/user.module';
import { SessionModule } from '../session/session.module';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => SessionModule),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'defaultSecretKey',
      signOptions: { expiresIn: '1h' },
      global: true,
    }),
  ],
  providers: [AuthResolver, AuthService, PrismaService],
  exports: [AuthService, JwtModule],
})
export class AuthModule {}
