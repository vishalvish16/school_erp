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
    const { schoolId } = req.parent;
    const { page = 1, limit = 20 } = req.query;
    const data = await service.getNotices({
        schoolId,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
    });
    return successResponse(res, 200, 'OK', data);
});

export const getNoticeById = handle(async (req, res) => {
    const { schoolId } = req.parent;
    const data = await service.getNoticeById({
        id: req.params.id,
        schoolId,
    });
    return successResponse(res, 200, 'OK', data);
});
