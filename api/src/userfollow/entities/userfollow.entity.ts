import { ObjectType, Field } from '@nestjs/graphql';

@ObjectType()
export class Userfollow {
  @Field(() => String)
  followId: string;

  @Field(() => String)
  followingId: string;

  @Field(() => Date)
  createdAt: Date;
}
