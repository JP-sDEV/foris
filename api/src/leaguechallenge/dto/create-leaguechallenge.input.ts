import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class CreateLeaguechallengeInput {
  @Field(() => String, { description: 'ID of the league' })
  leagueId: string;

  @Field(() => String, { description: 'ID of the challenge' })
  challengeId: string;
}
