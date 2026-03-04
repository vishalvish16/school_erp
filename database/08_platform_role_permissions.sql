-- =============================================================================
-- FILE: 08_platform_role_permissions.sql
-- PURPOSE: Create platform.role_permissions — RBAC permission matrix (role ↔ module)
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql, 05_platform_roles.sql, 07_platform_modules.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 08_platform_role_permissions.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- TABLE: platform.role_permissions
-- Purpose: CRUD permission matrix mapping roles → modules.
--          One row per (role, module) pair defines exactly what that role
--          can do inside that module.
--
--          Permission resolution order (for the application layer):
--            1. Check is_active on the user
--            2. Check is_active on the module
--            3. Look up this table for (role_id, module_id)
--            4. Check can_create / can_read / can_update / can_delete
--            5. If no row exists → DENY ALL (deny-by-default model)
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.role_permissions (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    permission_id           BIGINT              NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Role + Module (the composite key that matters)
    -- -------------------------------------------------------------------------
    role_id                 BIGINT              NOT NULL,
    module_id               BIGINT              NOT NULL,

    -- -------------------------------------------------------------------------
    -- CRUD Permission Flags (deny-by-default)
    -- -------------------------------------------------------------------------
    can_create              BOOLEAN             NOT NULL DEFAULT FALSE,
    can_read                BOOLEAN             NOT NULL DEFAULT TRUE,   -- read is the minimum meaningful grant
    can_update              BOOLEAN             NOT NULL DEFAULT FALSE,
    can_delete              BOOLEAN             NOT NULL DEFAULT FALSE,

    -- -------------------------------------------------------------------------
    -- Extended Permissions (common ERP patterns)
    -- -------------------------------------------------------------------------
    can_export              BOOLEAN             NOT NULL DEFAULT FALSE,  -- export CSV / PDF reports
    can_approve             BOOLEAN             NOT NULL DEFAULT FALSE,  -- workflow approval actions
    can_print               BOOLEAN             NOT NULL DEFAULT FALSE,  -- print documents / reports

    -- -------------------------------------------------------------------------
    -- Audit
    -- -------------------------------------------------------------------------
    granted_by              BIGINT              NULL,                    -- platform.users.user_id who set this
    created_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_role_permissions
        PRIMARY KEY (permission_id),

    -- Cascade: when a role is deleted, its permission rows go with it
    CONSTRAINT fk_role_permissions_role_id
        FOREIGN KEY (role_id)
        REFERENCES platform.roles (role_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Cascade: when a module is deleted, its permission rows go with it
    CONSTRAINT fk_role_permissions_module_id
        FOREIGN KEY (module_id)
        REFERENCES platform.modules (module_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Audit FK: who last modified this permission row (SET NULL if user deleted)
    CONSTRAINT fk_role_permissions_granted_by
        FOREIGN KEY (granted_by)
        REFERENCES platform.users (user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Each role may have exactly one permission row per module
    CONSTRAINT uq_role_permissions_role_module
        UNIQUE (role_id, module_id),

    -- Business rule: can_delete requires can_read (deleting without seeing makes no sense)
    CONSTRAINT chk_role_permissions_delete_requires_read
        CHECK (can_delete = FALSE OR can_read = TRUE),

    -- Business rule: can_update requires can_read
    CONSTRAINT chk_role_permissions_update_requires_read
        CHECK (can_update = FALSE OR can_read = TRUE),

    -- Business rule: can_create requires can_read
    CONSTRAINT chk_role_permissions_create_requires_read
        CHECK (can_create = FALSE OR can_read = TRUE),

    -- Business rule: can_approve requires can_read
    CONSTRAINT chk_role_permissions_approve_requires_read
        CHECK (can_approve = FALSE OR can_read = TRUE)

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.role_permissions IS
    'RBAC CRUD permission matrix. One row per (role, module) pair. '
    'No row = DENY ALL (deny-by-default). Application must check this table on every privileged action.';

COMMENT ON COLUMN platform.role_permissions.permission_id IS 'Surrogate PK. The meaningful key is (role_id, module_id) — enforced by UQ constraint.';
COMMENT ON COLUMN platform.role_permissions.role_id       IS 'FK to platform.roles. CASCADE on delete.';
COMMENT ON COLUMN platform.role_permissions.module_id     IS 'FK to platform.modules. CASCADE on delete.';
COMMENT ON COLUMN platform.role_permissions.can_create    IS 'Allows INSERT / create operations inside the module. Requires can_read = TRUE.';
COMMENT ON COLUMN platform.role_permissions.can_read      IS 'Allows SELECT / view operations. Minimum meaningful grant. Defaults TRUE.';
COMMENT ON COLUMN platform.role_permissions.can_update    IS 'Allows UPDATE / edit operations. Requires can_read = TRUE.';
COMMENT ON COLUMN platform.role_permissions.can_delete    IS 'Allows DELETE / archive operations. Requires can_read = TRUE.';
COMMENT ON COLUMN platform.role_permissions.can_export    IS 'Allows CSV / PDF / Excel export from the module.';
COMMENT ON COLUMN platform.role_permissions.can_approve   IS 'Allows workflow approval actions (e.g. approve leave, approve payment). Requires can_read = TRUE.';
COMMENT ON COLUMN platform.role_permissions.can_print     IS 'Allows print / document generation from the module.';
COMMENT ON COLUMN platform.role_permissions.granted_by    IS 'User who last set or modified this permission row. Audit trail.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- FK index: role-side lookup (cascade performance + permission evaluation)
CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id
    ON platform.role_permissions (role_id);

-- FK index: module-side lookup (cascade performance + "who can access this module?" query)
CREATE INDEX IF NOT EXISTS idx_role_permissions_module_id
    ON platform.role_permissions (module_id);

-- Composite index: THE hot path — permission check is always (role_id, module_id)
-- Covered by the UNIQUE constraint but named explicitly for observability
CREATE UNIQUE INDEX IF NOT EXISTS idx_role_permissions_role_module
    ON platform.role_permissions (role_id, module_id);

-- Granted-by: audit trail — "which permissions did user X grant?"
CREATE INDEX IF NOT EXISTS idx_role_permissions_granted_by
    ON platform.role_permissions (granted_by)
    WHERE granted_by IS NOT NULL;

-- Partial index: rows where any write permission is granted
-- Useful for security audit: "which roles have write access to any module?"
CREATE INDEX IF NOT EXISTS idx_role_permissions_has_write
    ON platform.role_permissions (role_id, module_id)
    WHERE can_create = TRUE OR can_update = TRUE OR can_delete = TRUE;

-- =============================================================================
-- TRIGGER: auto-stamp updated_at
-- =============================================================================

DROP TRIGGER IF EXISTS trg_role_permissions_updated_at ON platform.role_permissions;

CREATE TRIGGER trg_role_permissions_updated_at
    BEFORE UPDATE ON platform.role_permissions
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();

-- =============================================================================
-- HELPER FUNCTION: platform.check_permission()
-- Purpose: Single callable function for the application layer to evaluate
--          whether a given user has a specific permission on a module.
--          Encapsulates the full permission resolution chain.
--
-- Usage:
--   SELECT platform.check_permission(
--       p_user_id    := 42,
--       p_module_code:= 'STUDENT_MANAGEMENT',
--       p_action     := 'can_update'
--   );
-- Returns: TRUE / FALSE
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.check_permission(
    p_user_id       BIGINT,
    p_module_code   VARCHAR(100),
    p_action        TEXT            -- 'can_create' | 'can_read' | 'can_update' | 'can_delete' | 'can_export' | 'can_approve' | 'can_print'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = platform, public
AS $$
DECLARE
    v_result        BOOLEAN := FALSE;
    v_valid_actions TEXT[]  := ARRAY['can_create','can_read','can_update','can_delete','can_export','can_approve','can_print'];
BEGIN
    -- Validate action argument
    IF p_action != ALL(v_valid_actions) THEN
        RAISE EXCEPTION 'Invalid action "%". Must be one of: %', p_action, array_to_string(v_valid_actions, ', ')
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    EXECUTE format(
        $q$
        SELECT rp.%I
        FROM   platform.users           u
        JOIN   platform.role_permissions rp ON rp.role_id   = u.role_id
        JOIN   platform.modules          m  ON m.module_id  = rp.module_id
        WHERE  u.user_id     = $1
          AND  m.module_code = $2
          AND  u.is_active   = TRUE
          AND  u.deleted_at  IS NULL
          AND  m.is_active   = TRUE
        LIMIT 1
        $q$,
        p_action
    )
    INTO v_result
    USING p_user_id, p_module_code;

    RETURN COALESCE(v_result, FALSE);   -- No row = DENY
END;
$$;

COMMENT ON FUNCTION platform.check_permission(BIGINT, VARCHAR, TEXT) IS
    'Central RBAC permission check. Returns TRUE if the given user has the '
    'specified action on the given module_code. Returns FALSE if no permission '
    'row exists (deny-by-default). Checks user is_active and module is_active.';

-- =============================================================================
-- SEED: Super Admin role → full access to all platform modules
-- =============================================================================

DO $$
DECLARE
    v_super_admin_role_id   BIGINT;
    v_read_only_role_id     BIGINT;
    v_support_role_id       BIGINT;
    v_finance_role_id       BIGINT;
BEGIN
    -- Resolve role IDs
    SELECT role_id INTO v_super_admin_role_id FROM platform.roles
        WHERE role_name = 'Super Admin'   AND school_id IS NULL LIMIT 1;

    SELECT role_id INTO v_read_only_role_id   FROM platform.roles
        WHERE role_name = 'Read Only'     AND school_id IS NULL LIMIT 1;

    SELECT role_id INTO v_support_role_id     FROM platform.roles
        WHERE role_name = 'Support Admin' AND school_id IS NULL LIMIT 1;

    SELECT role_id INTO v_finance_role_id     FROM platform.roles
        WHERE role_name = 'Finance Admin' AND school_id IS NULL LIMIT 1;

    -- ── Super Admin: FULL ACCESS on all platform modules ─────────────────────
    IF v_super_admin_role_id IS NOT NULL THEN
        INSERT INTO platform.role_permissions
            (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
        SELECT
            v_super_admin_role_id,
            m.module_id,
            TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
        FROM platform.modules m
        WHERE m.is_platform_level = TRUE
        ON CONFLICT (role_id, module_id) DO NOTHING;
    END IF;

    -- ── Read Only: READ ONLY on all platform modules ──────────────────────────
    IF v_read_only_role_id IS NOT NULL THEN
        INSERT INTO platform.role_permissions
            (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
        SELECT
            v_read_only_role_id,
            m.module_id,
            FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE
        FROM platform.modules m
        WHERE m.is_platform_level = TRUE
        ON CONFLICT (role_id, module_id) DO NOTHING;
    END IF;

    -- ── Support Admin: READ + limited access (no billing/plan delete) ─────────
    IF v_support_role_id IS NOT NULL THEN
        INSERT INTO platform.role_permissions
            (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
        SELECT
            v_support_role_id,
            m.module_id,
            FALSE,                          -- no create
            TRUE,                           -- read all
            CASE WHEN m.module_code IN (
                'SCHOOL_MANAGEMENT', 'PLATFORM_USERS'
            ) THEN TRUE ELSE FALSE END,     -- update only schools + users
            FALSE,                          -- no delete
            TRUE,                           -- can export
            FALSE,                          -- no approve
            TRUE                            -- can print
        FROM platform.modules m
        WHERE m.is_platform_level = TRUE
        ON CONFLICT (role_id, module_id) DO NOTHING;
    END IF;

    -- ── Finance Admin: READ + full access on billing modules only ─────────────
    IF v_finance_role_id IS NOT NULL THEN
        INSERT INTO platform.role_permissions
            (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
        SELECT
            v_finance_role_id,
            m.module_id,
            CASE WHEN m.module_code IN ('BILLING_INVOICES','SUBSCRIPTION_MANAGEMENT') THEN TRUE ELSE FALSE END,
            TRUE,
            CASE WHEN m.module_code IN ('BILLING_INVOICES','SUBSCRIPTION_MANAGEMENT') THEN TRUE ELSE FALSE END,
            FALSE,
            TRUE,
            CASE WHEN m.module_code IN ('BILLING_INVOICES','SUBSCRIPTION_MANAGEMENT') THEN TRUE ELSE FALSE END,
            TRUE
        FROM platform.modules m
        WHERE m.is_platform_level = TRUE
        ON CONFLICT (role_id, module_id) DO NOTHING;
    END IF;

END;
$$;

-- =============================================================================
-- HELPER VIEW: platform.permission_matrix
-- Purpose: Flat, human-readable permission matrix for the admin UI permission
--          management screen. Shows all (role, module) combinations with flags.
-- =============================================================================

CREATE OR REPLACE VIEW platform.permission_matrix AS
SELECT
    rp.permission_id,
    r.role_id,
    r.role_name,
    r.role_type,
    m.module_id,
    m.module_name,
    m.module_code,
    m.is_platform_level,
    rp.can_create,
    rp.can_read,
    rp.can_update,
    rp.can_delete,
    rp.can_export,
    rp.can_approve,
    rp.can_print,
    -- Computed: quick human-readable summary of granted permissions
    CONCAT_WS(', ',
        CASE WHEN rp.can_create  THEN 'Create'  END,
        CASE WHEN rp.can_read    THEN 'Read'    END,
        CASE WHEN rp.can_update  THEN 'Update'  END,
        CASE WHEN rp.can_delete  THEN 'Delete'  END,
        CASE WHEN rp.can_export  THEN 'Export'  END,
        CASE WHEN rp.can_approve THEN 'Approve' END,
        CASE WHEN rp.can_print   THEN 'Print'   END
    )                                               AS granted_actions_summary,
    -- Computed: is this a fully-privileged row?
    (rp.can_create AND rp.can_read AND rp.can_update AND rp.can_delete) AS is_full_access,
    u.email                                         AS granted_by_email,
    rp.created_at,
    rp.updated_at
FROM
    platform.role_permissions   rp
    JOIN  platform.roles         r  ON r.role_id   = rp.role_id
    JOIN  platform.modules       m  ON m.module_id  = rp.module_id
    LEFT  JOIN platform.users    u  ON u.user_id    = rp.granted_by
ORDER BY
    r.role_name, m.display_order;

COMMENT ON VIEW platform.permission_matrix IS
    'Human-readable RBAC matrix: role × module with all permission flags, '
    'a granted_actions_summary string, and is_full_access boolean for UI rendering.';

COMMIT;

-- =============================================================================
-- END OF 08_platform_role_permissions.sql
-- Next: 09_platform_audit_log.sql  (platform-wide immutable audit trail)
-- =============================================================================
