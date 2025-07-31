import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class CreateLikeInput {
  @Field(() => String, { description: 'ID of the post to like' })
  postId: string;
}
