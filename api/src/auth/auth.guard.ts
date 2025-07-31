import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { GqlExecutionContext } from '@nestjs/graphql';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class GqlAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const ctx = GqlExecutionContext.create(context);
    const req = ctx.getContext().req;

    const authHeader = req.headers.authorization;
    if (!authHeader) throw new UnauthorizedException('No authorization header');

    const token = authHeader.replace('Bearer ', '');

    try {
      const decoded = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_SECRET || 'defaultSecretKey',
      });

      req.user = decoded; // store user in request
      return true;
    } catch (err) {
      console.error('JWT verification error:', err);
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
