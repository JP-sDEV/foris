import { join } from 'path';
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { ConfigModule } from '@nestjs/config';
import { PrismaService } from './prisma/prisma.service';
import { LoggerModule } from 'nestjs-pino';

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
import { LeagueuserModule } from './leagueuser/leagueuser.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: join(process.cwd(), 'src/schema.gql'),
      sortSchema: true,
      path: '/api/graphql',
      context: ({ req }) => ({ req }),
    }),
    LoggerModule.forRoot({
      pinoHttp: {
        transport:
          process.env.NODE_ENV !== 'production'
            ? {
                target: 'pino-pretty',
                options: {
                  colorize: true,
                  translateTime: 'SYS:standard',
                  ignore: 'pid,hostname',
                },
              }
            : undefined,
        redact: [
          'req.headers.authorization', // hide bearer token
          'req.headers.cookie', // hide cookies
        ],
        // if testing, disable pino logging
        level: process.env.NODE_ENV === 'test' ? 'silent' : 'info',
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
    LeagueuserModule,
  ],
  providers: [PrismaService],
})
export class AppModule {}
