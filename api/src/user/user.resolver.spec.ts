import { Test, TestingModule } from '@nestjs/testing';
import { UserResolver } from './user.resolver';
import { UserService } from './user.service';

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
    }).compile();

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

      const result = await resolver.createUser(input as any);
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
      const input = { id: '1', email: 'updated@example.com', name: 'Updated' };
      const updatedUser = { ...input };
      userServiceMock.update.mockResolvedValue(updatedUser);

      const result = await resolver.updateUser(input as any);
      expect(userServiceMock.update).toHaveBeenCalledWith(input.id, input);
      expect(result).toBe(updatedUser);
    });
  });

  describe('removeUser', () => {
    it('should call userService.remove and return User', async () => {
      const user = { id: '1', email: 'test@example.com', name: 'Test' };
      userServiceMock.remove.mockResolvedValue(user);

      const result = await resolver.removeUser('1');
      expect(userServiceMock.remove).toHaveBeenCalledWith('1');
      expect(result).toBe(user);
    });
  });
});
