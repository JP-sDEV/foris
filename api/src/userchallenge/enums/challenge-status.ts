import { registerEnumType } from '@nestjs/graphql';
import { ChallengeStatus } from '@prisma/client';

registerEnumType(ChallengeStatus, {
  name: 'ChallengeStatus',
  description: 'Status of a challenge for a user',
});

export { ChallengeStatus };
