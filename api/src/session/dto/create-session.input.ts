import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class CreateSessionInput {
  @Field(() => String)
  refreshToken: string;

  @Field(() => String, { nullable: true })
  ipAddress?: string;

  @Field(() => String, { nullable: true })
  userAgent?: string;

  @Field(() => String)
  userId?: string;

  @Field(() => String)
  email: string;

  @Field(() => Date, { nullable: true })
  expiresAt?: Date;
}
