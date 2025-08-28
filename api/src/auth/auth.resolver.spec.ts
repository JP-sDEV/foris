import { Test, TestingModule } from '@nestjs/testing';
import { AuthResolver } from './auth.resolver';
import { AuthService } from './auth.service';
import { JwtService } from '@nestjs/jwt';

describe('AuthResolver', () => {
  let resolver: AuthResolver;
  let authServiceMock: any;

  beforeEach(async () => {
    authServiceMock = {
      create: jest.fn(),
      findOneByEmail: jest.fn(),
      refreshToken: jest.fn(),
      remove: jest.fn(),
      login: jest.fn(),
      logout: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthResolver,
        { provide: AuthService, useValue: authServiceMock },
        JwtService,
      ],
    }).compile();

    resolver = module.get<AuthResolver>(AuthResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });

  describe('createAuth', () => {
    it('should call authService.create and return AuthPayload', async () => {
      const input = { email: 'test@example.com', name: 'Test' };
      const payload = {
        user: { id: '1', email: 'test@example.com', name: 'Test' },
        accessToken: 'access',
        refreshToken: 'refresh',
      };
      authServiceMock.create.mockResolvedValue(payload);

      const result = await resolver.createAuth(input as any);
      expect(authServiceMock.create).toHaveBeenCalledWith(input);
      expect(result).toBe(payload);
    });
  });

  describe('findOneByEmail', () => {
    it('should call authService.findOneByEmail and return User', async () => {
      const user = { id: '1', email: 'test@example.com', name: 'Test' };
      authServiceMock.findOneByEmail.mockResolvedValue(user);

      const result = await resolver.findOneByEmail('test@example.com');
      expect(authServiceMock.findOneByEmail).toHaveBeenCalledWith(
        'test@example.com',
      );
      expect(result).toBe(user);
    });
  });

  describe('refreshToken', () => {
    it('should call authService.refreshToken with userId and refreshToken', async () => {
      const payload = { userId: '1', email: 'test@example.com', name: 'Test' };
      const refreshToken = 'oldtoken';
      const returnedPayload = {
        user: { id: '1', email: 'test@example.com', name: 'Test' },
        refreshToken: 'newtoken',
        accessToken: 'newAccess',
      };
      authServiceMock.refreshToken.mockResolvedValue(returnedPayload);

      const result = await resolver.refreshToken(payload as any, refreshToken);
      expect(authServiceMock.refreshToken).toHaveBeenCalledWith(
        payload.userId,
        refreshToken,
      );
      expect(result).toBe(returnedPayload);
    });
  });

  describe('removeAuth', () => {
    it('should call authService.remove with userId from payload', async () => {
      const payload = { userId: '1', email: 'test@example.com', name: 'Test' };
      authServiceMock.remove.mockResolvedValue(true);

      const result = await resolver.removeAuth(payload as any);
      expect(authServiceMock.remove).toHaveBeenCalledWith(payload.userId);
      expect(result).toBe(true);
    });
  });

  describe('login', () => {
    it('should call authService.login with email', async () => {
      const email = 'test@example.com';
      const returnedPayload = {
        user: { id: '1', email, name: 'Test' },
        accessToken: 'access',
        refreshToken: 'refresh',
      };
      authServiceMock.login.mockResolvedValue(returnedPayload);

      const result = await resolver.login(email);
      expect(authServiceMock.login).toHaveBeenCalledWith(email);
      expect(result).toBe(returnedPayload);
    });
  });

  describe('logout', () => {
    it('should call authService.logout with refreshToken', async () => {
      const refreshToken = 'refresh';
      authServiceMock.logout.mockResolvedValue(true);

      const result = await resolver.logout(refreshToken);

      expect(authServiceMock.logout).toHaveBeenCalledWith(refreshToken);
      expect(result).toBe(true);
    });
  });
});
