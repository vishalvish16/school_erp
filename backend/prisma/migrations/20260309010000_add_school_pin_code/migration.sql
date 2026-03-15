-- Add pin_code column to schools table if it doesn't exist
ALTER TABLE schools ADD COLUMN IF NOT EXISTS pin_code VARCHAR(20);
