import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class Userchallenge {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
