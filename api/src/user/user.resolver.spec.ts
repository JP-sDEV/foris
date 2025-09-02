import { Test, TestingModule } from '@nestjs/testing';
import { UserResolver } from './user.resolver';
import { UserService } from './user.service';
import { JwtPayload } from '../auth/types/jwt-payload.type';
import { GqlAuthGuard } from '../auth/guards/auth.guard';

describe('UserResolver', () => {
  let resolver: UserResolver;
  let userServiceMock: any;

  beforeEach(async () => {
    userServiceMock = {
      create: jest.fn(),
      findOneById: jest.fn(),
      update: jest.fn(),
      remove: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserResolver,
        { provide: UserService, useValue: userServiceMock },
      ],
    })
      .overrideGuard(GqlAuthGuard)
      .useValue({
        canActivate: () => {
          return true;
        },
      })
      .compile();

    resolver = module.get<UserResolver>(UserResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });

  describe('createUser', () => {
    it('should call userService.create and return User', async () => {
      const input = { email: 'test@example.com', name: 'Test' };
      const user = { id: '1', ...input };
      userServiceMock.create.mockResolvedValue(user);

      const result = await resolver.createUser(input);
      expect(userServiceMock.create).toHaveBeenCalledWith(input);
      expect(result).toBe(user);
    });
  });

  describe('findOne', () => {
    it('should call userService.findOneById and return User', async () => {
      const user = { id: '1', email: 'test@example.com', name: 'Test' };
      userServiceMock.findOneById.mockResolvedValue(user);

      const result = await resolver.findOne('1');
      expect(userServiceMock.findOneById).toHaveBeenCalledWith('1');
      expect(result).toBe(user);
    });
  });

  describe('updateUser', () => {
    it('should call userService.update and return User', async () => {
      const input = { name: 'Updated', email: 'updated@example.com' };
      const payload: JwtPayload = {
        userId: '1',
        name: input.name,
        email: input.email,
      };
      const updatedUser = { id: '1', ...input };

      userServiceMock.update.mockResolvedValue(updatedUser);

      const result = await resolver.updateUser(input as any, payload);
      expect(userServiceMock.update).toHaveBeenCalledWith(
        payload.userId,
        input,
      );
      expect(result).toBe(updatedUser);
    });
  });

  describe('removeUser', () => {
    it('should call userService.remove and return User', async () => {
      const user = { id: '1', email: 'test@example.com', name: 'Test' };
      const payload: JwtPayload = {
        userId: '1',
        email: user.email,
        name: user.name,
      };

      userServiceMock.remove.mockResolvedValue(user);

      const result = await resolver.removeUser(payload);
      expect(userServiceMock.remove).toHaveBeenCalledWith(payload.userId);
      expect(result).toBe(user);
    });
  });

  describe('me', () => {
    it('should return the current user', async () => {
      const user = { id: '1', email: 'test@example.com', name: 'Test' };
      const payload: JwtPayload = {
        userId: '1',
        email: user.email,
        name: user.name,
      };

      userServiceMock.findOneById.mockResolvedValue(user);

      const result = await resolver.me(payload);
      expect(userServiceMock.findOneById).toHaveBeenCalledWith(payload.userId);
      expect(result).toBe(user);
    });
  });
});
