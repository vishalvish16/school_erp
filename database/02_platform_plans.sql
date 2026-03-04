-- =============================================================================
-- FILE: 02_platform_plans.sql
-- PURPOSE: Create platform.platform_plans table
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql, 01_platform_schema.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 02_platform_plans.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- TABLE: platform.platform_plans
-- Purpose: Defines the SaaS subscription plan tiers offered to schools,
--          controlling student/teacher/branch capacity and pricing.
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.platform_plans (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    plan_id             BIGINT                  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Plan Identity
    -- -------------------------------------------------------------------------
    plan_name           VARCHAR(100)            NOT NULL,

    -- -------------------------------------------------------------------------
    -- Capacity Limits
    -- -------------------------------------------------------------------------
    max_students        INTEGER                 NOT NULL,
    max_teachers        INTEGER                 NOT NULL,
    max_branches        INTEGER                 NOT NULL DEFAULT 1,

    -- -------------------------------------------------------------------------
    -- Pricing
    -- -------------------------------------------------------------------------
    price_monthly       NUMERIC(12, 2)          NOT NULL,
    price_yearly        NUMERIC(12, 2)          NULL,

    -- -------------------------------------------------------------------------
    -- Lifecycle
    -- -------------------------------------------------------------------------
    is_active           BOOLEAN                 NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_platform_plans
        PRIMARY KEY (plan_id),

    -- Unique plan names prevent duplicate tier definitions
    CONSTRAINT uq_platform_plans_plan_name
        UNIQUE (plan_name),

    -- Capacity must be meaningful (> 0)
    CONSTRAINT chk_platform_plans_max_students
        CHECK (max_students > 0),

    CONSTRAINT chk_platform_plans_max_teachers
        CHECK (max_teachers > 0),

    CONSTRAINT chk_platform_plans_max_branches
        CHECK (max_branches > 0),

    -- Prices must be non-negative
    CONSTRAINT chk_platform_plans_price_monthly
        CHECK (price_monthly >= 0),

    CONSTRAINT chk_platform_plans_price_yearly
        CHECK (price_yearly IS NULL OR price_yearly >= 0),

    -- Yearly price should be less than or equal to 12x monthly (discount logic)
    CONSTRAINT chk_platform_plans_yearly_discount
        CHECK (price_yearly IS NULL OR price_yearly <= price_monthly * 12)

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.platform_plans IS
    'SaaS plan tiers that define capacity limits (students, teachers, branches) and pricing for school subscriptions.';

COMMENT ON COLUMN platform.platform_plans.plan_id       IS 'Surrogate primary key — auto-generated, never exposed in APIs (use plan_name or a future public_id).';
COMMENT ON COLUMN platform.platform_plans.plan_name     IS 'Human-readable unique plan name shown in UI and invoices (e.g. Starter, Growth, Enterprise).';
COMMENT ON COLUMN platform.platform_plans.max_students  IS 'Maximum number of active students allowed under this plan. Must be > 0.';
COMMENT ON COLUMN platform.platform_plans.max_teachers  IS 'Maximum number of active teacher accounts allowed under this plan. Must be > 0.';
COMMENT ON COLUMN platform.platform_plans.max_branches  IS 'Maximum number of school branches allowed. Defaults to 1 (single-campus).';
COMMENT ON COLUMN platform.platform_plans.price_monthly IS 'Monthly subscription price in the platform default currency. Must be >= 0.';
COMMENT ON COLUMN platform.platform_plans.price_yearly  IS 'Optional yearly subscription price. NULL = yearly billing not offered. Must be <= price_monthly * 12.';
COMMENT ON COLUMN platform.platform_plans.is_active     IS 'FALSE = plan is archived; hidden from new school sign-ups but retained for existing subscribers.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Fast lookup / uniqueness enforcement on plan name (also covered by UQ above,
-- but an explicit named index makes query plans and maintenance easier to read)
CREATE UNIQUE INDEX IF NOT EXISTS idx_platform_plans_plan_name
    ON platform.platform_plans (plan_name);

-- Filter active plans quickly (dashboard, sign-up flow)
CREATE INDEX IF NOT EXISTS idx_platform_plans_is_active
    ON platform.platform_plans (is_active);

-- Composite: most common query — list active plans ordered by monthly price
CREATE INDEX IF NOT EXISTS idx_platform_plans_active_price
    ON platform.platform_plans (is_active, price_monthly)
    WHERE is_active = TRUE;

-- =============================================================================
-- TRIGGER: auto-update updated_at on every row modification
-- =============================================================================

DROP TRIGGER IF EXISTS trg_platform_plans_updated_at ON platform.platform_plans;

CREATE TRIGGER trg_platform_plans_updated_at
    BEFORE UPDATE ON platform.platform_plans
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();

-- =============================================================================
-- SEED: default plan tiers (idempotent via ON CONFLICT DO NOTHING)
-- =============================================================================

INSERT INTO platform.platform_plans
    (plan_name, max_students, max_teachers, max_branches, price_monthly, price_yearly)
VALUES
    ('Starter',    200,    20,  1,  29.00,   290.00),
    ('Growth',    1000,   100,  3,  79.00,   790.00),
    ('Business',  3000,   300,  10, 149.00, 1490.00),
    ('Enterprise',2147483647, 2147483647, 2147483647, 299.00, 2990.00)
ON CONFLICT (plan_name) DO NOTHING;

COMMIT;

-- =============================================================================
-- END OF 02_platform_plans.sql
-- =============================================================================
