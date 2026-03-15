-- Migration: 20260315130000_add_school_admin_models
-- Created: 2026-03-15
-- Description: Adds nine core school-admin tables:
--   school_classes, staff, sections, students, attendances,
--   fee_structures, fee_payments, school_notices, timetables

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. CreateTable: school_classes
--    Depends on: schools
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CreateTable: staff
--    Depends on: schools, users
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "staff" (
    "id"            UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"     UUID         NOT NULL,
    "user_id"       UUID,
    "employee_no"   VARCHAR(50)  NOT NULL,
    "first_name"    VARCHAR(100) NOT NULL,
    "last_name"     VARCHAR(100) NOT NULL,
    "gender"        VARCHAR(10)  NOT NULL,
    "date_of_birth" DATE,
    "phone"         VARCHAR(20),
    "email"         VARCHAR(255) NOT NULL,
    "designation"   VARCHAR(100) NOT NULL,
    "subjects"      TEXT[]       NOT NULL DEFAULT '{}',
    "qualification" VARCHAR(255),
    "join_date"     DATE         NOT NULL,
    "photo_url"     TEXT,
    "is_active"     BOOLEAN      NOT NULL DEFAULT true,
    "deleted_at"    TIMESTAMPTZ(6),
    "created_at"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_pkey" PRIMARY KEY ("id")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CreateTable: sections
--    Depends on: schools, school_classes, staff
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "sections" (
    "id"               UUID        NOT NULL DEFAULT gen_random_uuid(),
    "school_id"        UUID        NOT NULL,
    "class_id"         UUID        NOT NULL,
    "name"             VARCHAR(10) NOT NULL,
    "class_teacher_id" UUID,
    "capacity"         INTEGER     NOT NULL DEFAULT 40,
    "is_active"        BOOLEAN     NOT NULL DEFAULT true,
    "created_at"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sections_pkey" PRIMARY KEY ("id")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CreateTable: students
--    Depends on: schools, school_classes, sections
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "students" (
    "id"              UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"       UUID         NOT NULL,
    "admission_no"    VARCHAR(50)  NOT NULL,
    "first_name"      VARCHAR(100) NOT NULL,
    "last_name"       VARCHAR(100) NOT NULL,
    "gender"          VARCHAR(10)  NOT NULL,
    "date_of_birth"   DATE         NOT NULL,
    "blood_group"     VARCHAR(5),
    "phone"           VARCHAR(20),
    "email"           VARCHAR(255),
    "address"         TEXT,
    "photo_url"       TEXT,
    "class_id"        UUID,
    "section_id"      UUID,
    "roll_no"         INTEGER,
    "status"          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    "admission_date"  DATE         NOT NULL,
    "parent_name"     VARCHAR(200),
    "parent_phone"    VARCHAR(20),
    "parent_email"    VARCHAR(255),
    "parent_relation" VARCHAR(50),
    "deleted_at"      TIMESTAMPTZ(6),
    "created_at"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "students_pkey" PRIMARY KEY ("id")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CreateTable: attendances
--    Depends on: schools, students, sections
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. CreateTable: fee_structures
--    Depends on: schools, school_classes
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "fee_structures" (
    "id"           UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID         NOT NULL,
    "class_id"     UUID,
    "academic_year" VARCHAR(10) NOT NULL,
    "fee_head"     VARCHAR(100) NOT NULL,
    "amount"       DECIMAL(10,2) NOT NULL,
    "frequency"    VARCHAR(20)  NOT NULL,
    "due_day"      INTEGER,
    "is_active"    BOOLEAN      NOT NULL DEFAULT true,
    "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fee_structures_pkey" PRIMARY KEY ("id")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. CreateTable: fee_payments
--    Depends on: schools, students (FK added below)
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. CreateTable: school_notices
--    Depends on: schools
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "school_notices" (
    "id"           UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID         NOT NULL,
    "title"        VARCHAR(255) NOT NULL,
    "body"         TEXT         NOT NULL,
    "target_role"  VARCHAR(50),
    "is_pinned"    BOOLEAN      NOT NULL DEFAULT false,
    "published_at" TIMESTAMPTZ(6),
    "expires_at"   TIMESTAMPTZ(6),
    "created_by"   UUID         NOT NULL,
    "deleted_at"   TIMESTAMPTZ(6),
    "created_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "school_notices_pkey" PRIMARY KEY ("id")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. CreateTable: timetables
--    Depends on: schools, school_classes, sections
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "timetables" (
    "id"          UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"   UUID         NOT NULL,
    "class_id"    UUID         NOT NULL,
    "section_id"  UUID,
    "day_of_week" INTEGER      NOT NULL,
    "period_no"   INTEGER      NOT NULL,
    "subject"     VARCHAR(100) NOT NULL,
    "staff_id"    UUID,
    "start_time"  VARCHAR(8)   NOT NULL,
    "end_time"    VARCHAR(8)   NOT NULL,
    "room"        VARCHAR(50),
    "created_at"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "timetables_pkey" PRIMARY KEY ("id")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: school_classes (IF NOT EXISTS for idempotency)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "school_classes_school_id_name_key"
    ON "school_classes"("school_id", "name");

CREATE INDEX IF NOT EXISTS "school_classes_school_id_idx"
    ON "school_classes"("school_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: staff
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "staff_user_id_key"
    ON "staff"("user_id");

CREATE UNIQUE INDEX IF NOT EXISTS "staff_school_id_employee_no_key"
    ON "staff"("school_id", "employee_no");

CREATE INDEX IF NOT EXISTS "staff_school_id_idx"
    ON "staff"("school_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: sections
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "sections_class_id_name_key"
    ON "sections"("class_id", "name");

CREATE INDEX IF NOT EXISTS "sections_school_id_idx"
    ON "sections"("school_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: students
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "students_school_id_admission_no_key"
    ON "students"("school_id", "admission_no");

CREATE INDEX IF NOT EXISTS "students_school_id_idx"
    ON "students"("school_id");

CREATE INDEX IF NOT EXISTS "students_class_id_idx"
    ON "students"("class_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: attendances
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "attendances_student_id_date_key"
    ON "attendances"("student_id", "date");

CREATE INDEX IF NOT EXISTS "attendances_school_id_date_idx"
    ON "attendances"("school_id", "date");

CREATE INDEX IF NOT EXISTS "attendances_section_id_date_idx"
    ON "attendances"("section_id", "date");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: fee_structures
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS "fee_structures_school_id_academic_year_idx"
    ON "fee_structures"("school_id", "academic_year");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: fee_payments
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "fee_payments_school_id_receipt_no_key"
    ON "fee_payments"("school_id", "receipt_no");

CREATE INDEX IF NOT EXISTS "fee_payments_school_id_student_id_idx"
    ON "fee_payments"("school_id", "student_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: school_notices
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS "school_notices_school_id_idx"
    ON "school_notices"("school_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateIndex: timetables
-- ─────────────────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS "timetables_class_id_section_id_day_of_week_period_no_key"
    ON "timetables"("class_id", "section_id", "day_of_week", "period_no");

CREATE INDEX IF NOT EXISTS "timetables_school_id_idx"
    ON "timetables"("school_id");

-- ─────────────────────────────────────────────────────────────────────────────
-- AddForeignKey: (skip if exists for idempotency)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'school_classes_school_id_fkey') THEN
        ALTER TABLE "school_classes" ADD CONSTRAINT "school_classes_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'staff_school_id_fkey') THEN
        ALTER TABLE "staff" ADD CONSTRAINT "staff_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'staff_user_id_fkey') THEN
        ALTER TABLE "staff" ADD CONSTRAINT "staff_user_id_fkey"
            FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sections_school_id_fkey') THEN
        ALTER TABLE "sections" ADD CONSTRAINT "sections_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sections_class_id_fkey') THEN
        ALTER TABLE "sections" ADD CONSTRAINT "sections_class_id_fkey"
            FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sections_class_teacher_id_fkey') THEN
        ALTER TABLE "sections" ADD CONSTRAINT "sections_class_teacher_id_fkey"
            FOREIGN KEY ("class_teacher_id") REFERENCES "staff"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_school_id_fkey') THEN
        ALTER TABLE "students" ADD CONSTRAINT "students_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_class_id_fkey') THEN
        ALTER TABLE "students" ADD CONSTRAINT "students_class_id_fkey"
            FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_section_id_fkey') THEN
        ALTER TABLE "students" ADD CONSTRAINT "students_section_id_fkey"
            FOREIGN KEY ("section_id") REFERENCES "sections"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'attendances_school_id_fkey') THEN
        ALTER TABLE "attendances" ADD CONSTRAINT "attendances_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'attendances_student_id_fkey') THEN
        ALTER TABLE "attendances" ADD CONSTRAINT "attendances_student_id_fkey"
            FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'attendances_section_id_fkey') THEN
        ALTER TABLE "attendances" ADD CONSTRAINT "attendances_section_id_fkey"
            FOREIGN KEY ("section_id") REFERENCES "sections"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fee_structures_school_id_fkey') THEN
        ALTER TABLE "fee_structures" ADD CONSTRAINT "fee_structures_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fee_structures_class_id_fkey') THEN
        ALTER TABLE "fee_structures" ADD CONSTRAINT "fee_structures_class_id_fkey"
            FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fee_payments_school_id_fkey') THEN
        ALTER TABLE "fee_payments" ADD CONSTRAINT "fee_payments_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fee_payments_student_id_fkey') THEN
        ALTER TABLE "fee_payments" ADD CONSTRAINT "fee_payments_student_id_fkey"
            FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'school_notices_school_id_fkey') THEN
        ALTER TABLE "school_notices" ADD CONSTRAINT "school_notices_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'timetables_school_id_fkey') THEN
        ALTER TABLE "timetables" ADD CONSTRAINT "timetables_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'timetables_class_id_fkey') THEN
        ALTER TABLE "timetables" ADD CONSTRAINT "timetables_class_id_fkey"
            FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'timetables_section_id_fkey') THEN
        ALTER TABLE "timetables" ADD CONSTRAINT "timetables_section_id_fkey"
            FOREIGN KEY ("section_id") REFERENCES "sections"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;
