-- =============================================================================
-- FILE: 10_demo_data.sql
-- PURPOSE: Realistic demo seed data for all platform tables
-- ENGINE: PostgreSQL 16+  |  SCHEMA: platform
-- DEPENDS ON: 00_bootstrap → 09_rls_policies (all migrations applied)
-- GENERATED: 2026-02-21
-- =============================================================================
-- HOW TO RUN:
--   psql -U school_erp_owner -h localhost -p 5432 -d school_erp_saas -f 10_demo_data.sql
-- =============================================================================

BEGIN;
SET search_path TO platform, public;

-- =============================================================================
-- SECTION 1 : platform.schools  (3 demo schools)
-- =============================================================================

INSERT INTO platform.schools
    (plan_id, school_name, school_code, subdomain,
     contact_email, contact_phone,
     address, city, state, pincode, country,
     subscription_start, subscription_end, is_active)
SELECT
    p.plan_id,
    s.school_name, s.school_code, s.subdomain,
    s.contact_email, s.contact_phone,
    s.address, s.city, s.state, s.pincode, s.country,
    s.subscription_start::DATE, s.subscription_end::DATE, TRUE
FROM (VALUES
    ('Growth',    'Sunrise Public School',      'SPS001', 'sunrise',
     'admin@sunriseschool.in',   '+91-9876543210',
     '12, Nehru Nagar, Sector 5', 'Ahmedabad',  'Gujarat',  '380015', 'India',
     '2025-04-01', '2026-03-31'),

    ('Business',  'Delhi Heritage Academy',     'DHA002', 'delhiheritage',
     'principal@dha.edu.in',     '+91-9988776655',
     '47-B, Vasant Vihar',       'New Delhi',   'Delhi',    '110057', 'India',
     '2025-06-01', '2026-05-31'),

    ('Starter',   'Green Valley International', 'GVI003', 'greenvalley',
     'info@greenvalley.school',  '+91-9123456789',
     'Plot 88, MIDC Road',       'Pune',        'Maharashtra','411038', 'India',
     '2026-01-15', '2027-01-14')
) AS s(plan_name,
       school_name, school_code, subdomain,
       contact_email, contact_phone,
       address, city, state, pincode, country,
       subscription_start, subscription_end)
JOIN platform.platform_plans p ON p.plan_name = s.plan_name
ON CONFLICT (school_code) DO NOTHING;

-- =============================================================================
-- SECTION 2 : platform.branches  (7 branches across 3 schools)
-- =============================================================================

INSERT INTO platform.branches
    (school_id, branch_name, branch_code, address, city, state, is_active)
SELECT
    sc.school_id,
    b.branch_name, b.branch_code,
    b.address, b.city, b.state, TRUE
FROM (VALUES
    -- Sunrise Public School (SPS001) — 3 branches
    ('SPS001', 'Sunrise Main Campus',      'SPS-MAIN',  '12, Nehru Nagar, Sector 5', 'Ahmedabad', 'Gujarat'),
    ('SPS001', 'Sunrise Satellite Campus', 'SPS-SAT',   'B/4, Chandkheda Cross Rd',  'Ahmedabad', 'Gujarat'),
    ('SPS001', 'Sunrise South Campus',     'SPS-SOUTH', '23, Bopal Ring Road',       'Ahmedabad', 'Gujarat'),

    -- Delhi Heritage Academy (DHA002) — 2 branches
    ('DHA002', 'DHA Vasant Vihar',         'DHA-VV',    '47-B, Vasant Vihar',        'New Delhi',  'Delhi'),
    ('DHA002', 'DHA Dwarka',               'DHA-DWK',   'Sector 12, Dwarka',         'New Delhi',  'Delhi'),

    -- Green Valley International (GVI003) — 2 branches
    ('GVI003', 'Green Valley Main',        'GVI-MAIN',  'Plot 88, MIDC Road',        'Pune',       'Maharashtra'),
    ('GVI003', 'Green Valley Hinjewadi',   'GVI-HIN',   'Phase 2, Hinjewadi',        'Pune',       'Maharashtra')
) AS b(school_code, branch_name, branch_code, address, city, state)
JOIN platform.schools sc ON sc.school_code = b.school_code
ON CONFLICT (school_id, branch_code) DO NOTHING;

