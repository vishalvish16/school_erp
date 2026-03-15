-- Migration: 20260315200000_add_fee_structures_due_day
-- Adds missing due_day and is_active columns to fee_structures.
-- The preserve_data migration did not add these; Prisma schema expects them.

ALTER TABLE "fee_structures" ADD COLUMN IF NOT EXISTS "due_day" INTEGER;
ALTER TABLE "fee_structures" ADD COLUMN IF NOT EXISTS "is_active" BOOLEAN NOT NULL DEFAULT true;
