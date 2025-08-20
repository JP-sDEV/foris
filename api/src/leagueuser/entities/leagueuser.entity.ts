import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class Leagueuser {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
