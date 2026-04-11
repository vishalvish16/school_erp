/**
 * Driver Repository — Prisma queries for the driver portal.
 * Uses DriverTrip, DriverLocation, and DriverLocationCurrent tables
 * instead of denormalized fields on the Driver model.
 */

import prisma from '../../config/prisma.js';

class DriverRepository {
  async findByIdWithRelations(id, schoolId) {
    return prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
      include: {
        school: { select: { id: true, name: true, logoUrl: true } },
        vehicle: {
          include: {
            route: {
              include: { stops: true },
            },
          },
        },
        user: {
          select: {
            id: true,
            email: true,
            lastLogin: true,
          },
        },
      },
    });
  }

  async update(id, schoolId, data) {
    const existing = await prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
    });
    if (!existing) return null;
    return prisma.driver.update({
      where: { id },
      data: { ...data, updatedAt: new Date() },
    });
  }

  // ── Trip Methods ────────────────────────────────────────────────────────────

  /**
   * Find active trip (IN_PROGRESS) for a driver.
   */
  async findActiveTrip(driverId) {
    return prisma.driverTrip.findFirst({
      where: { driverId, status: 'IN_PROGRESS', deletedAt: null },
      orderBy: { startedAt: 'desc' },
    });
  }

  /**
   * Start a new trip — idempotent (returns existing if already IN_PROGRESS).
   */
  async startTrip(driverId, schoolId, vehicleId, routeId) {
    const existing = await prisma.driverTrip.findFirst({
      where: { driverId, status: 'IN_PROGRESS', deletedAt: null },
    });
    if (existing) return existing;

    return prisma.driverTrip.create({
      data: {
        driverId,
        schoolId,
        vehicleId: vehicleId || null,
        routeId: routeId || null,
        status: 'IN_PROGRESS',
        startedAt: new Date(),
      },
    });
  }

  /**
   * End the active trip for a driver.
   */
  async endTrip(driverId, notes) {
    const trip = await prisma.driverTrip.findFirst({
      where: { driverId, status: 'IN_PROGRESS', deletedAt: null },
      orderBy: { startedAt: 'desc' },
    });
    if (!trip) return null;

    return prisma.driverTrip.update({
      where: { id: trip.id },
      data: { status: 'COMPLETED', endedAt: new Date(), notes: notes || null },
    });
  }

  // ── Location Methods ────────────────────────────────────────────────────────

  /**
   * Insert a GPS point into DriverLocation and upsert DriverLocationCurrent.
   */
  async recordLocation(driverId, schoolId, vehicleId, tripId, { lat, lng, speed, heading, accuracy, recordedAt }) {
    const [location] = await prisma.$transaction([
      prisma.driverLocation.create({
        data: {
          driverId,
          schoolId,
          vehicleId: vehicleId || null,
          tripId: tripId || null,
          lat,
          lng,
          speed: speed ?? null,
          heading: heading ?? null,
          accuracy: accuracy ?? null,
          recordedAt: recordedAt ? new Date(recordedAt) : new Date(),
        },
      }),
      prisma.driverLocationCurrent.upsert({
        where: { driverId },
        create: {
          driverId,
          schoolId,
          vehicleId: vehicleId || null,
          lat,
          lng,
          speed: speed ?? null,
          heading: heading ?? null,
          accuracy: accuracy ?? null,
          tripId: tripId || null,
          updatedAt: new Date(),
        },
        update: {
          lat,
          lng,
          speed: speed ?? null,
          heading: heading ?? null,
          accuracy: accuracy ?? null,
          vehicleId: vehicleId || null,
          tripId: tripId || null,
          updatedAt: new Date(),
        },
      }),
    ]);
    return location;
  }

  /**
   * Get all active vehicles with current location for a school (live map).
   */
  async findLiveVehicles(schoolId) {
    return prisma.vehicle.findMany({
      where: { schoolId, isActive: true, deletedAt: null },
      include: {
        driver: {
          where: { deletedAt: null },
          select: { id: true, firstName: true, lastName: true, phone: true, photoUrl: true },
        },
        route: { select: { id: true, name: true } },
        locationCurrent: true,
      },
    });
  }
}

export const driverRepository = new DriverRepository();
