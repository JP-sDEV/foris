import { InputType, Field, ID } from '@nestjs/graphql';

@InputType()
export class CreateCommentInput {
  @Field(() => ID)
  postId: string;

  @Field(() => String)
  content: string;
}
