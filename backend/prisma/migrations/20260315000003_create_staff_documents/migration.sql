-- Migration: 20260315000003_create_staff_documents
-- Created: 2026-03-15
-- Description: Creates the staff_documents table to store metadata for HR documents
--   (Aadhaar, PAN, degree certificates, experience letters, etc.) associated with
--   each staff member. Actual files are stored in cloud storage; only URLs are saved here.

-- CreateTable: staff_documents
CREATE TABLE IF NOT EXISTS "staff_documents" (
    "id"            UUID          NOT NULL DEFAULT gen_random_uuid(),
    "school_id"     UUID          NOT NULL,
    "staff_id"      UUID          NOT NULL,
    "uploaded_by"   UUID          NOT NULL,
    "verified_by"   UUID,
    "document_type" VARCHAR(50)   NOT NULL,
    "document_name" VARCHAR(255)  NOT NULL,
    "file_url"      TEXT          NOT NULL,
    "file_size_kb"  INTEGER,
    "mime_type"     VARCHAR(100),
    "verified"      BOOLEAN       NOT NULL DEFAULT false,
    "verified_at"   TIMESTAMPTZ(6),
    "deleted_at"    TIMESTAMPTZ(6),
    "created_at"    TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_documents_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "staff_documents_school_id_idx"
    ON "staff_documents" ("school_id");

CREATE INDEX IF NOT EXISTS "staff_documents_staff_id_idx"
    ON "staff_documents" ("staff_id");

-- AddForeignKey: school_id → schools
ALTER TABLE "staff_documents"
    ADD CONSTRAINT "staff_documents_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: staff_id → staff
ALTER TABLE "staff_documents"
    ADD CONSTRAINT "staff_documents_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: uploaded_by → users
ALTER TABLE "staff_documents"
    ADD CONSTRAINT "staff_documents_uploaded_by_fkey"
    FOREIGN KEY ("uploaded_by") REFERENCES "users"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: verified_by → users
ALTER TABLE "staff_documents"
    ADD CONSTRAINT "staff_documents_verified_by_fkey"
    FOREIGN KEY ("verified_by") REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
