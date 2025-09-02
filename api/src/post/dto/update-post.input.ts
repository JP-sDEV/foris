import { CreatePostInput } from './create-post.input';
import { InputType, PartialType, Field } from '@nestjs/graphql';

@InputType()
export class UpdatePostInput extends PartialType(CreatePostInput) {
  @Field(() => String)
  id: string;
}
