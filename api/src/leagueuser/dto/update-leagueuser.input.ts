import { CreateLeagueuserInput } from './create-leagueuser.input';
import { InputType, Field, Int, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateLeagueuserInput extends PartialType(CreateLeagueuserInput) {
  @Field(() => Int)
  id: number;
}
