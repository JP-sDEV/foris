// dto/remove-leagueuser.response.ts
import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType()
export class RemoveLeagueuserResponse {
  @Field()
  message: string;

  @Field(() => ID)
  leagueId: string;

  @Field(() => ID)
  userId: string;
}
