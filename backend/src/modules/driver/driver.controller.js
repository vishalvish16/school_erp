import { driverService } from './driver.service.js';
import { successResponse } from '../../utils/response.js';

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
