import { Test, TestingModule } from '@nestjs/testing';
import { SessionResolver } from './session.resolver';
import { SessionService } from './session.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';

describe('SessionResolver', () => {
  let resolver: SessionResolver;
  let prismaMock: any;
  let userServiceMock: any;

  beforeEach(async () => {
    prismaMock = {
      session: {
        create: jest.fn(),
        findUnique: jest.fn(),
        delete: jest.fn(),
      },
    };

    userServiceMock = {
      findOneByEmail: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SessionResolver,
        SessionService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: UserService, useValue: userServiceMock },
      ],
    }).compile();

    resolver = module.get<SessionResolver>(SessionResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
