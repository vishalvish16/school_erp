-- CreateTable
CREATE TABLE "fcm_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "fcm_token" TEXT NOT NULL,
    "portal_type" VARCHAR(20) NOT NULL,
    "parent_id" UUID,
    "student_id" UUID,
    "school_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fcm_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "fcm_tokens_fcm_token_key" ON "fcm_tokens"("fcm_token");

-- CreateIndex
CREATE INDEX "fcm_tokens_parent_id_idx" ON "fcm_tokens"("parent_id");

-- CreateIndex
CREATE INDEX "fcm_tokens_student_id_idx" ON "fcm_tokens"("student_id");

-- CreateIndex
CREATE INDEX "fcm_tokens_school_id_idx" ON "fcm_tokens"("school_id");
