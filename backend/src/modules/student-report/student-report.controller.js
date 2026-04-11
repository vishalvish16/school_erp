/**
 * Student Report Controller — HTTP handlers for student report sub-routes.
 * Provides separate exports for school-admin (req.user.school_id) and
 * staff (req.staff.schoolId) portals.
 */
import { successResponse } from '../../utils/response.js';
import * as service from './student-report.service.js';

// Wraps async handlers and passes errors to Express error handler
const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── School Admin Handlers ────────────────────────────────────────────────────

export const getStudentReportSchoolAdmin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStudentReport({ studentId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentAttendanceSchoolAdmin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { month } = req.query;
    const data = await service.getStudentAttendance({ studentId: req.params.id, schoolId, month });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentAttendanceAnnualSchoolAdmin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStudentAttendanceAnnual({ studentId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentFeesSchoolAdmin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getStudentFees({
        studentId: req.params.id,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentNoticesSchoolAdmin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getStudentNotices({
        studentId: req.params.id,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const sendStudentNoticeSchoolAdmin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.sendStudentNotice({
        studentId: req.params.id,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 201, 'Notice sent successfully', data);
});

// ── Staff Handlers ───────────────────────────────────────────────────────────

export const getStudentReportStaff = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const data = await service.getStudentReport({ studentId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentAttendanceStaff = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { month } = req.query;
    const data = await service.getStudentAttendance({ studentId: req.params.id, schoolId, month });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentAttendanceAnnualStaff = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const data = await service.getStudentAttendanceAnnual({ studentId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentFeesStaff = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getStudentFees({
        studentId: req.params.id,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const getStudentNoticesStaff = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getStudentNotices({
        studentId: req.params.id,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const sendStudentNoticeStaff = handle(async (req, res) => {
    const schoolId = req.staff.schoolId;
    const userId   = req.user.userId || req.user.id;
    const data = await service.sendStudentNotice({
        studentId: req.params.id,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 201, 'Notice sent successfully', data);
});
