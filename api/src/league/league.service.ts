import { Injectable } from '@nestjs/common';
import { CreateLeagueInput } from './dto/create-league.input';
import { UpdateLeagueInput } from './dto/update-league.input';

@Injectable()
export class LeagueService {
  create(createLeagueInput: CreateLeagueInput) {
    return 'This action adds a new league';
  }

  findAll() {
    return `This action returns all league`;
  }

  findOne(id: number) {
    return `This action returns a #${id} league`;
  }

  update(id: number, updateLeagueInput: UpdateLeagueInput) {
    return `This action updates a #${id} league`;
  }

  remove(id: number) {
    return `This action removes a #${id} league`;
  }
}
