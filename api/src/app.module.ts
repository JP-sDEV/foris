import { join } from 'path';
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { UserModule } from './user/user.module';
import { AuthModule } from './auth/auth.module';
import { SessionModule } from './session/session.module';
import { PostModule } from './post/post.module';
import { CommentModule } from './comment/comment.module';
import { LikeModule } from './like/like.module';
import { UserfollowModule } from './userfollow/userfollow.module';
import { ChallengeModule } from './challenge/challenge.module';
import { UserchallengeModule } from './userchallenge/userchallenge.module';
import { LeagueModule } from './league/league.module';
import { LeaguechallengeModule } from './leaguechallenge/leaguechallenge.module';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: join(process.cwd(), 'src/schema.gql'),
      sortSchema: true,
      context: ({ req }) => {
        return { req };
      },
    }),
    UserModule,
    AuthModule,
    SessionModule,
    PostModule,
    CommentModule,
    LikeModule,
    UserfollowModule,
    ChallengeModule,
    UserchallengeModule,
    LeagueModule,
    LeaguechallengeModule,
  ],
})
export class AppModule {}
