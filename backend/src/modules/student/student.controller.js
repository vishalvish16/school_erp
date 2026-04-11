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
    const studentId = req.student.id;
    const { page = 1, limit = 20 } = req.query;
    const result = await service.getNotices({
        studentId,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', result);
});

export const getNoticeById = handle(async (req, res) => {
    const schoolId = req.student.schoolId;
    const studentId = req.student.id;
    const data = await service.getNoticeById({ id: req.params.id, studentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const registerFcmToken = handle(async (req, res) => {
    const { id: studentId, schoolId } = req.student;
    const { fcm_token: fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
        return res.status(400).json({ success: false, message: 'fcm_token required' });
    }
    await service.registerFcmToken({
        fcmToken: fcmToken.trim(),
        portalType: 'student',
        studentId,
        schoolId,
    });
    return successResponse(res, 200, 'FCM token registered');
});

export const getDocuments = handle(async (req, res) => {
    const schoolId  = req.student.schoolId;
    const studentId = req.student.id;
    const data = await service.getDocuments({ studentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getLiveDrivers = handle(async (req, res) => {
    const schoolId = req.student.schoolId;
    const data = await service.getLiveDrivers({ schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const changePassword = handle(async (req, res) => {
    const userId = req.user.userId || req.user.id;
    const { currentPassword, newPassword } = req.body;
    await service.changePassword({ userId, currentPassword, newPassword });
    return successResponse(res, 200, 'Password changed successfully', null);
});
