import { ObjectType, Field } from '@nestjs/graphql';
import { ChallengeStatus } from '@prisma/client';

@ObjectType()
export class Userchallenge {
  @Field()
  userId: string;

  @Field()
  challengeId: string;

  @Field(() => ChallengeStatus)
  status: ChallengeStatus;

  @Field({ nullable: true })
  completedAt?: Date;

  @Field()
  startedAt: Date;
}
