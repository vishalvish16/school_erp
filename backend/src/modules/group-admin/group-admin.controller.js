import { groupAdminService } from './group-admin.service.js';
import { successResponse } from '../../utils/response.js';

export const getDashboardStats = async (req, res, next) => {
  try {
    const data = await groupAdminService.getDashboardStats(req.groupId);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const getSchools = async (req, res, next) => {
  try {
    const { search, sortBy, sortOrder } = req.query;
    const data = await groupAdminService.getSchools(req.groupId, { search, sortBy, sortOrder });
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const getSchoolDetail = async (req, res, next) => {
  try {
    const data = await groupAdminService.getSchoolDetail(req.groupId, req.params.id);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const getAttendanceReport = async (req, res, next) => {
  try {
    return successResponse(res, 200, 'OK', { message: 'Attendance module not yet activated', data: [] });
  } catch (err) { next(err); }
};

export const getFeesReport = async (req, res, next) => {
  try {
    return successResponse(res, 200, 'OK', { message: 'Fees module not yet activated', data: [] });
  } catch (err) { next(err); }
};

export const getPerformanceReport = async (req, res, next) => {
  try {
    return successResponse(res, 200, 'OK', { message: 'Performance module not yet activated', data: [] });
  } catch (err) { next(err); }
};

export const getSchoolComparison = async (req, res, next) => {
  try {
    const data = await groupAdminService.getSchoolComparison(req.groupId);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const getProfile = async (req, res, next) => {
  try {
    const data = await groupAdminService.getProfile(req.user.userId, req.groupId);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const sendProfileOtp = async (req, res, next) => {
  try {
    const { email, phone } = req.body;
    const data = await groupAdminService.sendProfileOtp(req.user.userId, { email, phone });
    return successResponse(res, 200, 'OTP sent', data);
  } catch (err) { next(err); }
};

export const updateProfile = async (req, res, next) => {
  try {
    const { otp_session_id, otp_code, ...body } = req.body;
    const data = await groupAdminService.updateProfile(req.user.userId, body, {
      otpSessionId: otp_session_id,
      otpCode: otp_code,
    });
    return successResponse(res, 200, 'Profile updated', data);
  } catch (err) { next(err); }
};

export const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;
    await groupAdminService.changePassword(req.user.userId, current_password, new_password);
    return successResponse(res, 200, 'Password changed successfully');
  } catch (err) { next(err); }
};

export const getUnreadNotificationCount = async (req, res, next) => {
  try {
    const data = await groupAdminService.getUnreadNotificationCount(req.groupId);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const getNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const data = await groupAdminService.getNotifications(req.groupId, { page: +page, limit: +limit });
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const markNotificationRead = async (req, res, next) => {
  try {
    await groupAdminService.markNotificationRead(req.params.id, req.groupId);
    return successResponse(res, 200, 'Notification marked as read');
  } catch (err) { next(err); }
};

// ── Student Stats ──────────────────────────────────────────────────────────

export const getStudentStats = async (req, res, next) => {
  try {
    const data = await groupAdminService.getStudentStats(req.groupId);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

// ── Notices ────────────────────────────────────────────────────────────────

export const getNotices = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const data = await groupAdminService.getNotices(req.groupId, { page: +page, limit: +limit, search });
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const createNotice = async (req, res, next) => {
  try {
    const data = await groupAdminService.createNotice(req.groupId, req.user.userId, req.body);
    return successResponse(res, 201, 'Notice created', data);
  } catch (err) { next(err); }
};

export const updateNotice = async (req, res, next) => {
  try {
    const data = await groupAdminService.updateNotice(req.groupId, req.params.id, req.body);
    return successResponse(res, 200, 'Notice updated', data);
  } catch (err) { next(err); }
};

export const deleteNotice = async (req, res, next) => {
  try {
    await groupAdminService.deleteNotice(req.groupId, req.params.id);
    return successResponse(res, 200, 'Notice deleted');
  } catch (err) { next(err); }
};

// ── Alert Rules ────────────────────────────────────────────────────────────

export const getAlertRules = async (req, res, next) => {
  try {
    const data = await groupAdminService.getAlertRules(req.groupId);
    return successResponse(res, 200, 'OK', data);
  } catch (err) { next(err); }
};

export const createAlertRule = async (req, res, next) => {
  try {
    const data = await groupAdminService.createAlertRule(req.groupId, req.user.userId, req.body);
    return successResponse(res, 201, 'Alert rule created', data);
  } catch (err) { next(err); }
};

export const updateAlertRule = async (req, res, next) => {
  try {
    const data = await groupAdminService.updateAlertRule(req.groupId, req.params.id, req.body);
    return successResponse(res, 200, 'Alert rule updated', data);
  } catch (err) { next(err); }
};

export const deleteAlertRule = async (req, res, next) => {
  try {
    await groupAdminService.deleteAlertRule(req.groupId, req.params.id);
    return successResponse(res, 200, 'Alert rule deleted');
  } catch (err) { next(err); }
};
