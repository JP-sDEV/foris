import { InputType, Field } from '@nestjs/graphql';
import { IsUUID } from 'class-validator';

@InputType()
export class CreateLeagueuserInput {
  @Field(() => String)
  @IsUUID()
  leagueId: string;
}
