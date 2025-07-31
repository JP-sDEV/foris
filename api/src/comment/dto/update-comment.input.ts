import { CreateCommentInput } from './create-comment.input';
import { InputType, PartialType, Field } from '@nestjs/graphql';

@InputType()
export class UpdateCommentInput extends PartialType(CreateCommentInput) {
  @Field()
  id: string; // identifying which comment to update
}
