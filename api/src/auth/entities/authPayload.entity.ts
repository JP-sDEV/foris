import { ObjectType, Field } from '@nestjs/graphql';
import { User } from '../../user/entities/user.entity';

@ObjectType()
export class AuthPayload {
  @Field(() => User)
  user: User;

  @Field()
  refreshToken: string;

  @Field(() => String)
  accessToken: string;
}
