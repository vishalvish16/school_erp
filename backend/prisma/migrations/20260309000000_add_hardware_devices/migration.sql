-- Create hardware_devices table for platform device management
CREATE TABLE IF NOT EXISTS hardware_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL DEFAULT 'rfid',
    status VARCHAR(20) NOT NULL DEFAULT 'online',
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    location_label VARCHAR(255),
    firmware_version VARCHAR(50),
    ip_address INET,
    last_ping_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_hardware_devices_device_id ON hardware_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_hardware_devices_school ON hardware_devices(school_id);
CREATE INDEX IF NOT EXISTS idx_hardware_devices_status ON hardware_devices(status);
CREATE INDEX IF NOT EXISTS idx_hardware_devices_type ON hardware_devices(device_type);
