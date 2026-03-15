-- Migration: 20260316000004_add_non_teaching_staff_leaves
-- Created: 2026-03-16
-- Description: Creates the non_teaching_staff_leaves table for leave application and
--              approval workflow for non-teaching staff. Status lifecycle:
--              PENDING -> APPROVED | REJECTED | CANCELLED.
-- Depends on: 20260316000002_add_non_teaching_staff

-- CreateTable
CREATE TABLE IF NOT EXISTS "non_teaching_staff_leaves" (
    "id"           UUID        NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID        NOT NULL,
    "staff_id"     UUID        NOT NULL,
    "applied_by"   UUID        NOT NULL,
    "reviewed_by"  UUID,
    "leave_type"   VARCHAR(30) NOT NULL,
    "from_date"    DATE        NOT NULL,
    "to_date"      DATE        NOT NULL,
    "total_days"   SMALLINT    NOT NULL,
    "reason"       TEXT        NOT NULL,
    "status"       VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "reviewed_at"  TIMESTAMPTZ,
    "admin_remark" TEXT,
    "created_at"   TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updated_at"   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT "non_teaching_staff_leaves_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: all leaves for a school (admin dashboard view)
CREATE INDEX IF NOT EXISTS "nt_leaves_school_id_idx"
    ON "non_teaching_staff_leaves"("school_id");

-- CreateIndex: leave history per staff member
CREATE INDEX IF NOT EXISTS "nt_leaves_staff_id_idx"
    ON "non_teaching_staff_leaves"("staff_id");

-- CreateIndex: pending/approved/rejected filter
CREATE INDEX IF NOT EXISTS "nt_leaves_school_id_status_idx"
    ON "non_teaching_staff_leaves"("school_id", "status");

-- CreateIndex: date-range queries for calendar views
CREATE INDEX IF NOT EXISTS "nt_leaves_school_id_from_date_idx"
    ON "non_teaching_staff_leaves"("school_id", "from_date");

-- AddForeignKey: tenant isolation
ALTER TABLE "non_teaching_staff_leaves"
    ADD CONSTRAINT "nt_leaves_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff member the leave belongs to
ALTER TABLE "non_teaching_staff_leaves"
    ADD CONSTRAINT "nt_leaves_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "non_teaching_staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: user who submitted the leave application (RESTRICT to preserve audit)
ALTER TABLE "non_teaching_staff_leaves"
    ADD CONSTRAINT "nt_leaves_applied_by_fkey"
    FOREIGN KEY ("applied_by") REFERENCES "users"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: reviewer (admin/principal) — nullable until reviewed
ALTER TABLE "non_teaching_staff_leaves"
    ADD CONSTRAINT "nt_leaves_reviewed_by_fkey"
    FOREIGN KEY ("reviewed_by") REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
