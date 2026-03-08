-- =============================================================================
-- FILE: add_smart_login_public.sql
-- PURPOSE: Smart Login — for Prisma/public schema (run this if platform schema doesn't exist)
-- Run: psql -U postgres -d school_erp -f add_smart_login_public.sql
-- Or: psql -U postgres -d school_erp_saas -f add_smart_login_public.sql
-- =============================================================================

BEGIN;

SET search_path TO public;

-- Use "id" if your users/schools tables use "id", or "user_id"/"school_id" if mapped
-- Prisma maps User.id -> user_id, School.id -> school_id

-- 1. registered_devices (user_id/school_id as BIGINT to match Prisma users.id/schools.id)
CREATE TABLE IF NOT EXISTS registered_devices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT NOT NULL,
  school_id       BIGINT,
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

-- Add FKs (users.id, schools.id are BIGINT in Prisma)
DO $$
BEGIN
  ALTER TABLE registered_devices ADD CONSTRAINT fk_rd_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
  ALTER TABLE registered_devices ADD CONSTRAINT fk_rd_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_reg_devices_user ON registered_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_devices_fingerprint ON registered_devices(device_fingerprint);

-- 2. auth_sessions
CREATE TABLE IF NOT EXISTS auth_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT NOT NULL,
  school_id       BIGINT,
  device_id       UUID,
  session_token   TEXT NOT NULL UNIQUE,
  refresh_token   TEXT UNIQUE,
  role            VARCHAR(30),
  portal_type     VARCHAR(20),
  ip_address      INET,
  is_active       BOOLEAN DEFAULT true,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  last_active_at  TIMESTAMPTZ DEFAULT NOW()
);

DO $$ BEGIN
  ALTER TABLE auth_sessions ADD CONSTRAINT fk_as_device FOREIGN KEY (device_id) REFERENCES registered_devices(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
  ALTER TABLE auth_sessions ADD CONSTRAINT fk_as_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
  ALTER TABLE auth_sessions ADD CONSTRAINT fk_as_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_auth_sessions_user ON auth_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_token ON auth_sessions(session_token);

-- 3. otp_verifications
CREATE TABLE IF NOT EXISTS otp_verifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT,
  phone           VARCHAR(15),
  email           VARCHAR(100),
  otp_code        VARCHAR(6) NOT NULL,
  otp_type        VARCHAR(20),
  device_fingerprint TEXT,
  is_used         BOOLEAN DEFAULT false,
  attempts        INT DEFAULT 0,
  max_attempts    INT DEFAULT 3,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_verifications_user ON otp_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_verifications_expires ON otp_verifications(expires_at);

-- 4. rate_limit_tracking
CREATE TABLE IF NOT EXISTS rate_limit_tracking (
  id              BIGSERIAL PRIMARY KEY,
  identifier      VARCHAR(255) NOT NULL,
  action          VARCHAR(50) NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rate_limit_identifier ON rate_limit_tracking(identifier, action, created_at);

-- 5. login_attempts
CREATE TABLE IF NOT EXISTS login_attempts (
  id              BIGSERIAL PRIMARY KEY,
  identifier      VARCHAR(255) NOT NULL,
  ip_address      INET,
  success         BOOLEAN NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_login_attempts_identifier ON login_attempts(identifier, created_at);

COMMIT;
