-- Migration: 20260315160000_preserve_data_school_admin
-- Preserves existing data while aligning schema with Prisma school-admin models.
-- Run with: psql $DATABASE_URL -f migration.sql (or npx prisma migrate resolve)

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Create school_classes from legacy classes table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "school_classes" (
    "id"         UUID        NOT NULL DEFAULT gen_random_uuid(),
    "school_id"  UUID        NOT NULL,
    "name"       VARCHAR(50) NOT NULL,
    "numeric"    INTEGER,
    "is_active"  BOOLEAN     NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "school_classes_pkey" PRIMARY KEY ("id")
);

INSERT INTO "school_classes" ("id", "school_id", "name", "numeric", "is_active", "created_at", "updated_at")
SELECT c.id, c.school_id, c.class_name, c.sequence, COALESCE(c.is_active, true), c.created_at, c.updated_at
FROM classes c
WHERE c.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM school_classes sc WHERE sc.id = c.id);

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'school_classes_school_id_fkey') THEN
        ALTER TABLE "school_classes" ADD CONSTRAINT "school_classes_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF; END $$;
CREATE UNIQUE INDEX IF NOT EXISTS "school_classes_school_id_name_key" ON "school_classes"("school_id", "name");
CREATE INDEX IF NOT EXISTS "school_classes_school_id_idx" ON "school_classes"("school_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. sections: add "name" column, backfill from section_name, fix capacity
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE "sections" ADD COLUMN IF NOT EXISTS "name" VARCHAR(10);
UPDATE "sections" SET "name" = "section_name" WHERE "name" IS NULL AND "section_name" IS NOT NULL;
UPDATE "sections" SET "name" = 'A' WHERE "name" IS NULL;
ALTER TABLE "sections" ALTER COLUMN "name" SET NOT NULL;

UPDATE "sections" SET "capacity" = 40 WHERE "capacity" IS NULL;
ALTER TABLE "sections" ALTER COLUMN "capacity" SET DEFAULT 40;
ALTER TABLE "sections" ALTER COLUMN "capacity" SET NOT NULL;

-- Add class_teacher_id if missing
ALTER TABLE "sections" ADD COLUMN IF NOT EXISTS "class_teacher_id" UUID;

-- sections FK: ensure class_id references school_classes (may need to drop old FK to classes first)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name LIKE 'sections_class_id%' AND table_name = 'sections') THEN
        ALTER TABLE "sections" DROP CONSTRAINT IF EXISTS "sections_class_id_fkey";
    END IF;
END $$;
ALTER TABLE "sections" DROP CONSTRAINT IF EXISTS "sections_class_id_fkey";
ALTER TABLE "sections" ADD CONSTRAINT "sections_class_id_fkey"
    FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. students: add first_name, last_name, date_of_birth (0 rows - add with defaults)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "first_name" VARCHAR(100);
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "last_name" VARCHAR(100);
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "date_of_birth" DATE;
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "parent_name" VARCHAR(200);
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "parent_phone" VARCHAR(20);
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "parent_email" VARCHAR(255);
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "parent_relation" VARCHAR(50);

UPDATE "students" SET "first_name" = COALESCE("first_name", SPLIT_PART("name", ' ', 1), 'Unknown') WHERE "first_name" IS NULL;
UPDATE "students" SET "last_name" = COALESCE("last_name", NULLIF(TRIM(SUBSTRING("name" FROM POSITION(' ' IN COALESCE("name", '')) + 1)), ''), SPLIT_PART(COALESCE("name", 'Unknown'), ' ', 1)) WHERE "last_name" IS NULL;
UPDATE "students" SET "date_of_birth" = COALESCE("date_of_birth", "dob", '2000-01-01'::date) WHERE "date_of_birth" IS NULL;
UPDATE "students" SET "parent_name" = COALESCE("parent_name", "father_name", "mother_name") WHERE "parent_name" IS NULL;
UPDATE "students" SET "parent_phone" = COALESCE("parent_phone", "parent_mobile") WHERE "parent_phone" IS NULL;
UPDATE "students" SET "last_name" = COALESCE("last_name", 'Unknown') WHERE "last_name" IS NULL;
UPDATE "students" SET "date_of_birth" = COALESCE("date_of_birth", '2000-01-01'::date) WHERE "date_of_birth" IS NULL;
UPDATE "students" SET "admission_date" = COALESCE("admission_date", "created_at"::date) WHERE "admission_date" IS NULL;

ALTER TABLE "students" ALTER COLUMN "first_name" SET NOT NULL;
ALTER TABLE "students" ALTER COLUMN "last_name" SET NOT NULL;
ALTER TABLE "students" ALTER COLUMN "date_of_birth" SET NOT NULL;
ALTER TABLE "students" ALTER COLUMN "admission_date" SET NOT NULL;

