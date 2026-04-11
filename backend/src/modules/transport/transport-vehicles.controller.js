/**
 * Transport Vehicles Controller — HTTP handlers for /api/school/transport/*
 * Manages vehicle CRUD, driver/student assignments, and student/parent bus tracking.
 */
import { transportVehiclesRepository } from './transport-vehicles.repository.js';
import { successResponse, AppError } from '../../utils/response.js';
import { getIO } from '../../socket.js';
import { logger } from '../../config/logger.js';
import prisma from '../../config/prisma.js';

// ── Vehicle CRUD ──────────────────────────────────────────────────────────────

// GET /vehicles
export const listVehicles = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const { page = 1, limit = 20, search } = req.query;
    const result = await transportVehiclesRepository.findAll({
      schoolId,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      search,
    });

    const vehicles = result.data.map((v) => ({
      id: v.id,
      vehicleNo: v.vehicleNo,
      vehicleType: v.vehicleType,
      capacity: v.capacity,
      make: v.make,
      model: v.model,
      year: v.year,
      color: v.color,
      rcNumber: v.rcNumber,
      isActive: v.isActive,
      driver: v.driver
        ? { id: v.driver.id, firstName: v.driver.firstName, lastName: v.driver.lastName }
        : null,
      studentCount: v._count?.studentAssignments ?? 0,
      lastLocation: v.locationCurrent
        ? {
            lat: Number(v.locationCurrent.lat),
            lng: Number(v.locationCurrent.lng),
            updatedAt: v.locationCurrent.updatedAt?.toISOString() || null,
          }
        : null,
    }));

    return successResponse(res, 200, 'OK', {
      vehicles,
      total: result.pagination.total,
      page: result.pagination.page,
      total_pages: result.pagination.total_pages,
    });
  } catch (err) {
    next(err);
  }
};

// POST /vehicles
export const createVehicle = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const { vehicleNo } = req.body;

    // Check vehicleNo uniqueness for this school
    const existing = await transportVehiclesRepository.findByVehicleNo(vehicleNo, schoolId);
    if (existing) {
      throw new AppError('Vehicle number already exists in this school', 409);
    }

    const vehicle = await transportVehiclesRepository.create({
      schoolId,
      ...req.body,
    });

    logger.info(`[Transport] Vehicle created: ${vehicle.vehicleNo} (school=${schoolId})`);
    return successResponse(res, 201, 'Vehicle created', { vehicle });
  } catch (err) {
    next(err);
  }
};

// GET /vehicles/live
export const getLiveVehicles = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const vehicles = await transportVehiclesRepository.findLiveVehicles(schoolId);
    return successResponse(res, 200, 'OK', { vehicles });
  } catch (err) {
    next(err);
  }
};

// GET /vehicles/:id
export const getVehicle = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const vehicle = await transportVehiclesRepository.findById(req.params.id, schoolId);
    if (!vehicle) throw new AppError('Vehicle not found', 404);

    // Format students from assignments
    const students = (vehicle.studentAssignments || []).map((a) => ({
      id: a.student?.id,
      firstName: a.student?.firstName,
      lastName: a.student?.lastName,
      rollNo: a.student?.rollNo,
      class: a.student?.class_,
      section: a.student?.section,
      pickupStopName: a.pickupStopName,
      dropStopName: a.dropStopName,
    }));

    // Format current location
    const currentLocation = vehicle.locationCurrent
      ? {
          lat: Number(vehicle.locationCurrent.lat),
          lng: Number(vehicle.locationCurrent.lng),
          speed: vehicle.locationCurrent.speed ?? null,
          heading: vehicle.locationCurrent.heading ?? null,
          updatedAt: vehicle.locationCurrent.updatedAt?.toISOString() || null,
        }
      : null;

    // Format route
    const route = vehicle.route
      ? {
          id: vehicle.route.id,
          name: vehicle.route.name,
          description: vehicle.route.description,
          stops: (vehicle.route.stops || []).map((s) => ({
            id: s.id,
            name: s.name,
            sequence: s.sequence,
            lat: s.lat ? Number(s.lat) : null,
            lng: s.lng ? Number(s.lng) : null,
          })),
        }
      : null;

    return successResponse(res, 200, 'OK', {
      vehicle: {
        id: vehicle.id,
        vehicleNo: vehicle.vehicleNo,
        vehicleType: vehicle.vehicleType,
        capacity: vehicle.capacity,
        make: vehicle.make,
        model: vehicle.model,
        year: vehicle.year,
        color: vehicle.color,
        rcNumber: vehicle.rcNumber,
        insuranceExpiry: vehicle.insuranceExpiry,
        fitnessExpiry: vehicle.fitnessExpiry,
        gpsDeviceId: vehicle.gpsDeviceId,
        isActive: vehicle.isActive,
        createdAt: vehicle.createdAt,
        updatedAt: vehicle.updatedAt,
      },
      driver: vehicle.driver || null,
      students,
      route,
      currentLocation,
    });
  } catch (err) {
    next(err);
  }
};

