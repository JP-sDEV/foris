import { CreateChallengeInput } from './create-challenge.input';
import { InputType, Field, PartialType } from '@nestjs/graphql';
import { IsUUID } from 'class-validator';

@InputType()
export class UpdateChallengeInput extends PartialType(CreateChallengeInput) {
  @Field(() => String, { description: 'UUID of the challenge to update' })
  @IsUUID()
  id: string;
}
