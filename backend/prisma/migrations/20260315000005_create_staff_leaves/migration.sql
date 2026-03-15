-- Migration: 20260315000005_create_staff_leaves
-- Created: 2026-03-15
-- Description: Creates the staff_leaves table for leave request and approval workflow.
--   Staff apply for leave; school admin approves or rejects. Supports leave types:
--   CASUAL, MEDICAL, EARNED, MATERNITY, PATERNITY, UNPAID, OTHER.

-- CreateTable: staff_leaves
CREATE TABLE IF NOT EXISTS "staff_leaves" (
    "id"           UUID          NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID          NOT NULL,
    "staff_id"     UUID          NOT NULL,
    "applied_by"   UUID          NOT NULL,
    "reviewed_by"  UUID,
    "leave_type"   VARCHAR(30)   NOT NULL,
    "from_date"    DATE          NOT NULL,
    "to_date"      DATE          NOT NULL,
    "total_days"   SMALLINT      NOT NULL,
    "reason"       TEXT          NOT NULL,
    "status"       VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    "reviewed_at"  TIMESTAMPTZ(6),
    "admin_remark" TEXT,
    "created_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_leaves_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "staff_leaves_school_id_idx"
    ON "staff_leaves" ("school_id");

CREATE INDEX IF NOT EXISTS "staff_leaves_staff_id_idx"
    ON "staff_leaves" ("staff_id");

CREATE INDEX IF NOT EXISTS "staff_leaves_school_id_status_idx"
    ON "staff_leaves" ("school_id", "status");

CREATE INDEX IF NOT EXISTS "staff_leaves_school_id_from_date_idx"
    ON "staff_leaves" ("school_id", "from_date");

-- AddForeignKey: school_id → schools
ALTER TABLE "staff_leaves"
    ADD CONSTRAINT "staff_leaves_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff_id → staff
ALTER TABLE "staff_leaves"
    ADD CONSTRAINT "staff_leaves_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: applied_by → users
ALTER TABLE "staff_leaves"
    ADD CONSTRAINT "staff_leaves_applied_by_fkey"
    FOREIGN KEY ("applied_by") REFERENCES "users"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: reviewed_by → users
ALTER TABLE "staff_leaves"
    ADD CONSTRAINT "staff_leaves_reviewed_by_fkey"
    FOREIGN KEY ("reviewed_by") REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
