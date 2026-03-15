-- Migration: 20260314100000_expand_school_groups
-- Expands the school_groups table with full group management fields,
-- adds a group_admin relation to users, seeds the group_admin role,
-- and creates supporting indexes.

-- ─── Step 1: Create GroupStatus enum ─────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'group_status'
    ) THEN
        CREATE TYPE "group_status" AS ENUM ('ACTIVE', 'INACTIVE');
    END IF;
END $$;

-- ─── Step 2: Add new columns to school_groups ─────────────────────────────────

ALTER TABLE "school_groups"
    ADD COLUMN IF NOT EXISTS "slug"              VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "type"              VARCHAR(50),
    ADD COLUMN IF NOT EXISTS "description"       TEXT,
    ADD COLUMN IF NOT EXISTS "contact_person"    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS "contact_email"     VARCHAR(255),
    ADD COLUMN IF NOT EXISTS "contact_phone"     VARCHAR(20),
    ADD COLUMN IF NOT EXISTS "logo_url"          TEXT,
    ADD COLUMN IF NOT EXISTS "address"           TEXT,
    ADD COLUMN IF NOT EXISTS "city"              VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "state"             VARCHAR(100),
    ADD COLUMN IF NOT EXISTS "country"           VARCHAR(100) DEFAULT 'India',
    ADD COLUMN IF NOT EXISTS "status"            "group_status" DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS "group_admin_user_id" UUID,
    ADD COLUMN IF NOT EXISTS "deleted_at"        TIMESTAMPTZ;

-- ─── Step 3: Partial unique index on slug (only where slug IS NOT NULL) ───────
CREATE UNIQUE INDEX IF NOT EXISTS "school_groups_slug_key"
    ON "school_groups"("slug")
    WHERE slug IS NOT NULL;

-- ─── Step 4: Foreign key from school_groups.group_admin_user_id → users.id ───
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'school_groups_group_admin_user_id_fkey'
          AND table_name = 'school_groups'
    ) THEN
        ALTER TABLE "school_groups"
            ADD CONSTRAINT "school_groups_group_admin_user_id_fkey"
            FOREIGN KEY ("group_admin_user_id")
            REFERENCES "users"("id")
            ON DELETE SET NULL
            ON UPDATE CASCADE;
    END IF;
END $$;

-- ─── Step 5: Seed group_admin role ────────────────────────────────────────────
-- The roles table has a `scope` column (RoleScope enum: GLOBAL | SCHOOL).
-- Cast via text to avoid dependency on enum value ordering.
INSERT INTO "roles" ("name", "description", "scope")
VALUES (
    'group_admin',
    'Group administrator overseeing multiple schools',
    'GLOBAL'::"roles_scope_enum"
)
ON CONFLICT (name) DO NOTHING;

-- ─── Step 6: Partial index on status for non-deleted groups ───────────────────
CREATE INDEX IF NOT EXISTS "school_groups_status_idx"
    ON "school_groups"("status")
    WHERE deleted_at IS NULL;
