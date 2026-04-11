/**
 * Transport Vehicles Repository — Prisma queries for vehicle management.
 */

import prisma from '../../config/prisma.js';

class TransportVehiclesRepository {
  // ── Vehicle CRUD ───────────────────────────────────────────────────────────

  async findAll({ schoolId, page = 1, limit = 20, search }) {
    const skip = (page - 1) * limit;

    const where = {
      schoolId,
      deletedAt: null,
      ...(search && {
        OR: [
          { vehicleNo: { contains: search, mode: 'insensitive' } },
          { make: { contains: search, mode: 'insensitive' } },
          { model: { contains: search, mode: 'insensitive' } },
          { color: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [data, total] = await Promise.all([
      prisma.vehicle.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          driver: {
            select: { id: true, firstName: true, lastName: true },
          },
          locationCurrent: {
            select: { lat: true, lng: true, updatedAt: true },
          },
          _count: {
            select: { studentAssignments: { where: { isActive: true } } },
          },
        },
      }),
      prisma.vehicle.count({ where }),
    ]);

    return {
      data,
      pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  async findById(id, schoolId) {
    return prisma.vehicle.findFirst({
      where: { id, schoolId, deletedAt: null },
      include: {
        driver: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
            email: true,
            licenseNumber: true,
            licenseExpiry: true,
            photoUrl: true,
          },
        },
        route: {
          include: {
            stops: { orderBy: { sequence: 'asc' } },
          },
        },
        locationCurrent: true,
        studentAssignments: {
          where: { isActive: true },
          include: {
            student: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                rollNo: true,
                class_: { select: { id: true, name: true } },
                section: { select: { id: true, name: true } },
              },
            },
          },
        },
      },
    });
  }

  async findByVehicleNo(vehicleNo, schoolId) {
    return prisma.vehicle.findFirst({
      where: {
        vehicleNo: { equals: vehicleNo, mode: 'insensitive' },
        schoolId,
        deletedAt: null,
      },
    });
  }

  async create(data) {
    return prisma.vehicle.create({ data });
  }

  async update(id, schoolId, data) {
    const existing = await prisma.vehicle.findFirst({
      where: { id, schoolId, deletedAt: null },
    });
    if (!existing) return null;
    return prisma.vehicle.update({
      where: { id },
      data: { ...data, updatedAt: new Date() },
    });
  }

