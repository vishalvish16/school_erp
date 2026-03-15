/**
 * Teacher Controller — HTTP handlers for /api/teacher/*
 * req.user is populated by verifyAccessToken middleware.
 * req.teacher is populated by requireTeacher middleware — ALWAYS use req.teacher.schoolId
 * for tenant isolation (not req.user.school_id).
 * req.teacherSections and req.classTeacherSection are also set by the middleware.
 */
import { successResponse } from '../../utils/response.js';
import * as service from './teacher.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── Dashboard ──────────────────────────────────────────────────────────────────

export const getDashboard = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const data = await service.getDashboard({
        schoolId,
        teacher: req.teacher,
        teacherSections: req.teacherSections,
        classTeacherSection: req.classTeacherSection,
    });
    return successResponse(res, 200, 'OK', data);
});

// ── Sections ───────────────────────────────────────────────────────────────────

export const getSections = handle(async (req, res) => {
    const data = await service.getSections({ staffId: req.teacher.id });
    return successResponse(res, 200, 'OK', data);
});

// ── Attendance ─────────────────────────────────────────────────────────────────

export const getAttendance = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const { sectionId, date } = req.query;
    const data = await service.getAttendance({ schoolId, req, sectionId, date });
    return successResponse(res, 200, 'OK', data);
});

export const markAttendance = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const userId = req.user.userId || req.user.id;
    const { section_id, date, records } = req.body;
    const data = await service.markAttendance({
        schoolId,
        req,
        userId,
        staffId: req.teacher.id,
        sectionId: section_id,
        date,
        records,
    });
    return successResponse(res, 200, 'Attendance marked successfully', data);
});

export const getAttendanceReport = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const { sectionId, fromDate, toDate } = req.query;
    const data = await service.getAttendanceReport({ schoolId, req, sectionId, fromDate, toDate });
    return successResponse(res, 200, 'OK', data);
});

// ── Homework ───────────────────────────────────────────────────────────────────

export const getHomework = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const { page = 1, limit = 20, classId, sectionId, subject, status, fromDate, toDate } = req.query;
    const data = await service.getHomework({
        schoolId,
        staffId,
        page: parseInt(page, 10),
        limit: Math.min(parseInt(limit, 10) || 20, 50),
        classId,
        sectionId,
        subject,
        status,
        fromDate,
        toDate,
    });
    return successResponse(res, 200, 'OK', data);
});

export const createHomework = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    const data = await service.createHomework({ schoolId, staffId, userId, req, data: req.body });
    return successResponse(res, 201, 'Homework created', data);
});

export const getHomeworkById = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const data = await service.getHomeworkById({ id: req.params.id, schoolId, staffId });
    return successResponse(res, 200, 'OK', data);
});

export const updateHomework = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    const data = await service.updateHomework({ id: req.params.id, schoolId, staffId, userId, data: req.body });
    return successResponse(res, 200, 'Homework updated', data);
});

export const updateHomeworkStatus = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    const data = await service.updateHomeworkStatus({
        id: req.params.id,
        schoolId,
        staffId,
        userId,
        status: req.body.status,
    });
    return successResponse(res, 200, 'Homework status updated', data);
});

export const deleteHomework = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    await service.deleteHomework({ id: req.params.id, schoolId, staffId, userId });
    return successResponse(res, 200, 'Homework deleted', null);
});

// ── Class Diary ────────────────────────────────────────────────────────────────

export const getDiaryEntries = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const { page = 1, limit = 20, classId, sectionId, subject, fromDate, toDate } = req.query;
    const data = await service.getDiaryEntries({
        schoolId,
        staffId,
        classTeacherSection: req.classTeacherSection,
        page: parseInt(page, 10),
        limit: Math.min(parseInt(limit, 10) || 20, 50),
        classId,
        sectionId,
        subject,
        fromDate,
        toDate,
    });
    return successResponse(res, 200, 'OK', data);
});

export const createDiaryEntry = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    const data = await service.createDiaryEntry({ schoolId, staffId, userId, req, data: req.body });
    return successResponse(res, 201, 'Diary entry created', data);
});

export const updateDiaryEntry = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    const data = await service.updateDiaryEntry({
        id: req.params.id,
        schoolId,
        staffId,
        userId,
        data: req.body,
    });
    return successResponse(res, 200, 'Diary entry updated', data);
});

export const deleteDiaryEntry = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const userId = req.user.userId || req.user.id;
    await service.deleteDiaryEntry({ id: req.params.id, schoolId, staffId, userId });
    return successResponse(res, 200, 'Diary entry deleted', null);
});

// ── Profile ────────────────────────────────────────────────────────────────────

export const getProfile = handle(async (req, res) => {
    const schoolId = req.teacher.schoolId;
    const staffId = req.teacher.id;
    const data = await service.getProfile({ staffId, schoolId });
    return successResponse(res, 200, 'OK', data);
});
