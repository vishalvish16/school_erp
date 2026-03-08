-- =============================================================================
-- FILE: super_admin_complete_20260307.sql
-- PURPOSE: Super Admin complete schema — plans, groups, billing, audit, hardware
-- RULES: Only ADD — never DROP/TRUNCATE. Uses IF NOT EXISTS / IF EXISTS guards.
-- SCHEMA: Works with platform schema (BIGINT PKs) + new UUID tables
-- Run: psql -U school_erp_owner -d school_erp_saas -f super_admin_complete_20260307.sql
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- ════════════════════════════════════════
-- STEP 2A: UPDATE EXISTING SCHOOLS TABLE
-- Add missing columns only (platform.schools uses school_id BIGINT)
-- ════════════════════════════════════════
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS group_id         BIGINT;
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS student_limit    INT DEFAULT 500;
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS overdue_days    INT DEFAULT 0;
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS pin_code        VARCHAR(10);
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS school_type     VARCHAR(20) DEFAULT 'private';
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS established_year INT;
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS deleted_at       TIMESTAMPTZ;
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS created_by       BIGINT;
ALTER TABLE platform.schools ADD COLUMN IF NOT EXISTS status           VARCHAR(20) DEFAULT 'active';

-- subscription_start, subscription_end, subdomain, plan_id already exist in platform.schools

