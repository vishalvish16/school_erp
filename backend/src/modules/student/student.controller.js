/**
 * Student Portal Controller — HTTP handlers for /api/student/*
 * req.user is populated by verifyAccessToken middleware.
 * req.student is populated by requireStudent middleware — ALWAYS use req.student.schoolId
 * for tenant isolation.
 */
import { successResponse } from '../../utils/response.js';
import * as service from './student.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

export const getProfile = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const data = await service.getProfile({ studentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getDashboard = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const data = await service.getDashboard({ studentId, schoolId, student: req.student });
    return successResponse(res, 200, 'OK', data);
});

export const getAttendance = handle(async (req, res) => {
    const studentId = req.student.id;
    const { month } = req.query;
    const data = await service.getAttendance({ studentId, month });
    return successResponse(res, 200, 'OK', data);
});

export const getAttendanceSummary = handle(async (req, res) => {
    const studentId = req.student.id;
    const { month } = req.query;
    const data = await service.getAttendanceSummary({ studentId, month });
    return successResponse(res, 200, 'OK', data);
});

export const getFeeDues = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const data = await service.getFeeDues({ studentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getFeePayments = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const { page = 1, limit = 20 } = req.query;
    const result = await service.getFeePayments({
        studentId,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', result);
});

export const getReceiptByReceiptNo = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const { receiptNo } = req.params;
    const data = await service.getReceiptByReceiptNo({ studentId, schoolId, receiptNo });
    return successResponse(res, 200, 'OK', data);
});

export const getTimetable = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const data = await service.getTimetable({ studentId, schoolId, student: req.student });
    return successResponse(res, 200, 'OK', data);
});

export const getNotices = handle(async (req, res) => {
    const schoolId = req.student.schoolId;
    const { page = 1, limit = 20 } = req.query;
    const result = await service.getNotices({
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', result);
});

export const getNoticeById = handle(async (req, res) => {
    const schoolId = req.student.schoolId;
    const data = await service.getNoticeById({ id: req.params.id, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getDocuments = handle(async (req, res) => {
    const studentId = req.student.id;
    const data = await service.getDocuments({ studentId });
    return successResponse(res, 200, 'OK', data);
});

export const changePassword = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    const { currentPassword, newPassword } = req.body;
    await service.changePassword({ userId, currentPassword, newPassword });
    return successResponse(res, 200, 'Password changed successfully', null);
});