-- students class_id/section_id: may reference classes/sections. Update class_id to school_classes (same ids)
-- section_id stays - sections exist. class_id: classes and school_classes now have same ids from the copy.

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Create attendances table (empty)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "attendances" (
    "id"         UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"  UUID         NOT NULL,
    "student_id" UUID         NOT NULL,
    "section_id" UUID         NOT NULL,
    "date"       DATE         NOT NULL,
    "status"     VARCHAR(10)  NOT NULL,
    "marked_by"  UUID         NOT NULL,
    "remarks"    VARCHAR(255),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "attendances_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "attendances_student_id_date_key" ON "attendances"("student_id", "date");
CREATE INDEX IF NOT EXISTS "attendances_school_id_date_idx" ON "attendances"("school_id", "date");
CREATE INDEX IF NOT EXISTS "attendances_section_id_date_idx" ON "attendances"("section_id", "date");
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE;
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE;
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_section_id_fkey" FOREIGN KEY ("section_id") REFERENCES "sections"("id") ON DELETE CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Create fee_payments table (empty)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "fee_payments" (
    "id"           UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID         NOT NULL,
    "student_id"   UUID         NOT NULL,
    "fee_head"     VARCHAR(100) NOT NULL,
    "academic_year" VARCHAR(10) NOT NULL,
    "amount"       DECIMAL(10,2) NOT NULL,
    "payment_date" DATE         NOT NULL,
    "payment_mode" VARCHAR(30)  NOT NULL,
    "receipt_no"   VARCHAR(50)  NOT NULL,
    "collected_by" UUID         NOT NULL,
    "remarks"      VARCHAR(255),
    "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "fee_payments_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "fee_payments_school_id_receipt_no_key" ON "fee_payments"("school_id", "receipt_no");
CREATE INDEX IF NOT EXISTS "fee_payments_school_id_student_id_idx" ON "fee_payments"("school_id", "student_id");
ALTER TABLE "fee_payments" ADD CONSTRAINT "fee_payments_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE;
ALTER TABLE "fee_payments" ADD CONSTRAINT "fee_payments_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE RESTRICT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. fee_structures: add academic_year, fee_head, amount, frequency
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE "fee_structures" ADD COLUMN IF NOT EXISTS "academic_year" VARCHAR(10);
ALTER TABLE "fee_structures" ADD COLUMN IF NOT EXISTS "fee_head" VARCHAR(100);
ALTER TABLE "fee_structures" ADD COLUMN IF NOT EXISTS "amount" DECIMAL(10,2);
ALTER TABLE "fee_structures" ADD COLUMN IF NOT EXISTS "frequency" VARCHAR(20);

UPDATE "fee_structures" fs SET
    "academic_year" = COALESCE((SELECT ay.year_name FROM academic_years ay WHERE ay.id = fs.academic_year_id LIMIT 1), '2026-27'),
    "fee_head" = 'Tuition',
    "amount" = fs.total_amount,
    "frequency" = 'ANNUAL'
WHERE fs.academic_year IS NULL OR fs.fee_head IS NULL OR fs.amount IS NULL OR fs.frequency IS NULL;

ALTER TABLE "fee_structures" ALTER COLUMN "academic_year" SET NOT NULL;
ALTER TABLE "fee_structures" ALTER COLUMN "fee_head" SET NOT NULL;
ALTER TABLE "fee_structures" ALTER COLUMN "amount" SET NOT NULL;
ALTER TABLE "fee_structures" ALTER COLUMN "frequency" SET NOT NULL;

-- fee_structures class_id: ensure it references school_classes
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'fee_structures_class_id_fkey' AND table_name = 'fee_structures') THEN
        ALTER TABLE "fee_structures" DROP CONSTRAINT "fee_structures_class_id_fkey";
    END IF;
END $$;
ALTER TABLE "fee_structures" DROP CONSTRAINT IF EXISTS "fee_structures_class_id_fkey";
ALTER TABLE "fee_structures" ADD CONSTRAINT "fee_structures_class_id_fkey"
    FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. timetables: add subject, staff_id; convert start_time/end_time to VARCHAR; add room
-- (Existing: subject_id, teacher_id, start_time/end_time as TIME, room_no)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE "timetables" ADD COLUMN IF NOT EXISTS "subject" VARCHAR(100);
ALTER TABLE "timetables" ADD COLUMN IF NOT EXISTS "staff_id" UUID;
ALTER TABLE "timetables" ADD COLUMN IF NOT EXISTS "room" VARCHAR(50);

-- Backfill subject from subjects table (column: subject_name)
UPDATE "timetables" t SET "subject" = COALESCE(
    (SELECT s.subject_name FROM subjects s WHERE s.id = t.subject_id LIMIT 1),
    'General'
) WHERE t.subject IS NULL AND t.subject_id IS NOT NULL;
UPDATE "timetables" SET "subject" = COALESCE("subject", 'General') WHERE "subject" IS NULL;

UPDATE "timetables" SET "staff_id" = "teacher_id" WHERE "staff_id" IS NULL;
UPDATE "timetables" SET "room" = "room_no" WHERE "room" IS NULL AND "room_no" IS NOT NULL;

-- Convert start_time, end_time from TIME to VARCHAR(8)
ALTER TABLE "timetables" ADD COLUMN IF NOT EXISTS "start_time_new" VARCHAR(8);
ALTER TABLE "timetables" ADD COLUMN IF NOT EXISTS "end_time_new" VARCHAR(8);
UPDATE "timetables" SET "start_time_new" = TO_CHAR("start_time"::time, 'HH24:MI') WHERE "start_time" IS NOT NULL;
UPDATE "timetables" SET "end_time_new" = TO_CHAR("end_time"::time, 'HH24:MI') WHERE "end_time" IS NOT NULL;
UPDATE "timetables" SET "start_time_new" = COALESCE("start_time_new", '08:00') WHERE "start_time_new" IS NULL;
UPDATE "timetables" SET "end_time_new" = COALESCE("end_time_new", '09:00') WHERE "end_time_new" IS NULL;
ALTER TABLE "timetables" DROP COLUMN IF EXISTS "start_time";
ALTER TABLE "timetables" DROP COLUMN IF EXISTS "end_time";
ALTER TABLE "timetables" RENAME COLUMN "start_time_new" TO "start_time";
ALTER TABLE "timetables" RENAME COLUMN "end_time_new" TO "end_time";
ALTER TABLE "timetables" ALTER COLUMN "subject" SET NOT NULL;
ALTER TABLE "timetables" ALTER COLUMN "start_time" SET NOT NULL;
ALTER TABLE "timetables" ALTER COLUMN "end_time" SET NOT NULL;
