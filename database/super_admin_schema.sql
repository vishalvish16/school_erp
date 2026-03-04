-- =============================================================================
-- SUPER ADMIN (PLATFORM LEVEL) SCHEMA
-- Multi-Tenant School ERP SaaS Platform
-- PostgreSQL Production-Ready Script
-- Generated: 2026-02-21
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- ENUM TYPES
-- ---------------------------------------------------------------------------

DO $$ BEGIN
    CREATE TYPE organization_type_enum AS ENUM (
        'trust',
        'private_chain',
        'franchise',
        'independent'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE organization_status_enum AS ENUM (
        'active',
        'suspended',
        'inactive'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE school_status_enum AS ENUM (
        'active',
        'suspended',
        'inactive'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE billing_cycle_enum AS ENUM (
        'monthly',
        'yearly'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE subscription_plan_status_enum AS ENUM (
        'active',
        'inactive'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE platform_user_role_enum AS ENUM (
        'super_admin',
        'support_admin',
        'finance_admin',
        'read_only'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE platform_user_status_enum AS ENUM (
        'active',
        'inactive',
        'locked'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE audit_action_enum AS ENUM (
        'create',
        'update',
        'delete',
        'suspend',
        'activate'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- TABLE: subscription_plans
-- (defined before schools due to FK dependency)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS subscription_plans (
    id                  UUID                        NOT NULL DEFAULT gen_random_uuid(),
    name                VARCHAR(150)                NOT NULL,
    price_per_student   NUMERIC(10, 2)              NOT NULL CHECK (price_per_student >= 0),
    currency            CHAR(3)                     NOT NULL DEFAULT 'USD',
    billing_cycle       billing_cycle_enum          NOT NULL,
    student_limit       INTEGER                     NOT NULL CHECK (student_limit > 0),
    features_json       JSONB                       NOT NULL DEFAULT '{}',
    status              subscription_plan_status_enum NOT NULL DEFAULT 'active',
    created_at          TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_subscription_plans PRIMARY KEY (id),
    CONSTRAINT uq_subscription_plans_name UNIQUE (name)
);

-- Indexes: subscription_plans
CREATE INDEX IF NOT EXISTS idx_subscription_plans_status
    ON subscription_plans (status);

-- ---------------------------------------------------------------------------
-- TABLE: organizations
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS organizations (
    id                  UUID                        NOT NULL DEFAULT gen_random_uuid(),
    name                VARCHAR(255)                NOT NULL,
    type                organization_type_enum      NOT NULL,
    head_office_address TEXT                        NOT NULL,
    contact_email       VARCHAR(255)                NOT NULL,
    contact_phone       VARCHAR(30)                 NOT NULL,
    country             VARCHAR(100)                NOT NULL,
    timezone            VARCHAR(100)                NOT NULL DEFAULT 'UTC',
    status              organization_status_enum    NOT NULL DEFAULT 'active',
    created_at          TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP WITH TIME ZONE    NULL,

    CONSTRAINT pk_organizations PRIMARY KEY (id),
    CONSTRAINT uq_organizations_contact_email UNIQUE (contact_email),
    CONSTRAINT chk_organizations_contact_email CHECK (contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- Indexes: organizations
CREATE INDEX IF NOT EXISTS idx_organizations_status
    ON organizations (status);

CREATE INDEX IF NOT EXISTS idx_organizations_deleted_at
    ON organizations (deleted_at)
    WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- TABLE: schools
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS schools (
    id                      UUID                    NOT NULL DEFAULT gen_random_uuid(),
    organization_id         UUID                    NULL,
    name                    VARCHAR(255)            NOT NULL,
    code                    VARCHAR(50)             NOT NULL,
    address                 TEXT                    NOT NULL,
    city                    VARCHAR(100)            NOT NULL,
    state                   VARCHAR(100)            NOT NULL,
    country                 VARCHAR(100)            NOT NULL,
    timezone                VARCHAR(100)            NOT NULL DEFAULT 'UTC',
    subscription_plan_id    UUID                    NOT NULL,
    max_students            INTEGER                 NOT NULL CHECK (max_students > 0),
    current_student_count   INTEGER                 NOT NULL DEFAULT 0 CHECK (current_student_count >= 0),
    status                  school_status_enum      NOT NULL DEFAULT 'active',
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMP WITH TIME ZONE NULL,

    CONSTRAINT pk_schools PRIMARY KEY (id),
    CONSTRAINT uq_schools_code UNIQUE (code),
    CONSTRAINT fk_schools_organization_id
        FOREIGN KEY (organization_id)
        REFERENCES organizations (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_schools_subscription_plan_id
        FOREIGN KEY (subscription_plan_id)
        REFERENCES subscription_plans (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_schools_current_student_count
        CHECK (current_student_count <= max_students)
);

-- Indexes: schools
CREATE INDEX IF NOT EXISTS idx_schools_organization_id
    ON schools (organization_id);

CREATE INDEX IF NOT EXISTS idx_schools_status
    ON schools (status);

CREATE INDEX IF NOT EXISTS idx_schools_code
    ON schools (code);

CREATE INDEX IF NOT EXISTS idx_schools_subscription_plan_id
    ON schools (subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_schools_deleted_at
    ON schools (deleted_at)
    WHERE deleted_at IS NULL;

-- Composite index: frequently filtered by organization + status
CREATE INDEX IF NOT EXISTS idx_schools_organization_id_status
    ON schools (organization_id, status);

-- ---------------------------------------------------------------------------
-- TABLE: platform_users
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS platform_users (
    id              UUID                        NOT NULL DEFAULT gen_random_uuid(),
    name            VARCHAR(255)                NOT NULL,
    email           VARCHAR(255)                NOT NULL,
    password_hash   TEXT                        NOT NULL,
    role            platform_user_role_enum     NOT NULL DEFAULT 'read_only',
    status          platform_user_status_enum   NOT NULL DEFAULT 'active',
    last_login_at   TIMESTAMP WITH TIME ZONE    NULL,
    created_at      TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP WITH TIME ZONE    NULL,

    CONSTRAINT pk_platform_users PRIMARY KEY (id),
    CONSTRAINT uq_platform_users_email UNIQUE (email),
    CONSTRAINT chk_platform_users_email CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- Indexes: platform_users
CREATE INDEX IF NOT EXISTS idx_platform_users_email
    ON platform_users (email);

CREATE INDEX IF NOT EXISTS idx_platform_users_status
    ON platform_users (status);

CREATE INDEX IF NOT EXISTS idx_platform_users_role
    ON platform_users (role);

CREATE INDEX IF NOT EXISTS idx_platform_users_deleted_at
    ON platform_users (deleted_at)
    WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- TABLE: audit_logs
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS audit_logs (
    id              UUID                        NOT NULL DEFAULT gen_random_uuid(),
    user_id         UUID                        NOT NULL,
    entity_type     VARCHAR(100)                NOT NULL,
    entity_id       UUID                        NOT NULL,
    action          audit_action_enum           NOT NULL,
    metadata_json   JSONB                       NOT NULL DEFAULT '{}',
    ip_address      INET                        NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_audit_logs PRIMARY KEY (id),
    CONSTRAINT fk_audit_logs_user_id
        FOREIGN KEY (user_id)
        REFERENCES platform_users (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Indexes: audit_logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id
    ON audit_logs (user_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at
    ON audit_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type
    ON audit_logs (entity_type);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_id
    ON audit_logs (entity_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action
    ON audit_logs (action);

-- Composite index: common query pattern — filter by user + time range
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id_created_at
    ON audit_logs (user_id, created_at DESC);

-- Composite index: entity lookup
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type_entity_id
    ON audit_logs (entity_type, entity_id);

-- ---------------------------------------------------------------------------
-- TRIGGER FUNCTION: auto-update updated_at on row modification
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Attach trigger to: subscription_plans
DROP TRIGGER IF EXISTS trg_subscription_plans_updated_at ON subscription_plans;
CREATE TRIGGER trg_subscription_plans_updated_at
    BEFORE UPDATE ON subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Attach trigger to: organizations
DROP TRIGGER IF EXISTS trg_organizations_updated_at ON organizations;
CREATE TRIGGER trg_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Attach trigger to: schools
DROP TRIGGER IF EXISTS trg_schools_updated_at ON schools;
CREATE TRIGGER trg_schools_updated_at
    BEFORE UPDATE ON schools
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Attach trigger to: platform_users
DROP TRIGGER IF EXISTS trg_platform_users_updated_at ON platform_users;
CREATE TRIGGER trg_platform_users_updated_at
    BEFORE UPDATE ON platform_users
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- ---------------------------------------------------------------------------
-- COMMENTS (table-level documentation)
-- ---------------------------------------------------------------------------

COMMENT ON TABLE subscription_plans   IS 'SaaS subscription tiers available for schools on the platform.';
COMMENT ON TABLE organizations        IS 'Top-level tenant groups (trusts, chains, franchises) owning one or more schools.';
COMMENT ON TABLE schools              IS 'Individual school tenants registered on the platform.';
COMMENT ON TABLE platform_users       IS 'Super-admin-level users with platform-wide access control.';
COMMENT ON TABLE audit_logs           IS 'Immutable audit trail of all platform-level actions performed by platform users.';

COMMENT ON COLUMN organizations.deleted_at      IS 'Soft delete marker; NULL means the record is active.';
COMMENT ON COLUMN schools.deleted_at            IS 'Soft delete marker; NULL means the record is active.';
COMMENT ON COLUMN platform_users.deleted_at     IS 'Soft delete marker; NULL means the record is active.';
COMMENT ON COLUMN audit_logs.metadata_json      IS 'Arbitrary before/after state or additional context stored as JSON.';
COMMENT ON COLUMN schools.current_student_count IS 'Denormalised counter kept in sync by application logic or triggers.';

COMMIT;

-- =============================================================================
-- END OF SUPER ADMIN SCHEMA
-- =============================================================================
