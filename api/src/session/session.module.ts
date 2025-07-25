// session.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { SessionService } from './session.service';
import { AuthModule } from '../auth/auth.module';
import { UserModule } from '../user/user.module';

@Module({
  imports: [forwardRef(() => AuthModule), forwardRef(() => UserModule)],
  providers: [SessionService],
  exports: [SessionService],
})
export class SessionModule {}
