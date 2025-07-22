import { ObjectType, Field, Int } from '@nestjs/graphql';
import { Auth } from '../../auth/entities/auth.entity';

@ObjectType()
export class User {
  @Field(() => Int)
  id: number;

  @Field()
  name: string;

  @Field()
  email: string;

  @Field(() => [Auth], { nullable: true })
  oauthAccounts?: Auth[];
}
