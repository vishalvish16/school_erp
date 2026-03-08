-- =============================================================================
-- FILE: fix_smart_login_bigint.sql
-- PURPOSE: Recreate smart login tables with BIGINT for user_id/school_id (matches Prisma)
-- Run if add_smart_login_public.sql used UUID and OTP creation fails.
-- WARNING: Drops and recreates tables — any registered devices/OTP data will be lost.
-- Run: psql -U postgres -d school_erp -f fix_smart_login_bigint.sql
-- =============================================================================

BEGIN;

SET search_path TO public;

-- Drop existing tables (cascade will drop dependent FKs)
DROP TABLE IF EXISTS auth_sessions CASCADE;
DROP TABLE IF EXISTS otp_verifications CASCADE;
DROP TABLE IF EXISTS registered_devices CASCADE;

-- Recreate with BIGINT (matches Prisma users.id, schools.id)
CREATE TABLE registered_devices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       BIGINT REFERENCES schools(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_reg_devices_user ON registered_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_devices_fingerprint ON registered_devices(device_fingerprint);

CREATE TABLE auth_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       BIGINT REFERENCES schools(id) ON DELETE CASCADE,
  device_id       UUID REFERENCES registered_devices(id) ON DELETE SET NULL,
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
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user ON auth_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_token ON auth_sessions(session_token);

CREATE TABLE otp_verifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         BIGINT REFERENCES users(id) ON DELETE CASCADE,
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

COMMIT;
