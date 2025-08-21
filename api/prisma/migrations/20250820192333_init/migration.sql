-- CreateEnum
CREATE TYPE "LeagueRole" AS ENUM ('MEMBER', 'ADMIN');

-- CreateTable
CREATE TABLE "LeagueUser" (
    "leagueId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "role" "LeagueRole" NOT NULL DEFAULT 'MEMBER',

    CONSTRAINT "LeagueUser_pkey" PRIMARY KEY ("leagueId","userId")
);

-- AddForeignKey
ALTER TABLE "LeagueUser" ADD CONSTRAINT "LeagueUser_leagueId_fkey" FOREIGN KEY ("leagueId") REFERENCES "League"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LeagueUser" ADD CONSTRAINT "LeagueUser_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
