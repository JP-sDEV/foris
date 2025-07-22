import { InputType, Field, PickType } from '@nestjs/graphql';
import { CreateAuthInput } from '../../auth/dto/create-auth.input';
@InputType()
export class CreateUserInput extends PickType(CreateAuthInput, ['email']) {
  @Field()
  name: string;
}
