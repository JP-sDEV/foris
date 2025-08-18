import { CreateLeaguechallengeInput } from './create-leaguechallenge.input';
import { InputType, Field, Int, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateLeaguechallengeInput extends PartialType(CreateLeaguechallengeInput) {
  @Field(() => Int)
  id: number;
}
