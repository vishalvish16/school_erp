import { driverService } from './driver.service.js';
import { successResponse } from '../../utils/response.js';
import { getIO } from '../../socket.js';

export const getDashboardStats = async (req, res, next) => {
  try {
    const data = await driverService.getDashboardStats(req.driver);
    return successResponse(res, 200, 'OK', data);
  } catch (err) {
    next(err);
  }
};

export const getProfile = async (req, res, next) => {
  try {
    const data = await driverService.getProfile(req.driverId, req.user.school_id);
    return successResponse(res, 200, 'OK', data);
  } catch (err) {
    next(err);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const data = await driverService.updateProfile(req.driverId, req.user.school_id, req.body);
    return successResponse(res, 200, 'Profile updated', data);
  } catch (err) {
    next(err);
  }
};

export const startTrip = async (req, res, next) => {
  try {
    const vehicle = req.driver.vehicle;
    const route = vehicle?.route;
    const data = await driverService.startTrip({
      driverId: req.driverId,
      schoolId: req.driver.schoolId,
      vehicleId: vehicle?.id || null,
      routeId: route?.id || null,
    });
    return successResponse(res, 200, 'Trip started', data);
  } catch (err) {
    next(err);
  }
};

export const endTrip = async (req, res, next) => {
  try {
    const data = await driverService.endTrip({
      driverId: req.driverId,
      notes: req.body.notes,
    });
    return successResponse(res, 200, 'Trip ended', data);
  } catch (err) {
    next(err);
  }
};

export const updateLocation = async (req, res, next) => {
  try {
    const { lat, lng, speed, heading, accuracy, recordedAt } = req.body;
    const data = await driverService.recordLocation({
      driverId: req.driverId,
      schoolId: req.driver.schoolId,
      vehicleId: req.driver.vehicle?.id || null,
      lat, lng, speed, heading, accuracy, recordedAt,
    });

    // Emit via Socket.IO (graceful — don't crash if socket not ready)
    try {
      const io = getIO();
      io.to(`school:${req.driver.schoolId}`).emit('driver:location', {
        driverId: req.driverId,
        vehicleId: req.driver.vehicle?.id || null,
        vehicleNo: req.driver.vehicle?.vehicleNo || null,
        lat: Number(lat),
        lng: Number(lng),
        speed: speed ?? null,
        heading: heading ?? null,
        updatedAt: new Date().toISOString(),
      });
    } catch (_) { /* Socket not ready — ignore */ }

    return successResponse(res, 200, 'OK', data);
  } catch (err) {
    next(err);
  }
};

export const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    await driverService.changePassword(
      req.driverId,
      req.user.school_id,
      req.user.userId || req.user.id,
      currentPassword,
      newPassword
    );
    return successResponse(res, 200, 'Password changed successfully');
  } catch (err) {
    next(err);
  }
};