// PUT /vehicles/:id
export const updateVehicle = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    // If vehicleNo is being changed, check uniqueness
    if (req.body.vehicleNo) {
      const existing = await transportVehiclesRepository.findByVehicleNo(req.body.vehicleNo, schoolId);
      if (existing && existing.id !== req.params.id) {
        throw new AppError('Vehicle number already exists in this school', 409);
      }
    }

    const vehicle = await transportVehiclesRepository.update(req.params.id, schoolId, req.body);
    if (!vehicle) throw new AppError('Vehicle not found', 404);

    logger.info(`[Transport] Vehicle updated: ${vehicle.vehicleNo} (school=${schoolId})`);
    return successResponse(res, 200, 'Vehicle updated', { vehicle });
  } catch (err) {
    next(err);
  }
};

// DELETE /vehicles/:id
export const deleteVehicle = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const vehicle = await transportVehiclesRepository.softDelete(req.params.id, schoolId);
    if (!vehicle) throw new AppError('Vehicle not found', 404);

    logger.info(`[Transport] Vehicle deleted: ${vehicle.vehicleNo} (school=${schoolId})`);
    return successResponse(res, 200, 'Vehicle deleted');
  } catch (err) {
    next(err);
  }
};

// ── Driver Assignment ─────────────────────────────────────────────────────────

// POST /vehicles/:id/assign-driver
export const assignDriver = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const { driver_id } = req.body;

    // Verify vehicle exists in this school
    const vehicle = await transportVehiclesRepository.findById(req.params.id, schoolId);
    if (!vehicle) throw new AppError('Vehicle not found', 404);
    const driver = await prisma.driver.findFirst({
      where: { id: driver_id, schoolId, deletedAt: null, isActive: true },
    });
    if (!driver) throw new AppError('Driver not found in this school', 404);

    const updated = await transportVehiclesRepository.assignDriver(req.params.id, schoolId, driver_id);
    logger.info(`[Transport] Driver ${driver_id} assigned to vehicle ${req.params.id} (school=${schoolId})`);
    return successResponse(res, 200, 'Driver assigned', { vehicle: updated });
  } catch (err) {
    next(err);
  }
};

// DELETE /vehicles/:id/unassign-driver
export const unassignDriver = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const vehicle = await transportVehiclesRepository.findById(req.params.id, schoolId);
    if (!vehicle) throw new AppError('Vehicle not found', 404);

    const updated = await transportVehiclesRepository.unassignDriver(req.params.id, schoolId);
    logger.info(`[Transport] Driver unassigned from vehicle ${req.params.id} (school=${schoolId})`);
    return successResponse(res, 200, 'Driver unassigned', { vehicle: updated });
  } catch (err) {
    next(err);
  }
};

