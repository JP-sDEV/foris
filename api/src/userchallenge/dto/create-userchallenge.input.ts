import { InputType, Int, Field } from '@nestjs/graphql';

@InputType()
export class CreateUserchallengeInput {
  @Field(() => Int, { description: 'Example field (placeholder)' })
  exampleField: number;
}
