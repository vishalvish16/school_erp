-- Migration: 20260316000005_add_non_teaching_docs_and_quals
-- Created: 2026-03-16
-- Description: Creates non_teaching_staff_documents (file attachments with verification)
--              and non_teaching_staff_qualifications (academic credential records) tables.
-- Depends on: 20260316000002_add_non_teaching_staff

-- ─── Documents ───────────────────────────────────────────────────────────────

-- CreateTable
CREATE TABLE IF NOT EXISTS "non_teaching_staff_documents" (
    "id"            UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"     UUID         NOT NULL,
    "staff_id"      UUID         NOT NULL,
    "uploaded_by"   UUID         NOT NULL,
    "verified_by"   UUID,
    "document_type" VARCHAR(50)  NOT NULL,
    "document_name" VARCHAR(255) NOT NULL,
    "file_url"      TEXT         NOT NULL,
    "file_size_kb"  INTEGER,
    "mime_type"     VARCHAR(100),
    "verified"      BOOLEAN      NOT NULL DEFAULT false,
    "verified_at"   TIMESTAMPTZ,
    "deleted_at"    TIMESTAMPTZ,
    "created_at"    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "updated_at"    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT "non_teaching_staff_documents_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: all docs for a school
CREATE INDEX IF NOT EXISTS "nt_docs_school_id_idx"
    ON "non_teaching_staff_documents"("school_id");

-- CreateIndex: docs for a specific staff member
CREATE INDEX IF NOT EXISTS "nt_docs_staff_id_idx"
    ON "non_teaching_staff_documents"("staff_id");

-- AddForeignKey: tenant isolation
ALTER TABLE "non_teaching_staff_documents"
    ADD CONSTRAINT "nt_docs_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff member the document belongs to
ALTER TABLE "non_teaching_staff_documents"
    ADD CONSTRAINT "nt_docs_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "non_teaching_staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: uploader (RESTRICT — preserve who uploaded even if role changes)
ALTER TABLE "non_teaching_staff_documents"
    ADD CONSTRAINT "nt_docs_uploaded_by_fkey"
    FOREIGN KEY ("uploaded_by") REFERENCES "users"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: verifier (SET NULL — if verifier account deleted, doc stays verified)
ALTER TABLE "non_teaching_staff_documents"
    ADD CONSTRAINT "nt_docs_verified_by_fkey"
    FOREIGN KEY ("verified_by") REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ─── Qualifications ──────────────────────────────────────────────────────────

-- CreateTable
CREATE TABLE IF NOT EXISTS "non_teaching_staff_qualifications" (
    "id"                  UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"           UUID         NOT NULL,
    "staff_id"            UUID         NOT NULL,
    "degree"              VARCHAR(100) NOT NULL,
    "institution"         VARCHAR(255) NOT NULL,
    "board_or_university" VARCHAR(255),
    "year_of_passing"     SMALLINT,
    "grade_or_percentage" VARCHAR(20),
    "is_highest"          BOOLEAN      NOT NULL DEFAULT false,
    "created_at"          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "updated_at"          TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT "non_teaching_staff_qualifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: all qualifications for a school
CREATE INDEX IF NOT EXISTS "nt_quals_school_id_idx"
    ON "non_teaching_staff_qualifications"("school_id");

-- CreateIndex: qualifications per staff member
CREATE INDEX IF NOT EXISTS "nt_quals_staff_id_idx"
    ON "non_teaching_staff_qualifications"("staff_id");

-- AddForeignKey: tenant isolation
ALTER TABLE "non_teaching_staff_qualifications"
    ADD CONSTRAINT "nt_quals_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff member the qualification record belongs to
ALTER TABLE "non_teaching_staff_qualifications"
    ADD CONSTRAINT "nt_quals_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "non_teaching_staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