// ── Student Assignment ────────────────────────────────────────────────────────

// GET /vehicles/:id/students
export const listVehicleStudents = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const students = await transportVehiclesRepository.findStudentAssignments(req.params.id, schoolId);
    return successResponse(res, 200, 'OK', { students });
  } catch (err) {
    next(err);
  }
};

// POST /vehicles/:id/students
export const assignStudent = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const { student_id, pickup_stop_name, pickup_lat, pickup_lng, drop_stop_name, drop_lat, drop_lng } = req.body;

    // Verify vehicle exists in this school
    const vehicle = await transportVehiclesRepository.findById(req.params.id, schoolId);
    if (!vehicle) throw new AppError('Vehicle not found', 404);

    const assignment = await transportVehiclesRepository.assignStudent({
      schoolId,
      vehicleId: req.params.id,
      studentId: student_id,
      pickupStopName: pickup_stop_name || null,
      pickupLat: pickup_lat || null,
      pickupLng: pickup_lng || null,
      dropStopName: drop_stop_name || null,
      dropLat: drop_lat || null,
      dropLng: drop_lng || null,
    });

    logger.info(`[Transport] Student ${student_id} assigned to vehicle ${req.params.id} (school=${schoolId})`);
    return successResponse(res, 200, 'Student assigned', { assignment });
  } catch (err) {
    next(err);
  }
};

// DELETE /vehicles/:id/students/:studentId
export const removeStudent = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const result = await transportVehiclesRepository.removeStudent(req.params.id, req.params.studentId, schoolId);
    if (!result) throw new AppError('Student assignment not found', 404);

    logger.info(`[Transport] Student ${req.params.studentId} removed from vehicle ${req.params.id} (school=${schoolId})`);
    return successResponse(res, 200, 'Student removed from vehicle');
  } catch (err) {
    next(err);
  }
};

// ── Unassigned Students ───────────────────────────────────────────────────────

// GET /students/unassigned
export const listUnassignedStudents = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const { page = 1, limit = 20, search } = req.query;
    const result = await transportVehiclesRepository.findUnassignedStudents({
      schoolId,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });

    return successResponse(res, 200, 'OK', {
      students: result.data,
      total: result.pagination.total,
      page: result.pagination.page,
      total_pages: result.pagination.total_pages,
    });
  } catch (err) {
    next(err);
  }
};

// ── Student Portal: My Vehicle ────────────────────────────────────────────────

// GET /my-vehicle
export const getMyVehicle = async (req, res, next) => {
  try {
    const studentId = req.user.studentId || req.user.student_id;
    const schoolId = req.user.school_id || req.user.schoolId;
    if (!studentId || !schoolId) {
      return successResponse(res, 200, 'OK', { assignment: null, currentLocation: null, tripActive: false });
    }

    const assignmentRecord = await transportVehiclesRepository.findStudentVehicle(studentId, schoolId);
    if (!assignmentRecord) {
      return successResponse(res, 200, 'OK', { assignment: null, currentLocation: null, tripActive: false });
    }

    const vehicle = assignmentRecord.vehicle;
    const driver = vehicle?.driver;

    const assignment = {
      vehicleNo: vehicle?.vehicleNo || null,
      driverName: driver ? `${driver.firstName} ${driver.lastName}` : null,
      pickupStopName: assignmentRecord.pickupStopName || null,
      dropStopName: assignmentRecord.dropStopName || null,
    };

    const currentLocation = vehicle?.locationCurrent
      ? {
          lat: Number(vehicle.locationCurrent.lat),
          lng: Number(vehicle.locationCurrent.lng),
          updatedAt: vehicle.locationCurrent.updatedAt?.toISOString() || null,
          speed: vehicle.locationCurrent.speed ?? null,
        }
      : null;

    // Check if there's an active trip for this vehicle
    let tripActive = false;
    if (vehicle?.id) {
      const activeTrip = await prisma.driverTrip.findFirst({
        where: { vehicleId: vehicle.id, status: 'IN_PROGRESS', deletedAt: null },
      });
      tripActive = !!activeTrip;
    }

    return successResponse(res, 200, 'OK', { assignment, currentLocation, tripActive });
  } catch (err) {
    next(err);
  }
};

