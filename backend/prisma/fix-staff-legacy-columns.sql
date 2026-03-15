-- Make all legacy staff columns nullable so Prisma create (using new schema) succeeds.
-- Prisma uses: first_name, last_name, employee_no, designation, join_date, phone
-- Legacy columns not in Prisma schema: name, role, mobile, employee_code, joining_date, salary, rfid_tag

ALTER TABLE "staff" ALTER COLUMN "name" DROP NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "role" DROP NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "mobile" DROP NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "employee_code" DROP NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "joining_date" DROP NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "salary" DROP NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "rfid_tag" DROP NOT NULL;
