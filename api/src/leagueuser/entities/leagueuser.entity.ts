import { ObjectType, Field, ID } from '@nestjs/graphql';
import { User } from '../../user/entities/user.entity';
import { League } from '../../league/entities/league.entity';

@ObjectType()
export class Leagueuser {
  @Field(() => ID)
  id: string;

  @Field(() => String)
  userId: string;

  @Field(() => String)
  leagueId: string;

  @Field(() => Date)
  createdAt: Date;

  @Field(() => Date)
  updatedAt: Date;

  @Field(() => User, { nullable: true })
  user?: User;

  @Field(() => League, { nullable: true })
  league?: League;
}
