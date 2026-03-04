-- =============================================================================
-- FILE: 03_platform_schools.sql
-- PURPOSE: Create platform.schools — master tenant table
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql, 01_platform_schema.sql, 02_platform_plans.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 03_platform_schools.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- TABLE: platform.schools
-- Purpose: Master tenant registry. Every school onboarded to the SaaS platform
--          gets one row here. school_id is the multi-tenancy foreign key
--          referenced by ALL downstream modules (students, staff, timetables…).
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.schools (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    school_id               BIGINT                  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Plan Association
    -- -------------------------------------------------------------------------
    plan_id                 BIGINT                  NOT NULL,

    -- -------------------------------------------------------------------------
    -- Identity & Routing
    -- -------------------------------------------------------------------------
    school_name             VARCHAR(255)            NOT NULL,
    school_code             VARCHAR(50)             NOT NULL,
    subdomain               VARCHAR(100)            NOT NULL,  -- e.g. "greenvalley" → greenvalley.schoolerp.io

    -- -------------------------------------------------------------------------
    -- Contact Information
    -- -------------------------------------------------------------------------
    contact_email           VARCHAR(255)            NULL,
    contact_phone           VARCHAR(20)             NULL,

    -- -------------------------------------------------------------------------
    -- Address
    -- -------------------------------------------------------------------------
    address                 TEXT                    NULL,
    city                    VARCHAR(100)            NULL,
    state                   VARCHAR(100)            NULL,
    country                 VARCHAR(100)            NULL,
    pincode                 VARCHAR(20)             NULL,

    -- -------------------------------------------------------------------------
    -- Subscription Window
    -- -------------------------------------------------------------------------
    subscription_start      DATE                    NULL,
    subscription_end        DATE                    NULL,

    -- -------------------------------------------------------------------------
    -- Lifecycle
    -- -------------------------------------------------------------------------
    is_active               BOOLEAN                 NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_schools
        PRIMARY KEY (school_id),

    -- Every school must reference a valid plan
    CONSTRAINT fk_schools_plan_id
        FOREIGN KEY (plan_id)
        REFERENCES platform.platform_plans (plan_id)
        ON DELETE RESTRICT    -- Cannot delete a plan that has schools attached
        ON UPDATE CASCADE,    -- If plan_id PK ever changes, cascade here

    -- Short identifier used in reports / API paths
    CONSTRAINT uq_schools_school_code
        UNIQUE (school_code),

    -- Routes tenant-specific subdomains; must be globally unique
    CONSTRAINT uq_schools_subdomain
        UNIQUE (subdomain),

    -- Format guards
    CONSTRAINT chk_schools_contact_email
        CHECK (contact_email IS NULL OR contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),

    CONSTRAINT chk_schools_contact_phone
        CHECK (contact_phone IS NULL OR contact_phone ~ '^\+?[0-9\s\-\(\)]{7,20}$'),

    CONSTRAINT chk_schools_subdomain_format
        CHECK (subdomain ~ '^[a-z0-9]([a-z0-9\-]{0,98}[a-z0-9])?$'),  -- DNS-safe lowercase slug

    CONSTRAINT chk_schools_school_code_format
        CHECK (school_code ~ '^[A-Z0-9\-_]{2,50}$'),                   -- Uppercase alphanumeric + dash/underscore

    -- Subscription window integrity
    CONSTRAINT chk_schools_subscription_dates
        CHECK (
            subscription_start IS NULL
            OR subscription_end IS NULL
            OR subscription_end >= subscription_start
        )

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.schools IS
    'Master tenant table. One row per onboarded school. school_id is the '
    'multi-tenancy isolation key referenced by all child modules.';

COMMENT ON COLUMN platform.schools.school_id         IS 'Surrogate PK — auto-generated BIGINT identity, used as tenancy FK in all child tables.';
COMMENT ON COLUMN platform.schools.plan_id           IS 'Active subscription plan. FK to platform.platform_plans. Restricted from deletion.';
COMMENT ON COLUMN platform.schools.school_code       IS 'Short uppercase identifier used in reports and internal references (e.g. GVS-MUM-01). Immutable after creation.';
COMMENT ON COLUMN platform.schools.subdomain         IS 'DNS-safe subdomain slug for tenant routing (e.g. "greenvalley" → greenvalley.schoolerp.io). Lowercase only.';
COMMENT ON COLUMN platform.schools.subscription_start IS 'Inclusive start date of current subscription window. NULL = not yet activated.';
COMMENT ON COLUMN platform.schools.subscription_end  IS 'Inclusive end date of current subscription. NULL = no set expiry (e.g. lifetime/trial).';
COMMENT ON COLUMN platform.schools.is_active         IS 'FALSE = school is suspended/deactivated; hides tenant from all application queries.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- FK index: required for efficient JOIN with platform_plans and integrity checks
CREATE INDEX IF NOT EXISTS idx_schools_plan_id
    ON platform.schools (plan_id);

-- Fast toggle queries: "list all active schools"
CREATE INDEX IF NOT EXISTS idx_schools_is_active
    ON platform.schools (is_active);

-- Partial index variant: only index active schools (smaller, faster for app queries)
CREATE INDEX IF NOT EXISTS idx_schools_active_only
    ON platform.schools (school_id, plan_id)
    WHERE is_active = TRUE;

-- Geographic drill-down: filter/group by city + state in admin dashboards
CREATE INDEX IF NOT EXISTS idx_schools_city_state
    ON platform.schools (city, state);

-- Subscription expiry monitoring: find schools expiring soon (cron/alerts)
CREATE INDEX IF NOT EXISTS idx_schools_subscription_end
    ON platform.schools (subscription_end)
    WHERE subscription_end IS NOT NULL;

-- Composite: active schools expiring within a window (renewal reminder jobs)
CREATE INDEX IF NOT EXISTS idx_schools_active_sub_end
    ON platform.schools (is_active, subscription_end)
    WHERE is_active = TRUE AND subscription_end IS NOT NULL;

-- Fast lookup by subdomain (used on every tenant-routed HTTP request)
-- Already covered by the UNIQUE constraint index above, but aliased for clarity
-- (PostgreSQL automatically creates an index for UNIQUE constraints)

-- Country-level reporting
CREATE INDEX IF NOT EXISTS idx_schools_country
    ON platform.schools (country)
    WHERE country IS NOT NULL;

-- =============================================================================
-- TRIGGER: auto-stamp updated_at on every row modification
-- =============================================================================

DROP TRIGGER IF EXISTS trg_schools_updated_at ON platform.schools;

CREATE TRIGGER trg_schools_updated_at
    BEFORE UPDATE ON platform.schools
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();

-- =============================================================================
-- TRIGGER: block hard-deletes — use is_active = FALSE instead
-- =============================================================================

DROP TRIGGER IF EXISTS trg_schools_no_hard_delete ON platform.schools;

CREATE TRIGGER trg_schools_no_hard_delete
    BEFORE DELETE ON platform.schools
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_block_hard_delete();

-- =============================================================================
-- HELPER VIEW: active_schools
-- Purpose: Standard application-level view that always filters out inactive
--          tenants, so queries never accidentally expose suspended schools.
-- =============================================================================

CREATE OR REPLACE VIEW platform.active_schools AS
SELECT
    s.school_id,
    s.plan_id,
    s.school_name,
    s.school_code,
    s.subdomain,
    s.contact_email,
    s.contact_phone,
    s.address,
    s.city,
    s.state,
    s.country,
    s.pincode,
    s.subscription_start,
    s.subscription_end,
    s.created_at,
    s.updated_at,
    -- Joined plan metadata for convenience
    pp.plan_name,
    pp.max_students,
    pp.max_teachers,
    pp.max_branches,
    pp.price_monthly,
    -- Computed: days remaining in subscription
    CASE
        WHEN s.subscription_end IS NULL THEN NULL
        ELSE (s.subscription_end - CURRENT_DATE)
    END AS subscription_days_remaining,
    -- Computed: subscription health signal
    CASE
        WHEN s.subscription_end IS NULL                          THEN 'no_expiry'
        WHEN s.subscription_end < CURRENT_DATE                  THEN 'expired'
        WHEN s.subscription_end <= CURRENT_DATE + INTERVAL '30 days' THEN 'expiring_soon'
        ELSE 'healthy'
    END AS subscription_health
FROM
    platform.schools          s
    JOIN platform.platform_plans pp ON pp.plan_id = s.plan_id
WHERE
    s.is_active = TRUE;

COMMENT ON VIEW platform.active_schools IS
    'Active-schools-only view with plan details and computed subscription health signals. '
    'All application modules should query this view instead of the raw schools table.';

COMMIT;

-- =============================================================================
-- END OF 03_platform_schools.sql
-- Next: 04_platform_users.sql  (super-admin and support users)
-- =============================================================================
