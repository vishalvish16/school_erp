-- Migration: 20260315000001_extend_staff_table
-- Created: 2026-03-15
-- Description: Extends the staff table with additional personal/employment fields
--   required by the Teacher/Staff module, and adds a partial unique index on
--   (school_id, email) to enforce email uniqueness per school among non-deleted staff.

-- AlterTable: staff — add new columns
ALTER TABLE "staff"
    ADD COLUMN IF NOT EXISTS "address"                TEXT,
    ADD COLUMN IF NOT EXISTS "city"                   VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "state"                  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "blood_group"            VARCHAR(5),
    ADD COLUMN IF NOT EXISTS "emergency_contact_name" VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "emergency_contact_phone" VARCHAR(20),
    ADD COLUMN IF NOT EXISTS "employee_type"          VARCHAR(30) NOT NULL DEFAULT 'PERMANENT',
    ADD COLUMN IF NOT EXISTS "department"             VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "experience_years"       SMALLINT,
    ADD COLUMN IF NOT EXISTS "salary_grade"           VARCHAR(50);

-- CreateIndex: partial unique index — email uniqueness within a school for non-deleted staff
CREATE UNIQUE INDEX IF NOT EXISTS "staff_school_id_email_unique"
    ON "staff" ("school_id", "email")
    WHERE "deleted_at" IS NULL;
