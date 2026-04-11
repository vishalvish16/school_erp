/**
 * School Admin Controller — HTTP handlers for /api/school/*
 * req.user is populated by verifyAccessToken middleware.
 * req.user.school_id is normalised by requireSchoolAdmin middleware.
 */
import { successResponse, AppError } from '../../utils/response.js';
import { logger } from '../../config/logger.js';
import * as service from './school-admin.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── Dashboard ─────────────────────────────────────────────────────────────────

export const getDashboardStats = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getDashboardStats({ schoolId });
    return successResponse(res, 200, 'OK', data);
});

// ── Academic Years ───────────────────────────────────────────────────────────

export const getAcademicYears = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getAcademicYears({ schoolId });
    return successResponse(res, 200, 'OK', data);
});

// ── Students ──────────────────────────────────────────────────────────────────

export const getStudents = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    if (!schoolId) {
        logger.warn('[getStudents] Missing school_id in req.user');
        throw new AppError('School context missing. Please log in again.', 403);
    }
    const { page = 1, limit = 20, search, classId, sectionId, status } = req.query;
    const result = await service.getStudents({
        schoolId,
        page:    parseInt(page, 10),
        limit:   parseInt(limit, 10),
        search,
        classId,
        sectionId,
        status,
    });
    logger.debug(`[getStudents] schoolId=${schoolId} returned ${result?.data?.length ?? 0} students (total=${result?.pagination?.total ?? 0})`);
    return successResponse(res, 200, 'OK', result);
});

export const getStudentById = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const student = await service.getStudentById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', student);
});

export const createStudent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const student = await service.createStudent({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Student created', student);
});

export const updateStudent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const student = await service.updateStudent({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Student updated', student);
});

export const deleteStudent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteStudent({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Student deleted');
});

export const createStudentLogin = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createStudentLogin({
        studentId: req.params.id,
        schoolId,
        userId,
        password: req.body.password,
    });
    return successResponse(res, 201, data.message, data);
});

export const resetStudentPassword = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.resetStudentPassword({
        studentId: req.params.id,
        schoolId,
        userId,
        newPassword: req.body.newPassword,
    });
    return successResponse(res, 200, data.message, data);
});

// ── Staff ─────────────────────────────────────────────────────────────────────

export const getStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, search, designation, isActive } = req.query;
    const result = await service.getStaff({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        search,
        designation,
        isActive,
    });
    logger.debug(`[getStaff] schoolId=${schoolId} returned ${result?.data?.length ?? 0} staff`);
    return successResponse(res, 200, 'OK', result);
});

export const getStaffById = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const staff = await service.getStaffById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', staff);
});

export const getSuggestedEmployeeNo = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { firstName, lastName } = req.query;
    const suggested = await service.getSuggestedEmployeeNo({
        schoolId,
        firstName: firstName || '',
        lastName: lastName || '',
    });
    return successResponse(res, 200, 'OK', { employeeNo: suggested });
});

export const checkEmployeeNoAvailability = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { employeeNo, excludeStaffId } = req.query;
    const result = await service.checkEmployeeNoAvailability({
        schoolId,
        employeeNo: employeeNo || '',
        excludeStaffId: excludeStaffId || null,
    });
    return successResponse(res, 200, 'OK', result);
});

export const createStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const staff = await service.createStaff({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Staff member created', staff);
});

export const updateStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const staff = await service.updateStaff({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Staff member updated', staff);
});

export const deleteStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteStaff({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Staff member deleted');
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
        newPassword: req.body.newPassword,
    });
    return successResponse(res, 200, data.message, data);
});

export const updateStaffStatus = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateStaffStatus({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Staff status updated', data);
});

export const exportStaff = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { search, designation, department, isActive, employeeType } = req.query;
    const csv = await service.exportStaff({ schoolId, search, designation, department, isActive, employeeType });
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="staff-export.csv"');
    return res.send(csv);
});

// ── Staff Qualifications ───────────────────────────────────────────────────────

