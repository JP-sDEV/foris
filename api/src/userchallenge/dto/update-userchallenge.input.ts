import { CreateUserchallengeInput } from './create-userchallenge.input';
import { InputType, Field, Int, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateUserchallengeInput extends PartialType(CreateUserchallengeInput) {
  @Field(() => Int)
  id: number;
}
