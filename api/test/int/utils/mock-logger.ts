import { PinoLogger } from 'nestjs-pino';

export const mockLogger: PinoLogger = {
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
  setContext: jest.fn(),
} as unknown as PinoLogger;
