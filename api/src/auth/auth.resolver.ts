import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { AuthService } from './auth.service';
import { Auth } from './entities/auth.entity';
import { User } from '../user/entities/user.entity';
import { CreateAuthInput } from './dto/create-auth.input';
import { AuthPayload } from './entities/authPayload.entity';

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
  @Mutation(() => AuthPayload, { name: 'refreshToken' })
  refreshToken(@Args('refreshToken') refreshToken: string) {
    return this.authService.refreshToken(refreshToken);
  }

  @Mutation(() => Boolean)
  removeAuth(@Args('id', { type: () => String }) id: string) {
    return this.authService.remove(id);
  }
}
