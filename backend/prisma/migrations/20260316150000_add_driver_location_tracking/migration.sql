-- Migration: 20260316150000_add_driver_location_tracking
-- Created: 2026-03-16
-- Description: Adds DriverTrip, DriverLocation, and DriverLocationCurrent models
--              for real-time GPS tracking in the Driver Portal (Transport Module).
--              Also adds relation columns to School, Driver, Vehicle, and TransportRoute.

-- ─── CreateTable: driver_trips ───────────────────────────────────────────────

CREATE TABLE "driver_trips" (
    "id"         UUID         NOT NULL DEFAULT gen_random_uuid(),
    "school_id"  UUID         NOT NULL,
    "driver_id"  UUID         NOT NULL,
    "vehicle_id" UUID,
    "route_id"   UUID,
    "status"     VARCHAR(20)  NOT NULL DEFAULT 'NOT_STARTED',
    "started_at" TIMESTAMPTZ(6),
    "ended_at"   TIMESTAMPTZ(6),
    "notes"      TEXT,
    "deleted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "driver_trips_pkey" PRIMARY KEY ("id")
);

-- ─── CreateTable: driver_locations ───────────────────────────────────────────

CREATE TABLE "driver_locations" (
    "id"          UUID          NOT NULL DEFAULT gen_random_uuid(),
    "trip_id"     UUID,
    "driver_id"   UUID          NOT NULL,
    "vehicle_id"  UUID,
    "school_id"   UUID          NOT NULL,
    "lat"         DECIMAL(10,7) NOT NULL,
    "lng"         DECIMAL(10,7) NOT NULL,
    "speed"       DOUBLE PRECISION,
    "heading"     DOUBLE PRECISION,
    "accuracy"    DOUBLE PRECISION,
    "recorded_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at"  TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "driver_locations_pkey" PRIMARY KEY ("id")
);

-- ─── CreateTable: driver_location_current ────────────────────────────────────

CREATE TABLE "driver_location_current" (
    "driver_id"  UUID          NOT NULL,
    "vehicle_id" UUID,
    "school_id"  UUID          NOT NULL,
    "lat"        DECIMAL(10,7) NOT NULL,
    "lng"        DECIMAL(10,7) NOT NULL,
    "speed"      DOUBLE PRECISION,
    "heading"    DOUBLE PRECISION,
    "accuracy"   DOUBLE PRECISION,
    "trip_id"    UUID,
    "updated_at" TIMESTAMPTZ   NOT NULL,

    CONSTRAINT "driver_location_current_pkey" PRIMARY KEY ("driver_id")
);

-- One vehicle can have at most one current location row
CREATE UNIQUE INDEX "driver_location_current_vehicle_id_key" ON "driver_location_current"("vehicle_id");

-- ─── CreateIndex: driver_trips ────────────────────────────────────────────────

CREATE INDEX "driver_trips_school_id_status_idx"  ON "driver_trips"("school_id", "status");
CREATE INDEX "driver_trips_driver_id_status_idx"  ON "driver_trips"("driver_id", "status");
CREATE INDEX "driver_trips_vehicle_id_status_idx" ON "driver_trips"("vehicle_id", "status");
CREATE INDEX "driver_trips_created_at_idx"        ON "driver_trips"("created_at");

-- ─── CreateIndex: driver_locations ───────────────────────────────────────────

CREATE INDEX "driver_locations_driver_id_recorded_at_idx"  ON "driver_locations"("driver_id", "recorded_at");
CREATE INDEX "driver_locations_vehicle_id_recorded_at_idx" ON "driver_locations"("vehicle_id", "recorded_at");
CREATE INDEX "driver_locations_school_id_recorded_at_idx"  ON "driver_locations"("school_id", "recorded_at");

-- ─── CreateIndex: driver_location_current ────────────────────────────────────

CREATE INDEX "driver_location_current_school_id_idx" ON "driver_location_current"("school_id");

-- ─── AddForeignKey: driver_trips → schools ───────────────────────────────────

ALTER TABLE "driver_trips"
    ADD CONSTRAINT "driver_trips_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_trips → drivers ───────────────────────────────────

ALTER TABLE "driver_trips"
    ADD CONSTRAINT "driver_trips_driver_id_fkey"
    FOREIGN KEY ("driver_id") REFERENCES "drivers"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_trips → vehicles ──────────────────────────────────

ALTER TABLE "driver_trips"
    ADD CONSTRAINT "driver_trips_vehicle_id_fkey"
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_trips → transport_routes ──────────────────────────

ALTER TABLE "driver_trips"
    ADD CONSTRAINT "driver_trips_route_id_fkey"
    FOREIGN KEY ("route_id") REFERENCES "transport_routes"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_locations → drivers ───────────────────────────────

ALTER TABLE "driver_locations"
    ADD CONSTRAINT "driver_locations_driver_id_fkey"
    FOREIGN KEY ("driver_id") REFERENCES "drivers"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_locations → vehicles ──────────────────────────────

ALTER TABLE "driver_locations"
    ADD CONSTRAINT "driver_locations_vehicle_id_fkey"
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_locations → schools ───────────────────────────────

ALTER TABLE "driver_locations"
    ADD CONSTRAINT "driver_locations_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_location_current → drivers ────────────────────────

ALTER TABLE "driver_location_current"
    ADD CONSTRAINT "driver_location_current_driver_id_fkey"
    FOREIGN KEY ("driver_id") REFERENCES "drivers"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_location_current → vehicles ───────────────────────

ALTER TABLE "driver_location_current"
    ADD CONSTRAINT "driver_location_current_vehicle_id_fkey"
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ─── AddForeignKey: driver_location_current → schools ────────────────────────

ALTER TABLE "driver_location_current"
    ADD CONSTRAINT "driver_location_current_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
