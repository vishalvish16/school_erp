/**
 * Parent Portal Controller — HTTP handlers for /api/parent/*
 * req.user from verifyAccessToken, req.parent from requireParent.
 * Use req.parent.schoolId for tenant isolation.
 */
import { successResponse } from '../../utils/response.js';
import * as service from './parent.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

export const getDashboard = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getDashboard({ parentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getProfile = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getProfile({ parentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const updateProfile = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.updateProfile({ parentId, schoolId, data: req.body });
    return successResponse(res, 200, 'Profile updated', data);
});

export const getChildren = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getChildren({ parentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const getChildById = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getChildById({
        studentId: req.params.studentId,
        parentId,
        schoolId,
    });
    return successResponse(res, 200, 'OK', data);
});

export const getChildAttendance = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { month, limit = 31 } = req.query;
    const data = await service.getChildAttendance({
        studentId: req.params.studentId,
        parentId,
        schoolId,
        month,
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const getChildFees = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { academic_year } = req.query;
    const data = await service.getChildFees({
        studentId: req.params.studentId,
        parentId,
        schoolId,
        academicYear: academic_year,
    });
    return successResponse(res, 200, 'OK', data);
});

export const getNotices = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getNotices({
        parentId,
        schoolId,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const getNoticeById = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getNoticeById({
        id: req.params.id,
        parentId,
        schoolId,
    });
    return successResponse(res, 200, 'OK', data);
});

export const getChildAttendanceSummary = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { month } = req.query;
    const data = await service.getChildAttendanceSummary({
        studentId: req.params.studentId,
        parentId,
        schoolId,
        month,
    });
    return successResponse(res, 200, 'OK', data);
});

export const getChildTimetable = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getChildTimetable({
        studentId: req.params.studentId,
        parentId,
        schoolId,
    });
    return successResponse(res, 200, 'OK', data);
});

export const getChildDocuments = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getChildDocuments({
        studentId: req.params.studentId,
        parentId,
        schoolId,
    });
    return successResponse(res, 200, 'OK', data);
});

export const getBusLocation = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { studentId } = req.params;
    const data = await service.getBusForStudent({ parentId, studentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const registerFcmToken = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { fcm_token: fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
        return res.status(400).json({ success: false, message: 'fcm_token required' });
    }
    await service.registerFcmToken({
        fcmToken: fcmToken.trim(),
        portalType: 'parent',
        parentId,
        schoolId,
    });
    return successResponse(res, 200, 'FCM token registered');
});

export const changePassword = handle(async (req, res) => {
    const { id: parentId } = req.parent;
    const userId = req.user.userId || req.user.id;
    await service.changePassword({
        userId,
        parentId,
        currentPassword: req.body.current_password,
        newPassword: req.body.new_password,
    });
    return successResponse(res, 200, 'Password changed successfully');
});

export const getNotifications = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getNotifications({
        parentId,
        schoolId,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const getUnreadNotificationCount = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const data = await service.getUnreadNotificationCount({ parentId, schoolId });
    return successResponse(res, 200, 'OK', data);
});

export const markNotificationRead = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    await service.markNotificationRead({
        id: req.params.id,
        parentId,
        schoolId,
    });
    return successResponse(res, 200, 'Notification marked as read');
});
