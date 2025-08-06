import { BadRequestException, NotFoundException } from '@nestjs/common';

export class UserNotFoundException extends NotFoundException {
  constructor(userId: string) {
    super(`User with ID ${userId} not found`);
  }
}

export class SelfFollowException extends BadRequestException {
  constructor() {
    super('Users cannot follow themselves');
  }
}

export class DatabaseException extends Error {
  constructor(message: string) {
    super(`Database operation failed: ${message}`);
    this.name = 'DatabaseException';
  }
}
