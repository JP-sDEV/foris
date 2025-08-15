import { InputType, Int, Field } from '@nestjs/graphql';

@InputType()
export class CreateLeagueInput {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
