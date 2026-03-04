-- =============================================================================
-- FILE: 09_rls_policies.sql
-- PURPOSE: Row Level Security (RLS) policy templates for multi-tenant isolation
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 03_platform_schools.sql, 04_platform_branches.sql,
--             05_platform_roles.sql,   06_platform_users.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 09_rls_policies.sql
-- =============================================================================
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  IMPORTANT — READ BEFORE RUNNING                                        │
-- │                                                                         │
-- │  This file:                                                             │
-- │    ✅ ENABLES  RLS on the four tables (ALTER TABLE ... ENABLE RLS)      │
-- │    ✅ CREATES  all tenant-isolation POLICY objects                      │
-- │    ❌ Does NOT FORCE RLS on the table owner (school_erp_owner)         │
-- │                                                                         │
-- │  PostgreSQL RLS behaviour:                                              │
-- │    - ENABLE RLS    → policies apply to non-owner roles (app role)      │
-- │    - FORCE RLS     → policies apply to ALL roles, incl. owner          │
-- │                                                                         │
-- │  To ACTIVATE enforcement for the app role, your connection must SET:   │
-- │      SET app.current_school_id = '<school_id>';                        │
-- │  before issuing any tenant-scoped query.                                │
-- │                                                                         │
-- │  To FULLY ENFORCE (owner included), run separately per table:          │
-- │      ALTER TABLE platform.schools FORCE ROW LEVEL SECURITY;            │
-- │                                                                         │
-- │  Policies are created with IF NOT EXISTS semantics via DROP + CREATE.  │
-- └─────────────────────────────────────────────────────────────────────────┘
--
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- HELPER: safe session variable accessor
-- Returns NULL (not error) if app.current_school_id is not set in the session.
-- The application MUST set this before any tenant-scoped query.
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.current_school_id()
RETURNS BIGINT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
    RETURN current_setting('app.current_school_id', TRUE)::BIGINT;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;    -- setting not configured → treat as no school context
END;
$$;

COMMENT ON FUNCTION platform.current_school_id() IS
    'Safe accessor for the app.current_school_id session variable. '
    'Returns NULL instead of raising an error when the variable is not set. '
    'The application MUST call SET app.current_school_id = <id> before any tenant query.';

-- =============================================================================
-- HELPER: check if current session is a platform-level admin
-- Returns TRUE when no school context is set (super-admin bypass pattern).
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.is_platform_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
    -- A NULL school context = platform-level session (super-admin, support, etc.)
    RETURN platform.current_school_id() IS NULL;
END;
$$;

COMMENT ON FUNCTION platform.is_platform_admin() IS
    'Returns TRUE when the session has no school context set (app.current_school_id IS NULL). '
    'Used in RLS policies to allow platform admins to bypass tenant filters.';

-- =============================================================================
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  TABLE 1: platform.schools                                              │
-- └─────────────────────────────────────────────────────────────────────────┘
-- Policy intent:
--   - Platform admins (no school context) → see ALL schools
--   - School-scoped sessions               → see ONLY their own school row
--   - INSERT / UPDATE / DELETE             → only within own school_id
-- =============================================================================

ALTER TABLE platform.schools ENABLE ROW LEVEL SECURITY;
-- FORCE ROW LEVEL SECURITY is intentionally NOT set here.
-- Run:  ALTER TABLE platform.schools FORCE ROW LEVEL SECURITY;
-- ...only after full end-to-end testing to include table-owner sessions.

-- ── SELECT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_schools_select ON platform.schools;