-- =============================================================================
-- SECTION 3 : platform.roles  (school-level roles for each school)
-- =============================================================================

INSERT INTO platform.roles
    (school_id, role_name, role_type, description, is_system_role)
SELECT
    sc.school_id,
    r.role_name,
    'SCHOOL'::platform.role_type_enum,
    r.description,
    TRUE
FROM (VALUES
    ('Principal',           'Full school access — policy and operations'),
    ('Vice Principal',      'Delegated school management'),
    ('Class Teacher',       'Manages assigned class + attendance'),
    ('Subject Teacher',     'Teaching, homework, marks entry'),
    ('Accountant',          'Fee collection, payroll, expenses'),
    ('Librarian',           'Library module full access'),
    ('Transport Manager',   'Bus routes, drivers, student transport'),
    ('Reception / Admin',   'Front-desk: admissions, enquiries'),
    ('Student',             'Own profile, timetable, homework, results'),
    ('Parent / Guardian',   'Child progress, fee, attendance view'),
    ('IT Administrator',    'School settings, user management'),
    ('Exam Coordinator',    'Exam scheduling, marks, report cards')
) AS r(role_name, description)
CROSS JOIN (SELECT DISTINCT school_id FROM platform.schools) sc
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 4 : platform.users  (25 demo users)
-- =============================================================================

-- ── School-level users ──────────────────────────────────────────────────────
-- Resolves role_id and school_id/branch_id dynamically

DO $$
DECLARE
    -- school IDs
    v_sps   BIGINT; v_dha BIGINT; v_gvi BIGINT;
    -- branch IDs
    v_sps_main  BIGINT; v_sps_sat   BIGINT; v_sps_south BIGINT;
    v_dha_vv    BIGINT; v_dha_dwk   BIGINT;
    v_gvi_main  BIGINT; v_gvi_hin   BIGINT;
    -- role IDs per school (SPS)
    v_sps_principal   BIGINT; v_sps_vp          BIGINT;
    v_sps_ct          BIGINT; v_sps_st          BIGINT;
    v_sps_acct        BIGINT; v_sps_student      BIGINT;
    v_sps_parent      BIGINT; v_sps_exam         BIGINT;
    -- role IDs per school (DHA)
    v_dha_principal   BIGINT; v_dha_st          BIGINT;
    v_dha_acct        BIGINT; v_dha_student      BIGINT;
    -- role IDs per school (GVI)
    v_gvi_principal   BIGINT; v_gvi_st          BIGINT;
    v_gvi_student     BIGINT;
    -- platform roles
    v_super_admin  BIGINT;
