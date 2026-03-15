/**
 * Non-Teaching Staff Controller — HTTP handlers for /api/school/non-teaching/*
 * req.user is populated by verifyAccessToken middleware.
 * req.user.school_id is normalised by requireSchoolAdmin middleware.
 */
import { successResponse, AppError } from '../../utils/response.js';
import { logger } from '../../config/logger.js';
import * as service from './non-teaching-staff.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── Roles ──────────────────────────────────────────────────────────────────

export const getRoles = handle(async (req, res) => {
    const schoolId        = req.user.school_id;
    const { includeInactive } = req.query;
    const data = await service.getRoles({ schoolId, includeInactive });
    return successResponse(res, 200, 'OK', data);
});

export const createRole = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createRole({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Role created', data);
});

export const updateRole = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateRole({
        roleId: req.params.roleId,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 200, 'Role updated', data);
});

export const toggleRole = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.toggleRole({ roleId: req.params.roleId, schoolId, userId });
    return successResponse(res, 200, 'Role toggled', data);
});

export const deleteRole = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteRole({ roleId: req.params.roleId, schoolId, userId });
    return successResponse(res, 200, 'Role deleted');
});

// ── Staff ──────────────────────────────────────────────────────────────────

export const getStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const {
        page = 1, limit = 20,
        search, roleId, category, department,
        employeeType, isActive, sortBy, sortOrder,
    } = req.query;

    const parsedLimit = Math.min(parseInt(limit, 10) || 20, 100); // cap at 100 per page

    const result = await service.getStaff({
        schoolId,
        page:         parseInt(page, 10),
        limit:        parsedLimit,
        search,
        roleId,
        category,
        department,
        employeeType,
        isActive,
        sortBy,
        sortOrder,
    });

    logger.debug(`[NT getStaff] schoolId=${schoolId} total=${result?.pagination?.total ?? 0}`);
    return successResponse(res, 200, 'OK', result);
});

export const suggestEmployeeNo = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.generateEmployeeNo({ schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const exportStaff = handle(async (req, res) => {
    // CSV export is not yet implemented
    return successResponse(res, 501, 'Export coming soon', {});
});

export const createStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createStaff({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Staff member created', data);
});

export const getStaffById = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStaffById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const updateStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateStaff({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Staff member updated', data);
});

export const deleteStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteStaff({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Staff member deleted');
});

export const updateStaffStatus = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateStaffStatus({
        id: req.params.id,
        schoolId,
        userId,
        isActive: req.body.is_active,
    });
    return successResponse(res, 200, 'Staff status updated', data);
});

export const createStaffLogin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createStaffLogin({
        staffId:  req.params.id,
        schoolId,
        userId,
        password: req.body.password,
    });
    return successResponse(res, 201, data.message, data);
});

export const resetStaffPassword = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.resetStaffPassword({
        staffId:     req.params.id,
        schoolId,
        userId,
        newPassword: req.body.new_password,
    });
    return successResponse(res, 200, data.message, data);
});

// ── Qualifications ─────────────────────────────────────────────────────────

export const getQualifications = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getQualifications({ staffId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const addQualification = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.addQualification({ staffId: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Qualification added', data);
});

export const updateQualification = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateQualification({
        staffId: req.params.id,
        qualId:  req.params.qualId,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 200, 'Qualification updated', data);
});

export const deleteQualification = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteQualification({ staffId: req.params.id, qualId: req.params.qualId, schoolId, userId });
    return successResponse(res, 200, 'Qualification deleted');
});

// ── Documents ──────────────────────────────────────────────────────────────

export const getDocuments = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getDocuments({ staffId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const addDocument = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.addDocument({ staffId: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Document added', data);
});

export const verifyDocument = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.verifyDocument({
        staffId: req.params.id,
        docId:   req.params.docId,
        schoolId,
        userId,
    });
    return successResponse(res, 200, 'Document verified', data);
});

export const deleteDocument = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteDocument({ staffId: req.params.id, docId: req.params.docId, schoolId, userId });
    return successResponse(res, 200, 'Document deleted');
});

// ── Attendance ─────────────────────────────────────────────────────────────

export const getAttendanceForDate = handle(async (req, res) => {
    const schoolId              = req.user.school_id;
    const { date, department, category } = req.query;
    if (!date) throw new AppError('date query parameter is required', 400);
    const data = await service.getAttendanceForDate({ schoolId, date, department, category });
    return successResponse(res, 200, 'OK', data);
});

export const bulkMarkAttendance = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const { date, records } = req.body;
    const result = await service.bulkMarkAttendance({ schoolId, userId, date, records });
    return successResponse(res, 200, 'Attendance saved', result);
});

export const correctAttendance = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.correctAttendance({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Attendance corrected', data);
});

export const getAttendanceReport = handle(async (req, res) => {
    const schoolId              = req.user.school_id;
    const { month, staffId, department } = req.query;
    if (!month) throw new AppError('month query parameter is required (format: YYYY-MM)', 400);
    const data = await service.getAttendanceReport({ schoolId, month, staffId, department });
    return successResponse(res, 200, 'OK', data);
});

// ── Leaves ─────────────────────────────────────────────────────────────────

export const getLeaves = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, status, staffId, leaveType, fromDate, toDate } = req.query;
    const result = await service.getLeaves({
        schoolId,
        page:      parseInt(page, 10),
        limit:     Math.min(parseInt(limit, 10) || 20, 100),
        status,
        staffId,
        leaveType,
        fromDate,
        toDate,
    });
    return successResponse(res, 200, 'OK', result);
});

export const getLeaveSummary = handle(async (req, res) => {
    const schoolId              = req.user.school_id;
    const { staffId, academicYear } = req.query;
    const data = await service.getLeaveSummary({ schoolId, staffId, academicYear });
    return successResponse(res, 200, 'OK', data);
});

export const reviewLeave = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.reviewLeave({
        leaveId:  req.params.leaveId,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 200, 'Leave reviewed', data);
});

export const cancelLeave = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.cancelLeave({ leaveId: req.params.leaveId, schoolId, userId });
    return successResponse(res, 200, 'Leave cancelled', data);
});

export const getStaffLeaves = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    // Enforce limit cap in query to prevent large data pulls
    const safeQuery = {
        ...req.query,
        limit: req.query.limit ? Math.min(parseInt(req.query.limit, 10) || 20, 100) : 20,
    };
    const result = await service.getStaffLeaves({
        staffId: req.params.id,
        schoolId,
        query:   safeQuery,
    });
    return successResponse(res, 200, 'OK', result);
});

export const applyLeaveForStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.applyLeaveForStaff({
        staffId: req.params.id,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 201, 'Leave applied', data);
});
