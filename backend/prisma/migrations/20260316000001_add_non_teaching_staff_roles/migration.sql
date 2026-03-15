-- Migration: 20260316000001_add_non_teaching_staff_roles
-- Created: 2026-03-16
-- Description: Creates the staff_role_category_enum and non_teaching_staff_roles table
--              with 15 seeded system roles covering Finance, Library, Laboratory,
--              Admin Support, and General categories.

-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "staff_role_category_enum" AS ENUM (
    'FINANCE',
    'LIBRARY',
    'LABORATORY',
    'ADMIN_SUPPORT',
    'GENERAL'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "non_teaching_staff_roles" (
    "id"           UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"    UUID,
    "code"         VARCHAR(50)  NOT NULL,
    "display_name" VARCHAR(100) NOT NULL,
    "category"     "staff_role_category_enum" NOT NULL,
    "is_system"    BOOLEAN      NOT NULL DEFAULT false,
    "description"  TEXT,
    "is_active"    BOOLEAN      NOT NULL DEFAULT true,
    "created_at"   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "updated_at"   TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT "non_teaching_staff_roles_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: school_id lookup
CREATE INDEX IF NOT EXISTS "non_teaching_staff_roles_school_id_idx"
    ON "non_teaching_staff_roles"("school_id");

-- CreateIndex: unique code per school (partial — only enforced when school_id is NOT NULL;
-- system roles with school_id = NULL are unique-checked at the application layer)
CREATE UNIQUE INDEX IF NOT EXISTS "non_teaching_staff_roles_school_id_code_key"
    ON "non_teaching_staff_roles"("school_id", "code")
    WHERE "school_id" IS NOT NULL;

-- AddForeignKey: optional link to a school (nullable for system roles)
ALTER TABLE "non_teaching_staff_roles"
    ADD CONSTRAINT "non_teaching_staff_roles_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE
    NOT VALID;

-- Seed: 15 system roles (idempotent — safe to re-run)
INSERT INTO "non_teaching_staff_roles"
    ("id", "school_id", "code", "display_name", "category", "is_system", "is_active", "created_at", "updated_at")
VALUES
    (gen_random_uuid(), NULL, 'CLERK',                 'Clerk',                   'FINANCE',       true, true, now(), now()),
    (gen_random_uuid(), NULL, 'ACCOUNTANT',            'Accountant',              'FINANCE',       true, true, now(), now()),
    (gen_random_uuid(), NULL, 'CASHIER',               'Cashier',                 'FINANCE',       true, true, now(), now()),
    (gen_random_uuid(), NULL, 'FINANCE_OFFICER',       'Finance Officer',         'FINANCE',       true, true, now(), now()),
    (gen_random_uuid(), NULL, 'LIBRARIAN',             'Librarian',               'LIBRARY',       true, true, now(), now()),
    (gen_random_uuid(), NULL, 'ASST_LIBRARIAN',        'Assistant Librarian',     'LIBRARY',       true, true, now(), now()),
    (gen_random_uuid(), NULL, 'LAB_ASSISTANT',         'Lab Assistant',           'LABORATORY',    true, true, now(), now()),
    (gen_random_uuid(), NULL, 'LAB_TECHNICIAN',        'Lab Technician',          'LABORATORY',    true, true, now(), now()),
    (gen_random_uuid(), NULL, 'RECEPTIONIST',          'Receptionist',            'ADMIN_SUPPORT', true, true, now(), now()),
    (gen_random_uuid(), NULL, 'PEON',                  'Peon',                    'ADMIN_SUPPORT', true, true, now(), now()),
    (gen_random_uuid(), NULL, 'SECURITY',              'Security Guard',          'ADMIN_SUPPORT', true, true, now(), now()),
    (gen_random_uuid(), NULL, 'STORE_KEEPER',          'Store Keeper',            'ADMIN_SUPPORT', true, true, now(), now()),
    (gen_random_uuid(), NULL, 'IT_ADMIN',              'IT Administrator',        'ADMIN_SUPPORT', true, true, now(), now()),
    (gen_random_uuid(), NULL, 'TRANSPORT_COORDINATOR', 'Transport Coordinator',   'ADMIN_SUPPORT', true, true, now(), now()),
    (gen_random_uuid(), NULL, 'OTHER',                 'Other',                   'GENERAL',       true, true, now(), now())
ON CONFLICT DO NOTHING;
