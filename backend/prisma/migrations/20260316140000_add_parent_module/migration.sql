-- Migration: 20260316140000_add_parent_module
-- Created: 2026-03-16
-- Parent Portal: parents table, student_parents link table, parentPhone index on students

-- Step 1: Create parents table
CREATE TABLE "parents" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "email" VARCHAR(255),
    "relation" VARCHAR(50),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "deleted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "parents_pkey" PRIMARY KEY ("id")
);

-- Step 2: Create student_parents table
CREATE TABLE "student_parents" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "student_id" UUID NOT NULL,
    "parent_id" UUID NOT NULL,
    "relation" VARCHAR(50) NOT NULL,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_parents_pkey" PRIMARY KEY ("id")
);

-- Step 3: Create unique constraint and indexes for parents
CREATE UNIQUE INDEX "parents_school_id_phone_key" ON "parents"("school_id", "phone");
CREATE INDEX "parents_school_id_idx" ON "parents"("school_id");
CREATE INDEX "parents_phone_idx" ON "parents"("phone");

-- Step 4: Create unique constraint and indexes for student_parents
CREATE UNIQUE INDEX "student_parents_student_id_parent_id_key" ON "student_parents"("student_id", "parent_id");
CREATE INDEX "student_parents_parent_id_idx" ON "student_parents"("parent_id");
CREATE INDEX "student_parents_student_id_idx" ON "student_parents"("student_id");

-- Step 5: Add foreign keys for parents
ALTER TABLE "parents"
    ADD CONSTRAINT "parents_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Step 6: Add foreign keys for student_parents
ALTER TABLE "student_parents"
    ADD CONSTRAINT "student_parents_student_id_fkey"
    FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_parents"
    ADD CONSTRAINT "student_parents_parent_id_fkey"
    FOREIGN KEY ("parent_id") REFERENCES "parents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Step 7: Add index on students.parent_phone for faster lookup
CREATE INDEX IF NOT EXISTS "students_parent_phone_idx" ON "students"("parent_phone");
