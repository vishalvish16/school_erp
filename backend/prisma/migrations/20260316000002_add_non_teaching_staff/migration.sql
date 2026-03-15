-- Migration: 20260316000002_add_non_teaching_staff
-- Created: 2026-03-16
-- Description: Creates the non_teaching_staff table — the core HR record for every
--              non-teaching employee. Separate from the teachers/staff table to keep
--              the two workflows clearly isolated.
-- Depends on: 20260316000001_add_non_teaching_staff_roles

-- CreateTable
CREATE TABLE IF NOT EXISTS "non_teaching_staff" (
    "id"                      UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"               UUID         NOT NULL,
    "user_id"                 UUID         UNIQUE,
    "role_id"                 UUID         NOT NULL,
    "employee_no"             VARCHAR(50)  NOT NULL,
    "first_name"              VARCHAR(100) NOT NULL,
    "last_name"               VARCHAR(100) NOT NULL,
    "gender"                  VARCHAR(10)  NOT NULL,
    "date_of_birth"           DATE,
    "phone"                   VARCHAR(20),
    "email"                   VARCHAR(255) NOT NULL,
    "department"              VARCHAR(100),
    "designation"             VARCHAR(100),
    "qualification"           VARCHAR(255),
    "join_date"               DATE         NOT NULL,
    "employee_type"           VARCHAR(30)  NOT NULL DEFAULT 'PERMANENT',
    "salary_grade"            VARCHAR(50),
    "address"                 TEXT,
    "city"                    VARCHAR(100),
    "state"                   VARCHAR(100),
    "blood_group"             VARCHAR(5),
    "emergency_contact_name"  VARCHAR(100),
    "emergency_contact_phone" VARCHAR(20),
    "photo_url"               TEXT,
    "is_active"               BOOLEAN      NOT NULL DEFAULT true,
    "deleted_at"              TIMESTAMPTZ,
    "created_at"              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "updated_at"              TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT "non_teaching_staff_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: unique employee number per school (soft-delete aware — only active records
-- must be unique; a re-hired staff member after deletion gets a fresh row)
CREATE UNIQUE INDEX IF NOT EXISTS "non_teaching_staff_school_id_employee_no_key"
    ON "non_teaching_staff"("school_id", "employee_no")
    WHERE "deleted_at" IS NULL;

-- CreateIndex: tenant lookup
CREATE INDEX IF NOT EXISTS "non_teaching_staff_school_id_idx"
    ON "non_teaching_staff"("school_id");

-- CreateIndex: filter by role within a school
CREATE INDEX IF NOT EXISTS "non_teaching_staff_school_id_role_id_idx"
    ON "non_teaching_staff"("school_id", "role_id");

-- CreateIndex: active staff listing
CREATE INDEX IF NOT EXISTS "non_teaching_staff_school_id_is_active_idx"
    ON "non_teaching_staff"("school_id", "is_active");

-- AddForeignKey: tenant isolation
ALTER TABLE "non_teaching_staff"
    ADD CONSTRAINT "non_teaching_staff_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: optional linked login user (null until school admin creates login)
ALTER TABLE "non_teaching_staff"
    ADD CONSTRAINT "non_teaching_staff_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey: role assignment (RESTRICT prevents orphan records)
ALTER TABLE "non_teaching_staff"
    ADD CONSTRAINT "non_teaching_staff_role_id_fkey"
    FOREIGN KEY ("role_id") REFERENCES "non_teaching_staff_roles"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
