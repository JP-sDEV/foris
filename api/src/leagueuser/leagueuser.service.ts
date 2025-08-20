import { Injectable } from '@nestjs/common';
import { CreateLeagueuserInput } from './dto/create-leagueuser.input';
import { UpdateLeagueuserInput } from './dto/update-leagueuser.input';

@Injectable()
export class LeagueuserService {
  create(createLeagueuserInput: CreateLeagueuserInput) {
    return 'This action adds a new leagueuser';
  }

  findAll() {
    return `This action returns all leagueuser`;
  }

  findOne(id: number) {
    return `This action returns a #${id} leagueuser`;
  }

  update(id: number, updateLeagueuserInput: UpdateLeagueuserInput) {
    return `This action updates a #${id} leagueuser`;
  }

  remove(id: number) {
    return `This action removes a #${id} leagueuser`;
  }
}
