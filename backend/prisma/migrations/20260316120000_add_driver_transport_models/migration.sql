-- Migration: 20260316120000_add_driver_transport_models
-- Created: 2026-03-16
-- Driver Portal (Transport Module): drivers, vehicles, transport_routes, route_stops

-- Drop partially created tables from failed prior run (CASCADE for any legacy names)
DROP TABLE IF EXISTS "route_stops" CASCADE;
DROP TABLE IF EXISTS "transport_stops" CASCADE;
DROP TABLE IF EXISTS "transport_routes" CASCADE;
DROP TABLE IF EXISTS "vehicles" CASCADE;
DROP TABLE IF EXISTS "drivers" CASCADE;

-- CreateTable: drivers
CREATE TABLE "drivers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "user_id" UUID,
    "employee_no" VARCHAR(50) NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "gender" VARCHAR(10) NOT NULL,
    "date_of_birth" DATE,
    "phone" VARCHAR(20),
    "email" VARCHAR(255) NOT NULL,
    "license_number" VARCHAR(50),
    "license_expiry" DATE,
    "photo_url" TEXT,
    "address" TEXT,
    "emergency_contact_name" VARCHAR(100),
    "emergency_contact_phone" VARCHAR(20),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "deleted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "drivers_pkey" PRIMARY KEY ("id")
);

-- CreateTable: vehicles
CREATE TABLE "vehicles" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "driver_id" UUID,
    "vehicle_no" VARCHAR(50) NOT NULL,
    "capacity" INTEGER NOT NULL DEFAULT 30,
    "gps_device_id" VARCHAR(100),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "deleted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "vehicles_pkey" PRIMARY KEY ("id")
);

-- CreateTable: transport_routes
CREATE TABLE "transport_routes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "vehicle_id" UUID,
    "name" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "deleted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "transport_routes_pkey" PRIMARY KEY ("id")
);

-- CreateTable: route_stops
CREATE TABLE "route_stops" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "route_id" UUID NOT NULL,
    "sequence" SMALLINT NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "address" TEXT,
    "lat" DECIMAL(10, 7),
    "lng" DECIMAL(10, 7),
    "estimated_arrival" VARCHAR(8),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "route_stops_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: drivers (IF NOT EXISTS for idempotency)
CREATE UNIQUE INDEX IF NOT EXISTS "drivers_user_id_key" ON "drivers"("user_id");
CREATE UNIQUE INDEX IF NOT EXISTS "drivers_school_id_employee_no_key" ON "drivers"("school_id", "employee_no");
CREATE INDEX IF NOT EXISTS "drivers_school_id_idx" ON "drivers"("school_id");
CREATE INDEX IF NOT EXISTS "drivers_user_id_idx" ON "drivers"("user_id");

-- CreateIndex: vehicles
CREATE UNIQUE INDEX IF NOT EXISTS "vehicles_driver_id_key" ON "vehicles"("driver_id");
CREATE UNIQUE INDEX IF NOT EXISTS "vehicles_school_id_vehicle_no_key" ON "vehicles"("school_id", "vehicle_no");
CREATE INDEX IF NOT EXISTS "vehicles_school_id_idx" ON "vehicles"("school_id");
CREATE INDEX IF NOT EXISTS "vehicles_driver_id_idx" ON "vehicles"("driver_id");

-- CreateIndex: transport_routes
CREATE UNIQUE INDEX IF NOT EXISTS "transport_routes_vehicle_id_key" ON "transport_routes"("vehicle_id");
CREATE INDEX IF NOT EXISTS "transport_routes_school_id_idx" ON "transport_routes"("school_id");
CREATE INDEX IF NOT EXISTS "transport_routes_vehicle_id_idx" ON "transport_routes"("vehicle_id");

-- CreateIndex: route_stops
CREATE UNIQUE INDEX IF NOT EXISTS "route_stops_route_id_sequence_key" ON "route_stops"("route_id", "sequence");
CREATE INDEX IF NOT EXISTS "route_stops_route_id_idx" ON "route_stops"("route_id");

-- AddForeignKey: drivers (skip if exists)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'drivers_school_id_fkey') THEN
        ALTER TABLE "drivers" ADD CONSTRAINT "drivers_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'drivers_user_id_fkey') THEN
        ALTER TABLE "drivers" ADD CONSTRAINT "drivers_user_id_fkey"
            FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey: vehicles
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicles_school_id_fkey') THEN
        ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicles_driver_id_fkey') THEN
        ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_driver_id_fkey"
            FOREIGN KEY ("driver_id") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey: transport_routes
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'transport_routes_school_id_fkey') THEN
        ALTER TABLE "transport_routes" ADD CONSTRAINT "transport_routes_school_id_fkey"
            FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'transport_routes_vehicle_id_fkey') THEN
        ALTER TABLE "transport_routes" ADD CONSTRAINT "transport_routes_vehicle_id_fkey"
            FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey: route_stops
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'route_stops_route_id_fkey') THEN
        ALTER TABLE "route_stops" ADD CONSTRAINT "route_stops_route_id_fkey"
            FOREIGN KEY ("route_id") REFERENCES "transport_routes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
