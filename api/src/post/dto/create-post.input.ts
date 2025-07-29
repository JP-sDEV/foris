import { InputType, Field, ID } from '@nestjs/graphql';

@InputType()
export class CreatePostInput {
  // @Field(() => ID)
  // id: string;

  @Field()
  title: string;

  @Field({ nullable: true })
  content?: string;

  @Field(() => String)
  authorId: string;
}
