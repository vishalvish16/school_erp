-- Migration: 20260315000002_create_staff_qualifications
-- Created: 2026-03-15
-- Description: Creates the staff_qualifications table to store multiple academic
--   and professional qualifications per staff member.

-- CreateTable: staff_qualifications
CREATE TABLE IF NOT EXISTS "staff_qualifications" (
    "id"                  UUID          NOT NULL DEFAULT gen_random_uuid(),
    "school_id"           UUID          NOT NULL,
    "staff_id"            UUID          NOT NULL,
    "degree"              VARCHAR(100)  NOT NULL,
    "institution"         VARCHAR(255)  NOT NULL,
    "board_or_university" VARCHAR(255),
    "year_of_passing"     SMALLINT,
    "grade_or_percentage" VARCHAR(20),
    "is_highest"          BOOLEAN       NOT NULL DEFAULT false,
    "created_at"          TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"          TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_qualifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "staff_qualifications_school_id_idx"
    ON "staff_qualifications" ("school_id");

CREATE INDEX IF NOT EXISTS "staff_qualifications_staff_id_idx"
    ON "staff_qualifications" ("staff_id");

-- AddForeignKey: school_id → schools
ALTER TABLE "staff_qualifications"
    ADD CONSTRAINT "staff_qualifications_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff_id → staff
ALTER TABLE "staff_qualifications"
    ADD CONSTRAINT "staff_qualifications_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
