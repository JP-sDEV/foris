import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { SessionService } from '../session/session.service';
import { JwtService } from '@nestjs/jwt';
import { NotFoundException } from '@nestjs/common';

describe('AuthService', () => {
  let service: AuthService;
  let prismaMock: any;
  let userServiceMock: any;
  let sessionServiceMock: any;
  let jwtServiceMock: any;

  beforeEach(async () => {
    prismaMock = {
      user: {
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      session: {
        findFirst: jest.fn(),
        delete: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      oAuthAccount: {
        findUnique: jest.fn(),
        delete: jest.fn(),
      },
    };

    userServiceMock = {
      findOneByEmail: jest.fn(),
    };

    sessionServiceMock = {
      create: jest
        .fn()
        .mockResolvedValue({ refreshToken: 'mocked-refresh-token' }),
      findFirst: jest.fn(),
      delete: jest.fn(),
      findUnique: jest.fn(),
      generateSecureToken: jest.fn().mockReturnValue('mocked-token'),
      findOne: jest.fn(),
    };

    jwtServiceMock = {
      sign: jest.fn().mockReturnValue('token'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: UserService, useValue: userServiceMock },
        { provide: SessionService, useValue: sessionServiceMock },
        { provide: JwtService, useValue: jwtServiceMock },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a new user and session if user does not exist', async () => {
      userServiceMock.findOneByEmail.mockResolvedValue(null);
      prismaMock.user.create.mockResolvedValue({
        id: 1,
        email: 'test@example.com',
      });

      const input = {
        name: 'Test',
        email: 'test@example.com',
        provider: 'google',
        providerUserId: '123',
        accessToken: 'token',
        refreshToken: 'refresh',
      };
      const result = await service.create(input as any);

      expect(result).toEqual({
        user: { id: 1, email: 'test@example.com' },
        accessToken: 'token',
        refreshToken: 'mocked-refresh-token',
      });
    });

    it('should throw an error if user already exists', async () => {
      userServiceMock.findOneByEmail.mockResolvedValue({
        id: 1,
        email: 'test@example.com',
      });

      const input = {
        name: 'Test',
        email: 'test@example.com',
        provider: 'google',
        providerUserId: '123',
        accessToken: 'token',
        refreshToken: 'refresh',
      };

      await expect(service.create(input as any)).rejects.toThrow(
        'User with email test@example.com already exists',
      );
    });
  });

  describe('findOneByEmail', () => {
    it('should return user if found', async () => {
      userServiceMock.findOneByEmail.mockResolvedValue({
        id: 1,
        email: 'test@example.com',
      });

      const result = await service.findOneByEmail('test@example.com');
      expect(result).toEqual({ id: 1, email: 'test@example.com' });
    });

    it('should throw NotFoundException if user not found', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(
        service.findOneByEmail('notfound@example.com'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('refreshToken', () => {
    it('should refresh token if session exists', async () => {
      sessionServiceMock.findUnique.mockResolvedValue({
        id: 1,
        user: { id: 2, email: 'test@example.com' },
      });

      sessionServiceMock.update = jest.fn().mockResolvedValue({
        refreshToken: 'new-refresh-token',
      });
      const result = await service.refreshToken('sometoken');

      expect(sessionServiceMock.findUnique).toHaveBeenCalledWith('sometoken');
      expect(sessionServiceMock.update).toHaveBeenCalledWith('sometoken');
      expect(result).toEqual({
        user: { id: 2, email: 'test@example.com' },
        refreshToken: 'new-refresh-token',
      });
    });

    it('should throw error if session not found', async () => {
      prismaMock.session.findUnique.mockResolvedValue(null);

      await expect(service.refreshToken('badtoken')).rejects.toThrow(
        'Session not found',
      );
    });
  });

  describe('remove', () => {
    it('should delete oauth account if found', async () => {
      prismaMock.oAuthAccount.findUnique.mockResolvedValue({ id: 'abc' });
      prismaMock.oAuthAccount.delete.mockResolvedValue({ id: 'abc' });

      const result = await service.remove('abc');
      expect(result).toEqual({ id: 'abc' });
    });

    it('should throw NotFoundException if oauth account not found', async () => {
      prismaMock.oAuthAccount.findUnique.mockResolvedValue(null);

      await expect(service.remove('notfound')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
