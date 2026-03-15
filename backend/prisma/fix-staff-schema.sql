-- Fix staff table to match Prisma schema
-- Maps old columns (name, role, mobile, employee_code, joining_date) to new schema

-- 1. Add missing columns
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "employee_no" VARCHAR(50);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "first_name" VARCHAR(100);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "last_name" VARCHAR(100);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "gender" VARCHAR(10) DEFAULT 'M';
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "date_of_birth" DATE;
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "phone" VARCHAR(20);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "designation" VARCHAR(100);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "subjects" TEXT[] DEFAULT '{}';
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "join_date" DATE;
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "employee_type" VARCHAR(30) DEFAULT 'PERMANENT';
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "department" VARCHAR(100);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "experience_years" SMALLINT;
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "salary_grade" VARCHAR(50);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "emergency_contact_name" VARCHAR(100);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "emergency_contact_phone" VARCHAR(20);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "city" VARCHAR(100);
ALTER TABLE "staff" ADD COLUMN IF NOT EXISTS "state" VARCHAR(100);

-- 2. Migrate data from old columns (only if old columns exist)
DO $$
BEGIN
  -- Copy employee_code -> employee_no
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='staff' AND column_name='employee_code') THEN
    UPDATE "staff" SET employee_no = employee_code WHERE employee_no IS NULL AND employee_code IS NOT NULL;
  END IF;
  
  -- Split name -> first_name, last_name
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='staff' AND column_name='name') THEN
    UPDATE "staff" SET 
      first_name = COALESCE(NULLIF(trim(split_part(coalesce(name,''), ' ', 1)), ''), 'Unknown'),
      last_name = COALESCE(trim(substring(coalesce(name,'') from length(split_part(coalesce(name,''), ' ', 1)) + 2)), '')
    WHERE first_name IS NULL OR first_name = '';
  END IF;
  
  -- Copy mobile -> phone, role -> designation, joining_date -> join_date
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='staff' AND column_name='mobile') THEN
    UPDATE "staff" SET phone = mobile WHERE phone IS NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='staff' AND column_name='role') THEN
    UPDATE "staff" SET designation = role WHERE designation IS NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='staff' AND column_name='joining_date') THEN
    UPDATE "staff" SET join_date = joining_date::date WHERE join_date IS NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='staff' AND column_name='salary') THEN
    UPDATE "staff" SET salary_grade = salary::text WHERE salary_grade IS NULL AND salary IS NOT NULL;
  END IF;
END $$;

-- 3. Fill remaining NULLs for required columns
UPDATE "staff" SET employee_no = 'EMP-' || substr(id::text, 1, 8) WHERE employee_no IS NULL;
UPDATE "staff" SET first_name = 'Unknown' WHERE first_name IS NULL OR trim(first_name) = '';
UPDATE "staff" SET last_name = '' WHERE last_name IS NULL;
UPDATE "staff" SET gender = 'M' WHERE gender IS NULL OR trim(gender) = '';
UPDATE "staff" SET designation = 'Staff' WHERE designation IS NULL OR trim(designation) = '';
UPDATE "staff" SET join_date = COALESCE(created_at::date, CURRENT_DATE) WHERE join_date IS NULL;

-- 4. Add NOT NULL (skip if any row would violate - run after verifying)
ALTER TABLE "staff" ALTER COLUMN "employee_no" SET NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "first_name" SET NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "last_name" SET NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "gender" SET NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "designation" SET NOT NULL;
ALTER TABLE "staff" ALTER COLUMN "join_date" SET NOT NULL;
