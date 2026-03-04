-- =============================================================================
-- FILE: 07_platform_modules.sql
-- PURPOSE: Create platform.modules — feature/module registry for the ERP
-- ENGINE: PostgreSQL 15+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap.sql
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN (connected to school_erp_saas as school_erp_owner):
--   psql -U school_erp_owner -d school_erp_saas -f 07_platform_modules.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- TABLE: platform.modules
-- Purpose: Master registry of every feature module available in the ERP.
--          Modules are referenced by:
--             - platform.plan_modules        (which plans include which modules)
--             - platform.role_permissions    (which roles can access which modules)
--             - platform.school_modules      (per-school module toggle overrides)
--          is_platform_level = TRUE  → visible only to SaaS super-admins
--          is_platform_level = FALSE → school-facing module (students, staff, etc.)
-- =============================================================================

CREATE TABLE IF NOT EXISTS platform.modules (

    -- -------------------------------------------------------------------------
    -- Primary Key
    -- -------------------------------------------------------------------------
    module_id               BIGINT              NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- -------------------------------------------------------------------------
    -- Identity
    -- -------------------------------------------------------------------------
    module_name             VARCHAR(150)        NOT NULL,
    module_code             VARCHAR(100)        NOT NULL,   -- machine-readable key e.g. 'STUDENT_MANAGEMENT'
    description             TEXT                NULL,

    -- -------------------------------------------------------------------------
    -- Classification
    -- -------------------------------------------------------------------------
    parent_module_id        BIGINT              NULL,       -- NULL = top-level module; NOT NULL = sub-module
    display_order           SMALLINT            NOT NULL DEFAULT 0,   -- rendering order in UI menus
    icon_key                VARCHAR(100)        NULL,       -- icon identifier (e.g. material icon name)
    route_path              VARCHAR(255)        NULL,       -- frontend route e.g. '/admin/students'
    is_platform_level       BOOLEAN             NOT NULL DEFAULT FALSE,
    is_active               BOOLEAN             NOT NULL DEFAULT TRUE,

    -- -------------------------------------------------------------------------
    -- Audit
    -- -------------------------------------------------------------------------
    created_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- =========================================================================
    -- CONSTRAINTS
    -- =========================================================================

    CONSTRAINT pk_modules
        PRIMARY KEY (module_id),

    -- Machine-readable code must be globally unique (used in permission checks)
    CONSTRAINT uq_modules_module_code
        UNIQUE (module_code),

    -- Human-readable name must also be unique (prevents duplicate menu entries)
    CONSTRAINT uq_modules_module_name
        UNIQUE (module_name),

    -- Self-referential FK: sub-modules point to their parent
    CONSTRAINT fk_modules_parent_module_id
        FOREIGN KEY (parent_module_id)
        REFERENCES platform.modules (module_id)
        ON DELETE RESTRICT      -- cannot delete a parent while children exist
        ON UPDATE CASCADE,

    -- module_code must be uppercase, alphanumeric + underscore only
    CONSTRAINT chk_modules_module_code_format
        CHECK (module_code ~ '^[A-Z][A-Z0-9_]{1,99}$'),

    -- module_name must not be blank
    CONSTRAINT chk_modules_module_name_not_blank
        CHECK (TRIM(module_name) <> ''),

    -- A module cannot be its own parent
    CONSTRAINT chk_modules_no_self_reference
        CHECK (parent_module_id IS DISTINCT FROM module_id),

    -- display_order must be non-negative
    CONSTRAINT chk_modules_display_order
        CHECK (display_order >= 0)

);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE platform.modules IS
    'Master feature/module registry. Defines every navigable section of the ERP. '
    'Referenced by plan_modules (entitlement), role_permissions (access), and school_modules (overrides).';