BEGIN
    -- Fetch school IDs
    SELECT school_id INTO v_sps FROM platform.schools WHERE school_code = 'SPS001';
    SELECT school_id INTO v_dha FROM platform.schools WHERE school_code = 'DHA002';
    SELECT school_id INTO v_gvi FROM platform.schools WHERE school_code = 'GVI003';

    -- Fetch branch IDs
    SELECT branch_id INTO v_sps_main  FROM platform.branches WHERE branch_code = 'SPS-MAIN';
    SELECT branch_id INTO v_sps_sat   FROM platform.branches WHERE branch_code = 'SPS-SAT';
    SELECT branch_id INTO v_sps_south FROM platform.branches WHERE branch_code = 'SPS-SOUTH';
    SELECT branch_id INTO v_dha_vv    FROM platform.branches WHERE branch_code = 'DHA-VV';
    SELECT branch_id INTO v_dha_dwk   FROM platform.branches WHERE branch_code = 'DHA-DWK';
    SELECT branch_id INTO v_gvi_main  FROM platform.branches WHERE branch_code = 'GVI-MAIN';
    SELECT branch_id INTO v_gvi_hin   FROM platform.branches WHERE branch_code = 'GVI-HIN';

    -- Platform role
    SELECT role_id INTO v_super_admin FROM platform.roles
        WHERE role_name = 'Super Admin' AND school_id IS NULL LIMIT 1;

    -- SPS roles
    SELECT role_id INTO v_sps_principal FROM platform.roles WHERE school_id = v_sps AND role_name = 'Principal';
    SELECT role_id INTO v_sps_vp        FROM platform.roles WHERE school_id = v_sps AND role_name = 'Vice Principal';
    SELECT role_id INTO v_sps_ct        FROM platform.roles WHERE school_id = v_sps AND role_name = 'Class Teacher';
    SELECT role_id INTO v_sps_st        FROM platform.roles WHERE school_id = v_sps AND role_name = 'Subject Teacher';
    SELECT role_id INTO v_sps_acct      FROM platform.roles WHERE school_id = v_sps AND role_name = 'Accountant';
    SELECT role_id INTO v_sps_student   FROM platform.roles WHERE school_id = v_sps AND role_name = 'Student';
    SELECT role_id INTO v_sps_parent    FROM platform.roles WHERE school_id = v_sps AND role_name = 'Parent / Guardian';
    SELECT role_id INTO v_sps_exam      FROM platform.roles WHERE school_id = v_sps AND role_name = 'Exam Coordinator';

    -- DHA roles
    SELECT role_id INTO v_dha_principal FROM platform.roles WHERE school_id = v_dha AND role_name = 'Principal';
    SELECT role_id INTO v_dha_st        FROM platform.roles WHERE school_id = v_dha AND role_name = 'Subject Teacher';
    SELECT role_id INTO v_dha_acct      FROM platform.roles WHERE school_id = v_dha AND role_name = 'Accountant';
    SELECT role_id INTO v_dha_student   FROM platform.roles WHERE school_id = v_dha AND role_name = 'Student';

    -- GVI roles
    SELECT role_id INTO v_gvi_principal FROM platform.roles WHERE school_id = v_gvi AND role_name = 'Principal';
    SELECT role_id INTO v_gvi_st        FROM platform.roles WHERE school_id = v_gvi AND role_name = 'Subject Teacher';
    SELECT role_id INTO v_gvi_student   FROM platform.roles WHERE school_id = v_gvi AND role_name = 'Student';

    -- ── INSERT USERS ──────────────────────────────────────────────────────────
    -- All passwords = School@12345 (bcrypt cost 12) — must change on first login

    INSERT INTO platform.users
        (school_id, branch_id, role_id, first_name, last_name,
         email, phone, password_hash,
         is_active, email_verified, email_verified_at, must_change_password)
    VALUES

    -- ── SPS001 — Sunrise Public School ───────────────────────────────────────
    (v_sps, v_sps_main,  v_sps_principal, 'Radhika',  'Sharma',
     'radhika.sharma@sunriseschool.in',    '+91-9001001001',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_main,  v_sps_vp,        'Amit',     'Patel',
     'amit.patel@sunriseschool.in',        '+91-9001001002',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_main,  v_sps_ct,        'Priya',    'Mehta',
     'priya.mehta@sunriseschool.in',       '+91-9001001003',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_sat,   v_sps_st,        'Sundar',   'Krishnan',
     'sundar.k@sunriseschool.in',          '+91-9001001004',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_main,  v_sps_acct,      'Neha',     'Joshi',
     'neha.joshi@sunriseschool.in',        '+91-9001001005',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_main,  v_sps_exam,      'Vikram',   'Singh',
     'vikram.singh@sunriseschool.in',      '+91-9001001006',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_main,  v_sps_student,   'Arjun',    'Sharma',
     'arjun.sharma.s@sunriseschool.in',    '+91-9001001007',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_sat,   v_sps_student,   'Ananya',   'Patel',
     'ananya.patel.s@sunriseschool.in',    '+91-9001001008',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_sps, v_sps_south, v_sps_student,   'Rohan',    'Gupta',
     'rohan.gupta.s@sunriseschool.in',     '+91-9001001009',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, FALSE, NULL, FALSE),

    (v_sps, v_sps_main,  v_sps_parent,    'Suresh',   'Sharma',
     'suresh.sharma.p@sunriseschool.in',   '+91-9001001010',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    -- ── DHA002 — Delhi Heritage Academy ──────────────────────────────────────
    (v_dha, v_dha_vv,    v_dha_principal, 'Kavitha',  'Nair',
     'kavitha.nair@dha.edu.in',            '+91-9002002001',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_dha, v_dha_vv,    v_dha_st,        'Rajesh',   'Verma',
     'rajesh.verma@dha.edu.in',            '+91-9002002002',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_dha, v_dha_dwk,   v_dha_st,        'Divya',    'Chopra',
     'divya.chopra@dha.edu.in',            '+91-9002002003',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_dha, v_dha_vv,    v_dha_acct,      'Manish',   'Agarwal',
     'manish.agarwal@dha.edu.in',          '+91-9002002004',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_dha, v_dha_vv,    v_dha_student,   'Ishaan',   'Mehta',
     'ishaan.mehta.s@dha.edu.in',          '+91-9002002005',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_dha, v_dha_dwk,   v_dha_student,   'Zara',     'Khan',
     'zara.khan.s@dha.edu.in',             '+91-9002002006',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, FALSE, NULL, FALSE),

    -- ── GVI003 — Green Valley International ──────────────────────────────────
    (v_gvi, v_gvi_main,  v_gvi_principal, 'Thomas',   'Mathew',
     'thomas.mathew@greenvalley.school',   '+91-9003003001',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_gvi, v_gvi_main,  v_gvi_st,        'Sneha',    'Kulkarni',
     'sneha.kulkarni@greenvalley.school',  '+91-9003003002',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_gvi, v_gvi_hin,   v_gvi_st,        'Arun',     'Desai',
     'arun.desai@greenvalley.school',      '+91-9003003003',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_gvi, v_gvi_main,  v_gvi_student,   'Meera',    'Thomas',
     'meera.thomas.s@greenvalley.school',  '+91-9003003004',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (v_gvi, v_gvi_hin,   v_gvi_student,   'Dev',      'Kulkarni',
     'dev.kulkarni.s@greenvalley.school',  '+91-9003003005',
     crypt('School@12345', gen_salt('bf', 12)), TRUE, FALSE, NULL, FALSE),

    -- ── Platform-level extra users ────────────────────────────────────────────
    (NULL, NULL, (SELECT role_id FROM platform.roles WHERE role_name='Support Admin' AND school_id IS NULL LIMIT 1),
     'Ayesha', 'Khan',
     'ayesha.khan@schoolerp.io',           '+91-9000000002',
     crypt('Support@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (NULL, NULL, (SELECT role_id FROM platform.roles WHERE role_name='Finance Admin' AND school_id IS NULL LIMIT 1),
     'Kiran',  'Bhat',
     'kiran.bhat@schoolerp.io',            '+91-9000000003',
     crypt('Finance@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    (NULL, NULL, (SELECT role_id FROM platform.roles WHERE role_name='Read Only' AND school_id IS NULL LIMIT 1),
     'Pooja',  'Iyer',
     'pooja.iyer@schoolerp.io',            '+91-9000000004',
     crypt('Readonly@12345', gen_salt('bf', 12)), TRUE, TRUE, NOW(), FALSE),

    -- Inactive / locked demo user (for testing auth flows)
    (v_sps, v_sps_main,  v_sps_student,   'Demo',     'Locked',
     'demo.locked@sunriseschool.in',       NULL,
     crypt('School@12345', gen_salt('bf', 12)),
     FALSE, FALSE, NULL, FALSE)

    ON CONFLICT (email) DO NOTHING;

END;
$$;

-- =============================================================================
-- SECTION 5 : platform.role_permissions  (school-level module permissions)
-- Map key school roles → school-facing modules with appropriate CRUD flags
-- =============================================================================

DO $$
DECLARE
    v_school_id BIGINT;
    v_role_id   BIGINT;
BEGIN
    FOR v_school_id IN SELECT school_id FROM platform.schools LOOP
        -- ── Principal: full on all school modules ─────────────────────────────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Principal';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Vice Principal: full except delete ───────────────────────────────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Vice Principal';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Class Teacher: attendance, timetable, homework, report cards ──────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Class Teacher';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                CASE WHEN m.module_code IN ('ATTENDANCE','HOMEWORK','REPORT_CARDS','TIMETABLE','ANNOUNCEMENTS') THEN TRUE ELSE FALSE END,
                TRUE,
                CASE WHEN m.module_code IN ('ATTENDANCE','HOMEWORK','REPORT_CARDS','TIMETABLE') THEN TRUE ELSE FALSE END,
                FALSE,
                CASE WHEN m.module_code IN ('ATTENDANCE','REPORT_CARDS','HOMEWORK') THEN TRUE ELSE FALSE END,
                FALSE,
                CASE WHEN m.module_code IN ('REPORT_CARDS','ATTENDANCE') THEN TRUE ELSE FALSE END
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Subject Teacher: subjects, homework, examinations, report cards ───
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Subject Teacher';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                CASE WHEN m.module_code IN ('HOMEWORK','EXAMINATIONS') THEN TRUE ELSE FALSE END,
                CASE WHEN m.module_code IN ('TIMETABLE','SUBJECTS','HOMEWORK','EXAMINATIONS',
                                            'ATTENDANCE','REPORT_CARDS','ANNOUNCEMENTS',
                                            'SCHOOL_DASHBOARD') THEN TRUE ELSE FALSE END,
                CASE WHEN m.module_code IN ('HOMEWORK','EXAMINATIONS') THEN TRUE ELSE FALSE END,
                FALSE,
                CASE WHEN m.module_code IN ('HOMEWORK','EXAMINATIONS','REPORT_CARDS') THEN TRUE ELSE FALSE END,
                FALSE,
                CASE WHEN m.module_code IN ('REPORT_CARDS') THEN TRUE ELSE FALSE END
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Accountant: fee, payroll, expenses, invoices ──────────────────────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Accountant';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                CASE WHEN m.module_code IN ('FEE_MANAGEMENT','PAYROLL','EXPENSE_TRACKING') THEN TRUE ELSE FALSE END,
                CASE WHEN m.module_code IN ('FEE_MANAGEMENT','PAYROLL','EXPENSE_TRACKING',
                                            'REPORTS_ANALYTICS','SCHOOL_DASHBOARD') THEN TRUE ELSE FALSE END,
                CASE WHEN m.module_code IN ('FEE_MANAGEMENT','PAYROLL','EXPENSE_TRACKING') THEN TRUE ELSE FALSE END,
                FALSE,
                TRUE,
                CASE WHEN m.module_code IN ('FEE_MANAGEMENT','PAYROLL') THEN TRUE ELSE FALSE END,
                TRUE
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Student: read-only own modules ────────────────────────────────────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Student';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                FALSE,
                CASE WHEN m.module_code IN ('SCHOOL_DASHBOARD','TIMETABLE','ATTENDANCE',
                                            'EXAMINATIONS','REPORT_CARDS','HOMEWORK',
                                            'ANNOUNCEMENTS','MESSAGING','FEE_MANAGEMENT',
                                            'LIBRARY','EVENTS_CALENDAR') THEN TRUE ELSE FALSE END,
                FALSE, FALSE,
                CASE WHEN m.module_code IN ('REPORT_CARDS','ATTENDANCE') THEN TRUE ELSE FALSE END,
                FALSE,
                CASE WHEN m.module_code IN ('REPORT_CARDS') THEN TRUE ELSE FALSE END
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Parent / Guardian: view child progress ────────────────────────────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Parent / Guardian';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                FALSE,
                CASE WHEN m.module_code IN ('SCHOOL_DASHBOARD','ATTENDANCE','REPORT_CARDS',
                                            'EXAMINATIONS','HOMEWORK','FEE_MANAGEMENT',
                                            'ANNOUNCEMENTS','EVENTS_CALENDAR','TIMETABLE') THEN TRUE ELSE FALSE END,
                FALSE, FALSE,
                CASE WHEN m.module_code IN ('REPORT_CARDS','FEE_MANAGEMENT') THEN TRUE ELSE FALSE END,
                FALSE,
                CASE WHEN m.module_code IN ('REPORT_CARDS') THEN TRUE ELSE FALSE END
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

        -- ── Exam Coordinator ──────────────────────────────────────────────────
        SELECT role_id INTO v_role_id
        FROM platform.roles
        WHERE school_id = v_school_id AND role_name = 'Exam Coordinator';

        IF v_role_id IS NOT NULL THEN
            INSERT INTO platform.role_permissions
                (role_id, module_id, can_create, can_read, can_update, can_delete, can_export, can_approve, can_print)
            SELECT
                v_role_id, m.module_id,
                CASE WHEN m.module_code IN ('EXAMINATIONS','REPORT_CARDS','CLASS_SECTION') THEN TRUE ELSE FALSE END,
                TRUE,
                CASE WHEN m.module_code IN ('EXAMINATIONS','REPORT_CARDS','TIMETABLE','CLASS_SECTION') THEN TRUE ELSE FALSE END,
                FALSE,
                TRUE, TRUE, TRUE
            FROM platform.modules m WHERE m.is_platform_level = FALSE
            ON CONFLICT (role_id, module_id) DO NOTHING;
        END IF;

    END LOOP;
END;
$$;

-- =============================================================================
-- SECTION 6 : Demo user_sessions  (3 active sessions for testing)
-- =============================================================================

INSERT INTO platform.user_sessions
    (user_id, token_hash, ip_address, user_agent, expires_at)
SELECT
    u.user_id,
    encode(digest(u.email || '-session-demo-' || NOW()::TEXT, 'sha256'), 'hex'),
    '103.21.244.10'::INET,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/121.0.0.0 Safari/537.36',
    NOW() + INTERVAL '7 days'
FROM platform.users u
WHERE u.email IN (
    'radhika.sharma@sunriseschool.in',
    'kavitha.nair@dha.edu.in',
    'superadmin@schoolerp.io'
)
ON CONFLICT (token_hash) DO NOTHING;

COMMIT;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

\echo ''
\echo '============================================'
\echo ' Demo Data Loaded — Row Counts'
\echo '============================================'

SELECT 'platform_plans'   AS "Table", COUNT(*) AS "Rows" FROM platform.platform_plans
UNION ALL
SELECT 'schools',                      COUNT(*) FROM platform.schools
UNION ALL
SELECT 'branches',                     COUNT(*) FROM platform.branches
UNION ALL
SELECT 'roles',                        COUNT(*) FROM platform.roles
UNION ALL
SELECT 'users',                        COUNT(*) FROM platform.users
UNION ALL
SELECT 'user_sessions',                COUNT(*) FROM platform.user_sessions
UNION ALL
SELECT 'modules',                      COUNT(*) FROM platform.modules
UNION ALL
SELECT 'role_permissions',             COUNT(*) FROM platform.role_permissions
ORDER BY 1;

\echo ''
\echo ' Sample: active_users view'
\echo '--------------------------------------------'
SELECT full_name, role_name, school_name, branch_name, account_status
FROM platform.active_users
ORDER BY school_name NULLS FIRST, role_name
LIMIT 15;

-- =============================================================================
-- END OF 10_demo_data.sql
-- =============================================================================
