import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
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
  constructor(private readonly authService: AuthService) {}

  @Mutation(() => AuthPayload)
  createAuth(@Args('createAuthInput') createAuthInput: CreateAuthInput) {
    return this.authService.create(createAuthInput);
  }

  @Query(() => User, { name: 'authByEmail' })
  findOneByEmail(@Args('email', { type: () => String }) email: string) {
    return this.authService.findOneByEmail(email);
  }

  // refresh token
  @Mutation(() => AuthPayload, { name: 'payload' })
  @UseGuards(RefreshTokenGuard)
  refreshToken(
    @CurrentUser('payload') payload: JwtPayload,
    @Args('refreshToken', { type: () => String }) refreshToken: string,
  ) {
    return this.authService.refreshToken(payload.userId, refreshToken);
  }

  @Mutation(() => Boolean, { name: 'removeAuth' })
  @UseGuards(GqlAuthGuard)
  removeAuth(@CurrentUser() payload: JwtPayload) {
    return this.authService.remove(payload.userId);
  }

  @Mutation(() => AuthPayload, { name: 'login' })
  login(@Args('email') email: string) {
    return this.authService.login(email);
  }

  @Mutation(() => Boolean, { name: 'logout' })
  @UseGuards(GqlAuthGuard)
  async logout(@CurrentUser() payload: JwtPayload) {
    return this.authService.logoutByUserId(payload.userId);
  }
}
