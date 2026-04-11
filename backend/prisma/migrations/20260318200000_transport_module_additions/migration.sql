-- Migration: 20260318200000_transport_module_additions
-- Created: 2026-03-18
-- Description: Adds vehicle metadata fields, changes driver->vehicle from 1:1 to 1:many,
--              adds StudentVehicleAssignment and StudentTripEvent models.

-- ─── Step 1: Add new metadata columns to vehicles ────────────────────────────

ALTER TABLE "vehicles"
    ADD COLUMN IF NOT EXISTS "vehicle_type"      VARCHAR(20),
    ADD COLUMN IF NOT EXISTS "make"              VARCHAR(50),
    ADD COLUMN IF NOT EXISTS "model"             VARCHAR(50),
    ADD COLUMN IF NOT EXISTS "year"              INTEGER,
    ADD COLUMN IF NOT EXISTS "color"             VARCHAR(30),
    ADD COLUMN IF NOT EXISTS "rc_number"         VARCHAR(50),
    ADD COLUMN IF NOT EXISTS "insurance_expiry"  DATE,
    ADD COLUMN IF NOT EXISTS "fitness_expiry"    DATE;

-- ─── Step 2: Drop the unique constraint on vehicles.driver_id (1:1 → 1:many) ─

ALTER TABLE "vehicles" DROP CONSTRAINT IF EXISTS "vehicles_driver_id_key";

-- ─── Step 3: Create student_vehicle_assignments table ────────────────────────

CREATE TABLE "student_vehicle_assignments" (
    "id"               UUID        NOT NULL DEFAULT gen_random_uuid(),
    "school_id"        UUID        NOT NULL,
    "student_id"       UUID        NOT NULL,
    "vehicle_id"       UUID        NOT NULL,
    "pickup_stop_name" VARCHAR(100),
    "pickup_lat"       DECIMAL(10, 7),
    "pickup_lng"       DECIMAL(10, 7),
    "drop_stop_name"   VARCHAR(100),
    "drop_lat"         DECIMAL(10, 7),
    "drop_lng"         DECIMAL(10, 7),
    "is_active"        BOOLEAN     NOT NULL DEFAULT true,
    "created_at"       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_vehicle_assignments_pkey" PRIMARY KEY ("id")
);

-- Unique: one active assignment per student (application enforces deactivation before reassignment)
CREATE UNIQUE INDEX "student_vehicle_assignments_student_unique"
    ON "student_vehicle_assignments"("student_id");

CREATE INDEX "student_vehicle_assignments_school_id_idx"
    ON "student_vehicle_assignments"("school_id");

CREATE INDEX "student_vehicle_assignments_vehicle_id_idx"
    ON "student_vehicle_assignments"("vehicle_id");

CREATE INDEX "student_vehicle_assignments_student_id_is_active_idx"
    ON "student_vehicle_assignments"("student_id", "is_active");

-- Foreign keys
ALTER TABLE "student_vehicle_assignments"
    ADD CONSTRAINT "student_vehicle_assignments_school_id_fkey"
        FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_vehicle_assignments"
    ADD CONSTRAINT "student_vehicle_assignments_student_id_fkey"
        FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_vehicle_assignments"
    ADD CONSTRAINT "student_vehicle_assignments_vehicle_id_fkey"
        FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── Step 4: Create student_trip_events table ─────────────────────────────────

CREATE TABLE "student_trip_events" (
    "id"          UUID        NOT NULL DEFAULT gen_random_uuid(),
    "trip_id"     UUID        NOT NULL,
    "student_id"  UUID        NOT NULL,
    "school_id"   UUID        NOT NULL,
    "event_type"  VARCHAR(10) NOT NULL,
    "lat"         DECIMAL(10, 7),
    "lng"         DECIMAL(10, 7),
    "photo_url"   TEXT,
    "occurred_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at"  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_trip_events_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "student_trip_events_trip_id_idx"
    ON "student_trip_events"("trip_id");

CREATE INDEX "student_trip_events_student_id_occurred_at_idx"
    ON "student_trip_events"("student_id", "occurred_at");

CREATE INDEX "student_trip_events_school_id_idx"
    ON "student_trip_events"("school_id");

-- Foreign keys
ALTER TABLE "student_trip_events"
    ADD CONSTRAINT "student_trip_events_trip_id_fkey"
        FOREIGN KEY ("trip_id") REFERENCES "driver_trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_trip_events"
    ADD CONSTRAINT "student_trip_events_student_id_fkey"
        FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "student_trip_events"
    ADD CONSTRAINT "student_trip_events_school_id_fkey"
        FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
