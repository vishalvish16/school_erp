-- Migration: 20260315180000_fix_sections_fk
-- Fixes sections FK constraint that may reference wrong table (e.g. classes vs school_classes).
-- Ensures class_id references school_classes.

-- Drop all FK constraints on sections that involve class_id (by iterating)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT c.conname
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey) AND NOT a.attisdropped
        WHERE c.conrelid = 'public.sections'::regclass
          AND c.contype = 'f'
          AND a.attname = 'class_id'
    ) LOOP
        EXECUTE format('ALTER TABLE sections DROP CONSTRAINT IF EXISTS %I', r.conname);
    END LOOP;
END $$;

-- Fallback: drop by known names (Prisma/legacy may use different names)
ALTER TABLE "sections" DROP CONSTRAINT IF EXISTS "sections_class_id_fkey";
ALTER TABLE "sections" DROP CONSTRAINT IF EXISTS "FK_27db91d7369af6f181412afa99f";

-- Re-add correct FK to school_classes
ALTER TABLE "sections"
    ADD CONSTRAINT "sections_class_id_fkey"
    FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
