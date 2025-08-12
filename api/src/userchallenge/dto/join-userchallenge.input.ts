import { Field, InputType } from '@nestjs/graphql';
import { IsUUID } from 'class-validator';

@InputType()
export class JoinUserChallengeInput {
  @Field()
  @IsUUID()
  challengeId: string;
}
