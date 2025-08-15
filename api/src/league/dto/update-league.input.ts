import { CreateLeagueInput } from './create-league.input';
import { InputType, Field, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateLeagueInput extends PartialType(CreateLeagueInput) {
  @Field(() => String)
  id: string;
}
