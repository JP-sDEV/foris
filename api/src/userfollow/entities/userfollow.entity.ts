import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class Userfollow {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
