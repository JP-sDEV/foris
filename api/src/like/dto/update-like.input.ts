import { CreateLikeInput } from './create-like.input';
import { InputType, PartialType } from '@nestjs/graphql';

@InputType()
export class UpdateLikeInput extends PartialType(CreateLikeInput) {}
