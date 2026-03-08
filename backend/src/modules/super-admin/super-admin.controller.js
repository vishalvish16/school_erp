/**
 * Super Admin Controller — HTTP handlers for /super-admin/*
 */
import { successResponse, AppError } from '../../utils/response.js';
import * as service from './super-admin.service.js';
import * as twoFaService from '../auth/two-fa.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── Dashboard ─────────────────────────────────────────────────────────────
export const getDashboardStats = handle(async (req, res) => {
    const data = await service.getDashboardStats();
    return successResponse(res, 200, 'OK', data);
});

// ── Schools ───────────────────────────────────────────────────────────────
export const getSchools = handle(async (req, res) => {
    const { page, limit, search, status, plan_id, state, group_id } = req.query;
    const result = await service.getSchools({
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 20,
        search,
        status,
        plan_id,
        state,
        group_id,
    });
    const pagination = result.pagination || {};
    return successResponse(res, 200, 'OK', {
        data: result.data,
        pagination: {
            page: pagination.page,
            limit: pagination.limit,
            total: pagination.total,
            totalPages: pagination.total_pages ?? pagination.totalPages ?? 1,
        },
    });
});

export const getSchoolById = handle(async (req, res) => {
    const school = await service.getSchoolById(req.params.id);
    if (!school) throw new AppError('School not found', 404);
    return successResponse(res, 200, 'OK', school);
});

export const createSchool = handle(async (req, res) => {
    const school = await service.createSchool(req.body);
    return successResponse(res, 201, 'School created', school);
});

export const updateSchool = handle(async (req, res) => {
    const school = await service.updateSchool(req.params.id, req.body);
    return successResponse(res, 200, 'School updated', school);
});

export const updateSchoolStatus = handle(async (req, res) => {
    const { status } = req.body || {};
    if (!status) throw new AppError('status is required', 400);
    await service.updateSchoolStatus(req.params.id, status);
    const school = await service.getSchoolById(req.params.id);
    return successResponse(res, 200, 'Status updated', school);
});

export const updateSchoolSubdomain = handle(async (req, res) => {
    const { subdomain } = req.body || {};
    if (!subdomain) throw new AppError('subdomain is required', 400);
    await service.updateSchoolSubdomain(req.params.id, subdomain);
    const school = await service.getSchoolById(req.params.id);
    return successResponse(res, 200, 'Subdomain updated', school);
});

// ── Groups ─────────────────────────────────────────────────────────────────
export const getGroups = handle(async (req, res) => {
    const data = await service.getGroups();
    return successResponse(res, 200, 'OK', data.data);
});

export const createGroup = handle(async (req, res) => {
    try {
        const data = await service.createGroup(req.body);
        return successResponse(res, 201, 'Group created', data);
    } catch (err) {
        if (err.message?.includes('not yet implemented')) {
            throw new AppError('School groups not yet implemented', 501);
        }
        throw err;
    }
});

// ── Plans ──────────────────────────────────────────────────────────────────
export const getPlans = handle(async (req, res) => {
    const data = await service.getPlans();
    return successResponse(res, 200, 'OK', data.data);
});

export const createPlan = handle(async (req, res) => {
    const data = await service.createPlan(req.body);
    return successResponse(res, 201, 'Plan created', data);
});

export const updatePlan = handle(async (req, res) => {
    const data = await service.updatePlan(req.params.id, req.body);
    return successResponse(res, 200, 'Plan updated', data);
});

export const updatePlanStatus = handle(async (req, res) => {
    const { status } = req.body || {};
    if (!status) throw new AppError('status is required', 400);
    await service.updatePlanStatus(req.params.id, status);
    const plan = await service.getPlans().then((r) => r.data.find((p) => p.id === req.params.id));
    return successResponse(res, 200, 'Plan status updated', plan);
});

// ── Billing ────────────────────────────────────────────────────────────────
export const getSubscriptions = handle(async (req, res) => {
    const { status, expiring_days, search, page, limit } = req.query;
    const result = await service.getSubscriptions({
        status,
        expiring_days,
        search,
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 20,
    });
    const pagination = result.pagination || {};
    return successResponse(res, 200, 'OK', {
        data: result.data,
        pagination: {
            page: pagination.page,
            limit: pagination.limit,
            total: pagination.total,
            totalPages: pagination.total_pages ?? pagination.totalPages ?? 1,
        },
    });
});

