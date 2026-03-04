-- =============================================================================
-- FILE: 01_platform_schema.sql
-- PURPOSE: Full platform-level table definitions — multi-tenant School ERP SaaS
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql  (schema, extensions, utility functions)
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 01_platform_schema.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- ===========================================================================
-- ENUM TYPES
-- ===========================================================================

DO $$ BEGIN CREATE TYPE platform.organization_type AS ENUM
    ('trust','private_chain','franchise','independent');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.entity_status AS ENUM
    ('active','suspended','inactive');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.billing_cycle AS ENUM
    ('monthly','yearly');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.platform_user_role AS ENUM
    ('super_admin','support_admin','finance_admin','read_only');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.platform_user_status AS ENUM
    ('active','inactive','locked');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.audit_action AS ENUM
    ('create','update','delete','suspend','activate','login','logout','password_change');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.subscription_status AS ENUM
    ('trialing','active','past_due','cancelled','expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE platform.invoice_status AS ENUM
    ('draft','open','paid','void','uncollectible');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ===========================================================================
-- TABLE: subscription_plans
-- Purpose: Define SaaS tiers available on the platform.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.subscription_plans (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    public_id               UUID                            NOT NULL DEFAULT uuid_generate_v4(),
    name                    VARCHAR(150)                    NOT NULL,
    description             TEXT                            NULL,
    price_per_student       NUMERIC(12, 4)                  NOT NULL,
    base_price              NUMERIC(12, 4)                  NOT NULL DEFAULT 0,
    currency                CHAR(3)                         NOT NULL DEFAULT 'USD',
    billing_cycle           platform.billing_cycle          NOT NULL,
    student_limit           INTEGER                         NOT NULL,
    trial_days              SMALLINT                        NOT NULL DEFAULT 0,
    features_json           JSONB                           NOT NULL DEFAULT '{}',
    status                  platform.entity_status          NOT NULL DEFAULT 'active',
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_subscription_plans                    PRIMARY KEY (id),
    CONSTRAINT uq_subscription_plans_public_id          UNIQUE      (public_id),
    CONSTRAINT uq_subscription_plans_name               UNIQUE      (name),
    CONSTRAINT chk_subscription_plans_price             CHECK       (price_per_student >= 0),
    CONSTRAINT chk_subscription_plans_base_price        CHECK       (base_price >= 0),
    CONSTRAINT chk_subscription_plans_student_limit     CHECK       (student_limit > 0),
    CONSTRAINT chk_subscription_plans_trial_days        CHECK       (trial_days >= 0),
    CONSTRAINT chk_subscription_plans_currency          CHECK       (currency ~ '^[A-Z]{3}$')
);

COMMENT ON TABLE  platform.subscription_plans                   IS 'SaaS pricing tiers available for school subscriptions.';
COMMENT ON COLUMN platform.subscription_plans.public_id         IS 'UUID exposed in APIs; internal BIGINT id never leaves the database.';
COMMENT ON COLUMN platform.subscription_plans.features_json     IS 'Key/value feature flags, e.g. {"max_branches":5,"sms_alerts":true}.';

CREATE INDEX IF NOT EXISTS idx_subscription_plans_status
    ON platform.subscription_plans (status);

DROP TRIGGER IF EXISTS trg_subscription_plans_updated_at ON platform.subscription_plans;
CREATE TRIGGER trg_subscription_plans_updated_at
    BEFORE UPDATE ON platform.subscription_plans
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: organizations
-- Purpose: Top-level tenant grouping (trusts, chains, franchises).
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.organizations (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    public_id               UUID                            NOT NULL DEFAULT uuid_generate_v4(),
    name                    VARCHAR(255)                    NOT NULL,
    type                    platform.organization_type      NOT NULL,
    head_office_address     TEXT                            NOT NULL,
    contact_email           VARCHAR(255)                    NOT NULL,
    contact_phone           VARCHAR(30)                     NOT NULL,
    country                 VARCHAR(100)                    NOT NULL,
    state                   VARCHAR(100)                    NULL,
    timezone                VARCHAR(100)                    NOT NULL DEFAULT 'UTC',
    locale                  VARCHAR(20)                     NOT NULL DEFAULT 'en-US',
    logo_url                TEXT                            NULL,
    status                  platform.entity_status          NOT NULL DEFAULT 'active',
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMPTZ                     NULL,

    CONSTRAINT pk_organizations                 PRIMARY KEY (id),
    CONSTRAINT uq_organizations_public_id       UNIQUE      (public_id),
    CONSTRAINT uq_organizations_contact_email   UNIQUE      (contact_email),
    CONSTRAINT chk_organizations_email          CHECK       (contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

COMMENT ON TABLE  platform.organizations            IS 'Top-level multi-tenant group: trusts, chains, or franchise networks.';
COMMENT ON COLUMN platform.organizations.deleted_at IS 'Soft-delete marker. NULL = active.';

CREATE INDEX IF NOT EXISTS idx_organizations_status
    ON platform.organizations (status) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_organizations_country
    ON platform.organizations (country);

CREATE INDEX IF NOT EXISTS idx_organizations_deleted_at
    ON platform.organizations (deleted_at) WHERE deleted_at IS NOT NULL;

DROP TRIGGER IF EXISTS trg_organizations_updated_at ON platform.organizations;
CREATE TRIGGER trg_organizations_updated_at
    BEFORE UPDATE ON platform.organizations
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: schools
-- Purpose: Individual school tenants — the primary isolation unit.
--          school_id is the multi-tenancy key used across ALL child tables.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.schools (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    public_id               UUID                            NOT NULL DEFAULT uuid_generate_v4(),
    organization_id         BIGINT                          NULL,
    subscription_plan_id    BIGINT                          NOT NULL,
    name                    VARCHAR(255)                    NOT NULL,
    code                    VARCHAR(50)                     NOT NULL,
    address                 TEXT                            NOT NULL,
    city                    VARCHAR(100)                    NOT NULL,
    state                   VARCHAR(100)                    NOT NULL,
    country                 VARCHAR(100)                    NOT NULL,
    postal_code             VARCHAR(20)                     NULL,
    timezone                VARCHAR(100)                    NOT NULL DEFAULT 'UTC',
    locale                  VARCHAR(20)                     NOT NULL DEFAULT 'en-US',
    max_students            INTEGER                         NOT NULL,
    current_student_count   INTEGER                         NOT NULL DEFAULT 0,
    logo_url                TEXT                            NULL,
    primary_color           CHAR(7)                         NULL,        -- hex color e.g. #1A73E8
    status                  platform.entity_status          NOT NULL DEFAULT 'active',
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMPTZ                     NULL,

    CONSTRAINT pk_schools                           PRIMARY KEY (id),
    CONSTRAINT uq_schools_public_id                 UNIQUE      (public_id),
    CONSTRAINT uq_schools_code                      UNIQUE      (code),
    CONSTRAINT fk_schools_organization_id
        FOREIGN KEY (organization_id)
        REFERENCES platform.organizations (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_schools_subscription_plan_id
        FOREIGN KEY (subscription_plan_id)
        REFERENCES platform.subscription_plans (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_schools_max_students             CHECK       (max_students > 0),
    CONSTRAINT chk_schools_current_student_count    CHECK       (current_student_count >= 0),
    CONSTRAINT chk_schools_student_cap              CHECK       (current_student_count <= max_students),
    CONSTRAINT chk_schools_primary_color            CHECK       (primary_color ~ '^#[0-9A-Fa-f]{6}$')
);

COMMENT ON TABLE  platform.schools IS
    'Individual school tenants. school_id from this table is the foreign-key anchor across all child modules.';
COMMENT ON COLUMN platform.schools.code IS
    'Short, human-readable unique school identifier used in URLs and reports (e.g. DPS-MUM-01).';

CREATE INDEX IF NOT EXISTS idx_schools_organization_id
    ON platform.schools (organization_id);

CREATE INDEX IF NOT EXISTS idx_schools_subscription_plan_id
    ON platform.schools (subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_schools_status
    ON platform.schools (status) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_schools_code
    ON platform.schools (code);

CREATE INDEX IF NOT EXISTS idx_schools_country
    ON platform.schools (country);

-- Composite: the single most-common multi-tenant filter
CREATE INDEX IF NOT EXISTS idx_schools_org_status
    ON platform.schools (organization_id, status) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_schools_deleted_at
    ON platform.schools (deleted_at) WHERE deleted_at IS NOT NULL;

DROP TRIGGER IF EXISTS trg_schools_updated_at ON platform.schools;
CREATE TRIGGER trg_schools_updated_at
    BEFORE UPDATE ON platform.schools
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: school_subscriptions
-- Purpose: Tracks the active and historical subscription lifecycle per school.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.school_subscriptions (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    public_id               UUID                            NOT NULL DEFAULT uuid_generate_v4(),
    school_id               BIGINT                          NOT NULL,
    plan_id                 BIGINT                          NOT NULL,
    status                  platform.subscription_status    NOT NULL DEFAULT 'trialing',
    trial_ends_at           TIMESTAMPTZ                     NULL,
    current_period_start    TIMESTAMPTZ                     NOT NULL,
    current_period_end      TIMESTAMPTZ                     NOT NULL,
    cancelled_at            TIMESTAMPTZ                     NULL,
    cancel_reason           TEXT                            NULL,
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_school_subscriptions              PRIMARY KEY (id),
    CONSTRAINT uq_school_subscriptions_public_id    UNIQUE      (public_id),
    CONSTRAINT fk_school_subscriptions_school_id
        FOREIGN KEY (school_id)
        REFERENCES platform.schools (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_school_subscriptions_plan_id
        FOREIGN KEY (plan_id)
        REFERENCES platform.subscription_plans (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_school_subscriptions_period
        CHECK (current_period_end > current_period_start)
);

COMMENT ON TABLE platform.school_subscriptions IS
    'Active and historical subscription records per school. One active subscription per school at a time.';

CREATE INDEX IF NOT EXISTS idx_school_subscriptions_school_id
    ON platform.school_subscriptions (school_id);

CREATE INDEX IF NOT EXISTS idx_school_subscriptions_plan_id
    ON platform.school_subscriptions (plan_id);

CREATE INDEX IF NOT EXISTS idx_school_subscriptions_status
    ON platform.school_subscriptions (status);

CREATE INDEX IF NOT EXISTS idx_school_subscriptions_period_end
    ON platform.school_subscriptions (current_period_end);

-- Composite: find currently active subscription for a school
CREATE INDEX IF NOT EXISTS idx_school_subscriptions_school_status
    ON platform.school_subscriptions (school_id, status);

DROP TRIGGER IF EXISTS trg_school_subscriptions_updated_at ON platform.school_subscriptions;
CREATE TRIGGER trg_school_subscriptions_updated_at
    BEFORE UPDATE ON platform.school_subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: invoices
-- Purpose: Per-subscription billing records.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.invoices (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    public_id               UUID                            NOT NULL DEFAULT uuid_generate_v4(),
    school_id               BIGINT                          NOT NULL,
    subscription_id         BIGINT                          NOT NULL,
    invoice_number          VARCHAR(60)                     NOT NULL,
    amount_due              NUMERIC(12, 4)                  NOT NULL,
    amount_paid             NUMERIC(12, 4)                  NOT NULL DEFAULT 0,
    currency                CHAR(3)                         NOT NULL DEFAULT 'USD',
    status                  platform.invoice_status         NOT NULL DEFAULT 'draft',
    billing_period_start    TIMESTAMPTZ                     NOT NULL,
    billing_period_end      TIMESTAMPTZ                     NOT NULL,
    due_date                TIMESTAMPTZ                     NOT NULL,
    paid_at                 TIMESTAMPTZ                     NULL,
    notes                   TEXT                            NULL,
    metadata_json           JSONB                           NOT NULL DEFAULT '{}',
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_invoices                  PRIMARY KEY (id),
    CONSTRAINT uq_invoices_public_id        UNIQUE      (public_id),
    CONSTRAINT uq_invoices_number           UNIQUE      (invoice_number),
    CONSTRAINT fk_invoices_school_id
        FOREIGN KEY (school_id)
        REFERENCES platform.schools (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_invoices_subscription_id
        FOREIGN KEY (subscription_id)
        REFERENCES platform.school_subscriptions (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_invoices_amount_due      CHECK (amount_due >= 0),
    CONSTRAINT chk_invoices_amount_paid     CHECK (amount_paid >= 0),
    CONSTRAINT chk_invoices_currency        CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_invoices_period          CHECK (billing_period_end > billing_period_start)
);

COMMENT ON TABLE platform.invoices IS 'Billing invoices generated per subscription cycle.';

CREATE INDEX IF NOT EXISTS idx_invoices_school_id
    ON platform.invoices (school_id);

CREATE INDEX IF NOT EXISTS idx_invoices_subscription_id
    ON platform.invoices (subscription_id);

CREATE INDEX IF NOT EXISTS idx_invoices_status
    ON platform.invoices (status);

CREATE INDEX IF NOT EXISTS idx_invoices_due_date
    ON platform.invoices (due_date);

CREATE INDEX IF NOT EXISTS idx_invoices_school_status
    ON platform.invoices (school_id, status);

DROP TRIGGER IF EXISTS trg_invoices_updated_at ON platform.invoices;
CREATE TRIGGER trg_invoices_updated_at
    BEFORE UPDATE ON platform.invoices
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: platform_users
-- Purpose: Super-admin layer users — not school staff/students.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.platform_users (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    public_id               UUID                            NOT NULL DEFAULT uuid_generate_v4(),
    name                    VARCHAR(255)                    NOT NULL,
    email                   VARCHAR(255)                    NOT NULL,
    password_hash           TEXT                            NOT NULL,
    role                    platform.platform_user_role     NOT NULL DEFAULT 'read_only',
    status                  platform.platform_user_status   NOT NULL DEFAULT 'active',
    failed_login_attempts   SMALLINT                        NOT NULL DEFAULT 0,
    locked_until            TIMESTAMPTZ                     NULL,
    last_login_at           TIMESTAMPTZ                     NULL,
    last_login_ip           INET                            NULL,
    mfa_enabled             BOOLEAN                         NOT NULL DEFAULT FALSE,
    mfa_secret              TEXT                            NULL,          -- encrypted at app layer
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMPTZ                     NULL,

    CONSTRAINT pk_platform_users                PRIMARY KEY (id),
    CONSTRAINT uq_platform_users_public_id      UNIQUE      (public_id),
    CONSTRAINT uq_platform_users_email          UNIQUE      (email),
    CONSTRAINT chk_platform_users_email         CHECK       (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    CONSTRAINT chk_platform_users_failed_logins CHECK       (failed_login_attempts >= 0)
);

COMMENT ON TABLE  platform.platform_users IS
    'Platform-level administrators. Never school staff or students.';
COMMENT ON COLUMN platform.platform_users.mfa_secret IS
    'TOTP shared secret; stored encrypted at the application layer, never plain-text.';

CREATE INDEX IF NOT EXISTS idx_platform_users_email
    ON platform.platform_users (email) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_platform_users_status
    ON platform.platform_users (status) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_platform_users_role
    ON platform.platform_users (role);

CREATE INDEX IF NOT EXISTS idx_platform_users_deleted_at
    ON platform.platform_users (deleted_at) WHERE deleted_at IS NOT NULL;

DROP TRIGGER IF EXISTS trg_platform_users_updated_at ON platform.platform_users;
CREATE TRIGGER trg_platform_users_updated_at
    BEFORE UPDATE ON platform.platform_users
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: platform_user_sessions
-- Purpose: Active session / refresh-token tracking per platform user.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.platform_user_sessions (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id                 BIGINT                          NOT NULL,
    token_hash              TEXT                            NOT NULL,   -- SHA-256 of refresh token
    ip_address              INET                            NOT NULL,
    user_agent              TEXT                            NULL,
    expires_at              TIMESTAMPTZ                     NOT NULL,
    revoked_at              TIMESTAMPTZ                     NULL,
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_platform_user_sessions            PRIMARY KEY (id),
    CONSTRAINT uq_platform_user_sessions_token      UNIQUE      (token_hash),
    CONSTRAINT fk_platform_user_sessions_user_id
        FOREIGN KEY (user_id)
        REFERENCES platform.platform_users (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

COMMENT ON TABLE platform.platform_user_sessions IS
    'Refresh token tracking for platform users; revoke by setting revoked_at.';

CREATE INDEX IF NOT EXISTS idx_platform_user_sessions_user_id
    ON platform.platform_user_sessions (user_id);

CREATE INDEX IF NOT EXISTS idx_platform_user_sessions_expires_at
    ON platform.platform_user_sessions (expires_at);

-- Active sessions only
CREATE INDEX IF NOT EXISTS idx_platform_user_sessions_active
    ON platform.platform_user_sessions (user_id, expires_at)
    WHERE revoked_at IS NULL;


-- ===========================================================================
-- TABLE: audit_logs
-- Purpose: Immutable, append-only compliance trail for all platform actions.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.audit_logs (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id                 BIGINT                          NOT NULL,
    entity_type             VARCHAR(100)                    NOT NULL,
    entity_id               BIGINT                          NOT NULL,
    action                  platform.audit_action           NOT NULL,
    old_value_json          JSONB                           NULL,
    new_value_json          JSONB                           NULL,
    metadata_json           JSONB                           NOT NULL DEFAULT '{}',
    ip_address              INET                            NOT NULL,
    user_agent              TEXT                            NULL,
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_audit_logs        PRIMARY KEY (id),
    CONSTRAINT fk_audit_logs_user_id
        FOREIGN KEY (user_id)
        REFERENCES platform.platform_users (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE  platform.audit_logs IS
    'Immutable audit trail. No UPDATE or DELETE should ever be issued on this table.';
COMMENT ON COLUMN platform.audit_logs.old_value_json IS 'State of the entity BEFORE the action (for update/delete).';
COMMENT ON COLUMN platform.audit_logs.new_value_json IS 'State of the entity AFTER the action (for create/update).';

-- audit_logs is append-only: block UPDATE and DELETE at DB level
CREATE OR REPLACE RULE audit_logs_no_update AS
    ON UPDATE TO platform.audit_logs DO INSTEAD NOTHING;

CREATE OR REPLACE RULE audit_logs_no_delete AS
    ON DELETE TO platform.audit_logs DO INSTEAD NOTHING;

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id
    ON platform.audit_logs (user_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at
    ON platform.audit_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type
    ON platform.audit_logs (entity_type);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_id
    ON platform.audit_logs (entity_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action
    ON platform.audit_logs (action);

-- Composite: entity drill-down
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type_id
    ON platform.audit_logs (entity_type, entity_id);

-- Composite: user activity timeline
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created
    ON platform.audit_logs (user_id, created_at DESC);

-- Composite: time-range scans across all entities
CREATE INDEX IF NOT EXISTS idx_audit_logs_action_created
    ON platform.audit_logs (action, created_at DESC);


-- ===========================================================================
-- TABLE: system_settings
-- Purpose: Key/value store for global platform configuration.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.system_settings (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    key                     VARCHAR(200)                    NOT NULL,
    value                   TEXT                            NOT NULL,
    description             TEXT                            NULL,
    is_secret               BOOLEAN                         NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_system_settings           PRIMARY KEY (id),
    CONSTRAINT uq_system_settings_key       UNIQUE      (key)
);

COMMENT ON TABLE  platform.system_settings          IS 'Global platform-level configuration key/value store.';
COMMENT ON COLUMN platform.system_settings.is_secret IS 'If TRUE, value is encrypted at the application layer and must never be logged.';

CREATE INDEX IF NOT EXISTS idx_system_settings_key
    ON platform.system_settings (key);

DROP TRIGGER IF EXISTS trg_system_settings_updated_at ON platform.system_settings;
CREATE TRIGGER trg_system_settings_updated_at
    BEFORE UPDATE ON platform.system_settings
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- TABLE: feature_flags
-- Purpose: Per-school feature toggle overrides on top of plan-level features.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS platform.feature_flags (
    id                      BIGINT                          NOT NULL GENERATED ALWAYS AS IDENTITY,
    school_id               BIGINT                          NOT NULL,
    flag_key                VARCHAR(200)                    NOT NULL,
    is_enabled              BOOLEAN                         NOT NULL DEFAULT FALSE,
    overridden_by           BIGINT                          NULL,       -- platform_users.id
    note                    TEXT                            NULL,
    created_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ                     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_feature_flags                         PRIMARY KEY (id),
    CONSTRAINT uq_feature_flags_school_flag             UNIQUE      (school_id, flag_key),
    CONSTRAINT fk_feature_flags_school_id
        FOREIGN KEY (school_id)
        REFERENCES platform.schools (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_feature_flags_overridden_by
        FOREIGN KEY (overridden_by)
        REFERENCES platform.platform_users (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

COMMENT ON TABLE platform.feature_flags IS
    'Per-school feature flag overrides managed by platform admins.';

CREATE INDEX IF NOT EXISTS idx_feature_flags_school_id
    ON platform.feature_flags (school_id);

CREATE INDEX IF NOT EXISTS idx_feature_flags_overridden_by
    ON platform.feature_flags (overridden_by) WHERE overridden_by IS NOT NULL;

DROP TRIGGER IF EXISTS trg_feature_flags_updated_at ON platform.feature_flags;
CREATE TRIGGER trg_feature_flags_updated_at
    BEFORE UPDATE ON platform.feature_flags
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ===========================================================================
-- SEED: default subscription plans
-- ===========================================================================

INSERT INTO platform.subscription_plans
    (name, description, price_per_student, base_price, currency, billing_cycle, student_limit, trial_days, features_json, status)
VALUES
    ('Starter',  'Up to 200 students, core modules only.',
     1.5000, 0, 'USD', 'monthly', 200, 14, '{"sms_alerts":false,"multi_branch":false,"analytics":false}', 'active'),

    ('Growth',   'Up to 1 000 students, analytics included.',
     1.2000, 49, 'USD', 'monthly', 1000, 14, '{"sms_alerts":true,"multi_branch":false,"analytics":true}', 'active'),

    ('Enterprise','Unlimited students, all features, SLA.',
     0.9000, 199, 'USD', 'monthly', 2147483647, 30, '{"sms_alerts":true,"multi_branch":true,"analytics":true,"dedicated_support":true}', 'active')

ON CONFLICT (name) DO NOTHING;

-- ===========================================================================
-- SEED: default system settings
-- ===========================================================================

INSERT INTO platform.system_settings (key, value, description, is_secret)
VALUES
    ('platform.name',               'School ERP SaaS',              'Platform display name',                FALSE),
    ('platform.support_email',      'support@schoolerp.io',         'Support contact email',                FALSE),
    ('platform.max_login_attempts', '5',                            'Max failed logins before lockout',      FALSE),
    ('platform.lockout_minutes',    '30',                           'Account lockout duration in minutes',   FALSE),
    ('platform.jwt_secret',         'REPLACE_WITH_STRONG_SECRET',   'JWT signing secret — rotate regularly',TRUE),
    ('platform.smtp_host',          'smtp.mailprovider.com',        'Outbound SMTP host',                   FALSE),
    ('platform.smtp_port',          '587',                          'Outbound SMTP port',                   FALSE)
ON CONFLICT (key) DO NOTHING;

-- ===========================================================================
-- SEED: default super admin user
-- ===========================================================================
-- Password: SuperAdmin@123  (bcrypt cost 12 — CHANGE IMMEDIATELY after first login)

INSERT INTO platform.platform_users
    (name, email, password_hash, role, status)
VALUES
    (
        'Super Admin',
        'superadmin@schoolerp.io',
        crypt('SuperAdmin@123', gen_salt('bf', 12)),
        'super_admin',
        'active'
    )
ON CONFLICT (email) DO NOTHING;

COMMIT;

-- =============================================================================
-- END OF 01_platform_schema.sql
-- Next: 02_school_module_schema.sql  (academic year, branches, staff, students…)
-- =============================================================================
