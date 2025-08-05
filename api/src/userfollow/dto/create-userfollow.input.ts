import { InputType, Int, Field } from '@nestjs/graphql';

@InputType()
export class CreateUserfollowInput {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
