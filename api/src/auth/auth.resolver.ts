import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { PinoLogger } from 'nestjs-pino';
import { AuthService } from './auth.service';
import { Auth } from './entities/auth.entity';
import { User } from '../user/entities/user.entity';
import { CreateAuthInput } from './dto/create-auth.input';
import { AuthPayload } from './entities/authPayload.entity';
import { UseGuards } from '@nestjs/common';
import { GqlAuthGuard } from './guards/auth.guard';
import { RefreshTokenGuard } from './guards/refresh-token.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from './types/jwt-payload.type';

@Resolver(() => Auth)
export class AuthResolver {
  constructor(
    private readonly authService: AuthService,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(AuthResolver.name);
  }

  @Mutation(() => AuthPayload)
  createAuth(@Args('createAuthInput') createAuthInput: CreateAuthInput) {
    try {
      this.logger.info({ email: createAuthInput.email }, 'Creating auth');
      return this.authService.create(createAuthInput);
    } catch (error) {
      this.logger.error(
        { error, email: createAuthInput.email },
        'Error creating auth',
      );
      throw error;
    }
  }

  @Query(() => User, { name: 'authByEmail' })
  findOneByEmail(@Args('email', { type: () => String }) email: string) {
    try {
      this.logger.info({ email: email }, 'Finding auth by email');
      return this.authService.findOneByEmail(email);
    } catch (error) {
      this.logger.error({ error, email: email }, 'Error finding auth by email');
      throw error;
    }
  }

  // refresh token
  @Mutation(() => AuthPayload, { name: 'payload' })
  @UseGuards(RefreshTokenGuard)
  refreshToken(
    @CurrentUser('payload') payload: JwtPayload,
    @Args('refreshToken', { type: () => String }) refreshToken: string,
  ) {
    try {
      this.logger.info({ userId: payload.userId }, 'Refreshing token');
      return this.authService.refreshToken(payload.userId, refreshToken);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId },
        'Error refreshing token',
      );
    }
  }

  @Mutation(() => Boolean, { name: 'removeAuth' })
  @UseGuards(GqlAuthGuard)
  removeAuth(@CurrentUser() payload: JwtPayload) {
    try {
      this.logger.info({ userId: payload.userId }, 'Removing auth');
      return this.authService.remove(payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId },
        'Error removing auth',
      );
    }
  }

  @Mutation(() => AuthPayload, { name: 'login' })
  login(@Args('email') email: string) {
    this.logger.info({ email: email }, 'Logging in user');
    return this.authService.login(email);
  }

  @Mutation(() => Boolean, { name: 'logout' })
  @UseGuards(GqlAuthGuard)
  async logout(@CurrentUser() payload: JwtPayload) {
    try {
      this.logger.info({ userId: payload.userId }, 'Logging out user: %s');
      return this.authService.logoutByUserId(payload.userId);
    } catch (error) {
      this.logger.error(
        { error, userId: payload.userId },
        'Error logging out user',
      );
    }
  }
}
