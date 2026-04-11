/**
 * Transport Controller — HTTP handlers for /api/school/transport/*
 */
import { findLiveVehicles } from './transport.repository.js';
import { successResponse, AppError } from '../../utils/response.js';

export const getLiveVehicles = async (req, res, next) => {
  try {
    const schoolId = req.user.school_id;
    if (!schoolId) return next(new AppError('School context required', 403));
    const vehicles = await findLiveVehicles(schoolId);
    return successResponse(res, 200, 'OK', { vehicles });
  } catch (err) {
    next(err);
  }
};
