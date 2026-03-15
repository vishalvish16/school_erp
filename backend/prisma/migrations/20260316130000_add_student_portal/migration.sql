-- Migration: 20260316130000_add_student_portal
-- Created: 2026-03-16
-- Student Portal: user_id on students, student_documents table

-- Step 1: Add user_id column to students (nullable UUID, unique)
ALTER TABLE "students"
    ADD COLUMN IF NOT EXISTS "user_id" UUID;

CREATE UNIQUE INDEX IF NOT EXISTS "students_user_id_key" ON "students"("user_id");

-- Step 2: Create student_documents table
CREATE TABLE "student_documents" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "document_type" VARCHAR(50) NOT NULL,
    "document_name" VARCHAR(255) NOT NULL,
    "file_url" TEXT NOT NULL,
    "file_size_kb" INTEGER,
    "mime_type" VARCHAR(100),
    "uploaded_by" UUID NOT NULL,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "verified_at" TIMESTAMPTZ(6),
    "verified_by" UUID,
    "deleted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_documents_pkey" PRIMARY KEY ("id")
);

-- Step 3: Add foreign key students.user_id -> users.id (ON DELETE SET NULL)
ALTER TABLE "students"
    ADD CONSTRAINT "students_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Step 4: Create indexes for students
CREATE INDEX IF NOT EXISTS "students_user_id_idx" ON "students"("user_id");

-- Step 5: Create indexes for student_documents
CREATE INDEX IF NOT EXISTS "student_documents_school_id_idx" ON "student_documents"("school_id");
CREATE INDEX IF NOT EXISTS "student_documents_student_id_idx" ON "student_documents"("student_id");
CREATE INDEX IF NOT EXISTS "student_documents_student_id_deleted_at_idx" ON "student_documents"("student_id", "deleted_at");

-- Step 6: Add foreign keys for student_documents
ALTER TABLE "student_documents"
    ADD CONSTRAINT "student_documents_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_documents"
    ADD CONSTRAINT "student_documents_student_id_fkey"
    FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_documents"
    ADD CONSTRAINT "student_documents_uploaded_by_fkey"
    FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "student_documents"
    ADD CONSTRAINT "student_documents_verified_by_fkey"
    FOREIGN KEY ("verified_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
