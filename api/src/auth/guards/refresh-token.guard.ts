import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

// refresh-token.guard.ts
@Injectable()
export class RefreshTokenGuard extends AuthGuard('jwt-refresh') {}
