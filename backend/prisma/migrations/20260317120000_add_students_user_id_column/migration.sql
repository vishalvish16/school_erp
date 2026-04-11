-- Migration: 20260317120000_add_students_user_id_column
-- Fix: Add user_id column to students if missing (Prisma schema expects it for Student Portal)
-- Safe to run: uses IF NOT EXISTS

-- Add user_id column (nullable UUID, unique)
ALTER TABLE "students"
    ADD COLUMN IF NOT EXISTS "user_id" UUID;

-- Create unique index if not exists
CREATE UNIQUE INDEX IF NOT EXISTS "students_user_id_key" ON "students"("user_id");

-- Add foreign key if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_user_id_fkey') THEN
        ALTER TABLE "students"
            ADD CONSTRAINT "students_user_id_fkey"
            FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

-- Create index if not exists
CREATE INDEX IF NOT EXISTS "students_user_id_idx" ON "students"("user_id");
