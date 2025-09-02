import { InputType, Field } from '@nestjs/graphql';
import { IsDate, IsOptional, IsString } from 'class-validator';

@InputType()
export class CreateChallengeInput {
  @Field(() => String, { description: 'Name of the challenge' })
  @IsString()
  name: string;

  @Field(() => String, {
    nullable: true,
    description: 'Optional description of the challenge',
  })
  @Field(() => Date, {
    nullable: true,
    description: 'Optional end date for the challenge',
  })
  @IsOptional()
  @IsDate()
  endDate?: Date;
}
