import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType()
export class League {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field(() => ID)
  createdBy: string;
}
