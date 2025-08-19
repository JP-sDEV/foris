import { ObjectType, Field } from '@nestjs/graphql';

@ObjectType()
export class Leaguechallenge {
  @Field(() => String)
  leagueId: string;

  @Field(() => String)
  challengeId: string;

  // Optional: include relations if needed in tests or GraphQL
  @Field(() => Object, { nullable: true })
  league?: any;

  @Field(() => Object, { nullable: true })
  challenge?: any;
}
