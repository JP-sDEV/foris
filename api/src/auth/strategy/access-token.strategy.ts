import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthPayload } from '../entities/authPayload.entity';

@Injectable()
export class AccessTokenStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET || 'defaultSecretKey',
      ignoreExpiration: false,
    });
  }

  async validate(payload: AuthPayload) {
    // This becomes @CurrentUser() in resolvers
    return {
      userId: payload.user.id,
      email: payload.user.email,
      name: payload.user.name,
    };
  }
}
