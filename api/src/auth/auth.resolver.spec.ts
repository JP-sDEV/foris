import { Test, TestingModule } from '@nestjs/testing';
import { AuthResolver } from './auth.resolver';
import { AuthService } from './auth.service';

describe('AuthResolver', () => {
  let resolver: AuthResolver;
  let authServiceMock: any;

  beforeEach(async () => {
    authServiceMock = {
      create: jest.fn(),
      findOneByEmail: jest.fn(),
      refreshToken: jest.fn(),
      remove: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthResolver,
        { provide: AuthService, useValue: authServiceMock },
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
        user: { id: 1, email: 'test@example.com' },
        refreshToken: 'token',
      };
      authServiceMock.create.mockResolvedValue(payload);

      const result = await resolver.createAuth(input as any);
      expect(authServiceMock.create).toHaveBeenCalledWith(input);
      expect(result).toBe(payload);
    });
  });

  describe('findOneByEmail', () => {
    it('should call authService.findOneByEmail and return User', async () => {
      const user = { id: 1, email: 'test@example.com' };
      authServiceMock.findOneByEmail.mockResolvedValue(user);

      const result = await resolver.findOneByEmail('test@example.com');
      expect(authServiceMock.findOneByEmail).toHaveBeenCalledWith(
        'test@example.com',
      );
      expect(result).toBe(user);
    });
  });

  describe('refreshToken', () => {
    it('should call authService.refreshToken and return AuthPayload', async () => {
      const payload = {
        user: { id: 1, email: 'test@example.com' },
        refreshToken: 'newtoken',
      };
      authServiceMock.refreshToken.mockResolvedValue(payload);

      const result = await resolver.refreshToken('oldtoken');
      expect(authServiceMock.refreshToken).toHaveBeenCalledWith('oldtoken');
      expect(result).toBe(payload);
    });
  });

  describe('removeAuth', () => {
    it('should call authService.remove and return true', async () => {
      authServiceMock.remove.mockResolvedValue({ id: 'abc' });

      const result = await resolver.removeAuth('abc');
      expect(authServiceMock.remove).toHaveBeenCalledWith('abc');
      expect(result).toBeTruthy();
    });
  });
});
