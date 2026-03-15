-- Create audit_super_admin_logs table for super admin audit trail
-- Note: actor_id uses BIGINT to match users.id at this point in migration history
CREATE TABLE IF NOT EXISTS audit_super_admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    actor_name VARCHAR(100),
    actor_role VARCHAR(30),
    action VARCHAR(80) NOT NULL,
    entity_type VARCHAR(30),
    entity_id UUID,
    entity_name VARCHAR(150),
    ip_address INET DEFAULT '0.0.0.0'::inet,
    request_data JSONB DEFAULT '{}',
    response_status VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_sa_created_at ON audit_super_admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_sa_actor ON audit_super_admin_logs(actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_sa_entity_type ON audit_super_admin_logs(entity_type);
