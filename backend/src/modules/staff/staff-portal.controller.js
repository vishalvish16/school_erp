/**
 * Staff Portal Controller — HTTP handlers for /api/staff/*
 * req.user is populated by verifyAccessToken middleware.
 * req.staff is populated by requireStaff middleware — ALWAYS use req.staff.schoolId
 * for tenant isolation (not req.user.school_id).
 * req.isNonTeaching (boolean) is set when the logged-in user is a NonTeachingStaff.
 */
import { successResponse } from '../../utils/response.js';
import * as service from './staff-portal.service.js';

// Wraps async handlers and passes errors to Express error handler
const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── Dashboard ──────────────────────────────────────────────────────────────────

export const getDashboardStats = handle(async (req, res) => {
    const schoolId    = req.staff.schoolId;
    const staffRecord = req.staff;
    const data = await service.getDashboardStats({ schoolId, staffRecord });
    return successResponse(res, 200, 'OK', data);
});

// ── Fee Payments ───────────────────────────────────────────────────────────────

export const getFeePayments = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { page = 1, limit = 20, studentId, month, academicYear } = req.query;
    const result = await service.getFeePayments({
        schoolId,
        page:         parseInt(page, 10),
        limit:        parseInt(limit, 10),
        studentId,
        month,
        academicYear,
    });
    return successResponse(res, 200, 'OK', result);
});

export const createFeePayment = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const staffId  = req.staff.id;
    const userId   = req.user.userId || req.user.id;
    const payment  = await service.createFeePayment({ schoolId, staffId, userId, data: req.body });
    return successResponse(res, 201, 'Fee payment recorded', payment);
});

export const getFeePaymentById = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const payment  = await service.getFeePaymentById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', payment);
});

export const getFeeSummary = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { month } = req.query;
    const summary  = await service.getFeeSummary({ schoolId, month });
    return successResponse(res, 200, 'OK', summary);
});

export const getFeeStructures = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { academicYear, classId } = req.query;
    const structures = await service.getFeeStructures({ schoolId, academicYear, classId });
    return successResponse(res, 200, 'OK', structures);
});

// ── Students (read-only) ───────────────────────────────────────────────────────

export const getStudents = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { page = 1, limit = 20, search, classId, sectionId } = req.query;
    const result   = await service.getStudents({
        schoolId,
        page:      parseInt(page, 10),
        limit:     parseInt(limit, 10),
        search,
        classId,
        sectionId,
    });
    return successResponse(res, 200, 'OK', result);
});

export const getStudentById = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const student  = await service.getStudentById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', student);
});

export const getClasses = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const classes  = await service.getClasses({ schoolId });
    return successResponse(res, 200, 'OK', classes);
});

// ── Notices (read-only) ────────────────────────────────────────────────────────

export const getNotices = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { page = 1, limit = 20 } = req.query;
    const result   = await service.getNotices({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', result);
});

export const getNoticeById = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const notice   = await service.getNoticeById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', notice);
});

// ── Notifications ──────────────────────────────────────────────────────────────

