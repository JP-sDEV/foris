import { PickType, InputType } from '@nestjs/graphql';
import { CreateSessionInput } from './create-session.input';

@InputType()
export class UpdateSessionInput extends PickType(CreateSessionInput, [
  'refreshToken',
] as const) {}
