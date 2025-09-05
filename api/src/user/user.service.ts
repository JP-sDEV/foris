// user.service.ts
import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserInput } from './dto/create-user.input';
import { UpdateUserInput } from './dto/update-user.input';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private logger: PinoLogger,
  ) {
    this.logger.setContext(UserService.name);
  }

  async create(createUserInput: CreateUserInput) {
    this.logger.info({ email: createUserInput.email }, 'Creating user');
    const user = await this.findOneByEmail(createUserInput.email);

    if (user) {
      this.logger.warn({ email: createUserInput.email }, 'User already exists');
      throw new ConflictException(
        `User with email ${createUserInput.email} already exists`,
      );
    }

    const newUser = await this.prisma.user.create({
      data: { name: createUserInput.name, email: createUserInput.email },
    });

    this.logger.info({ userId: newUser.id }, 'User created successfully');
    return newUser;
  }

  async findOneById(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      this.logger.warn({ userId: id }, 'User not found');
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async findOneByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async update(id: string, updateUserInput: UpdateUserInput) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      this.logger.warn({ userId: id }, 'User not found for update');
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: updateUserInput,
    });

    this.logger.info({ userId: id }, 'User updated successfully');
    return updatedUser;
  }

  async remove(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      this.logger.warn({ userId: id }, 'User not found for deletion');
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    await this.prisma.user.delete({ where: { id } });
    this.logger.info({ userId: id }, 'User removed successfully');
    return user;
  }
}