COMMENT ON COLUMN platform.modules.module_id          IS 'Surrogate PK. Referenced as FK in plan_modules, role_permissions, school_modules.';
COMMENT ON COLUMN platform.modules.module_code        IS 'Stable machine-readable key. Used in code-level permission checks. UPPERCASE_SNAKE format enforced.';
COMMENT ON COLUMN platform.modules.module_name        IS 'UI display name. Must be unique and non-blank.';
COMMENT ON COLUMN platform.modules.parent_module_id   IS 'NULL = top-level menu item. NOT NULL = sub-module nested under parent. RESTRICT prevents orphaned sub-modules.';
COMMENT ON COLUMN platform.modules.display_order      IS 'Ascending sort order for sidebar/menu rendering. Lower number = renders first.';
COMMENT ON COLUMN platform.modules.icon_key           IS 'Optional icon identifier (e.g. Material Design icon name). Resolved to actual icon at frontend.';
COMMENT ON COLUMN platform.modules.route_path         IS 'Frontend SPA route for this module (e.g. /school/students). NULL = not directly navigable (grouping node).';
COMMENT ON COLUMN platform.modules.is_platform_level  IS 'TRUE = visible to SaaS super-admins only. FALSE = school-facing, subject to plan entitlement.';
COMMENT ON COLUMN platform.modules.is_active          IS 'FALSE = module is disabled platform-wide. Inactive modules are hidden from all UIs and permission checks.';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Platform vs school-facing filter (permission middleware, plan entitlement checks)
CREATE INDEX IF NOT EXISTS idx_modules_is_platform_level
    ON platform.modules (is_platform_level);

-- Active modules only (UI rendering, permission evaluation hot path)
CREATE INDEX IF NOT EXISTS idx_modules_is_active
    ON platform.modules (is_active)
    WHERE is_active = TRUE;

-- Self-referential FK: parent lookup (build module tree queries)
CREATE INDEX IF NOT EXISTS idx_modules_parent_module_id
    ON platform.modules (parent_module_id)
    WHERE parent_module_id IS NOT NULL;

-- Composite: active modules by platform level + display order (menu build query)
CREATE INDEX IF NOT EXISTS idx_modules_platform_active_order
    ON platform.modules (is_platform_level, is_active, display_order);

-- Top-level modules only (frequently queried to build navigation roots)
CREATE INDEX IF NOT EXISTS idx_modules_top_level
    ON platform.modules (display_order)
    WHERE parent_module_id IS NULL AND is_active = TRUE;

-- =============================================================================
-- SEED: all ERP modules (platform-level + school-level)
-- =============================================================================

INSERT INTO platform.modules
    (module_name, module_code, description, display_order, icon_key, route_path, is_platform_level, is_active)
