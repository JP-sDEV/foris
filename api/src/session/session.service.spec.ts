import { Test, TestingModule } from '@nestjs/testing';
import { SessionService } from './session.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { CreateSessionInput } from './dto/create-session.input';

describe('SessionService', () => {
  let service: SessionService;
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
        SessionService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: UserService, useValue: userServiceMock },
      ],
    }).compile();

    service = module.get<SessionService>(SessionService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a session when user is found', async () => {
      const user = { id: 'user123' };
      const input: CreateSessionInput = {
        email: 'test@example.com',
        refreshToken: 'abc123',
        expiresAt: new Date(),
        ipAddress: '127.0.0.1',
        userAgent: 'test-agent',
      };

      userServiceMock.findOneByEmail.mockResolvedValue(user);
      prismaMock.session.create.mockResolvedValue({ id: 'session123', user });

      const result = await service.create(input);

      expect(userServiceMock.findOneByEmail).toHaveBeenCalledWith(input.email);
      expect(prismaMock.session.create).toHaveBeenCalled();
      expect(result).toEqual({ id: 'session123', user });
    });

    it('should throw error if user not found', async () => {
      userServiceMock.findOneByEmail.mockResolvedValue(null);
      const input = {
        email: 'missing@example.com',
        refreshToken: 'abc',
        expiresAt: new Date(),
        ipAddress: undefined,
        userAgent: undefined,
      };

      await expect(service.create(input)).rejects.toThrow('User not found');
    });
  });

  describe('findOne', () => {
    it('should find a session by refresh token', async () => {
      const session = { id: 's1', refreshToken: 'token', user: {} };
      prismaMock.session.findUnique.mockResolvedValue(session);

      const result = await service.findUnique('token');

      expect(prismaMock.session.findUnique).toHaveBeenCalledWith({
        where: { refreshToken: 'token' },
        include: { user: true },
      });
      expect(result).toEqual(session);
    });
  });

  describe('update', () => {
    it('should update a session with new token and expiry', async () => {
      const oldSession = { id: 's1', refreshToken: 'old-token' };
      prismaMock.session.findUnique.mockResolvedValue(oldSession);
      prismaMock.session.update = jest.fn().mockResolvedValue({
        id: 's1',
        refreshToken: 'new-token',
        user: {},
      });

      const result = await service.update('old-token');

      expect(prismaMock.session.findUnique).toHaveBeenCalledWith({
        where: { refreshToken: 'old-token' },
      });
      expect(prismaMock.session.update).toHaveBeenCalled();
      expect(result.refreshToken).toBeDefined();
    });

    it('should throw error if refresh token is missing', async () => {
      await expect(service.update('')).rejects.toThrow(
        'Refresh token is required for updating session',
      );
    });

    it('should throw error if session not found', async () => {
      prismaMock.session.findUnique.mockResolvedValue(null);
      await expect(service.update('bad-token')).rejects.toThrow(
        'Session not found',
      );
    });
  });

  describe('remove', () => {
    it('should delete the session if found', async () => {
      const session = { id: 'abc' };
      prismaMock.session.findUnique.mockResolvedValue(session);
      prismaMock.session.delete.mockResolvedValue(session);

      const result = await service.remove('abc');

      expect(prismaMock.session.delete).toHaveBeenCalledWith({
        where: { id: 'abc' },
      });
      expect(result).toEqual(session);
    });

    it('should throw if session not found', async () => {
      prismaMock.session.findUnique.mockResolvedValue(null);
      await expect(service.remove('missing')).rejects.toThrow(
        'Session not found',
      );
    });
  });

  describe('generateSecureToken', () => {
    it('should return a 64-character hex string', () => {
      const token = service.generateSecureToken();
      expect(typeof token).toBe('string');
      expect(token).toMatch(/^[a-f0-9]{64}$/);
    });
  });
});
