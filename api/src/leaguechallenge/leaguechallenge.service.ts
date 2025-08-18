import { Injectable } from '@nestjs/common';
import { CreateLeaguechallengeInput } from './dto/create-leaguechallenge.input';
import { UpdateLeaguechallengeInput } from './dto/update-leaguechallenge.input';

@Injectable()
export class LeaguechallengeService {
  create(createLeaguechallengeInput: CreateLeaguechallengeInput) {
    return 'This action adds a new leaguechallenge';
  }

  findAll() {
    return `This action returns all leaguechallenge`;
  }

  findOne(id: number) {
    return `This action returns a #${id} leaguechallenge`;
  }

  update(id: number, updateLeaguechallengeInput: UpdateLeaguechallengeInput) {
    return `This action updates a #${id} leaguechallenge`;
  }

  remove(id: number) {
    return `This action removes a #${id} leaguechallenge`;
  }
}
