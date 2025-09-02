import { Module, forwardRef } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { AuthResolver } from './auth.resolver';
import { PrismaService } from '../prisma/prisma.service';
import { UserModule } from '../user/user.module';
import { SessionModule } from '../session/session.module';
import { AccessTokenStrategy } from './strategy/access-token.strategy';
import { RefreshTokenStrategy } from './strategy/refresh-token.strategy';

@Module({
  imports: [
    forwardRef(() => UserModule),
    forwardRef(() => SessionModule),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'local-jwt-test-secret',
      signOptions: { expiresIn: '1h' },
      global: true,
    }),
  ],
  providers: [
    AuthResolver,
    AuthService,
    PrismaService,
    AccessTokenStrategy,
    RefreshTokenStrategy,
  ],
  exports: [AuthService, JwtModule],
})
export class AuthModule {}
