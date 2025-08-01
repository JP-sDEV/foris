import { ObjectType, Field } from '@nestjs/graphql';
import { User } from '../../user/entities/user.entity';
import { Post } from '../../post/entities/post.entity';

@ObjectType()
export class Like {
  @Field(() => String)
  userId: string;

  @Field(() => String)
  postId: string;

  @Field(() => User, { nullable: true })
  user?: User;

  @Field(() => Post, { nullable: true })
  post?: Post;
}
