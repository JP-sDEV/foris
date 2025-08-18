// src/challenge/entities/challenge.entity.ts
import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType()
export class Challenge {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field()
  createdBy: string;
}
