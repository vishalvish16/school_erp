-- Migration: 20260316000003_add_non_teaching_staff_attendance
-- Created: 2026-03-16
-- Description: Creates the non_teaching_attendance_status_enum and
--              non_teaching_staff_attendance table. One row per staff member per date.
--              Stores optional check-in/check-out times as HH:MM strings for simplicity.
-- Depends on: 20260316000002_add_non_teaching_staff

-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "non_teaching_attendance_status_enum" AS ENUM (
    'PRESENT',
    'ABSENT',
    'HALF_DAY',
    'ON_LEAVE',
    'HOLIDAY',
    'LATE'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "non_teaching_staff_attendance" (
    "id"            UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"     UUID         NOT NULL,
    "staff_id"      UUID         NOT NULL,
    "date"          DATE         NOT NULL,
    "status"        "non_teaching_attendance_status_enum" NOT NULL,
    "check_in_time" VARCHAR(8),
    "check_out_time" VARCHAR(8),
    "marked_by"     UUID         NOT NULL,
    "remarks"       VARCHAR(255),
    "created_at"    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "updated_at"    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT "non_teaching_staff_attendance_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "non_teaching_staff_attendance_staff_id_date_key" UNIQUE ("staff_id", "date")
);

-- CreateIndex: daily attendance sheet by school + date
CREATE INDEX IF NOT EXISTS "nt_attendance_school_id_date_idx"
    ON "non_teaching_staff_attendance"("school_id", "date");

-- CreateIndex: attendance history per staff member
CREATE INDEX IF NOT EXISTS "nt_attendance_school_id_staff_id_idx"
    ON "non_teaching_staff_attendance"("school_id", "staff_id");

-- AddForeignKey: tenant isolation
ALTER TABLE "non_teaching_staff_attendance"
    ADD CONSTRAINT "nt_attendance_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff member
ALTER TABLE "non_teaching_staff_attendance"
    ADD CONSTRAINT "nt_attendance_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "non_teaching_staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: user who marked the attendance (RESTRICT to preserve audit trail)
ALTER TABLE "non_teaching_staff_attendance"
    ADD CONSTRAINT "nt_attendance_marked_by_fkey"
    FOREIGN KEY ("marked_by") REFERENCES "users"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
