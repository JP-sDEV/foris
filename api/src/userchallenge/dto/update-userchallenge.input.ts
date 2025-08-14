import { JoinUserChallengeInput } from './join-userchallenge.input';
import { InputType, Field, PartialType } from '@nestjs/graphql';
// import { ChallengeStatus } from '@prisma/client';
import { ChallengeStatus } from '../enums/challenge-status';

@InputType()
export class UpdateUserChallengeInput extends PartialType(
  JoinUserChallengeInput,
) {
  @Field(() => ChallengeStatus, { nullable: true })
  status?: ChallengeStatus;

  @Field(() => Date, { nullable: true })
  completedAt?: Date;
}
