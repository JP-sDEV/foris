import { ObjectType, Field, ID } from '@nestjs/graphql';
import { User } from '../../user/entities/user.entity';

@ObjectType()
export class Session {
  @Field(() => ID)
  id: string;

  @Field()
  refreshToken: string;

  @Field({ nullable: true })
  ipAddress?: string;

  @Field({ nullable: true })
  userAgent?: string;

  @Field()
  createdAt: Date;

  @Field()
  expiresAt: Date;

  @Field()
  userId: string;

  @Field(() => User)
  user: User;
}
