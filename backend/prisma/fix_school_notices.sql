-- Fix: Create school_notices table if missing (resolves 500 error on Notice Board)
-- Run with: psql $DATABASE_URL -f fix_school_notices.sql
-- Or: npx prisma db execute --file prisma/fix_school_notices.sql

CREATE TABLE IF NOT EXISTS "school_notices" (
    "id"           UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID         NOT NULL,
    "title"        VARCHAR(255) NOT NULL,
    "body"         TEXT         NOT NULL,
    "target_role"  VARCHAR(50),
    "is_pinned"    BOOLEAN      NOT NULL DEFAULT false,
    "published_at" TIMESTAMPTZ(6),
    "expires_at"   TIMESTAMPTZ(6),
    "created_by"   UUID         NOT NULL,
    "deleted_at"   TIMESTAMPTZ(6),
    "created_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"   TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "school_notices_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "school_notices_school_id_idx"
    ON "school_notices"("school_id");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'school_notices_school_id_fkey'
  ) THEN
    ALTER TABLE "school_notices"
    ADD CONSTRAINT "school_notices_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
