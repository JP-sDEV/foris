import { InputType, Field } from '@nestjs/graphql';
import { IsOptional, IsString } from 'class-validator';

@InputType()
export class CreateLeagueInput {
  @Field(() => String, { description: 'Name of the league' })
  @IsString()
  name: string;

  @Field(() => String, {
    nullable: true,
    description: 'Optional description of the league',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