-- Status check (platform uses is_active; status is additive)
DO $$
BEGIN
  ALTER TABLE platform.schools DROP CONSTRAINT IF EXISTS schools_status_check;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER TABLE platform.schools ADD CONSTRAINT schools_status_check
    CHECK (status IN ('active','trial','suspended','terminated','expiring'));
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ════════════════════════════════════════
-- STEP 2B: SCHOOL_FEATURES (create or alter)
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.school_features (
  id           BIGSERIAL PRIMARY KEY,
  school_id    BIGINT NOT NULL REFERENCES platform.schools(school_id) ON DELETE CASCADE,
  feature_name VARCHAR(100),
  feature_key  VARCHAR(50),
  is_enabled   BOOLEAN DEFAULT true,
  updated_by   BIGINT,
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if table already existed
ALTER TABLE platform.school_features ADD COLUMN IF NOT EXISTS feature_key  VARCHAR(50);
ALTER TABLE platform.school_features ADD COLUMN IF NOT EXISTS updated_by   BIGINT;
ALTER TABLE platform.school_features ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_school_features_school ON platform.school_features(school_id);

-- Migrate feature_name to feature_key if feature_key is empty
UPDATE platform.school_features
SET feature_key = LOWER(REGEXP_REPLACE(COALESCE(feature_name, ''), '[^a-zA-Z0-9]', '_', 'g'))
WHERE feature_key IS NULL AND feature_name IS NOT NULL AND feature_name != '';

DO $$
BEGIN
  ALTER TABLE platform.school_features ADD CONSTRAINT school_features_unique
    UNIQUE(school_id, feature_key);
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ════════════════════════════════════════
-- STEP 2C: BILLING (create if not exists)
-- platform has school_subscriptions; create billing for super-admin invoicing
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.billing (
  id               BIGSERIAL PRIMARY KEY,
  school_id        BIGINT NOT NULL REFERENCES platform.schools(school_id) ON DELETE CASCADE,
  invoice_number   VARCHAR(50),
  amount           DECIMAL(12,2) NOT NULL DEFAULT 0,
  payment_date     DATE,
  payment_status   VARCHAR(20) DEFAULT 'pending',
  payment_method   VARCHAR(30),
  plan_id          BIGINT REFERENCES platform.platform_plans(plan_id) ON DELETE SET NULL,
  student_count    INT DEFAULT 0,
  price_per_student DECIMAL(10,2),
  duration_months  INT DEFAULT 12,
  start_date       DATE,
  end_date         DATE,
  status           VARCHAR(15) DEFAULT 'active',
  notes            TEXT,
  created_by       BIGINT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_school ON platform.billing(school_id);
CREATE INDEX IF NOT EXISTS idx_billing_status ON platform.billing(status);

-- ════════════════════════════════════════
-- STEP 2D: AUDIT_LOGS (create if not exists)
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.audit_logs (
  id             BIGSERIAL PRIMARY KEY,
  user_id        BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  action         VARCHAR(100),
  entity         VARCHAR(50),
  entity_id      BIGINT,
  old_value      JSONB,
  new_value      JSONB,
  ip_address     INET,
  status_code    INT,
  response_time  INT,
  method         VARCHAR(10),
  url            TEXT,
  error_message  TEXT,
  actor_name     VARCHAR(100),
  actor_role     VARCHAR(30),
  device_info    VARCHAR(200),
  city           VARCHAR(50),
  school_id      BIGINT REFERENCES platform.schools(school_id) ON DELETE SET NULL,
  description    TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_school ON platform.audit_logs(school_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON platform.audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON platform.audit_logs(entity, entity_id);

-- ════════════════════════════════════════
-- STEP 2E: PLAN FEATURES (new)
-- Maps feature_key to platform_plans
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.plan_features (
  id          BIGSERIAL PRIMARY KEY,
  plan_id     BIGINT NOT NULL REFERENCES platform.platform_plans(plan_id) ON DELETE CASCADE,
  feature_key VARCHAR(50) NOT NULL,
  is_enabled  BOOLEAN DEFAULT true,
  UNIQUE(plan_id, feature_key)
);

-- ════════════════════════════════════════
-- STEP 2F: SCHOOL GROUPS (new)
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.school_groups (
  id              BIGSERIAL PRIMARY KEY,
  name            VARCHAR(100) NOT NULL,
  slug            VARCHAR(50) UNIQUE,
  subdomain       VARCHAR(50) UNIQUE,
  group_type      VARCHAR(30) DEFAULT 'trust'
                  CHECK (group_type IN ('trust','chain','franchise','government','other')),
  hq_city         VARCHAR(50),
  hq_state        VARCHAR(50),
  contact_person  VARCHAR(100),
  contact_email   VARCHAR(100),
  contact_phone   VARCHAR(15),
  status          VARCHAR(10) DEFAULT 'active'
                  CHECK (status IN ('active','inactive','suspended')),
  created_by      BIGINT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Add FK from schools to school_groups
DO $$
BEGIN
  ALTER TABLE platform.schools ADD CONSTRAINT fk_schools_group
    FOREIGN KEY (group_id) REFERENCES platform.school_groups(id) ON DELETE SET NULL;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ════════════════════════════════════════
-- STEP 2G: PLATFORM FEATURES (new)
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.platform_features (
  id            BIGSERIAL PRIMARY KEY,
  feature_key   VARCHAR(50) UNIQUE NOT NULL,
  feature_name  VARCHAR(100) NOT NULL,
  description   TEXT,
  is_enabled    BOOLEAN DEFAULT true,
  category      VARCHAR(20) DEFAULT 'feature'
                CHECK (category IN ('feature','system','maintenance')),
  updated_by    BIGINT,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- STEP 2H: SUPER ADMINS (new)
-- Links platform.users to super_admin role
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.super_admins (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT NOT NULL REFERENCES platform.users(user_id) ON DELETE CASCADE,
  role         VARCHAR(20) DEFAULT 'ops_admin'
               CHECK (role IN ('owner','tech_admin','ops_admin','support_admin')),
  is_active    BOOLEAN DEFAULT true,
  totp_secret  TEXT,
  totp_enabled BOOLEAN DEFAULT false,
  invited_by   BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ════════════════════════════════════════
-- STEP 2I: SCHOOL ADMINS (new)
-- Links users as admins for specific schools
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.school_admins (
  id           BIGSERIAL PRIMARY KEY,
  school_id    BIGINT NOT NULL REFERENCES platform.schools(school_id) ON DELETE CASCADE,
  user_id      BIGINT NOT NULL REFERENCES platform.users(user_id) ON DELETE CASCADE,
  role         VARCHAR(30) DEFAULT 'school_admin',
  is_primary   BOOLEAN DEFAULT false,
  is_active    BOOLEAN DEFAULT true,
  created_by   BIGINT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, user_id)
);

-- ════════════════════════════════════════
-- STEP 2J: PLAN CHANGE LOG (new)
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.plan_change_log (
  id             BIGSERIAL PRIMARY KEY,
  school_id      BIGINT NOT NULL REFERENCES platform.schools(school_id) ON DELETE CASCADE,
  old_plan_id    BIGINT REFERENCES platform.platform_plans(plan_id) ON DELETE SET NULL,
  new_plan_id    BIGINT NOT NULL REFERENCES platform.platform_plans(plan_id) ON DELETE RESTRICT,
  changed_by     BIGINT NOT NULL REFERENCES platform.users(user_id) ON DELETE RESTRICT,
  reason         VARCHAR(100),
  notes          TEXT,
  effective_date DATE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- STEP 2K: HARDWARE DEVICES (new)
-- ════════════════════════════════════════
CREATE TABLE IF NOT EXISTS platform.hardware_devices (
  id               BIGSERIAL PRIMARY KEY,
  device_serial    VARCHAR(50) UNIQUE NOT NULL,
  device_type      VARCHAR(20) NOT NULL
                   CHECK (device_type IN ('rfid','gps','biometric','qr_scanner')),
  school_id        BIGINT REFERENCES platform.schools(school_id) ON DELETE SET NULL,
  location_label   VARCHAR(100),
  firmware_version VARCHAR(20),
  status           VARCHAR(15) DEFAULT 'online'
                   CHECK (status IN ('online','offline','error','maintenance')),
  last_ping_at     TIMESTAMPTZ,
  ip_address       INET,
  meta             JSONB DEFAULT '{}',
  registered_by    BIGINT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- STEP 2L: SEPARATE AUDIT LOG TABLES
-- ════════════════════════════════════════

CREATE TABLE IF NOT EXISTS platform.audit_school_logs (
  id           BIGSERIAL PRIMARY KEY,
  school_id    BIGINT REFERENCES platform.schools(school_id) ON DELETE SET NULL,
  action       VARCHAR(60) NOT NULL,
  actor_id     BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name   VARCHAR(100),
  actor_ip     INET,
  device_info  VARCHAR(200),
  description  TEXT,
  old_data     JSONB,
  new_data     JSONB,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_asl_school ON platform.audit_school_logs(school_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_asl_time ON platform.audit_school_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS platform.audit_plan_logs (
  id           BIGSERIAL PRIMARY KEY,
  plan_id      BIGINT REFERENCES platform.platform_plans(plan_id) ON DELETE SET NULL,
  school_id    BIGINT REFERENCES platform.schools(school_id) ON DELETE SET NULL,
  action       VARCHAR(60) NOT NULL,
  actor_id     BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name   VARCHAR(100),
  actor_ip     INET,
  description  TEXT,
  old_data     JSONB,
  new_data     JSONB,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_apl_time ON platform.audit_plan_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS platform.audit_billing_logs (
  id              BIGSERIAL PRIMARY KEY,
  school_id       BIGINT REFERENCES platform.schools(school_id) ON DELETE SET NULL,
  billing_id      BIGINT REFERENCES platform.billing(id) ON DELETE SET NULL,
  action          VARCHAR(60) NOT NULL,
  amount          DECIMAL(12,2),
  actor_id        BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name      VARCHAR(100),
  actor_ip        INET,
  description     TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_abl_school ON platform.audit_billing_logs(school_id, created_at DESC);

CREATE TABLE IF NOT EXISTS platform.audit_feature_logs (
  id           BIGSERIAL PRIMARY KEY,
  school_id    BIGINT REFERENCES platform.schools(school_id) ON DELETE SET NULL,
  feature_key  VARCHAR(50),
  scope        VARCHAR(10) DEFAULT 'school'
               CHECK (scope IN ('school','platform')),
  action       VARCHAR(60) NOT NULL,
  old_value    BOOLEAN,
  new_value    BOOLEAN,
  actor_id     BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name   VARCHAR(100),
  actor_ip     INET,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_afl_time ON platform.audit_feature_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS platform.audit_security_logs (
  id             BIGSERIAL PRIMARY KEY,
  actor_id       BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_email    VARCHAR(100),
  action         VARCHAR(60) NOT NULL,
  ip_address     INET,
  device_info    VARCHAR(200),
  city           VARCHAR(50),
  country        VARCHAR(50),
  event_status   VARCHAR(10) CHECK (event_status IN ('success','failed','blocked')),
  failure_reason VARCHAR(100),
  created_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_asecu_time ON platform.audit_security_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_asecu_ip ON platform.audit_security_logs(ip_address);

CREATE TABLE IF NOT EXISTS platform.audit_hardware_logs (
  id          BIGSERIAL PRIMARY KEY,
  device_id   BIGINT REFERENCES platform.hardware_devices(id) ON DELETE SET NULL,
  action      VARCHAR(60) NOT NULL,
  actor_id    BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name  VARCHAR(100),
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS platform.audit_group_logs (
  id          BIGSERIAL PRIMARY KEY,
  group_id    BIGINT REFERENCES platform.school_groups(id) ON DELETE SET NULL,
  action      VARCHAR(60) NOT NULL,
  actor_id    BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name  VARCHAR(100),
  actor_ip    INET,
  description TEXT,
  old_data    JSONB,
  new_data    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS platform.audit_super_admin_logs (
  id              BIGSERIAL PRIMARY KEY,
  actor_id        BIGINT REFERENCES platform.users(user_id) ON DELETE SET NULL,
  actor_name      VARCHAR(100),
  actor_role      VARCHAR(30),
  action          VARCHAR(80) NOT NULL,
  entity_type     VARCHAR(30),
  entity_id       BIGINT,
  entity_name     VARCHAR(150),
  ip_address      INET,
  device_info     VARCHAR(200),
  city            VARCHAR(50),
  request_data    JSONB,
  response_status VARCHAR(10),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_asa_time ON platform.audit_super_admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_asa_actor ON platform.audit_super_admin_logs(actor_id, created_at DESC);

-- ════════════════════════════════════════
-- STEP 2M: SEED PLATFORM FEATURES
-- ════════════════════════════════════════
INSERT INTO platform.platform_features (feature_key, feature_name, description, category)
VALUES
  ('rfid_attendance',    'RFID Attendance',     'Gate & classroom RFID',          'feature'),
  ('gps_transport',      'GPS Transport',       'Live vehicle tracking',           'feature'),
  ('ai_intelligence',    'AI Intelligence',     'Anomaly detection',               'feature'),
  ('parent_app',         'Parent App',          'Mobile access for parents',       'feature'),
  ('student_app',        'Student App',         'Mobile access for students',      'feature'),
  ('chat_system',        'Chat System',         'In-app messaging',                'feature'),
  ('online_payments',    'Online Payments',     'Razorpay / UPI',                  'feature'),
  ('biometric',          'Biometric',           'Fingerprint / face recognition',  'feature'),
  ('certificates',       'Certificates',        'Auto certificate generation',     'feature'),
  ('advanced_analytics', 'Advanced Analytics',  'Detailed reports',                'feature'),
  ('api_access',         'API Access',          'Third-party integration',         'feature'),
  ('maintenance_mode',   'Maintenance Mode',    'Show maintenance to all users',   'maintenance'),
  ('new_registrations',  'New Registrations',   'Allow new school onboarding',     'system'),
  ('email_notifications','Email Notifications', 'System email delivery',           'system'),
  ('sms_gateway',        'SMS Gateway',         'OTP and alert SMS',               'system'),
  ('push_notifications', 'Push Notifications',  'Firebase push notifications',     'system')
ON CONFLICT (feature_key) DO NOTHING;

COMMIT;