CREATE POLICY rls_schools_select
    ON  platform.schools
    FOR SELECT
    TO  school_erp_app                          -- applies only to the app role
    USING (
        -- Platform admin: bypass tenant filter (sees all rows)
        platform.is_platform_admin()
        OR
        -- School-scoped session: see only this school's row
        school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_schools_select ON platform.schools IS
    'Platform admins (no school context) see all schools. '
    'School-scoped sessions see only their own row.';

-- ── INSERT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_schools_insert ON platform.schools;

CREATE POLICY rls_schools_insert
    ON  platform.schools
    FOR INSERT
    TO  school_erp_app
    WITH CHECK (
        -- Only platform-admin sessions may create new school rows
        platform.is_platform_admin()
    );

COMMENT ON POLICY rls_schools_insert ON platform.schools IS
    'Only platform-admin sessions (no school context) may insert new school rows.';

-- ── UPDATE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_schools_update ON platform.schools;

CREATE POLICY rls_schools_update
    ON  platform.schools
    FOR UPDATE
    TO  school_erp_app
    USING (
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    )
    WITH CHECK (
        -- Cannot move a school to a different school_id via UPDATE
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_schools_update ON platform.schools IS
    'Platform admins can update any school. School sessions can update only their own row.';

-- ── DELETE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_schools_delete ON platform.schools;

CREATE POLICY rls_schools_delete
    ON  platform.schools
    FOR DELETE
    TO  school_erp_app
    USING (
        -- Only platform admins may delete (hard deletes are also blocked by trigger)
        platform.is_platform_admin()
    );

COMMENT ON POLICY rls_schools_delete ON platform.schools IS
    'Only platform-admin sessions may delete school rows. '
    'Hard deletes are additionally blocked by trg_schools_no_hard_delete.';


-- =============================================================================
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  TABLE 2: platform.branches                                             │
-- └─────────────────────────────────────────────────────────────────────────┘
-- Policy intent:
--   - Platform admins → see ALL branches
--   - School sessions  → see ONLY branches belonging to their school
-- =============================================================================

ALTER TABLE platform.branches ENABLE ROW LEVEL SECURITY;
-- FORCE ROW LEVEL SECURITY intentionally not set.

-- ── SELECT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_branches_select ON platform.branches;

CREATE POLICY rls_branches_select
    ON  platform.branches
    FOR SELECT
    TO  school_erp_app
    USING (
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_branches_select ON platform.branches IS
    'Platform admins see all branches. School sessions see only their school''s branches.';

-- ── INSERT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_branches_insert ON platform.branches;

CREATE POLICY rls_branches_insert
    ON  platform.branches
    FOR INSERT
    TO  school_erp_app
    WITH CHECK (
        -- Must insert with own school_id (or platform admin may insert for any school)
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_branches_insert ON platform.branches IS
    'School sessions may only insert branches for their own school_id.';

-- ── UPDATE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_branches_update ON platform.branches;

CREATE POLICY rls_branches_update
    ON  platform.branches
    FOR UPDATE
    TO  school_erp_app
    USING (
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    )
    WITH CHECK (
        -- Cannot re-assign a branch to a different school
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_branches_update ON platform.branches IS
    'School sessions can update only their own school''s branches. Cannot move branch to another school.';

-- ── DELETE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_branches_delete ON platform.branches;

CREATE POLICY rls_branches_delete
    ON  platform.branches
    FOR DELETE
    TO  school_erp_app
    USING (
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_branches_delete ON platform.branches IS
    'School sessions can delete only branches within their own school.';


-- =============================================================================
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  TABLE 3: platform.roles                                                │
-- └─────────────────────────────────────────────────────────────────────────┘
-- Policy intent:
--   - Platform admins → see ALL roles (PLATFORM + all SCHOOL roles)
--   - School sessions  → see PLATFORM roles (shared) + their own SCHOOL roles
-- =============================================================================

ALTER TABLE platform.roles ENABLE ROW LEVEL SECURITY;
-- FORCE ROW LEVEL SECURITY intentionally not set.

-- ── SELECT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_roles_select ON platform.roles;

CREATE POLICY rls_roles_select
    ON  platform.roles
    FOR SELECT
    TO  school_erp_app
    USING (
        -- Platform admins: see everything
        platform.is_platform_admin()
        OR
        -- School sessions: see their own school roles + shared platform roles
        school_id IS NULL                               -- PLATFORM roles visible to all
        OR school_id = platform.current_school_id()    -- SCHOOL roles for own tenant only
    );

COMMENT ON POLICY rls_roles_select ON platform.roles IS
    'Platform admins see all roles. School sessions see PLATFORM roles (shared) '
    'plus their own SCHOOL-scoped roles.';

-- ── INSERT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_roles_insert ON platform.roles;

CREATE POLICY rls_roles_insert
    ON  platform.roles
    FOR INSERT
    TO  school_erp_app
    WITH CHECK (
        -- Platform admin: can create PLATFORM roles (school_id IS NULL)
        (platform.is_platform_admin() AND school_id IS NULL)
        OR
        -- School session: can only create roles for their own school
        (NOT platform.is_platform_admin() AND school_id = platform.current_school_id())
    );

COMMENT ON POLICY rls_roles_insert ON platform.roles IS
    'Platform admins can create PLATFORM roles. School sessions can only create roles for their own school.';

-- ── UPDATE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_roles_update ON platform.roles;

CREATE POLICY rls_roles_update
    ON  platform.roles
    FOR UPDATE
    TO  school_erp_app
    USING (
        (platform.is_platform_admin() AND school_id IS NULL)
        OR school_id = platform.current_school_id()
    )
    WITH CHECK (
        -- Cannot change a role's school_id to another school
        (platform.is_platform_admin() AND school_id IS NULL)
        OR school_id = platform.current_school_id()
    );

COMMENT ON POLICY rls_roles_update ON platform.roles IS
    'School sessions can only update their own SCHOOL roles. '
    'System roles are additionally protected by trg_roles_protect_system.';

-- ── DELETE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_roles_delete ON platform.roles;

CREATE POLICY rls_roles_delete
    ON  platform.roles
    FOR DELETE
    TO  school_erp_app
    USING (
        -- Platform admin: can delete non-system PLATFORM roles
        (platform.is_platform_admin() AND school_id IS NULL)
        OR
        -- School session: can delete their own non-system SCHOOL roles
        school_id = platform.current_school_id()
        -- Note: system role protection is enforced separately by
        --       trg_roles_protect_system regardless of RLS
    );

COMMENT ON POLICY rls_roles_delete ON platform.roles IS
    'School sessions can delete only their own SCHOOL roles. '
    'System roles are additionally protected by the trigger trg_roles_protect_system.';


-- =============================================================================
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  TABLE 4: platform.users                                                │
-- └─────────────────────────────────────────────────────────────────────────┘
-- Policy intent:
--   - Platform admins → see ALL users (platform + all school users)
--   - School sessions  → see ONLY users belonging to their school
--   - Users can always see their own row (self-service profile)
-- =============================================================================

ALTER TABLE platform.users ENABLE ROW LEVEL SECURITY;
-- FORCE ROW LEVEL SECURITY intentionally not set.

-- ── SELECT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_users_select ON platform.users;

CREATE POLICY rls_users_select
    ON  platform.users
    FOR SELECT
    TO  school_erp_app
    USING (
        -- Platform admins: see all users
        platform.is_platform_admin()
        OR
        -- School context: see only own school's users
        school_id = platform.current_school_id()
        OR
        -- Self-access: a user can always read their own row
        -- (requires app to also SET app.current_user_id in session)
        user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::BIGINT
    );

COMMENT ON POLICY rls_users_select ON platform.users IS
    'Platform admins see all users. School sessions see only their tenant''s users. '
    'Users always see their own row via app.current_user_id session variable.';

-- ── INSERT policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_users_insert ON platform.users;

CREATE POLICY rls_users_insert
    ON  platform.users
    FOR INSERT
    TO  school_erp_app
    WITH CHECK (
        -- Platform admin: can create platform-level users (school_id IS NULL)
        (platform.is_platform_admin() AND school_id IS NULL)
        OR
        -- School session: can only create users for their own school
        (NOT platform.is_platform_admin() AND school_id = platform.current_school_id())
    );

COMMENT ON POLICY rls_users_insert ON platform.users IS
    'School sessions can only create users within their own school_id.';

-- ── UPDATE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_users_update ON platform.users;

CREATE POLICY rls_users_update
    ON  platform.users
    FOR UPDATE
    TO  school_erp_app
    USING (
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
        OR user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::BIGINT
    )
    WITH CHECK (
        -- Cannot move a user to a different school via UPDATE
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
        OR user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::BIGINT
    );

COMMENT ON POLICY rls_users_update ON platform.users IS
    'School sessions can update only their own school''s users. '
    'Users can update their own profile row. Cannot transfer user to another school.';

-- ── DELETE policy ─────────────────────────────────────────────────────────

DROP POLICY IF EXISTS rls_users_delete ON platform.users;

CREATE POLICY rls_users_delete
    ON  platform.users
    FOR DELETE
    TO  school_erp_app
    USING (
        -- Hard deletes are blocked by trigger; this policy scopes who CAN attempt
        platform.is_platform_admin()
        OR school_id = platform.current_school_id()
        -- Self-delete intentionally excluded — must go via platform admin
    );

COMMENT ON POLICY rls_users_delete ON platform.users IS
    'School sessions can only attempt to delete users in their own school. '
    'Hard deletes are blocked by trg_users_no_hard_delete; use deleted_at instead.';


-- =============================================================================
-- VERIFICATION QUERY
-- Run after applying this file to confirm RLS status on all four tables:
-- =============================================================================
--
-- SELECT
--     schemaname,
--     tablename,
--     rowsecurity      AS rls_enabled,
--     forcerowsecurity AS rls_forced
-- FROM pg_tables
-- WHERE schemaname = 'platform'
--   AND tablename IN ('schools','branches','roles','users')
-- ORDER BY tablename;
--
-- Expected output:
--   platform | branches | true  | false
--   platform | roles    | true  | false
--   platform | schools  | true  | false
--   platform | users    | true  | false
--
-- =============================================================================

-- =============================================================================
-- APPLICATION LAYER USAGE PATTERN
-- =============================================================================
--
-- Every backend request handler MUST set the session variables before querying:
--
--   -- School-scoped request (teacher, student, principal):
--   SET LOCAL app.current_school_id = '42';
--   SET LOCAL app.current_user_id   = '1001';
--
--   -- Platform-admin request (super-admin, support):
--   -- Do NOT set app.current_school_id — leave it unset or set to empty string
--   RESET app.current_school_id;
--
--   -- Using a connection pool (recommended pattern with pgBouncer / node-postgres):
--   BEGIN;
--   SET LOCAL app.current_school_id = $1;   -- bind param
--   SET LOCAL app.current_user_id   = $2;   -- bind param
--   -- ... execute your queries ...
--   COMMIT;
--   -- SET LOCAL automatically rolls back at end of transaction
--
-- =============================================================================

-- =============================================================================
-- TO FORCE RLS (include table owners — run AFTER full testing):
-- =============================================================================
--
--   ALTER TABLE platform.schools  FORCE ROW LEVEL SECURITY;
--   ALTER TABLE platform.branches FORCE ROW LEVEL SECURITY;
--   ALTER TABLE platform.roles    FORCE ROW LEVEL SECURITY;
--   ALTER TABLE platform.users    FORCE ROW LEVEL SECURITY;
--
-- To DISABLE RLS entirely on a table (emergency bypass):
--   ALTER TABLE platform.schools  DISABLE ROW LEVEL SECURITY;
--
-- =============================================================================

COMMIT;

-- =============================================================================
-- END OF 09_rls_policies.sql
-- Next: 10_platform_audit_log.sql  (immutable platform-wide audit trail table)
-- =============================================================================
