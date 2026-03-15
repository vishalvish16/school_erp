-- Migration: 20260315000004_create_staff_subject_assignments
-- Created: 2026-03-15
-- Description: Creates the staff_subject_assignments table — the canonical declaration
--   of which teacher is responsible for which subject in which class-section for a
--   given academic year. Distinct from the timetable (period slots); this table
--   records the authority relationship.

-- CreateTable: staff_subject_assignments
CREATE TABLE IF NOT EXISTS "staff_subject_assignments" (
    "id"            UUID          NOT NULL DEFAULT gen_random_uuid(),
    "school_id"     UUID          NOT NULL,
    "staff_id"      UUID          NOT NULL,
    "class_id"      UUID          NOT NULL,
    "section_id"    UUID,
    "subject"       VARCHAR(100)  NOT NULL,
    "academic_year" VARCHAR(10)   NOT NULL,
    "is_active"     BOOLEAN       NOT NULL DEFAULT true,
    "created_at"    TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_subject_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: composite unique — prevents the same teacher from being assigned
--   the same subject in the same class-section twice in a year, and prevents
--   two teachers from being assigned the same subject in the same class-section.
--   NULL section_id is treated as a distinct value by Postgres NULLS NOT DISTINCT
--   is not used here; the application layer handles the null-section conflict check.
CREATE UNIQUE INDEX IF NOT EXISTS "staff_subject_assignments_unique_idx"
    ON "staff_subject_assignments" ("school_id", "staff_id", "class_id", "section_id", "subject", "academic_year");

-- CreateIndex: standard lookup indexes
CREATE INDEX IF NOT EXISTS "staff_subject_assignments_school_id_idx"
    ON "staff_subject_assignments" ("school_id");

CREATE INDEX IF NOT EXISTS "staff_subject_assignments_staff_id_idx"
    ON "staff_subject_assignments" ("staff_id");

CREATE INDEX IF NOT EXISTS "staff_subject_assignments_class_id_idx"
    ON "staff_subject_assignments" ("class_id");

-- AddForeignKey: school_id → schools
ALTER TABLE "staff_subject_assignments"
    ADD CONSTRAINT "staff_subject_assignments_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff_id → staff
ALTER TABLE "staff_subject_assignments"
    ADD CONSTRAINT "staff_subject_assignments_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: class_id → school_classes
ALTER TABLE "staff_subject_assignments"
    ADD CONSTRAINT "staff_subject_assignments_class_id_fkey"
    FOREIGN KEY ("class_id") REFERENCES "school_classes"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: section_id → sections
ALTER TABLE "staff_subject_assignments"
    ADD CONSTRAINT "staff_subject_assignments_section_id_fkey"
    FOREIGN KEY ("section_id") REFERENCES "sections"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
