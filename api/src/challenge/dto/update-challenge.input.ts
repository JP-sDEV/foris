import { CreateChallengeInput } from './create-challenge.input';
import { InputType, Field, Int, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateChallengeInput extends PartialType(CreateChallengeInput) {
  @Field(() => Int)
  id: number;
}
