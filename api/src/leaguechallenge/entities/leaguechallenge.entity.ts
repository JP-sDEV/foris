import { ObjectType, Field } from '@nestjs/graphql';
import { League } from '../../league/entities/league.entity';
import { Challenge } from '../../challenge/entities/challenge.entity';

@ObjectType()
export class Leaguechallenge {
  @Field(() => String)
  leagueId: string;

  @Field(() => String)
  challengeId: string;

  @Field(() => League, { nullable: true })
  league?: League;

  @Field(() => Challenge, { nullable: true })
  challenge?: Challenge;
}
