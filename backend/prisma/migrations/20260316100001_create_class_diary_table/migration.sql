-- Migration: 20260316100001_create_class_diary_table
-- Created: 2026-03-15

-- CreateTable
CREATE TABLE "class_diary" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "staff_id" UUID NOT NULL,
    "class_id" UUID NOT NULL,
    "section_id" UUID,
    "subject" VARCHAR(100) NOT NULL,
    "date" DATE NOT NULL,
    "period_no" SMALLINT,
    "topic_covered" VARCHAR(500) NOT NULL,
    "description" TEXT,
    "page_from" VARCHAR(20),
    "page_to" VARCHAR(20),
    "homework_given" VARCHAR(500),
    "remarks" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "class_diary_pkey" PRIMARY KEY ("id")
);

-- CreateIndex (unique constraint handles nullable columns via COALESCE)
CREATE UNIQUE INDEX "idx_class_diary_unique"
    ON "class_diary"("school_id", "staff_id", "class_id", COALESCE("section_id", '00000000-0000-0000-0000-000000000000'), "subject", "date", COALESCE("period_no", -1));

CREATE INDEX "idx_class_diary_school" ON "class_diary"("school_id");
CREATE INDEX "idx_class_diary_staff" ON "class_diary"("staff_id");
CREATE INDEX "idx_class_diary_class_section_date" ON "class_diary"("class_id", "section_id", "date");
CREATE INDEX "idx_class_diary_school_date" ON "class_diary"("school_id", "date");

-- AddForeignKey
ALTER TABLE "class_diary" ADD CONSTRAINT "class_diary_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "class_diary" ADD CONSTRAINT "class_diary_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "class_diary" ADD CONSTRAINT "class_diary_class_id_fkey"
    FOREIGN KEY ("class_id") REFERENCES "school_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "class_diary" ADD CONSTRAINT "class_diary_section_id_fkey"
    FOREIGN KEY ("section_id") REFERENCES "sections"("id") ON DELETE SET NULL ON UPDATE CASCADE;
