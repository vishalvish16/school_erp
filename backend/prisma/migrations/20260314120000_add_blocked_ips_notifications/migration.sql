-- Add blocked_ips table for IP blocking feature
CREATE TABLE IF NOT EXISTS blocked_ips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address INET NOT NULL,
    reason VARCHAR(255),
    blocked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    blocked_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_blocked_ips_ip ON blocked_ips(ip_address) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_blocked_ips_active ON blocked_ips(is_active, blocked_at DESC);

-- Add platform_notifications table for super admin notifications
CREATE TABLE IF NOT EXISTS platform_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL DEFAULT 'info',
    title VARCHAR(200) NOT NULL,
    body TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    target_role VARCHAR(30) DEFAULT 'super_admin',
    link VARCHAR(300),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_platform_notif_read ON platform_notifications(is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_platform_notif_role ON platform_notifications(target_role, created_at DESC);
