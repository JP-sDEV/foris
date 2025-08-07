import { Injectable } from '@nestjs/common';
import { CreateUserchallengeInput } from './dto/create-userchallenge.input';
import { UpdateUserchallengeInput } from './dto/update-userchallenge.input';

@Injectable()
export class UserchallengeService {
  create(createUserchallengeInput: CreateUserchallengeInput) {
    return 'This action adds a new userchallenge';
  }

  findAll() {
    return `This action returns all userchallenge`;
  }

  findOne(id: number) {
    return `This action returns a #${id} userchallenge`;
  }

  update(id: number, updateUserchallengeInput: UpdateUserchallengeInput) {
    return `This action updates a #${id} userchallenge`;
  }

  remove(id: number) {
    return `This action removes a #${id} userchallenge`;
  }
}