export const getStaffQualifications = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStaffQualifications({ staffId: req.params.id, schoolId });
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

// ── Staff Documents ───────────────────────────────────────────────────────────

export const getStaffDocuments = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStaffDocuments({ staffId: req.params.id, schoolId });
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

// ── Subject Assignments ───────────────────────────────────────────────────────

export const getSubjectAssignments = handle(async (req, res) => {
    const schoolId    = req.user.school_id;
    const { academicYear } = req.query;
    const data = await service.getSubjectAssignments({ staffId: req.params.id, schoolId, academicYear });
    return successResponse(res, 200, 'OK', data);
});

export const addSubjectAssignment = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.addSubjectAssignment({ staffId: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Subject assignment added', data);
});

export const removeSubjectAssignment = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.removeSubjectAssignment({
        staffId:  req.params.id,
        assignId: req.params.assignId,
        schoolId,
        userId,
    });
    return successResponse(res, 200, 'Subject assignment removed');
});

// ── Staff Timetable ───────────────────────────────────────────────────────────

export const getStaffTimetable = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStaffTimetable({ staffId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

// ── Leave Management ──────────────────────────────────────────────────────────

export const getLeaves = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, status, staffId, leaveType, fromDate, toDate, academicYear } = req.query;
    const result = await service.getLeaves({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        status,
        staffId,
        leaveType,
        fromDate,
        toDate,
        academicYear,
    });
    return successResponse(res, 200, 'OK', result);
});

export const getLeaveSummary = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { academicYear, staffId } = req.query;
    const data = await service.getLeaveSummary({ schoolId, academicYear, staffId });
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
    const { page = 1, limit = 20, status, academicYear } = req.query;
    const result = await service.getStaffLeaves({
        staffId: req.params.id,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        status,
        academicYear,
    });
    return successResponse(res, 200, 'OK', result);
});

export const applyLeave = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.applyLeave({ staffId: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Leave applied', data);
});

// ── Classes ───────────────────────────────────────────────────────────────────

export const getClasses = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getClasses({ schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const createClass = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createClass({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Class created', data);
});

export const updateClass = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateClass({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Class updated', data);
});

export const deleteClass = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteClass({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Class deleted');
});

// ── Sections ──────────────────────────────────────────────────────────────────

export const getSections = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getSections({ classId: req.params.classId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const createSection = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createSection({
        classId: req.params.classId,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 201, 'Section created', data);
});

export const updateSection = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateSection({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Section updated', data);
});

export const deleteSection = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteSection({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Section deleted');
});

// ── Attendance ────────────────────────────────────────────────────────────────

export const getAttendance = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { classId, sectionId, date } = req.query;
    if (!date) throw new AppError('date query parameter is required', 400);
    const data = await service.getAttendance({ schoolId, classId, sectionId, date });
    return successResponse(res, 200, 'OK', data);
});

export const bulkMarkAttendance = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const { sectionId, date, records } = req.body;
    const result = await service.bulkMarkAttendance({ schoolId, userId, sectionId, date, records });
    return successResponse(res, 200, 'Attendance saved', result);
});

export const getAttendanceReport = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { classId, sectionId, month } = req.query;
    const data = await service.getAttendanceReport({ schoolId, classId, sectionId, month });
    return successResponse(res, 200, 'OK', data);
});

// ── Fee Structures ────────────────────────────────────────────────────────────

export const getFeeStructures = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { academicYear, classId } = req.query;
    const data = await service.getFeeStructures({ schoolId, academicYear, classId });
    return successResponse(res, 200, 'OK', data);
});

export const createFeeStructure = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createFeeStructure({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Fee structure created', data);
});

export const updateFeeStructure = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateFeeStructure({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Fee structure updated', data);
});

export const deleteFeeStructure = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteFeeStructure({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Fee structure deleted');
});

// ── Fee Payments ──────────────────────────────────────────────────────────────

