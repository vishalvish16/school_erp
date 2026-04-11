/**
 * Transport Drivers Controller — HTTP handlers for /api/school/transport/drivers/*
 * School admin manages drivers (CRUD).
 */
import { transportDriversRepository } from './transport-drivers.repository.js';
import { successResponse, AppError } from '../../utils/response.js';
import { logger } from '../../config/logger.js';

function generateTempPassword() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let pwd = '';
  for (let i = 0; i < 8; i++) pwd += chars[Math.floor(Math.random() * chars.length)];
  return pwd;
}

// GET /drivers
export const listDrivers = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const { page = 1, limit = 20, search } = req.query;
    const result = await transportDriversRepository.findAll({
      schoolId,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      search,
    });

    const drivers = result.data.map((d) => ({
      id: d.id,
      firstName: d.firstName,
      lastName: d.lastName,
      phone: d.phone,
      email: d.email,
      licenseNumber: d.licenseNumber,
      licenseExpiry: d.licenseExpiry,
      isActive: d.isActive,
      vehicles: (d.vehicles || []).map((v) => ({ id: v.id, vehicleNo: v.vehicleNo })),
    }));

    return successResponse(res, 200, 'OK', {
      drivers,
      total: result.pagination.total,
      page: result.pagination.page,
      total_pages: result.pagination.total_pages,
    });
  } catch (err) {
    next(err);
  }
};

// POST /drivers
export const createDriver = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const tempPassword = generateTempPassword();

    const { driver } = await transportDriversRepository.create({
      schoolId,
      driverData: req.body,
      password: tempPassword,
    });

    logger.info(`[Transport] Driver created: ${driver.firstName} ${driver.lastName} (school=${schoolId})`);

    return successResponse(res, 201, 'Driver created', {
      driver: {
        id: driver.id,
        firstName: driver.firstName,
        lastName: driver.lastName,
        phone: driver.phone,
        email: driver.email,
        employeeNo: driver.employeeNo,
        licenseNumber: driver.licenseNumber,
        licenseExpiry: driver.licenseExpiry,
        isActive: driver.isActive,
      },
      tempPassword,
    });
  } catch (err) {
    next(err);
  }
};

// GET /drivers/:id
export const getDriver = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const driver = await transportDriversRepository.findById(req.params.id, schoolId);
    if (!driver) throw new AppError('Driver not found', 404);

    return successResponse(res, 200, 'OK', { driver });
  } catch (err) {
    next(err);
  }
};

// PUT /drivers/:id
export const updateDriver = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const driver = await transportDriversRepository.update(req.params.id, schoolId, req.body);
    if (!driver) throw new AppError('Driver not found', 404);

    logger.info(`[Transport] Driver updated: ${driver.firstName} ${driver.lastName} (school=${schoolId})`);
    return successResponse(res, 200, 'Driver updated', { driver });
  } catch (err) {
    next(err);
  }
};

// DELETE /drivers/:id
export const deleteDriver = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));

    const driver = await transportDriversRepository.softDelete(req.params.id, schoolId);
    if (!driver) throw new AppError('Driver not found', 404);

    logger.info(`[Transport] Driver deleted: ${driver.firstName} ${driver.lastName} (school=${schoolId})`);
    return successResponse(res, 200, 'Driver deleted');
  } catch (err) {
    next(err);
  }
};
