-- Migration: 20260318100000_add_student_documents_school_id
-- Fix: Add school_id column to student_documents if missing (schema mismatch)

-- Add school_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'student_documents'
          AND column_name = 'school_id'
    ) THEN
        -- Add as nullable first
        ALTER TABLE "student_documents" ADD COLUMN "school_id" UUID;

        -- Populate from students for existing rows
        UPDATE "student_documents" sd
        SET "school_id" = s."school_id"
        FROM "students" s
        WHERE sd."student_id" = s.id;

        -- Remove orphaned documents (student no longer exists)
        DELETE FROM "student_documents" WHERE "school_id" IS NULL;

        -- Set NOT NULL
        ALTER TABLE "student_documents" ALTER COLUMN "school_id" SET NOT NULL;

        -- Add foreign key
        ALTER TABLE "student_documents"
            ADD CONSTRAINT "student_documents_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

        -- Add index
        CREATE INDEX IF NOT EXISTS "student_documents_school_id_idx" ON "student_documents"("school_id");
    END IF;
END $$;
