import { Injectable } from '@nestjs/common';
import { CreateChallengeInput } from './dto/create-challenge.input';
import { UpdateChallengeInput } from './dto/update-challenge.input';

@Injectable()
export class ChallengeService {
  create(createChallengeInput: CreateChallengeInput) {
    return 'This action adds a new challenge';
  }

  findAll() {
    return `This action returns all challenge`;
  }

  findOne(id: number) {
    return `This action returns a #${id} challenge`;
  }

  update(id: number, updateChallengeInput: UpdateChallengeInput) {
    return `This action updates a #${id} challenge`;
  }

  remove(id: number) {
    return `This action removes a #${id} challenge`;
  }
}
