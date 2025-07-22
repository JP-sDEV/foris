import { Test, TestingModule } from '@nestjs/testing';
import { UserService } from './user.service';
import { PrismaService } from '../prisma/prisma.service';
import { ConflictException, NotFoundException } from '@nestjs/common';

describe('UserService', () => {
  let service: UserService;
  let prismaMock: any;

  beforeEach(async () => {
    prismaMock = {
      user: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should throw ConflictException if user exists', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
      });
      await expect(
        service.create({ name: 'Test', email: 'test@example.com' }),
      ).rejects.toThrow(ConflictException);
    });

    it('should create and return new user if not exists', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);
      prismaMock.user.create.mockResolvedValue({
        id: '1',
        name: 'Test',
        email: 'test@example.com',
      });

      const result = await service.create({
        name: 'Test',
        email: 'test@example.com',
      });
      expect(prismaMock.user.create).toHaveBeenCalledWith({
        data: { name: 'Test', email: 'test@example.com' },
      });
      expect(result).toEqual({
        id: '1',
        name: 'Test',
        email: 'test@example.com',
      });
    });
  });

  describe('findOneById', () => {
    it('should return user by id', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
      });
      const result = await service.findOneById('1');
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { id: '1' },
      });
      expect(result).toEqual({ id: '1', email: 'test@example.com' });
    });
  });

  describe('findOneByEmail', () => {
    it('should return user by email', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
      });
      const result = await service.findOneByEmail('test@example.com');
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'test@example.com' },
      });
      expect(result).toEqual({ id: '1', email: 'test@example.com' });
    });
  });

  describe('update', () => {
    it('should throw NotFoundException if user does not exist', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);
      await expect(
        service.update('1', { id: '1', name: 'New', email: 'new@example.com' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should update and return user if exists', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
      });
      prismaMock.user.update.mockResolvedValue({
        id: '1',
        name: 'New',
        email: 'new@example.com',
      });

      const result = await service.update('1', {
        id: '1',
        name: 'New',
        email: 'new@example.com',
      });
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: '1' },
        data: { id: '1', name: 'New', email: 'new@example.com' },
      });
      expect(result).toEqual({
        id: '1',
        name: 'New',
        email: 'new@example.com',
      });
    });
  });

  describe('remove', () => {
    it('should throw NotFoundException if user does not exist', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);
      await expect(service.remove('1')).rejects.toThrow(NotFoundException);
    });

    it('should delete and return user if exists', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
      });
      prismaMock.user.delete.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
      });

      const result = await service.remove('1');
      expect(prismaMock.user.delete).toHaveBeenCalledWith({
        where: { id: '1' },
      });
      expect(result).toEqual({ id: '1', email: 'test@example.com' });
    });
  });
});
