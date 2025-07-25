import { ObjectType, Field, ID } from '@nestjs/graphql';
import { Auth } from '../../auth/entities/auth.entity';

@ObjectType()
export class User {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field()
  email: string;

  @Field(() => [Auth], { nullable: true })
  oauthAccounts?: Auth[];
}
