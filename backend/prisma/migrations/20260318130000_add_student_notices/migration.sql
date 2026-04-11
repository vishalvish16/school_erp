-- Migration: 20260318130000_add_student_notices
-- Created: 2026-03-18

-- CreateEnum
CREATE TYPE "notice_priority_enum" AS ENUM ('NORMAL', 'URGENT');

-- CreateTable
CREATE TABLE "student_notices" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "sent_by_user_id" UUID NOT NULL,
    "target_student" BOOLEAN NOT NULL DEFAULT true,
    "target_parent" BOOLEAN NOT NULL DEFAULT false,
    "subject" VARCHAR(255) NOT NULL,
    "message" TEXT NOT NULL,
    "priority" "notice_priority_enum" NOT NULL DEFAULT 'NORMAL',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "student_notices_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "student_notices_school_id_idx" ON "student_notices"("school_id");

-- CreateIndex
CREATE INDEX "student_notices_student_id_idx" ON "student_notices"("student_id");

-- CreateIndex
CREATE INDEX "student_notices_school_id_student_id_idx" ON "student_notices"("school_id", "student_id");

-- AddForeignKey
ALTER TABLE "student_notices" ADD CONSTRAINT "student_notices_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_notices" ADD CONSTRAINT "student_notices_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_notices" ADD CONSTRAINT "student_notices_sent_by_user_id_fkey" FOREIGN KEY ("sent_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