export const getNotifications = handle(async (req, res) => {
    const userId   = req.user.userId || req.user.id;
    const schoolId = req.staff.schoolId;
    const { page = 1, limit = 20 } = req.query;
    const result = await service.getNotifications({
        userId,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', result);
});

export const getUnreadNotificationCount = handle(async (req, res) => {
    const userId   = req.user.userId || req.user.id;
    const schoolId = req.staff.schoolId;
    const data = await service.getUnreadNotificationCount({ userId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const markNotificationRead = handle(async (req, res) => {
    const userId   = req.user.userId || req.user.id;
    const schoolId = req.staff.schoolId;
    const data = await service.markNotificationRead({ id: req.params.id, userId, schoolId });
    return successResponse(res, 200, 'Notification marked as read', data);
});

export const markAllNotificationsRead = handle(async (req, res) => {
    const userId   = req.user.userId || req.user.id;
    const schoolId = req.staff.schoolId;
    const data = await service.markAllNotificationsRead({ userId, schoolId });
    return successResponse(res, 200, 'All notifications marked as read', data);
});

// ── Profile ────────────────────────────────────────────────────────────────────

export const getProfile = handle(async (req, res) => {
    const userId      = req.user.userId || req.user.id;
    const schoolId    = req.staff.schoolId;
    const staffRecord = req.staff;
    const data = await service.getProfile({ userId, schoolId, staffRecord });
    return successResponse(res, 200, 'OK', data);
});

export const updateUserProfile = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    const user   = await service.updateUserProfile({ userId, data: req.body });
    return successResponse(res, 200, 'Profile updated', user);
});

export const sendOtp = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    const data   = await service.sendOtp({ userId, data: req.body });
    return successResponse(res, 200, 'OTP sent', data);
});

// ── Change Password ────────────────────────────────────────────────────────────

export const changePassword = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    const { currentPassword, newPassword } = req.body;
    await service.changePassword({ userId, currentPassword, newPassword });
    return successResponse(res, 200, 'Password changed successfully', null);
});

// ── Non-Teaching Staff Self-Service (my/) ──────────────────────────────────

export const getMyProfile = handle(async (req, res) => {
    const userId      = req.user.userId || req.user.id;
    const schoolId    = req.staff.schoolId;
    const staffRecord = req.staff;
    const isNonTeaching = req.isNonTeaching || false;
    const data = await service.getMyProfile({ userId, schoolId, staffRecord, isNonTeaching });
    return successResponse(res, 200, 'OK', data);
});

export const getMyAttendance = handle(async (req, res) => {
    const schoolId    = req.staff.schoolId;
    const staffId     = req.staff.id;
    const isNonTeaching = req.isNonTeaching || false;
    const { month } = req.query;
    const data = await service.getMyAttendance({ staffId, schoolId, month, isNonTeaching });
    return successResponse(res, 200, 'OK', data);
});

export const getMyLeaves = handle(async (req, res) => {
    const schoolId    = req.staff.schoolId;
    const staffId     = req.staff.id;
    const isNonTeaching = req.isNonTeaching || false;
    const { page = 1, limit = 20, status } = req.query;
    const data = await service.getMyLeaves({
        staffId,
        schoolId,
        isNonTeaching,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        status,
    });
    return successResponse(res, 200, 'OK', data);
});

export const applyMyLeave = handle(async (req, res) => {
    const schoolId    = req.staff.schoolId;
    const staffId     = req.staff.id;
    const userId      = req.user.userId || req.user.id;
    const isNonTeaching = req.isNonTeaching || false;
    const data = await service.applyMyLeave({ staffId, schoolId, userId, isNonTeaching, data: req.body });
    return successResponse(res, 201, 'Leave applied', data);
});

export const cancelMyLeave = handle(async (req, res) => {
    const schoolId    = req.staff.schoolId;
    const staffId     = req.staff.id;
    const userId      = req.user.userId || req.user.id;
    const isNonTeaching = req.isNonTeaching || false;
    const data = await service.cancelMyLeave({
        leaveId: req.params.leaveId,
        staffId,
        schoolId,
        userId,
        isNonTeaching,
    });
    return successResponse(res, 200, 'Leave cancelled', data);
});

export const getMyLeaveSummary = handle(async (req, res) => {
    const schoolId    = req.staff.schoolId;
    const staffId     = req.staff.id;
    const isNonTeaching = req.isNonTeaching || false;
    const { academicYear } = req.query;
    const data = await service.getMyLeaveSummary({ staffId, schoolId, isNonTeaching, academicYear });
    return successResponse(res, 200, 'OK', data);
});

export const getPayslipPlaceholder = handle(async (req, res) => {
    return successResponse(res, 501, 'Payroll module coming soon', { placeholder: true });
});