// GET /my-trips
export const getMyTrips = async (req, res, next) => {
  try {
    const studentId = req.user.studentId || req.user.student_id;
    const schoolId = req.user.school_id || req.user.schoolId;
    if (!studentId || !schoolId) {
      return successResponse(res, 200, 'OK', { trips: [], total: 0, page: 1, total_pages: 0 });
    }

    const { page = 1, limit = 10 } = req.query;
    const result = await transportVehiclesRepository.findStudentTrips(studentId, schoolId, {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });

    return successResponse(res, 200, 'OK', {
      trips: result.data,
      total: result.pagination.total,
      page: result.pagination.page,
      total_pages: result.pagination.total_pages,
    });
  } catch (err) {
    next(err);
  }
};

// ── Parent Portal: Child Vehicle ──────────────────────────────────────────────

// GET /child/:studentId/vehicle
export const getChildVehicle = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id || req.user.schoolId;
    const parentId = req.user.parent_id || req.user.parentId;
    const { studentId } = req.params;

    if (!schoolId) return next(new AppError('School context required', 403));

    // Verify parent has access to this student
    const link = await prisma.parentStudentLink.findFirst({
      where: { parentId, studentId, schoolId },
    });
    if (!link) throw new AppError('Access denied: student not linked to your account', 403);

    const assignmentRecord = await transportVehiclesRepository.findStudentVehicle(studentId, schoolId);
    if (!assignmentRecord) {
      return successResponse(res, 200, 'OK', { assignment: null, currentLocation: null, tripActive: false });
    }

    const vehicle = assignmentRecord.vehicle;
    const driver = vehicle?.driver;

    const assignment = {
      vehicleNo: vehicle?.vehicleNo || null,
      driverName: driver ? `${driver.firstName} ${driver.lastName}` : null,
      driverPhone: driver?.phone || null,
      pickupStopName: assignmentRecord.pickupStopName || null,
      dropStopName: assignmentRecord.dropStopName || null,
    };

    const currentLocation = vehicle?.locationCurrent
      ? {
          lat: Number(vehicle.locationCurrent.lat),
          lng: Number(vehicle.locationCurrent.lng),
          updatedAt: vehicle.locationCurrent.updatedAt?.toISOString() || null,
          speed: vehicle.locationCurrent.speed ?? null,
        }
      : null;

    let tripActive = false;
    if (vehicle?.id) {
      const activeTrip = await prisma.driverTrip.findFirst({
        where: { vehicleId: vehicle.id, status: 'IN_PROGRESS', deletedAt: null },
      });
      tripActive = !!activeTrip;
    }

    return successResponse(res, 200, 'OK', { assignment, currentLocation, tripActive });
  } catch (err) {
    next(err);
  }
};

// GET /child/:studentId/trips
export const getChildTrips = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id || req.user.schoolId;
    const parentId = req.user.parent_id || req.user.parentId;
    const { studentId } = req.params;

    if (!schoolId) return next(new AppError('School context required', 403));

    // Verify parent has access to this student
    const link = await prisma.parentStudentLink.findFirst({
      where: { parentId, studentId, schoolId },
    });
    if (!link) throw new AppError('Access denied: student not linked to your account', 403);

    const { page = 1, limit = 10 } = req.query;
    const result = await transportVehiclesRepository.findStudentTrips(studentId, schoolId, {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });

    return successResponse(res, 200, 'OK', {
      trips: result.data,
      total: result.pagination.total,
      page: result.pagination.page,
      total_pages: result.pagination.total_pages,
    });
  } catch (err) {
    next(err);
  }
};
