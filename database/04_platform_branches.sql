-- =============================================================================
-- FILE: 04_platform_branches.sql
-- PURPOSE: Create platform.branches — multi-branch support per school tenant
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql, 02_platform_plans.sql, 03_platform_schools.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 04_platform_branches.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- TABLE: platform.branches
-- Purpose: Represents physical campuses / branches under a school tenant.
--          school_id + branch_id together form the tenancy scope for all
--          child entities (classrooms, students, timetables, etc.).
--          A school with one campus will have exactly one branch row.
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.branches (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    branch_id               BIGINT                  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Tenant Anchor
    -- -------------------------------------------------------------------------
    school_id               BIGINT                  NOT NULL,

    -- -------------------------------------------------------------------------
    -- Identity
    -- -------------------------------------------------------------------------
    branch_name             VARCHAR(255)            NOT NULL,
    branch_code             VARCHAR(50)             NULL,       -- optional short code; unique per school

    -- -------------------------------------------------------------------------
    -- Location
    -- -------------------------------------------------------------------------
    address                 TEXT                    NULL,
    city                    VARCHAR(100)            NULL,
    state                   VARCHAR(100)            NULL,

    -- -------------------------------------------------------------------------
    -- Lifecycle
    -- -------------------------------------------------------------------------
    is_active               BOOLEAN                 NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_branches
        PRIMARY KEY (branch_id),

    -- Cascade: when a school is deactivated/deleted, all its branches follow
    CONSTRAINT fk_branches_school_id
        FOREIGN KEY (school_id)
        REFERENCES platform.schools (school_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- branch_code must be unique within a school (NULL values are excluded
    -- from UNIQUE enforcement in PostgreSQL — intentional for optional codes)
    CONSTRAINT uq_branches_school_code
        UNIQUE (school_id, branch_code),

    -- branch_name must be unique within a school to avoid user confusion
    CONSTRAINT uq_branches_school_name
        UNIQUE (school_id, branch_name),

    -- branch_code format guard: uppercase alphanumeric, dash, underscore
    CONSTRAINT chk_branches_branch_code_format
        CHECK (branch_code IS NULL OR branch_code ~ '^[A-Z0-9\-_]{1,50}$')

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.branches IS
    'Physical campus / branch registry per school tenant. '
    'school_id + branch_id together scope all child entities (rooms, staff, students).';

COMMENT ON COLUMN platform.branches.branch_id    IS 'Surrogate PK — BIGINT identity. Referenced as FK in classrooms, timetables, staff assignments, etc.';
COMMENT ON COLUMN platform.branches.school_id    IS 'Tenant anchor. FK to platform.schools. Cascades on school deletion.';
COMMENT ON COLUMN platform.branches.branch_name  IS 'Human-readable branch name, unique within the school (e.g. Main Campus, North Wing).';
COMMENT ON COLUMN platform.branches.branch_code  IS 'Optional short identifier unique per school (e.g. MC, NW). NULL = not assigned. Case-insensitive format enforced at app layer.';
COMMENT ON COLUMN platform.branches.is_active    IS 'FALSE = branch is closed/suspended. Inactive branches are excluded from scheduling and reporting.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- FK index: mandatory for JOIN and cascade performance
CREATE INDEX IF NOT EXISTS idx_branches_school_id
    ON platform.branches (school_id);

-- Global active-flag filter (admin dashboards, health checks)
CREATE INDEX IF NOT EXISTS idx_branches_is_active
    ON platform.branches (is_active);

-- Primary application query pattern: "give me all active branches for school X"
-- This is the hottest query path — covers school_id lookup + is_active filter
CREATE INDEX IF NOT EXISTS idx_branches_school_id_is_active
    ON platform.branches (school_id, is_active);

-- Partial variant: only active branches (smaller index, faster scans for app queries)
CREATE INDEX IF NOT EXISTS idx_branches_school_id_active_only
    ON platform.branches (school_id, branch_id)
    WHERE is_active = TRUE;

-- Geographic reporting at branch level (city/state drill-down)
CREATE INDEX IF NOT EXISTS idx_branches_city_state
    ON platform.branches (city, state)
    WHERE city IS NOT NULL;

-- =============================================================================
-- TRIGGER: auto-stamp updated_at on every row modification
-- =============================================================================

DROP TRIGGER IF EXISTS trg_branches_updated_at ON platform.branches;

CREATE TRIGGER trg_branches_updated_at
    BEFORE UPDATE ON platform.branches
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();

-- =============================================================================
-- TRIGGER: guard against hard deletes (deactivate instead)
-- =============================================================================

DROP TRIGGER IF EXISTS trg_branches_no_hard_delete ON platform.branches;

CREATE TRIGGER trg_branches_no_hard_delete
    BEFORE DELETE ON platform.branches
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_block_hard_delete();

-- =============================================================================
-- HELPER VIEW: active_branches
-- Purpose: Standard application view — only active branches, joined with
--          school context. All downstream modules query this instead of
--          the raw table to avoid accidentally exposing closed campuses.
-- =============================================================================

CREATE OR REPLACE VIEW platform.active_branches AS
SELECT
    b.branch_id,
    b.school_id,
    b.branch_name,
    b.branch_code,
    b.address,
    b.city,
    b.state,
    b.created_at,
    b.updated_at,
    -- School context (avoids extra JOIN in most queries)
    s.school_name,
    s.school_code,
    s.subdomain,
    s.plan_id,
    -- Convenience: full location label
    TRIM(BOTH ', ' FROM
        CONCAT_WS(', ',
            NULLIF(TRIM(b.city), ''),
            NULLIF(TRIM(b.state), '')
        )
    ) AS location_label
FROM
    platform.branches b
    JOIN platform.schools s ON s.school_id = b.school_id
WHERE
    b.is_active = TRUE
    AND s.is_active = TRUE;

COMMENT ON VIEW platform.active_branches IS
    'Active branches only, joined with parent school context. '
    'Filters out both inactive branches and inactive parent schools.';

-- =============================================================================
-- SCALABILITY NOTES (inline documentation)
-- =============================================================================
-- 1. PARTITIONING READINESS
--    When branch count per school exceeds ~500k rows total, consider range-
--    partitioning by school_id range or list-partitioning by country/region.
--    The current schema is partition-ready: school_id is always in WHERE clauses.
--
-- 2. TENANT ISOLATION
--    Every query on child tables MUST include school_id (and optionally branch_id)
--    in the WHERE clause. Never query branches without a school_id predicate.
--    Enforce this via Row-Level Security (RLS) in the application schema if needed:
--
--      ALTER TABLE platform.branches ENABLE ROW LEVEL SECURITY;
--      CREATE POLICY branches_tenant_isolation ON platform.branches
--          USING (school_id = current_setting('app.current_school_id')::BIGINT);
--
-- 3. BRANCH LIMIT ENFORCEMENT
--    The max_branches column in platform_plans defines the cap per school.
--    Enforce this at the application layer (before INSERT) or via a trigger:
--
--      -- Example trigger pseudocode (add if hard enforcement required at DB level):
--      IF (SELECT COUNT(*) FROM platform.branches WHERE school_id = NEW.school_id
--              AND is_active = TRUE)
--         >= (SELECT pp.max_branches FROM platform.schools s
--                JOIN platform.platform_plans pp ON pp.plan_id = s.plan_id
--              WHERE s.school_id = NEW.school_id)
--      THEN RAISE EXCEPTION 'Branch limit reached for this plan.';
--      END IF;
-- =============================================================================

COMMIT;

-- =============================================================================
-- END OF 04_platform_branches.sql
-- Next: 05_platform_academic_years.sql  (academic year per school/branch)
-- =============================================================================
