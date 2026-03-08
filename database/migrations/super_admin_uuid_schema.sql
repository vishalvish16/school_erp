-- =============================================================================
-- FILE: super_admin_uuid_schema.sql
-- PURPOSE: Super Admin complete schema — UUID-based (per Cursor prompt)
-- RULES: Only ADD — never DROP/TRUNCATE. Uses IF NOT EXISTS guards.
-- NOTE: Requires users(id UUID) — if your users table uses BIGINT, run
--       super_admin_complete_20260307.sql (BIGINT version) instead.
-- Run: psql -U postgres -d your_db -f super_admin_uuid_schema.sql
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ════════════════════════════
-- PLANS TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS plans (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             VARCHAR(50) NOT NULL,
  slug             VARCHAR(30) UNIQUE NOT NULL,
  description      TEXT,
  price_per_student DECIMAL(10,2) NOT NULL DEFAULT 0,
  icon_emoji       VARCHAR(10) DEFAULT '📦',
  color_hex        VARCHAR(7) DEFAULT '#00D2FF',
  max_students     INT,
  support_level    VARCHAR(20) DEFAULT 'standard'
                   CHECK (support_level IN ('standard','priority','dedicated')),
  status           VARCHAR(10) DEFAULT 'active'
                   CHECK (status IN ('active','draft','inactive')),
  sort_order       INT DEFAULT 0,
  created_by       UUID,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════
-- PLAN FEATURES TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS plan_features (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id    UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  feature_key VARCHAR(50) NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  UNIQUE(plan_id, feature_key)
);

-- ════════════════════════════
-- SCHOOL GROUPS TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS school_groups (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             VARCHAR(100) NOT NULL,
  slug             VARCHAR(50) UNIQUE,
  subdomain        VARCHAR(50) UNIQUE,
  type             VARCHAR(30) DEFAULT 'trust'
                   CHECK (type IN ('trust','chain','franchise','government','other')),
  hq_city          VARCHAR(50),
  hq_state         VARCHAR(50),
  contact_person   VARCHAR(100),
  contact_email    VARCHAR(100),
  contact_phone    VARCHAR(15),
  status           VARCHAR(10) DEFAULT 'active'
                   CHECK (status IN ('active','inactive','suspended')),
  created_by       UUID,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════
-- SCHOOLS TABLE (create if not exists; alter if exists)
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS schools (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             VARCHAR(150) NOT NULL,
  code             VARCHAR(20) UNIQUE NOT NULL,
  subdomain        VARCHAR(50) UNIQUE,
  group_id         UUID REFERENCES school_groups(id) ON DELETE SET NULL,
  plan_id          UUID REFERENCES plans(id),
  board            VARCHAR(20) DEFAULT 'CBSE'
                   CHECK (board IN ('CBSE','ICSE','STATE_BOARD','IB','OTHER')),
  school_type      VARCHAR(20) DEFAULT 'private'
                   CHECK (school_type IN ('private','government','trust','franchise')),
  city             VARCHAR(50),
  state            VARCHAR(50),
  pin_code         VARCHAR(10),
  phone            VARCHAR(15),
  email            VARCHAR(100),
  logo_url         TEXT,
  student_limit    INT DEFAULT 500,
  student_count    INT DEFAULT 0,
  status           VARCHAR(15) DEFAULT 'trial'
                   CHECK (status IN ('active','trial','suspended','terminated','expiring')),
  subscription_start TIMESTAMPTZ,
  subscription_end   TIMESTAMPTZ,
  payment_due_date   TIMESTAMPTZ,
  overdue_days       INT DEFAULT 0,
  established_year INT,
  created_by       UUID,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Add columns to existing schools (if table exists with different structure)
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS subdomain VARCHAR(50) UNIQUE;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES plans(id);
EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES school_groups(id);
EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS student_limit INT DEFAULT 500;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS overdue_days INT DEFAULT 0;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS subscription_start TIMESTAMPTZ;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE schools ADD COLUMN IF NOT EXISTS subscription_end TIMESTAMPTZ;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- ════════════════════════════
-- SCHOOL FEATURES TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS school_features (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  feature_key VARCHAR(50) NOT NULL,
  is_enabled  BOOLEAN DEFAULT true,
  updated_by  UUID,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, feature_key)
);

-- ════════════════════════════
-- PLATFORM FEATURE FLAGS TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS platform_features (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_key   VARCHAR(50) UNIQUE NOT NULL,
  feature_name  VARCHAR(100) NOT NULL,
  description   TEXT,
  is_enabled    BOOLEAN DEFAULT true,
  category      VARCHAR(20) DEFAULT 'feature'
                CHECK (category IN ('feature','system','maintenance')),
  updated_by    UUID,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════
-- USERS TABLE (create minimal if not exists — for FK references)
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS users (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email      VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════
-- SCHOOL ADMIN USERS
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS school_admins (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role          VARCHAR(30) DEFAULT 'school_admin',
  is_primary    BOOLEAN DEFAULT false,
  is_active     BOOLEAN DEFAULT true,
  created_by    UUID,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, user_id)
);

-- ════════════════════════════
-- SUPER ADMIN USERS TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS super_admins (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role           VARCHAR(20) DEFAULT 'ops_admin'
                 CHECK (role IN ('owner','tech_admin','ops_admin','support_admin')),
  is_active      BOOLEAN DEFAULT true,
  totp_secret    TEXT,
  totp_enabled   BOOLEAN DEFAULT false,
  invited_by     UUID,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ════════════════════════════
-- HARDWARE DEVICES TABLE
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS hardware_devices (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id      VARCHAR(50) UNIQUE NOT NULL,
  device_type    VARCHAR(20) NOT NULL
                 CHECK (device_type IN ('rfid','gps','biometric','qr_scanner')),
  school_id      UUID REFERENCES schools(id) ON DELETE SET NULL,
  location_label VARCHAR(100),
  firmware_version VARCHAR(20),
  status         VARCHAR(15) DEFAULT 'online'
                 CHECK (status IN ('online','offline','error','maintenance')),
  last_ping_at   TIMESTAMPTZ,
  ip_address     INET,
  meta           JSONB DEFAULT '{}',
  registered_by  UUID,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════
-- BILLING / SUBSCRIPTIONS
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS school_subscriptions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id      UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  plan_id        UUID NOT NULL REFERENCES plans(id),
  student_count  INT NOT NULL DEFAULT 0,
  price_per_student DECIMAL(10,2) NOT NULL,
  monthly_amount DECIMAL(12,2) NOT NULL,
  duration_months INT DEFAULT 12,
  start_date     DATE NOT NULL,
  end_date      DATE NOT NULL,
  status         VARCHAR(15) DEFAULT 'active'
                 CHECK (status IN ('active','expired','cancelled','trial','grace')),
  payment_ref   VARCHAR(100),
  notes          TEXT,
  created_by     UUID,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- PLAN CHANGE LOG
CREATE TABLE IF NOT EXISTS plan_change_log (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id      UUID NOT NULL REFERENCES schools(id),
  old_plan_id    UUID REFERENCES plans(id),
  new_plan_id    UUID NOT NULL REFERENCES plans(id),
  changed_by     UUID NOT NULL,
  reason         VARCHAR(100),
  notes          TEXT,
  effective_date DATE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════
-- AUDIT LOG TABLES
-- ════════════════════════════
CREATE TABLE IF NOT EXISTS audit_school_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID REFERENCES schools(id) ON DELETE SET NULL,
  action      VARCHAR(50) NOT NULL,
  actor_id    UUID,
  actor_name  VARCHAR(100),
  actor_ip    INET,
  actor_device VARCHAR(100),
  old_data    JSONB,
  new_data    JSONB,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_school ON audit_school_logs(school_id, created_at DESC);

CREATE TABLE IF NOT EXISTS audit_plan_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id     UUID REFERENCES plans(id) ON DELETE SET NULL,
  school_id   UUID REFERENCES schools(id) ON DELETE SET NULL,
  action      VARCHAR(50) NOT NULL,
  actor_id    UUID,
  actor_name  VARCHAR(100),
  actor_ip    INET,
  old_data    JSONB,
  new_data    JSONB,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_plan ON audit_plan_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS audit_billing_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID REFERENCES schools(id) ON DELETE SET NULL,
  subscription_id UUID REFERENCES school_subscriptions(id) ON DELETE SET NULL,
  action      VARCHAR(50) NOT NULL,
  amount      DECIMAL(12,2),
  actor_id    UUID,
  actor_name  VARCHAR(100),
  actor_ip    INET,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_billing ON audit_billing_logs(school_id, created_at DESC);

CREATE TABLE IF NOT EXISTS audit_feature_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID REFERENCES schools(id) ON DELETE SET NULL,
  feature_key VARCHAR(50),
  action      VARCHAR(50) NOT NULL,
  old_value   BOOLEAN,
  new_value   BOOLEAN,
  actor_id    UUID,
  actor_name  VARCHAR(100),
  actor_ip    INET,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_feature ON audit_feature_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS audit_security_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  actor_email VARCHAR(100),
  action      VARCHAR(50) NOT NULL,
  ip_address  INET,
  device_info VARCHAR(200),
  city        VARCHAR(50),
  country     VARCHAR(50),
  status      VARCHAR(10) CHECK (status IN ('success','failed','blocked')),
  failure_reason VARCHAR(100),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_security ON audit_security_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_security_ip ON audit_security_logs(ip_address, created_at DESC);

CREATE TABLE IF NOT EXISTS audit_hardware_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id   UUID REFERENCES hardware_devices(id) ON DELETE SET NULL,
  action      VARCHAR(50) NOT NULL,
  actor_id    UUID,
  actor_name  VARCHAR(100),
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_group_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID REFERENCES school_groups(id) ON DELETE SET NULL,
  action      VARCHAR(50) NOT NULL,
  actor_id    UUID,
  actor_name  VARCHAR(100),
  actor_ip    INET,
  old_data    JSONB,
  new_data    JSONB,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_super_admin_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  actor_name  VARCHAR(100),
  actor_role  VARCHAR(30),
  action      VARCHAR(80) NOT NULL,
  entity_type VARCHAR(30),
  entity_id   UUID,
  entity_name VARCHAR(150),
  ip_address  INET,
  device_info VARCHAR(200),
  city        VARCHAR(50),
  request_data JSONB,
  response_status VARCHAR(10),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_sa ON audit_super_admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_sa_actor ON audit_super_admin_logs(actor_id, created_at DESC);

-- Seed default platform features
INSERT INTO platform_features (feature_key, feature_name, description, category) VALUES
  ('rfid_attendance',    'RFID Attendance',      'Gate & classroom RFID readers',       'feature'),
  ('gps_transport',      'GPS Transport',        'Live vehicle tracking',               'feature'),
  ('ai_intelligence',    'AI Intelligence',      'Anomaly detection & predictions',     'feature'),
  ('parent_app',         'Parent App',           'Mobile access for parents',           'feature'),
  ('student_app',        'Student App',          'Mobile access for students',          'feature'),
  ('chat_system',        'Chat System',          'In-app messaging',                    'feature'),
  ('online_payments',    'Online Payments',      'Razorpay / UPI integration',          'feature'),
  ('biometric',          'Biometric',            'Fingerprint / face recognition',      'feature'),
  ('certificates',       'Certificates',         'Auto certificate generation',         'feature'),
  ('advanced_analytics', 'Advanced Analytics',   'Detailed reports and dashboards',     'feature'),
  ('api_access',         'API Access',           'Third-party API integration',         'feature'),
  ('maintenance_mode',   'Maintenance Mode',     'Show maintenance page to all users',  'system'),
  ('new_registrations',  'New Registrations',    'Allow new school onboarding',         'system'),
  ('email_notifications','Email Notifications',  'System email delivery',               'system'),
  ('sms_gateway',        'SMS Gateway',          'OTP and alert SMS',                   'system'),
  ('push_notifications', 'Push Notifications',   'Mobile push via FCM',                 'system')
ON CONFLICT (feature_key) DO NOTHING;

-- Seed default plans
INSERT INTO plans (name, slug, description, price_per_student, icon_emoji, sort_order, status) VALUES
  ('Basic',    'basic',    'Core school management tools', 25.00, '📋', 1, 'active'),
  ('Standard', 'standard', 'Full school + safety features', 35.00, '🚀', 2, 'active'),
  ('Premium',  'premium',  'Complete platform with AI & biometric', 45.00, '⭐', 3, 'active')
ON CONFLICT (slug) DO NOTHING;

COMMIT;
