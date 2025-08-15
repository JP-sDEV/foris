import { CreateLeagueInput } from './create-league.input';
import { InputType, Field, Int, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateLeagueInput extends PartialType(CreateLeagueInput) {
  @Field(() => Int)
  id: number;
}
