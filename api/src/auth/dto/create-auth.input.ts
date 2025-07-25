import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class CreateAuthInput {
  @Field()
  name: string;

  @Field()
  email: string;

  @Field()
  provider: string;

  @Field()
  providerUserId: string;

  // @Field()
  // accessToken: string;

  // @Field()
  // refreshToken: string;

  @Field({ nullable: true }) // GraphQL: optional
  idToken?: string;
}
