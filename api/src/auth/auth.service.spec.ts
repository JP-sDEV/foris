import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { NotFoundException } from '@nestjs/common';

describe('AuthService', () => {
  let service: AuthService;
  let prismaMock: any;
  let userServiceMock: any;

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

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: UserService, useValue: userServiceMock },
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

      expect(prismaMock.user.create).toHaveBeenCalled();
      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('refreshToken');
    });

    it('should revoke old session and create new session if user exists', async () => {
      userServiceMock.findOneByEmail.mockResolvedValue({
        id: 1,
        email: 'test@example.com',
      });
      prismaMock.session.findFirst.mockResolvedValue({ id: 2 });
      prismaMock.session.delete.mockResolvedValue({});
      prismaMock.session.create.mockResolvedValue({});

      const input = {
        name: 'Test',
        email: 'test@example.com',
        provider: 'google',
        providerUserId: '123',
        accessToken: 'token',
        refreshToken: 'refresh',
      };

      const result = await service.create(input as any);

      expect(prismaMock.session.delete).toHaveBeenCalledWith({
        where: { id: 2 },
      });
      expect(prismaMock.session.create).toHaveBeenCalled();
      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('refreshToken');
    });
  });

  describe('findOneByEmail', () => {
    it('should return user if found', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
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
      prismaMock.session.findUnique.mockResolvedValue({
        id: 1,
        user: { id: 2, email: 'test@example.com' },
      });
      prismaMock.session.delete.mockResolvedValue({});
      prismaMock.session.create.mockResolvedValue({});

      const result = await service.refreshToken('sometoken');
      expect(prismaMock.session.delete).toHaveBeenCalledWith({
        where: { id: 1 },
      });
      expect(prismaMock.session.create).toHaveBeenCalled();
      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('refreshToken');
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
