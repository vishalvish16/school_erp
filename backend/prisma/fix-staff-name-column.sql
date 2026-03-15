-- Fix: Make 'name' column nullable so Prisma create (using first_name/last_name) succeeds.
-- The staff table has legacy 'name' column; Prisma schema uses firstName/lastName.
ALTER TABLE "staff" ALTER COLUMN "name" DROP NOT NULL;
