-- =============================================================================
-- FILE: 05_platform_roles.sql
-- PURPOSE: Create platform.roles — unified role registry (platform + school level)
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql, 03_platform_schools.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 05_platform_roles.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- ENUM: role_type
-- PLATFORM → global roles defined by the SaaS vendor (super_admin, support…)
-- SCHOOL   → tenant-scoped roles defined per school (principal, teacher…)
-- =============================================================================

DO $$ BEGIN
    CREATE TYPE platform.role_type_enum AS ENUM ('PLATFORM', 'SCHOOL');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================================
-- TABLE: platform.roles
-- Purpose: Unified role registry for both platform-level (SaaS admin) and
--          school-level (tenant) roles.
--          school_id IS NULL  → PLATFORM role (applies across the whole platform)
--          school_id NOT NULL → SCHOOL role   (scoped to one tenant)
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.roles (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    role_id                 BIGINT                      NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Tenant Scope  (NULL = platform-wide)
    -- -------------------------------------------------------------------------
    school_id               BIGINT                      NULL,

    -- -------------------------------------------------------------------------
    -- Identity
    -- -------------------------------------------------------------------------
    role_name               VARCHAR(100)                NOT NULL,
    role_type               platform.role_type_enum     NOT NULL,

    -- -------------------------------------------------------------------------
    -- Optional metadata
    -- -------------------------------------------------------------------------
    description             TEXT                        NULL,
    is_system_role          BOOLEAN                     NOT NULL DEFAULT FALSE,  -- system roles cannot be deleted/renamed

    -- -------------------------------------------------------------------------
    -- Lifecycle
    -- -------------------------------------------------------------------------
    created_at              TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_roles
        PRIMARY KEY (role_id),

    -- FK: school_id must point to a real school when set
    CONSTRAINT fk_roles_school_id
        FOREIGN KEY (school_id)
        REFERENCES platform.schools (school_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Unique role name per school (NULL school_id = platform scope)
    -- Using COALESCE so that (NULL, 'Super Admin') can only exist once:
    --   standard UNIQUE allows multiple NULLs; we use a partial index instead
    --   (see idx_roles_platform_unique below)
    CONSTRAINT uq_roles_school_role_name
        UNIQUE (school_id, role_name),

    -- Role type must match school_id nullability:
    --   PLATFORM roles → school_id must be NULL
    --   SCHOOL roles   → school_id must be NOT NULL
    CONSTRAINT chk_roles_type_scope_alignment
        CHECK (
            (role_type = 'PLATFORM' AND school_id IS NULL)
            OR
            (role_type = 'SCHOOL'   AND school_id IS NOT NULL)
        ),

    -- role_name must not be blank or only whitespace
    CONSTRAINT chk_roles_role_name_not_blank
        CHECK (TRIM(role_name) <> '')

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.roles IS
    'Unified role registry. '
    'PLATFORM roles (school_id IS NULL) are defined by the SaaS vendor and apply globally. '
    'SCHOOL roles (school_id IS NOT NULL) are tenant-scoped and cascade-deleted with the school.';

COMMENT ON COLUMN platform.roles.role_id        IS 'Surrogate PK — referenced by platform.user_roles and permission tables.';
COMMENT ON COLUMN platform.roles.school_id      IS 'NULL = PLATFORM-level role. NOT NULL = SCHOOL-level role scoped to one tenant.';
COMMENT ON COLUMN platform.roles.role_name      IS 'Human-readable role label. Must be unique within its scope (platform or school).';
COMMENT ON COLUMN platform.roles.role_type      IS 'PLATFORM or SCHOOL — must align with school_id nullability (enforced by CHECK).';
COMMENT ON COLUMN platform.roles.is_system_role IS 'TRUE = seeded by the platform; application layer must block rename/delete of system roles.';
COMMENT ON COLUMN platform.roles.description    IS 'Optional plain-text description shown in the admin UI role management screen.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- FK index: cascade operations and JOIN to schools
CREATE INDEX IF NOT EXISTS idx_roles_school_id
    ON platform.roles (school_id)
    WHERE school_id IS NOT NULL;

-- Filter by role type (platform admin UIs, permission evaluation)
CREATE INDEX IF NOT EXISTS idx_roles_role_type
    ON platform.roles (role_type);

-- Composite: most common query — "give me all roles for school X"
CREATE INDEX IF NOT EXISTS idx_roles_school_id_role_type
    ON platform.roles (school_id, role_type)
    WHERE school_id IS NOT NULL;

-- Partial unique index: enforce uniqueness of PLATFORM role names
-- (standard UNIQUE on (school_id, role_name) allows multiple NULLs in PostgreSQL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_platform_unique
    ON platform.roles (role_name)
    WHERE school_id IS NULL;

-- Lookup by name within a school (permission evaluation hot path)
CREATE INDEX IF NOT EXISTS idx_roles_school_name
    ON platform.roles (school_id, role_name)
    WHERE school_id IS NOT NULL;

-- System roles lookup (admin UI: show which roles cannot be modified)
CREATE INDEX IF NOT EXISTS idx_roles_is_system_role
    ON platform.roles (is_system_role)
    WHERE is_system_role = TRUE;

-- =============================================================================
-- TRIGGER: auto-stamp updated_at
-- =============================================================================

DROP TRIGGER IF EXISTS trg_roles_updated_at ON platform.roles;

CREATE TRIGGER trg_roles_updated_at
    BEFORE UPDATE ON platform.roles
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();

-- =============================================================================
-- TRIGGER: block delete of system roles
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.fn_protect_system_roles()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
    IF OLD.is_system_role = TRUE THEN
        RAISE EXCEPTION
            'System role "%" (role_id=%) cannot be deleted. '
            'Disable or reassign instead.',
            OLD.role_name, OLD.role_id
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN OLD;
END;
$$;

COMMENT ON FUNCTION platform.fn_protect_system_roles() IS
    'Prevents hard-deletion of any role flagged as is_system_role = TRUE.';

DROP TRIGGER IF EXISTS trg_roles_protect_system ON platform.roles;

CREATE TRIGGER trg_roles_protect_system
    BEFORE DELETE ON platform.roles
    FOR EACH ROW
    EXECUTE FUNCTION platform.fn_protect_system_roles();

-- =============================================================================
-- TRIGGER: block rename of system roles
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.fn_protect_system_role_rename()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
    IF OLD.is_system_role = TRUE AND NEW.role_name <> OLD.role_name THEN
        RAISE EXCEPTION
            'System role "%" (role_id=%) cannot be renamed.',
            OLD.role_name, OLD.role_id
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION platform.fn_protect_system_role_rename() IS
    'Prevents renaming any role flagged as is_system_role = TRUE.';

DROP TRIGGER IF EXISTS trg_roles_protect_system_rename ON platform.roles;

CREATE TRIGGER trg_roles_protect_system_rename
    BEFORE UPDATE OF role_name ON platform.roles
    FOR EACH ROW
    EXECUTE FUNCTION platform.fn_protect_system_role_rename();

-- =============================================================================
-- SEED: platform-level system roles (is_system_role = TRUE)
-- =============================================================================

INSERT INTO platform.roles
    (school_id, role_name, role_type, description, is_system_role)
VALUES
    (NULL, 'Super Admin',    'PLATFORM', 'Full unrestricted access to the entire SaaS platform.',               TRUE),
    (NULL, 'Support Admin',  'PLATFORM', 'Read + limited write access for customer support operations.',        TRUE),
    (NULL, 'Finance Admin',  'PLATFORM', 'Access to billing, invoices, and subscription management only.',     TRUE),
    (NULL, 'Read Only',      'PLATFORM', 'Read-only access across all platform dashboards and reports.',        TRUE)
ON CONFLICT (school_id, role_name) DO NOTHING;

-- =============================================================================
-- HELPER VIEW: platform.roles_summary
-- Purpose: Flat view showing all roles with their scope context. Used by
--          admin UIs and permission evaluation services.
-- =============================================================================

CREATE OR REPLACE VIEW platform.roles_summary AS
SELECT
    r.role_id,
    r.school_id,
    r.role_name,
    r.role_type,
    r.description,
    r.is_system_role,
    r.created_at,
    r.updated_at,
    -- School context (NULL for PLATFORM roles)
    s.school_name,
    s.school_code,
    -- Derived display label
    CASE
        WHEN r.school_id IS NULL THEN 'Platform: ' || r.role_name
        ELSE s.school_name || ': ' || r.role_name
    END AS display_label,
    -- Editable flag for UI
    NOT r.is_system_role AS is_editable
FROM
    platform.roles r
    LEFT JOIN platform.schools s ON s.school_id = r.school_id;

COMMENT ON VIEW platform.roles_summary IS
    'Flat roles view with school context and UI-friendly computed columns. '
    'Use is_editable to conditionally show edit/delete controls in the admin UI.';

COMMIT;

-- =============================================================================
-- END OF 05_platform_roles.sql
-- Next: 06_platform_permissions.sql  (permission registry + role_permissions map)
-- =============================================================================
