-- Migration: 20260316000000_driver_live_location
-- Created: 2026-03-16

-- Add live location fields to drivers table
ALTER TABLE "drivers" ADD COLUMN IF NOT EXISTS "last_lat" DECIMAL(10,7);
ALTER TABLE "drivers" ADD COLUMN IF NOT EXISTS "last_lng" DECIMAL(10,7);
ALTER TABLE "drivers" ADD COLUMN IF NOT EXISTS "last_location_at" TIMESTAMPTZ(6);
ALTER TABLE "drivers" ADD COLUMN IF NOT EXISTS "trip_active" BOOLEAN NOT NULL DEFAULT FALSE;
