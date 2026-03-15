-- Migration: 20260315170000_fix_sections_section_name
-- Fixes legacy sections table: section_name may still be NOT NULL while we use "name".
-- Makes section_name nullable so Prisma inserts (which only set "name") succeed.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sections' AND column_name = 'section_name'
    ) THEN
        UPDATE "sections" SET "section_name" = "name" WHERE "section_name" IS NULL;
        ALTER TABLE "sections" ALTER COLUMN "section_name" DROP NOT NULL;
    END IF;
END $$;
