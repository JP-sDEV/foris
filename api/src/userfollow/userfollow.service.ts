import { Injectable } from '@nestjs/common';
import { CreateUserfollowInput } from './dto/create-userfollow.input';
import { UpdateUserfollowInput } from './dto/update-userfollow.input';

@Injectable()
export class UserfollowService {
  create(createUserfollowInput: CreateUserfollowInput) {
    return 'This action adds a new userfollow';
  }

  findAll() {
    return `This action returns all userfollow`;
  }

  findOne(id: number) {
    return `This action returns a #${id} userfollow`;
  }

  update(id: number, updateUserfollowInput: UpdateUserfollowInput) {
    return `This action updates a #${id} userfollow`;
  }

  remove(id: number) {
    return `This action removes a #${id} userfollow`;
  }
}
