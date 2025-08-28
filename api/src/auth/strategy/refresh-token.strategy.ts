// refresh-token.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Request } from 'express';

@Injectable()
export class RefreshTokenStrategy extends PassportStrategy(
  Strategy,
  'jwt-refresh', // strategy name
) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(), // or from cookie
      secretOrKey: process.env.JWT_REFRESH_SECRET, // different secret than access token
      passReqToCallback: true,
    });
  }

  async validate(req: Request, payload: any) {
    // Optionally also validate that the refreshToken still exists in DB
    const refreshToken = req
      ?.get('authorization')
      ?.replace('Bearer', '')
      .trim();

    return { ...payload, refreshToken }; // will be injected into @CurrentUser()
  }
}
