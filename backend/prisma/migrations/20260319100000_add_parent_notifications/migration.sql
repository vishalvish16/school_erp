-- Add parent_notifications table for in-app notifications to parents
-- Used when school admin/clerk approves or rejects profile update requests
CREATE TABLE IF NOT EXISTS parent_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES parents(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL DEFAULT 'info',
    title VARCHAR(255) NOT NULL,
    body TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    link VARCHAR(500),
    entity_type VARCHAR(50),
    entity_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_parent_notif_parent ON parent_notifications(parent_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_parent_notif_read ON parent_notifications(parent_id, is_read, created_at DESC);
