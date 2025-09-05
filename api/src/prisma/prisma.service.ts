import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor(private readonly logger: PinoLogger) {
    super();
    this.logger.setContext(PrismaService.name);
  }

  async onModuleInit() {
    try {
      await this.$connect();
      this.logger.info('✅ Connected to the database successfully');
    } catch (err) {
      this.logger.error({ err }, '❌ Failed to connect to the database');
      throw err; // rethrow so NestJS fails fast
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
    this.logger.info('🔌 Database connection closed');
  }
}
