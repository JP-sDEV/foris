import { CreateUserfollowInput } from './create-userfollow.input';
import { InputType, Field, Int, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateUserfollowInput extends PartialType(CreateUserfollowInput) {
  @Field(() => Int)
  id: number;
}
