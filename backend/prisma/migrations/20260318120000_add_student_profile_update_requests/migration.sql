-- Migration: 20260318120000_add_student_profile_update_requests
-- Created: 2026-03-18

-- CreateEnum
CREATE TYPE "profile_update_status_enum" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateTable
CREATE TABLE "student_profile_update_requests" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "requested_by_parent_id" UUID NOT NULL,
    "status" "profile_update_status_enum" NOT NULL DEFAULT 'PENDING',
    "requested_changes" JSONB NOT NULL,
    "current_values" JSONB NOT NULL,
    "review_note" TEXT,
    "reviewed_by_user_id" UUID,
    "reviewed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "student_profile_update_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "student_profile_update_requests_school_id_status_idx" ON "student_profile_update_requests"("school_id", "status");

-- CreateIndex
CREATE INDEX "student_profile_update_requests_student_id_idx" ON "student_profile_update_requests"("student_id");

-- CreateIndex
CREATE INDEX "student_profile_update_requests_requested_by_parent_id_idx" ON "student_profile_update_requests"("requested_by_parent_id");

-- AddForeignKey
ALTER TABLE "student_profile_update_requests" ADD CONSTRAINT "student_profile_update_requests_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_profile_update_requests" ADD CONSTRAINT "student_profile_update_requests_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_profile_update_requests" ADD CONSTRAINT "student_profile_update_requests_requested_by_parent_id_fkey" FOREIGN KEY ("requested_by_parent_id") REFERENCES "parents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_profile_update_requests" ADD CONSTRAINT "student_profile_update_requests_reviewed_by_user_id_fkey" FOREIGN KEY ("reviewed_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
