-- Create platform_features table for Global Feature Flags
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

-- Seed default platform features (match screenshot: RFID, GPS, AI, Parent App, Chat, Payments, Biometric, Certificates, etc.)
INSERT INTO platform_features (feature_key, feature_name, description, category, is_enabled) VALUES
  ('rfid_attendance',    'RFID Attendance Engine',     'All RFID readers across platform',                    'feature', true),
  ('gps_transport',      'GPS Transport Engine',       'Live vehicle tracking for all schools',                'feature', true),
  ('ai_intelligence',    'AI Intelligence Engine',     'Anomaly detection and predictions',                    'feature', true),
  ('parent_app',         'Parent Mobile App',          'App access for all parents',                            'feature', true),
  ('chat_system',        'Chat System',                'In-app messaging globally',                             'feature', true),
  ('online_payments',    'Online Payments',            'Razorpay / UPI integration',                           'feature', true),
  ('biometric',          'Biometric Module',           'Fingerprint / face recognition',                       'feature', false),
  ('certificates',       'Certificate Generator',      'Auto-generate school certificates',                     'feature', true),
  ('maintenance_mode',   'Maintenance Mode',           'Shows maintenance page to all users',                   'system', false),
  ('new_registrations',  'New Registrations',          'Allow new school onboarding',                          'system', true),
  ('email_notifications','Email Notifications',        'System email delivery',                                 'system', true),
  ('sms_gateway',        'SMS Gateway',                'OTP and alert SMS delivery',                           'system', true),
  ('push_notifications', 'Push Notifications',         'Mobile push via FCM',                                  'system', true),
  ('ai_auto_alerts',     'AI Auto-Alerts',             'Proactive AI-generated alerts',                        'system', true)
ON CONFLICT (feature_key) DO NOTHING;