export const renewSubscription = handle(async (req, res) => {
    await service.renewSubscription(req.params.school_id, req.body);
    return successResponse(res, 200, 'Subscription renewed');
});

export const assignPlan = handle(async (req, res) => {
    await service.assignPlan(req.params.school_id, req.body);
    return successResponse(res, 200, 'Plan assigned');
});

export const resolveOverdue = handle(async (req, res) => {
    await service.resolveOverdue(req.params.school_id, req.body);
    return successResponse(res, 200, 'Overdue resolved');
});

// ── Features ───────────────────────────────────────────────────────────────
export const getPlatformFeatures = handle(async (req, res) => {
    const data = await service.getPlatformFeatures();
    return successResponse(res, 200, 'OK', data.data);
});

export const togglePlatformFeature = handle(async (req, res) => {
    const { feature_key } = req.params;
    const { is_enabled } = req.body || {};
    await service.togglePlatformFeature(feature_key, !!is_enabled);
    return successResponse(res, 200, 'Feature updated');
});

export const getSchoolFeatures = handle(async (req, res) => {
    const data = await service.getSchoolFeatures(req.params.school_id);
    return successResponse(res, 200, 'OK', data);
});

// ── Hardware ───────────────────────────────────────────────────────────────
export const getHardware = handle(async (req, res) => {
    const { page, limit } = req.query;
    const result = await service.getHardware({
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 50,
    });
    const pagination = result.pagination || {};
    return successResponse(res, 200, 'OK', {
        data: result.data,
        pagination: {
            page: pagination.page ?? 1,
            limit: pagination.limit ?? 50,
            total: pagination.total ?? 0,
            totalPages: pagination.total_pages ?? pagination.totalPages ?? 1,
        },
    });
});

// ── Admins ─────────────────────────────────────────────────────────────────
export const getSuperAdmins = handle(async (req, res) => {
    const data = await service.getSuperAdmins();
    return successResponse(res, 200, 'OK', data.data);
});

// ── Audit ─────────────────────────────────────────────────────────────────
export const getAuditLogs = handle(async (req, res) => {
    const { type } = req.params;
    const { page, limit } = req.query;
    const result = await service.getAuditLogs(type, {
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 50,
    });
    const pagination = result.pagination || {};
    return successResponse(res, 200, 'OK', {
        data: result.data,
        pagination: {
            page: pagination.page ?? 1,
            limit: pagination.limit ?? 50,
            total: pagination.total ?? 0,
            totalPages: pagination.total_pages ?? pagination.totalPages ?? 1,
        },
    });
});

// ── Security ──────────────────────────────────────────────────────────────
export const getSecurityEvents = handle(async (req, res) => {
    const data = await service.getSecurityEvents();
    return successResponse(res, 200, 'OK', data.data);
});

export const getTrustedDevices = handle(async (req, res) => {
    const data = await service.getTrustedDevices();
    return successResponse(res, 200, 'OK', data.data);
});

export const get2faStatus = handle(async (req, res) => {
    const userId = req.user?.userId;
    if (!userId) throw new AppError('Unauthorized', 401);
    const data = await twoFaService.get2faStatus(userId);
    return successResponse(res, 200, 'OK', data);
});

export const setup2fa = handle(async (req, res) => {
    const userId = req.user?.userId;
    if (!userId) throw new AppError('Unauthorized', 401);
    const data = await twoFaService.setup2fa(userId);
    return successResponse(res, 200, '2FA setup initiated', data);
});

export const enable2fa = handle(async (req, res) => {
    const userId = req.user?.userId;
    const { totp_code } = req.body || {};
    if (!userId) throw new AppError('Unauthorized', 401);
    if (!totp_code) throw new AppError('totp_code is required', 400);
    await twoFaService.enable2fa(userId, totp_code);
    return successResponse(res, 200, '2FA enabled');
});

export const disable2fa = handle(async (req, res) => {
    const userId = req.user?.userId;
    const { password } = req.body || {};
    if (!userId) throw new AppError('Unauthorized', 401);
    if (!password) throw new AppError('password is required', 400);
    await twoFaService.disable2fa(userId, password);
    return successResponse(res, 200, '2FA disabled');
});

// ── Infra ─────────────────────────────────────────────────────────────────
export const getInfraStatus = handle(async (req, res) => {
    const data = await service.getInfraStatus();
    return successResponse(res, 200, 'OK', data.data);
});
