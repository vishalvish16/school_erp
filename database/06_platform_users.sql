-- =============================================================================
-- FILE: 06_platform_users.sql
-- PURPOSE: Create platform.users — unified user identity table (all personas)
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql, 03_platform_schools.sql,
--             04_platform_branches.sql, 05_platform_roles.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 06_platform_users.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- TABLE: platform.users
-- Purpose: Unified identity table for every human actor on the platform:
--          SaaS super-admins (school_id IS NULL) and school-level users
--          (students, teachers, principals — school_id IS NOT NULL).
--          password_hash uses bcrypt stored at cost ≥ 12 (application layer).
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.users (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    user_id                 BIGINT              NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Tenant Scope  (NULL = platform-level user)
    -- -------------------------------------------------------------------------
    school_id               BIGINT              NULL,
    branch_id               BIGINT              NULL,

    -- -------------------------------------------------------------------------
    -- Role
    -- -------------------------------------------------------------------------
    role_id                 BIGINT              NOT NULL,

    -- -------------------------------------------------------------------------
    -- Identity
    -- -------------------------------------------------------------------------
    first_name              VARCHAR(100)        NULL,
    last_name               VARCHAR(100)        NULL,
    email                   VARCHAR(255)        NOT NULL,
    phone                   VARCHAR(20)         NULL,

    -- -------------------------------------------------------------------------
    -- Credentials (security fields)
    -- -------------------------------------------------------------------------
    password_hash           TEXT                NOT NULL,
    failed_login_attempts   SMALLINT            NOT NULL DEFAULT 0,
    locked_until            TIMESTAMPTZ         NULL,       -- brute-force lockout window
    password_changed_at     TIMESTAMPTZ         NULL,       -- force-rotate detection
    must_change_password    BOOLEAN             NOT NULL DEFAULT FALSE,

    -- -------------------------------------------------------------------------
    -- MFA
    -- -------------------------------------------------------------------------
    mfa_enabled             BOOLEAN             NOT NULL DEFAULT FALSE,
    mfa_secret              TEXT                NULL,       -- TOTP secret; encrypted at app layer

    -- -------------------------------------------------------------------------
    -- Lifecycle
    -- -------------------------------------------------------------------------
    is_active               BOOLEAN             NOT NULL DEFAULT TRUE,
    email_verified          BOOLEAN             NOT NULL DEFAULT FALSE,
    email_verified_at       TIMESTAMPTZ         NULL,
    last_login              TIMESTAMPTZ         NULL,
    last_login_ip           INET                NULL,
    deleted_at              TIMESTAMPTZ         NULL,       -- soft delete
    created_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_users
        PRIMARY KEY (user_id),

    -- School tenant: cascade — user records are owned by the school
    CONSTRAINT fk_users_school_id
        FOREIGN KEY (school_id)
        REFERENCES platform.schools (school_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Branch assignment: nullable, SET NULL when branch is removed
    CONSTRAINT fk_users_branch_id
        FOREIGN KEY (branch_id)
        REFERENCES platform.branches (branch_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Role: RESTRICT — cannot delete a role while users are assigned to it
    CONSTRAINT fk_users_role_id
        FOREIGN KEY (role_id)
        REFERENCES platform.roles (role_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Email is unique globally across ALL tenants and platform users
    CONSTRAINT uq_users_email
        UNIQUE (email),

    -- ---- Format guards -------------------------------------------------------

    CONSTRAINT chk_users_email_format
        CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),

    CONSTRAINT chk_users_phone_format
        CHECK (phone IS NULL OR phone ~ '^\+?[0-9\s\-\(\)]{7,20}$'),

    CONSTRAINT chk_users_failed_login_attempts
        CHECK (failed_login_attempts >= 0),

    -- first_name / last_name must not be blank if provided
    CONSTRAINT chk_users_first_name_not_blank
        CHECK (first_name IS NULL OR TRIM(first_name) <> ''),

    CONSTRAINT chk_users_last_name_not_blank
        CHECK (last_name IS NULL OR TRIM(last_name) <> ''),

    -- ---- Scope alignment guard -----------------------------------------------
    -- A branch can only be assigned if the user already has a school
    CONSTRAINT chk_users_branch_requires_school
        CHECK (branch_id IS NULL OR school_id IS NOT NULL),

    -- email_verified_at only makes sense when email_verified = TRUE
    CONSTRAINT chk_users_email_verified_at_alignment
        CHECK (
            (email_verified = FALSE AND email_verified_at IS NULL)
            OR
            (email_verified = TRUE  AND email_verified_at IS NOT NULL)
        )

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.users IS
    'Unified identity table for all platform actors. '
    'school_id IS NULL = SaaS platform admin. school_id IS NOT NULL = school-level user (teacher, student, principal, etc.).';

COMMENT ON COLUMN platform.users.user_id               IS 'Surrogate PK. Referenced as FK in sessions, audit_logs, assignments, etc.';
COMMENT ON COLUMN platform.users.school_id             IS 'NULL = platform-level user. NOT NULL = tenant-scoped user. Cascade-deleted with school.';
COMMENT ON COLUMN platform.users.branch_id             IS 'Optional home-branch for school users. SET NULL when branch is removed.';
COMMENT ON COLUMN platform.users.role_id               IS 'Single primary role. FK to platform.roles. RESTRICT prevents accidental role deletion.';
COMMENT ON COLUMN platform.users.password_hash         IS 'bcrypt hash, cost ≥ 12. Plain-text password MUST NEVER be stored here.';
COMMENT ON COLUMN platform.users.failed_login_attempts IS 'Incremented on each failed login. Reset to 0 on successful login.';
COMMENT ON COLUMN platform.users.locked_until          IS 'Non-NULL = account locked until this timestamp. Checked before auth proceeds.';
COMMENT ON COLUMN platform.users.password_changed_at   IS 'Timestamp of last password change. Used to force re-login after admin resets.';
COMMENT ON COLUMN platform.users.must_change_password  IS 'TRUE = user must set a new password on next login (e.g. after admin-created account).';
COMMENT ON COLUMN platform.users.mfa_secret            IS 'TOTP shared secret. Stored encrypted at application layer — never plain-text.';
COMMENT ON COLUMN platform.users.email_verified        IS 'FALSE = email address not yet confirmed via link/code.';
COMMENT ON COLUMN platform.users.last_login_ip         IS 'IP address of the most recent successful login (INET supports IPv4 + IPv6).';
COMMENT ON COLUMN platform.users.deleted_at            IS 'Soft delete. NULL = active. Application filters WHERE deleted_at IS NULL.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Global unique email lookup (login, forgot-password, duplicate checks)
-- Covered by the UNIQUE constraint — adding explicit named index for observability
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email
    ON platform.users (email)
    WHERE deleted_at IS NULL;

-- FK + tenant isolation: all school-scoped queries include school_id
CREATE INDEX IF NOT EXISTS idx_users_school_id
    ON platform.users (school_id)
    WHERE school_id IS NOT NULL;

-- FK index: branch assignment lookups and cascade
CREATE INDEX IF NOT EXISTS idx_users_branch_id
    ON platform.users (branch_id)
    WHERE branch_id IS NOT NULL;

-- FK + permission evaluation: role lookups
CREATE INDEX IF NOT EXISTS idx_users_role_id
    ON platform.users (role_id);

-- Lifecycle flag: active/inactive filter used in almost every query
CREATE INDEX IF NOT EXISTS idx_users_is_active
    ON platform.users (is_active);

-- Composite: school users query — hottest production path
CREATE INDEX IF NOT EXISTS idx_users_school_id_is_active
    ON platform.users (school_id, is_active)
    WHERE deleted_at IS NULL;

-- Partial composite: active users only (tightest index, covers 99% of app reads)
CREATE INDEX IF NOT EXISTS idx_users_school_active_only
    ON platform.users (school_id, role_id)
    WHERE is_active = TRUE AND deleted_at IS NULL;

-- Soft-delete: admin recovery + purge-old-records jobs
CREATE INDEX IF NOT EXISTS idx_users_deleted_at
    ON platform.users (deleted_at)
    WHERE deleted_at IS NOT NULL;

-- Brute-force lockout: auth service checks locked_until before verifying password
CREATE INDEX IF NOT EXISTS idx_users_locked_until
    ON platform.users (locked_until)
    WHERE locked_until IS NOT NULL;

-- MFA management: list users with MFA enabled (admin security report)
CREATE INDEX IF NOT EXISTS idx_users_mfa_enabled
    ON platform.users (school_id, mfa_enabled)
    WHERE mfa_enabled = TRUE;

-- Unverified email: background job to send reminder / expire unverified accounts
CREATE INDEX IF NOT EXISTS idx_users_email_unverified
    ON platform.users (created_at)
    WHERE email_verified = FALSE AND deleted_at IS NULL;

-- =============================================================================
-- TRIGGER: auto-stamp updated_at
-- =============================================================================

DROP TRIGGER IF EXISTS trg_users_updated_at ON platform.users;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON platform.users
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();

-- =============================================================================
-- TRIGGER: auto-set password_changed_at when password_hash changes
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.fn_users_track_password_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
    -- Only stamp when the hash actually changes value
    IF NEW.password_hash IS DISTINCT FROM OLD.password_hash THEN
        NEW.password_changed_at := NOW();
        NEW.must_change_password := FALSE;   -- reset force-change flag after a real change
        NEW.failed_login_attempts := 0;      -- reset lockout counter on fresh password
        NEW.locked_until := NULL;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION platform.fn_users_track_password_change() IS
    'Auto-stamps password_changed_at, resets must_change_password, '
    'failed_login_attempts, and locked_until whenever password_hash changes.';

DROP TRIGGER IF EXISTS trg_users_password_change ON platform.users;

CREATE TRIGGER trg_users_password_change
    BEFORE UPDATE OF password_hash ON platform.users
    FOR EACH ROW
    EXECUTE FUNCTION platform.fn_users_track_password_change();

-- =============================================================================
-- TRIGGER: auto-set email_verified_at when email_verified flips to TRUE
-- =============================================================================

CREATE OR REPLACE FUNCTION platform.fn_users_track_email_verification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
    IF NEW.email_verified = TRUE AND OLD.email_verified = FALSE THEN
        NEW.email_verified_at := NOW();
    END IF;
    IF NEW.email_verified = FALSE THEN
        NEW.email_verified_at := NULL;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION platform.fn_users_track_email_verification() IS
    'Auto-stamps email_verified_at when email_verified is set to TRUE; '
    'nullifies it when reverted to FALSE.';

DROP TRIGGER IF EXISTS trg_users_email_verification ON platform.users;

CREATE TRIGGER trg_users_email_verification
    BEFORE UPDATE OF email_verified ON platform.users
    FOR EACH ROW
    EXECUTE FUNCTION platform.fn_users_track_email_verification();

-- =============================================================================
-- TRIGGER: prevent hard delete — use deleted_at instead
-- =============================================================================

DROP TRIGGER IF EXISTS trg_users_no_hard_delete ON platform.users;

CREATE TRIGGER trg_users_no_hard_delete
    BEFORE DELETE ON platform.users
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_block_hard_delete();

-- =============================================================================
-- RELATED TABLE: platform.user_sessions
-- Purpose: Per-user session + refresh-token tracking.
--          Kept in same migration file for cohesion.
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.user_sessions (

    session_id              BIGINT              NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id                 BIGINT              NOT NULL,
    token_hash              TEXT                NOT NULL,   -- SHA-256 of refresh token; never store raw JWT
    ip_address              INET                NOT NULL,
    user_agent              TEXT                NULL,
    device_fingerprint      TEXT                NULL,       -- optional client device hash
    expires_at              TIMESTAMPTZ         NOT NULL,
    revoked_at              TIMESTAMPTZ         NULL,       -- NULL = still valid
    created_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_user_sessions
        PRIMARY KEY (session_id),

    CONSTRAINT uq_user_sessions_token_hash
        UNIQUE (token_hash),

    CONSTRAINT fk_user_sessions_user_id
        FOREIGN KEY (user_id)
        REFERENCES platform.users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_user_sessions_expires_at
        CHECK (expires_at > created_at)
);

COMMENT ON TABLE platform.user_sessions IS
    'Refresh-token registry per user. Revoke by setting revoked_at. '
    'Purge expired rows with a nightly cron: DELETE WHERE expires_at < NOW().';

COMMENT ON COLUMN platform.user_sessions.token_hash IS 'SHA-256 of the raw refresh token. Raw token lives only in client cookie/storage.';

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id
    ON platform.user_sessions (user_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at
    ON platform.user_sessions (expires_at);

-- Active sessions only: the auth middleware checks this path on every request
CREATE INDEX IF NOT EXISTS idx_user_sessions_active
    ON platform.user_sessions (user_id, expires_at)
    WHERE revoked_at IS NULL;

-- =============================================================================
-- HELPER VIEW: platform.active_users
-- Purpose: Application-safe view — strips soft-deleted and inactive users,
--          joins role + school context. Use as default user lookup target.
-- =============================================================================

CREATE OR REPLACE VIEW platform.active_users AS
SELECT
    u.user_id,
    u.school_id,
    u.branch_id,
    u.role_id,
    u.first_name,
    u.last_name,
    TRIM(CONCAT_WS(' ', u.first_name, u.last_name))    AS full_name,
    u.email,
    u.phone,
    u.mfa_enabled,
    u.email_verified,
    u.must_change_password,
    u.last_login,
    u.last_login_ip,
    u.created_at,
    u.updated_at,
    -- Role context
    r.role_name,
    r.role_type,
    -- School context (NULL for platform users)
    s.school_name,
    s.school_code,
    -- Branch context (NULL when not assigned)
    b.branch_name,
    b.branch_code,
    -- Derived: account security posture
    CASE
        WHEN u.locked_until IS NOT NULL AND u.locked_until > NOW() THEN 'locked'
        WHEN u.must_change_password                                 THEN 'password_reset_required'
        WHEN NOT u.email_verified                                   THEN 'email_unverified'
        ELSE 'ok'
    END AS account_status
FROM
    platform.users          u
    JOIN  platform.roles    r ON r.role_id   = u.role_id
    LEFT  JOIN platform.schools   s ON s.school_id  = u.school_id
    LEFT  JOIN platform.branches  b ON b.branch_id  = u.branch_id
WHERE
    u.is_active   = TRUE
    AND u.deleted_at IS NULL;

COMMENT ON VIEW platform.active_users IS
    'Active, non-deleted users with role, school, and branch context. '
    'account_status column reflects live security posture: locked / password_reset_required / email_unverified / ok.';

-- =============================================================================
-- SEED: default platform super-admin user
-- Password: Admin@12345  (bcrypt cost 12 — MUST CHANGE on first login)
-- =============================================================================

DO $$
DECLARE
    v_role_id BIGINT;
BEGIN
    SELECT role_id INTO v_role_id
    FROM platform.roles
    WHERE role_name = 'Super Admin' AND school_id IS NULL
    LIMIT 1;

    IF v_role_id IS NOT NULL THEN
        INSERT INTO platform.users
            (school_id, branch_id, role_id, first_name, last_name,
             email, password_hash, is_active, email_verified,
             email_verified_at, must_change_password)
        VALUES
            (NULL, NULL, v_role_id, 'Super', 'Admin',
             'superadmin@schoolerp.io',
             crypt('Admin@12345', gen_salt('bf', 12)),
             TRUE, TRUE, NOW(), TRUE)
        ON CONFLICT (email) DO NOTHING;
    END IF;
END;
$$;

COMMIT;

-- =============================================================================
-- END OF 06_platform_users.sql
-- Next: 07_platform_permissions.sql  (permission registry + role_permissions)
-- =============================================================================
