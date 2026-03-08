-- =============================================================================
-- FILE: add_smart_login_20260307.sql
-- PURPOSE: Smart Login System — registered_devices, auth_sessions, otp_verifications
--          + columns for schools, users
-- ENGINE: PostgreSQL 15+  |  Run against existing platform schema
-- =============================================================================

BEGIN;

SET search_path TO platform, public;

-- =============================================================================
-- 2A. registered_devices
-- =============================================================================
CREATE TABLE IF NOT EXISTS platform.registered_devices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT NOT NULL REFERENCES platform.users(user_id) ON DELETE CASCADE,
  school_id       BIGINT REFERENCES platform.schools(school_id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  device_name     VARCHAR(100),
  device_type     VARCHAR(20) CHECK (device_type IN ('mobile','tablet','desktop','unknown')),
  browser         VARCHAR(50),
  os              VARCHAR(50),
  ip_address      INET,
  city            VARCHAR(50),
  country         VARCHAR(50),
  is_trusted      BOOLEAN DEFAULT false,
  trusted_at      TIMESTAMPTZ,
  trusted_until   TIMESTAMPTZ,
  last_used_at    TIMESTAMPTZ DEFAULT NOW(),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reg_devices_user ON platform.registered_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_devices_fingerprint ON platform.registered_devices(device_fingerprint);

-- =============================================================================
-- 2B. auth_sessions (smart login sessions — distinct from user_sessions)
-- =============================================================================
CREATE TABLE IF NOT EXISTS platform.auth_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT NOT NULL REFERENCES platform.users(user_id) ON DELETE CASCADE,
  school_id       BIGINT REFERENCES platform.schools(school_id) ON DELETE CASCADE,
  device_id       UUID REFERENCES platform.registered_devices(id) ON DELETE SET NULL,
  session_token   TEXT NOT NULL UNIQUE,
  refresh_token   TEXT UNIQUE,
  role            VARCHAR(30),
  portal_type     VARCHAR(20) CHECK (portal_type IN 
                  ('super_admin','group_admin','school_admin','staff','parent','student')),
  ip_address      INET,
  is_active       BOOLEAN DEFAULT true,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  last_active_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_user ON platform.auth_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_token ON platform.auth_sessions(session_token);

-- =============================================================================
-- 2C. otp_verifications
-- =============================================================================
CREATE TABLE IF NOT EXISTS platform.otp_verifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT REFERENCES platform.users(user_id) ON DELETE CASCADE,
  phone           VARCHAR(15),
  email           VARCHAR(100),
  otp_code        VARCHAR(6) NOT NULL,
  otp_type        VARCHAR(20) CHECK (otp_type IN 
                  ('login','device_verify','forgot_password','register')),
  device_fingerprint TEXT,
  is_used         BOOLEAN DEFAULT false,
  attempts        INT DEFAULT 0,
  max_attempts    INT DEFAULT 3,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_verifications_user ON platform.otp_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_verifications_expires ON platform.otp_verifications(expires_at);

-- =============================================================================
-- 2D. schools — add subdomain_active, login_url (subdomain already exists)
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'platform' AND table_name = 'schools' AND column_name = 'subdomain_active') THEN
    ALTER TABLE platform.schools ADD COLUMN subdomain_active BOOLEAN DEFAULT true;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'platform' AND table_name = 'schools' AND column_name = 'login_url') THEN
    ALTER TABLE platform.schools ADD COLUMN login_url TEXT 
      GENERATED ALWAYS AS (subdomain || '.vidyron.in') STORED;
  END IF;
END $$;

-- =============================================================================
-- 2E. school_groups — skip if table does not exist
-- =============================================================================
-- school_groups table not present in current schema; add when created

-- =============================================================================
-- 2F. users — add portal_type if not exist
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'platform' AND table_name = 'users' AND column_name = 'portal_type') THEN
    ALTER TABLE platform.users ADD COLUMN portal_type VARCHAR(20);
  END IF;
END $$;

-- users already has school_id, failed_login_attempts, locked_until, last_login, last_login_ip

-- =============================================================================
-- rate_limit_tracking — for forgot password etc.
-- =============================================================================
CREATE TABLE IF NOT EXISTS platform.rate_limit_tracking (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  identifier      VARCHAR(255) NOT NULL,
  action          VARCHAR(50) NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rate_limit_identifier_action ON platform.rate_limit_tracking(identifier, action, created_at);

-- =============================================================================
-- login_attempts — for rate limiting / audit
-- =============================================================================
CREATE TABLE IF NOT EXISTS platform.login_attempts (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  identifier      VARCHAR(255) NOT NULL,
  ip_address      INET,
  success         BOOLEAN NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_login_attempts_identifier ON platform.login_attempts(identifier, created_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip ON platform.login_attempts(ip_address, created_at);

-- Sample subdomain for first school (if subdomain is empty)
UPDATE platform.schools
SET subdomain = LOWER(REGEXP_REPLACE(COALESCE(school_name, school_code, 'school'), '[^a-zA-Z0-9]', '', 'g'))
WHERE school_id IN (
  SELECT school_id FROM platform.schools 
  WHERE subdomain IS NULL OR subdomain = '' 
  LIMIT 1
);

COMMIT;