  async softDelete(id, schoolId) {
    const existing = await prisma.vehicle.findFirst({
      where: { id, schoolId, deletedAt: null },
    });
    if (!existing) return null;
    return prisma.vehicle.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // ── Driver Assignment ──────────────────────────────────────────────────────

  async assignDriver(vehicleId, schoolId, driverId) {
    return prisma.vehicle.update({
      where: { id: vehicleId },
      data: { driverId, updatedAt: new Date() },
    });
  }

  async unassignDriver(vehicleId, schoolId) {
    return prisma.vehicle.update({
      where: { id: vehicleId },
      data: { driverId: null, updatedAt: new Date() },
    });
  }

  // ── Student Assignments ────────────────────────────────────────────────────

  async findStudentAssignments(vehicleId, schoolId) {
    return prisma.studentVehicleAssignment.findMany({
      where: { vehicleId, schoolId, isActive: true },
      include: {
        student: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            rollNo: true,
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findStudentAssignment(studentId) {
    return prisma.studentVehicleAssignment.findFirst({
      where: { studentId, isActive: true },
    });
  }

  async assignStudent(data) {
    // Upsert: if student already has an assignment (even inactive), reactivate and update
    const existing = await prisma.studentVehicleAssignment.findFirst({
      where: { studentId: data.studentId },
    });
    if (existing) {
      return prisma.studentVehicleAssignment.update({
        where: { id: existing.id },
        data: {
          vehicleId: data.vehicleId,
          pickupStopName: data.pickupStopName || null,
          pickupLat: data.pickupLat || null,
          pickupLng: data.pickupLng || null,
          dropStopName: data.dropStopName || null,
          dropLat: data.dropLat || null,
          dropLng: data.dropLng || null,
          isActive: true,
          updatedAt: new Date(),
        },
      });
    }
    return prisma.studentVehicleAssignment.create({ data });
  }

  async removeStudent(vehicleId, studentId, schoolId) {
    const assignment = await prisma.studentVehicleAssignment.findFirst({
      where: { vehicleId, studentId, schoolId, isActive: true },
    });
    if (!assignment) return null;
    return prisma.studentVehicleAssignment.update({
      where: { id: assignment.id },
      data: { isActive: false, updatedAt: new Date() },
    });
  }

  // ── Live Vehicles ──────────────────────────────────────────────────────────

  async findLiveVehicles(schoolId) {
    const vehicles = await prisma.vehicle.findMany({
      where: { schoolId, isActive: true, deletedAt: null },
      include: {
        driver: {
          select: { id: true, firstName: true, lastName: true, tripActive: true },
        },
        locationCurrent: true,
      },
    });

    // Get active trips for vehicles
    const vehicleIds = vehicles.map((v) => v.id);
    const activeTrips = vehicleIds.length > 0
      ? await prisma.driverTrip.findMany({
          where: { vehicleId: { in: vehicleIds }, status: 'IN_PROGRESS', deletedAt: null },
          select: { vehicleId: true },
        })
      : [];
    const tripVehicleSet = new Set(activeTrips.map((t) => t.vehicleId));

    return vehicles.map((v) => ({
      id: v.id,
      vehicleNo: v.vehicleNo,
      lat: v.locationCurrent ? Number(v.locationCurrent.lat) : null,
      lng: v.locationCurrent ? Number(v.locationCurrent.lng) : null,
      speed: v.locationCurrent?.speed ?? null,
      heading: v.locationCurrent?.heading ?? null,
      updatedAt: v.locationCurrent?.updatedAt?.toISOString() || null,
      driverName: v.driver ? `${v.driver.firstName} ${v.driver.lastName}` : null,
      tripActive: tripVehicleSet.has(v.id),
    }));
  }

  // ── Unassigned Students ────────────────────────────────────────────────────

  async findUnassignedStudents({ schoolId, search, page = 1, limit = 20 }) {
    const skip = (page - 1) * limit;

    // Get student IDs that have active assignments
    const assignedStudentIds = (
      await prisma.studentVehicleAssignment.findMany({
        where: { schoolId, isActive: true },
        select: { studentId: true },
      })
    ).map((a) => a.studentId);

    const where = {
      schoolId,
      deletedAt: null,
      status: 'ACTIVE',
      ...(assignedStudentIds.length > 0 && { id: { notIn: assignedStudentIds } }),
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { admissionNo: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [data, total] = await Promise.all([
      prisma.student.findMany({
        where,
        skip,
        take: limit,
        orderBy: { firstName: 'asc' },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          admissionNo: true,
          rollNo: true,
          class_: { select: { id: true, name: true } },
          section: { select: { id: true, name: true } },
        },
      }),
      prisma.student.count({ where }),
    ]);

    return {
      data,
      pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  // ── Student/Parent: My Vehicle ─────────────────────────────────────────────

  async findStudentVehicle(studentId, schoolId) {
    const assignment = await prisma.studentVehicleAssignment.findFirst({
      where: { studentId, schoolId, isActive: true },
      include: {
        vehicle: {
          include: {
            driver: { select: { id: true, firstName: true, lastName: true, phone: true } },
            locationCurrent: true,
          },
        },
      },
    });
    return assignment;
  }

  // ── Student/Parent: Trip History ───────────────────────────────────────────

  async findStudentTrips(studentId, schoolId, { page = 1, limit = 10 }) {
    const skip = (page - 1) * limit;

    // Find events for this student
    const where = { studentId, schoolId };

    const [events, total] = await Promise.all([
      prisma.studentTripEvent.findMany({
        where,
        skip,
        take: limit,
        orderBy: { occurredAt: 'desc' },
        include: {
          trip: {
            include: {
              vehicle: { select: { id: true, vehicleNo: true } },
              driver: { select: { id: true, firstName: true, lastName: true } },
            },
          },
        },
      }),
      prisma.studentTripEvent.count({ where }),
    ]);

    // Group events by trip
    const tripMap = {};
    for (const event of events) {
      const tripId = event.tripId;
      if (!tripMap[tripId]) {
        tripMap[tripId] = {
          id: event.trip.id,
          startedAt: event.trip.startedAt?.toISOString() || null,
          endedAt: event.trip.endedAt?.toISOString() || null,
          vehicleNo: event.trip.vehicle?.vehicleNo || null,
          driverName: event.trip.driver ? `${event.trip.driver.firstName} ${event.trip.driver.lastName}` : null,
          events: [],
        };
      }
      tripMap[tripId].events.push({
        eventType: event.eventType,
        occurredAt: event.occurredAt.toISOString(),
        lat: event.lat ? Number(event.lat) : null,
        lng: event.lng ? Number(event.lng) : null,
      });
    }

    return {
      data: Object.values(tripMap),
      pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  // ── Trip Event ─────────────────────────────────────────────────────────────

  async createTripEvent(data) {
    return prisma.studentTripEvent.create({ data });
  }
}

export const transportVehiclesRepository = new TransportVehiclesRepository();
