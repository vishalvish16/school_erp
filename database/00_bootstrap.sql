-- =============================================================================
-- FILE: 00_bootstrap.sql
-- PURPOSE: Database bootstrap — create DB, roles, extensions, schema, search_path
-- ENGINE: PostgreSQL 15+
-- PROJECT: Multi-Tenant School ERP SaaS Platform
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (as superuser, e.g. postgres):
--   psql -U postgres -f 00_bootstrap.sql
-- =============================================================================


-- =============================================================================
-- STEP 1 — CREATE APPLICATION ROLES
-- =============================================================================
-- Run as superuser (postgres). Roles are cluster-level objects.

DO $$
BEGIN
    -- Owner / migration role
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'school_erp_owner') THEN
        CREATE ROLE school_erp_owner
            NOINHERIT
            NOCREATEDB
            NOCREATEROLE
            LOGIN
            PASSWORD 'CHANGE_ME_OWNER';          -- ← replace before production deploy
    END IF;

    -- Application runtime role (API server connects as this)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'school_erp_app') THEN
        CREATE ROLE school_erp_app
            NOINHERIT
            NOCREATEDB
            NOCREATEROLE
            LOGIN
            PASSWORD 'CHANGE_ME_APP';             -- ← replace before production deploy
    END IF;

    -- Read-only analytics / reporting role
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'school_erp_readonly') THEN
        CREATE ROLE school_erp_readonly
            NOINHERIT
            NOCREATEDB
            NOCREATEROLE
            LOGIN
            PASSWORD 'CHANGE_ME_READONLY';        -- ← replace before production deploy
    END IF;
END
$$;


-- =============================================================================
-- STEP 2 — CREATE DATABASE
-- =============================================================================
-- NOTE: CREATE DATABASE cannot run inside a transaction block and cannot
--       be called if you are already connected to the target DB.
--       Execute this manually or via a CI step, then re-connect.

-- Run this line in psql as superuser BEFORE connecting to the new DB:
--   CREATE DATABASE school_erp_saas
--       WITH
--       OWNER           = school_erp_owner
--       ENCODING        = 'UTF8'
--       LC_COLLATE      = 'en_US.UTF-8'
--       LC_CTYPE        = 'en_US.UTF-8'
--       TEMPLATE        = template0
--       CONNECTION LIMIT = -1;

-- After creation, connect to the new database:
--   \c school_erp_saas


-- =============================================================================
-- STEP 3 — EXTENSIONS  (must be superuser or have CREATE privilege on DB)
-- =============================================================================
-- Connect to school_erp_saas before running below.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp"   WITH SCHEMA public;   -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pgcrypto"    WITH SCHEMA public;   -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS "pg_trgm"     WITH SCHEMA public;   -- trigram indexes for ILIKE search
CREATE EXTENSION IF NOT EXISTS "btree_gist"  WITH SCHEMA public;   -- GiST indexes on scalar types


-- =============================================================================
-- STEP 4 — CREATE PLATFORM SCHEMA
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS platform
    AUTHORIZATION school_erp_owner;

COMMENT ON SCHEMA platform IS
    'SaaS platform-level namespace: organisations, schools, subscriptions, platform users, and audit.';


-- =============================================================================
-- STEP 5 — SET search_path
-- =============================================================================
-- Database-level default (persists for all new connections):

ALTER DATABASE school_erp_saas
    SET search_path TO platform, public;

-- Role-level overrides (so the app role always resolves platform objects first):

ALTER ROLE school_erp_owner   IN DATABASE school_erp_saas SET search_path TO platform, public;
ALTER ROLE school_erp_app     IN DATABASE school_erp_saas SET search_path TO platform, public;
ALTER ROLE school_erp_readonly IN DATABASE school_erp_saas SET search_path TO platform, public;

-- Also set it for this current session:
SET search_path TO platform, public;


-- =============================================================================
-- STEP 6 — SCHEMA-LEVEL PRIVILEGE GRANTS
-- =============================================================================

-- Owner has full control already via AUTHORIZATION above.

-- App role: USAGE on schema + object-level grants come after tables are created.
GRANT USAGE ON SCHEMA platform TO school_erp_app;
GRANT USAGE ON SCHEMA platform TO school_erp_readonly;

-- Future objects automatically inherit grants:
ALTER DEFAULT PRIVILEGES FOR ROLE school_erp_owner IN SCHEMA platform
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO school_erp_app;

ALTER DEFAULT PRIVILEGES FOR ROLE school_erp_owner IN SCHEMA platform
    GRANT USAGE, SELECT ON SEQUENCES TO school_erp_app;

ALTER DEFAULT PRIVILEGES FOR ROLE school_erp_owner IN SCHEMA platform
    GRANT SELECT ON TABLES TO school_erp_readonly;

ALTER DEFAULT PRIVILEGES FOR ROLE school_erp_owner IN SCHEMA platform
    GRANT USAGE, SELECT ON SEQUENCES TO school_erp_readonly;


-- =============================================================================
-- STEP 7 — SHARED UTILITY FUNCTION: updated_at auto-maintenance
-- =============================================================================
-- Created once here in public so every schema can reference it.

CREATE OR REPLACE FUNCTION public.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.fn_set_updated_at() IS
    'Generic BEFORE UPDATE trigger function that stamps updated_at with the current timestamp.';


-- =============================================================================
-- STEP 8 — SHARED UTILITY FUNCTION: soft-delete guard
-- =============================================================================
-- Prevents hard-DELETE on tables that use soft-delete (deleted_at col).
-- Attach per table if hard deletes must be blocked at DB level.

CREATE OR REPLACE FUNCTION public.fn_block_hard_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RAISE EXCEPTION
        'Hard DELETE is disabled on table %. Set deleted_at instead.',
        TG_TABLE_NAME
        USING ERRCODE = 'restrict_violation';
    RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.fn_block_hard_delete() IS
    'Trigger function that raises an error when a hard DELETE is attempted on a soft-delete table.';


-- =============================================================================
-- BOOTSTRAP COMPLETE
-- =============================================================================
-- Next step: run  01_platform_schema.sql  to create all platform-level tables.
-- =============================================================================