export const getFeePayments = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, studentId, month, academicYear } = req.query;
    const result = await service.getFeePayments({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        studentId,
        month,
        academicYear,
    });
    return successResponse(res, 200, 'OK', result);
});

export const createFeePayment = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createFeePayment({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Payment recorded', data);
});

export const getFeePaymentById = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getFeePaymentById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getFeeSummary = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { month } = req.query;
    const data = await service.getFeeSummary({ schoolId, month });
    return successResponse(res, 200, 'OK', data);
});

// ── Timetable ─────────────────────────────────────────────────────────────────

export const getTimetable = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { classId, sectionId } = req.query;
    const data = await service.getTimetable({ schoolId, classId, sectionId });
    return successResponse(res, 200, 'OK', data);
});

export const bulkUpdateTimetable = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const { classId, sectionId, entries } = req.body;
    const data = await service.bulkUpdateTimetable({ schoolId, userId, classId, sectionId, entries });
    return successResponse(res, 200, 'Timetable updated', data);
});

// ── Notices ───────────────────────────────────────────────────────────────────

export const getNotices = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, search } = req.query;
    const result = await service.getNotices({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        search,
    });
    return successResponse(res, 200, 'OK', result);
});

export const createNotice = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.createNotice({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Notice created', data);
});

export const updateNotice = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateNotice({ id: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Notice updated', data);
});

export const deleteNotice = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.deleteNotice({ id: req.params.id, schoolId, userId });
    return successResponse(res, 200, 'Notice deleted');
});

// ── Notifications ─────────────────────────────────────────────────────────────

export const getNotifications = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20 } = req.query;
    const result = await service.getNotifications({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', result);
});

export const getUnreadNotificationCount = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getUnreadNotificationCount({ schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const markNotificationRead = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.markNotificationRead({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'Notification marked as read', data);
});

// ── Parents ──────────────────────────────────────────────────────────────────

export const searchParents = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, search } = req.query;
    const result = await service.searchParents({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        search,
    });
    return successResponse(res, 200, 'OK', result);
});

export const createParent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const parent = await service.createParent({ schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Parent created', parent);
});

export const getParentById = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const parent = await service.getParentById({ id: req.params.parentId, schoolId });
    return successResponse(res, 200, 'OK', parent);
});

export const updateParent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const parent = await service.updateParent({ id: req.params.parentId, schoolId, userId, data: req.body });
    return successResponse(res, 200, 'Parent updated', parent);
});

export const getStudentParents = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getStudentParents({ studentId: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const linkParentToStudent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.linkParentToStudent({ studentId: req.params.id, schoolId, userId, data: req.body });
    return successResponse(res, 201, 'Parent linked to student', data);
});

export const updateParentLink = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateParentLink({
        studentId: req.params.id,
        parentId:  req.params.parentId,
        schoolId,
        userId,
        data: req.body,
    });
    return successResponse(res, 200, 'Parent link updated', data);
});

export const unlinkParentFromStudent = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    await service.unlinkParentFromStudent({
        studentId: req.params.id,
        parentId:  req.params.parentId,
        schoolId,
        userId,
    });
    return successResponse(res, 200, 'Parent unlinked successfully');
});

// ── Profile ───────────────────────────────────────────────────────────────────

export const getProfile = handle(async (req, res) => {
    const userId   = req.user.userId || req.user.id;
    const schoolId = req.user.school_id;
    const data = await service.getProfile({ userId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const updateUserProfile = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    const data = await service.updateUserProfile({ userId, data: req.body });
    return successResponse(res, 200, 'Profile updated', data);
});

export const updateSchoolProfile = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId   = req.user.userId || req.user.id;
    const data = await service.updateSchoolProfile({ schoolId, userId, data: req.body });
    return successResponse(res, 200, 'School profile updated', data);
});

export const changePassword = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    if (!userId) throw new AppError('Not authenticated', 401);
    const { currentPassword, newPassword } = req.body;
    await service.changePassword({ userId, currentPassword, newPassword });
    return successResponse(res, 200, 'Password changed successfully');
});
