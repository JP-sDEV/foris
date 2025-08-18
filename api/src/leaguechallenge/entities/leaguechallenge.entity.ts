import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class Leaguechallenge {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
