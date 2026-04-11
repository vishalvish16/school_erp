/**
 * Transport Repository — Prisma queries for school admin transport/live-map.
 */

import prisma from '../../config/prisma.js';

export async function findLiveVehicles(schoolId) {
  const vehicles = await prisma.vehicle.findMany({
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

  // Get active trips for each vehicle that has one
  const vehicleIds = vehicles.map((v) => v.id).filter(Boolean);
  const activeTrips =
    vehicleIds.length > 0
      ? await prisma.driverTrip.findMany({
          where: { vehicleId: { in: vehicleIds }, status: 'IN_PROGRESS', deletedAt: null },
          select: { vehicleId: true, id: true, status: true, startedAt: true },
        })
      : [];

  const tripByVehicle = {};
  for (const t of activeTrips) {
    if (t.vehicleId) tripByVehicle[t.vehicleId] = t;
  }

  return vehicles.map((v) => ({
    id: v.id,
    vehicleNo: v.vehicleNo,
    capacity: v.capacity,
    driver: v.driver
      ? {
          id: v.driver.id,
          firstName: v.driver.firstName,
          lastName: v.driver.lastName,
          phone: v.driver.phone,
          photoUrl: v.driver.photoUrl,
        }
      : null,
    route: v.route ? { id: v.route.id, name: v.route.name } : null,
    tripStatus: tripByVehicle[v.id]?.status || 'NOT_STARTED',
    location: v.locationCurrent
      ? {
          lat: Number(v.locationCurrent.lat),
          lng: Number(v.locationCurrent.lng),
          speed: v.locationCurrent.speed ?? null,
          heading: v.locationCurrent.heading ?? null,
          updatedAt: v.locationCurrent.updatedAt.toISOString(),
        }
      : null,
  }));
}
