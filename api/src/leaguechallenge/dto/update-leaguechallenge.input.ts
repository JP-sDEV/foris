import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class UpdateLeaguechallengeInput {
  @Field()
  leagueId: string;

  @Field()
  challengeId: string;
}