VALUES

    -- ── PLATFORM LEVEL (super-admin only) ────────────────────────────────────
    ('Platform Dashboard',      'PLATFORM_DASHBOARD',       'SaaS-wide KPI overview.',                          1,  'dashboard',            '/platform/dashboard',              TRUE,  TRUE),
    ('School Management',       'SCHOOL_MANAGEMENT',        'Onboard and manage school tenants.',               2,  'school',               '/platform/schools',                TRUE,  TRUE),
    ('Plan Management',         'PLAN_MANAGEMENT',          'Define and edit subscription plans.',              3,  'subscriptions',        '/platform/plans',                  TRUE,  TRUE),
    ('Subscription Management', 'SUBSCRIPTION_MANAGEMENT',  'Monitor and manage school subscriptions.',         4,  'receipt_long',         '/platform/subscriptions',          TRUE,  TRUE),
    ('Billing & Invoices',      'BILLING_INVOICES',         'View and manage platform invoices.',               5,  'payments',             '/platform/billing',                TRUE,  TRUE),
    ('Platform Users',          'PLATFORM_USERS',           'Super-admin and support staff accounts.',          6,  'admin_panel_settings', '/platform/users',                  TRUE,  TRUE),
    ('Roles & Permissions',     'ROLES_PERMISSIONS',        'Define roles and map module permissions.',         7,  'lock',                 '/platform/roles',                  TRUE,  TRUE),
    ('Module Registry',         'MODULE_REGISTRY',          'View and manage ERP module definitions.',          8,  'apps',                 '/platform/modules',                TRUE,  TRUE),
    ('Platform Audit Logs',     'PLATFORM_AUDIT_LOGS',      'Immutable log of all platform-level actions.',     9,  'history',              '/platform/audit-logs',             TRUE,  TRUE),
    ('System Settings',         'SYSTEM_SETTINGS',          'Global platform configuration key/value store.',  10,  'settings',             '/platform/settings',               TRUE,  TRUE),

    -- ── SCHOOL LEVEL (tenant-facing) ─────────────────────────────────────────

    -- Core Admin
    ('School Dashboard',        'SCHOOL_DASHBOARD',         'School-level KPI overview.',                       1,  'dashboard',            '/school/dashboard',                FALSE, TRUE),
    ('Branch Management',       'BRANCH_MANAGEMENT',        'Manage campus branches.',                          2,  'account_tree',         '/school/branches',                 FALSE, TRUE),
    ('Academic Years',          'ACADEMIC_YEARS',           'Manage academic year definitions.',                3,  'event',                '/school/academic-years',           FALSE, TRUE),
    ('Class & Section',         'CLASS_SECTION',            'Manage class grades and sections.',                4,  'class',                '/school/classes',                  FALSE, TRUE),
    ('Subjects',                'SUBJECTS',                 'Manage subjects and syllabi.',                     5,  'menu_book',            '/school/subjects',                 FALSE, TRUE),

    -- People
    ('Student Management',      'STUDENT_MANAGEMENT',       'Enroll and manage student records.',               6,  'people',               '/school/students',                 FALSE, TRUE),
    ('Staff Management',        'STAFF_MANAGEMENT',         'Manage teaching and non-teaching staff.',          7,  'badge',                '/school/staff',                    FALSE, TRUE),
    ('Parent Management',       'PARENT_MANAGEMENT',        'Manage parent/guardian records.',                  8,  'family_restroom',      '/school/parents',                  FALSE, TRUE),

    -- Academic
    ('Timetable',               'TIMETABLE',                'Schedule and view class timetables.',              9,  'schedule',             '/school/timetable',                FALSE, TRUE),
    ('Attendance',              'ATTENDANCE',               'Track daily student and staff attendance.',        10, 'fact_check',           '/school/attendance',               FALSE, TRUE),
    ('Examinations',            'EXAMINATIONS',             'Conduct exams and record marks.',                  11, 'quiz',                 '/school/exams',                    FALSE, TRUE),
    ('Report Cards',            'REPORT_CARDS',             'Generate and publish student report cards.',       12, 'description',          '/school/report-cards',             FALSE, TRUE),
    ('Homework',                'HOMEWORK',                 'Assign and track homework.',                       13, 'assignment',           '/school/homework',                 FALSE, TRUE),

    -- Finance
    ('Fee Management',          'FEE_MANAGEMENT',           'Define fee structures and collect payments.',      14, 'account_balance_wallet','/school/fees',                   FALSE, TRUE),
    ('Payroll',                 'PAYROLL',                  'Manage staff salary and payroll.',                 15, 'payments',             '/school/payroll',                  FALSE, TRUE),
    ('Expense Tracking',        'EXPENSE_TRACKING',         'Track school expenses and budgets.',               16, 'receipt',              '/school/expenses',                 FALSE, TRUE),

    -- Communication
    ('Announcements',           'ANNOUNCEMENTS',            'Publish school-wide announcements.',               17, 'campaign',             '/school/announcements',            FALSE, TRUE),
    ('Messaging',               'MESSAGING',                'Internal messaging between staff, students.',      18, 'chat',                 '/school/messaging',                FALSE, TRUE),
    ('SMS & Email Alerts',      'SMS_EMAIL_ALERTS',         'Send SMS / email notifications.',                  19, 'notifications_active', '/school/alerts',                   FALSE, TRUE),

    -- Operations
    ('Library',                 'LIBRARY',                  'Manage book inventory and lending.',               20, 'local_library',        '/school/library',                  FALSE, TRUE),
    ('Transport',               'TRANSPORT',                'Manage school buses and routes.',                  21, 'directions_bus',       '/school/transport',                FALSE, TRUE),
    ('Hostel',                  'HOSTEL',                   'Manage hostel rooms and boarders.',                22, 'hotel',                '/school/hostel',                   FALSE, TRUE),
    ('Inventory',               'INVENTORY',                'Track school asset and inventory.',                23, 'inventory_2',          '/school/inventory',                FALSE, TRUE),
    ('Events & Calendar',       'EVENTS_CALENDAR',          'Manage school events and calendar.',               24, 'event_available',      '/school/events',                   FALSE, TRUE),

    -- Reporting
    ('Reports & Analytics',     'REPORTS_ANALYTICS',        'Advanced reporting and analytics dashboards.',     25, 'bar_chart',            '/school/reports',                  FALSE, TRUE),
    ('School Audit Logs',       'SCHOOL_AUDIT_LOGS',        'School-scoped action audit trail.',                26, 'history',              '/school/audit-logs',               FALSE, TRUE),
    ('School Settings',         'SCHOOL_SETTINGS',          'School-level configuration and preferences.',      27, 'tune',                 '/school/settings',                 FALSE, TRUE)

ON CONFLICT (module_code) DO NOTHING;

COMMIT;

-- =============================================================================
-- END OF 07_platform_modules.sql
-- Next: 08_platform_permissions.sql  (role_permissions: role ↔ module access map)
-- =============================================================================
