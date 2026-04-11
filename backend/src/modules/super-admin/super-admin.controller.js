/**
 * Super Admin Controller — HTTP handlers for /super-admin/*
 */
import { successResponse, AppError } from '../../utils/response.js';
import * as service from './super-admin.service.js';
import * as twoFaService from '../auth/two-fa.service.js';
import * as auditService from '../audit/audit.service.js';

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
    const { page, limit, search, status, plan_id, country, state, city, group_id } = req.query;
    const parsedLimit = Math.min(parseInt(limit, 10) || 20, 100);
    const result = await service.getSchools({
        page: page ? parseInt(page, 10) : 1,
        limit: parsedLimit,
        search,
        status,
        plan_id,
        country,
        state,
        city,
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

export const checkSubdomainAvailability = handle(async (req, res) => {
    const { value } = req.query;
    const available = await service.checkSubdomainAvailable(value);
    return successResponse(res, 200, 'OK', { available });
});

export const getSchoolById = handle(async (req, res) => {
    const school = await service.getSchoolById(req.params.id);
    if (!school) throw new AppError('School not found', 404);
    return successResponse(res, 200, 'OK', school);
});

export const createSchool = handle(async (req, res) => {
    const school = await service.createSchool(req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'CREATE_SCHOOL',
        entityType: 'schools',
        entityId: school?.id,
        entityName: school?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 201, 'School created', school);
});

export const updateSchool = handle(async (req, res) => {
    const school = await service.updateSchool(req.params.id, req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_SCHOOL',
        entityType: 'schools',
        entityId: req.params.id,
        entityName: school?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'School updated', school);
});

export const updateSchoolStatus = handle(async (req, res) => {
    const { status } = req.body || {};
    if (!status) throw new AppError('status is required', 400);
    await service.updateSchoolStatus(req.params.id, status);
    const school = await service.getSchoolById(req.params.id);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_SCHOOL_STATUS',
        entityType: 'schools',
        entityId: req.params.id,
        entityName: school?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { status },
    }).catch(() => {});
    return successResponse(res, 200, 'Status updated', school);
});

export const updateSchoolSubdomain = handle(async (req, res) => {
    const { subdomain } = req.body || {};
    if (!subdomain) throw new AppError('subdomain is required', 400);
    await service.updateSchoolSubdomain(req.params.id, subdomain);
    const school = await service.getSchoolById(req.params.id);
    return successResponse(res, 200, 'Subdomain updated', school);
});

export const assignSchoolAdmin = handle(async (req, res) => {
    const school = await service.assignSchoolAdmin(req.params.id, req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'ASSIGN_SCHOOL_ADMIN',
        entityType: 'schools',
        entityId: req.params.id,
        entityName: school?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { admin_email: req.body?.admin_email },
    }).catch(() => {});
    return successResponse(res, 201, 'Admin assigned', school);
});

export const resetSchoolAdminPassword = handle(async (req, res) => {
    const { user_id, new_password } = req.body || {};
    const userId = user_id || req.params.user_id;
    if (!userId || !new_password || new_password.length < 8) {
        throw new AppError('user_id and new_password (min 8 chars) are required', 400);
    }
    await service.resetSchoolAdminPassword(req.params.id, userId, new_password);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'RESET_SCHOOL_ADMIN_PASSWORD',
        entityType: 'schools',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { target_user_id: userId },
    }).catch(() => {});
    return successResponse(res, 200, 'Password reset');
});

export const deactivateSchoolAdmin = handle(async (req, res) => {
    const userId = req.params.user_id;
    if (!userId) throw new AppError('user_id is required', 400);
    await service.deactivateSchoolAdmin(req.params.id, userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'DEACTIVATE_SCHOOL_ADMIN',
        entityType: 'schools',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { target_user_id: userId },
    }).catch(() => {});
    return successResponse(res, 200, 'Admin deactivated');
});

// ── Groups ─────────────────────────────────────────────────────────────────
export const getGroups = handle(async (req, res) => {
    const { page, limit, search, status, state } = req.query;
    const result = await service.getGroups({
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 20,
        search,
        status,
        state,
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

export const checkGroupSlugAvailability = handle(async (req, res) => {
    const { value, exclude_id } = req.query;
    const available = await service.checkGroupSlugAvailable(value, exclude_id);
    return successResponse(res, 200, 'OK', { available });
});

export const getGroupById = handle(async (req, res) => {
    const data = await service.getGroupById(req.params.id);
    return successResponse(res, 200, 'OK', data);
});

export const createGroup = handle(async (req, res) => {
    const data = await service.createGroup(req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'CREATE_GROUP',
        entityType: 'groups',
        entityId: data?.id,
        entityName: data?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 201, 'Group created', data);
});

export const updateGroup = handle(async (req, res) => {
    const data = await service.updateGroup(req.params.id, req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_GROUP',
        entityType: 'groups',
        entityId: req.params.id,
        entityName: data?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Group updated', data);
});

export const deleteGroupHandler = handle(async (req, res) => {
    await service.deleteGroup(req.params.id, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'DELETE_GROUP',
        entityType: 'groups',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Group deleted');
});

export const assignGroupAdminHandler = handle(async (req, res) => {
    const data = await service.assignGroupAdmin(req.params.id, req.body, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'ASSIGN_GROUP_ADMIN',
        entityType: 'groups',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { admin_email: req.body?.admin_email },
    }).catch(() => {});
    return successResponse(res, 201, 'Group admin assigned', data);
});

export const resetGroupAdminPasswordHandler = handle(async (req, res) => {
    const { new_password } = req.body || {};
    await service.resetGroupAdminPassword(req.params.id, new_password, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'RESET_GROUP_ADMIN_PASSWORD',
        entityType: 'groups',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Group admin password reset');
});

export const lockGroupAdminHandler = handle(async (req, res) => {
    await service.lockGroupAdmin(req.params.id, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'LOCK_GROUP_ADMIN',
        entityType: 'groups',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Group admin account locked');
});

export const unlockGroupAdminHandler = handle(async (req, res) => {
    await service.unlockGroupAdmin(req.params.id, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UNLOCK_GROUP_ADMIN',
        entityType: 'groups',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Group admin account unlocked');
});

export const deactivateGroupAdminHandler = handle(async (req, res) => {
    await service.deactivateGroupAdmin(req.params.id, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'DEACTIVATE_GROUP_ADMIN',
        entityType: 'groups',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Group admin deactivated');
});

export const addSchoolToGroup = handle(async (req, res) => {
    const { school_id } = req.body || {};
    if (!school_id) throw new AppError('school_id is required', 400);
    await service.addSchoolToGroup(req.params.id, school_id);
    return successResponse(res, 200, 'School added to group');
});

export const removeSchoolFromGroup = handle(async (req, res) => {
    await service.removeSchoolFromGroup(req.params.id, req.params.school_id);
    return successResponse(res, 200, 'School removed from group');
});

// ── Plans ──────────────────────────────────────────────────────────────────
export const getPlans = handle(async (req, res) => {
    const data = await service.getPlans();
    return successResponse(res, 200, 'OK', data.data);
});

export const createPlan = handle(async (req, res) => {
    const data = await service.createPlan(req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'CREATE_PLAN',
        entityType: 'plans',
        entityId: data?.id,
        entityName: data?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: {
            entity_id: data?.id,
            new_value: { name: data?.name, price_per_student: data?.price_per_student, description: data?.description, max_students: data?.max_students },
        },
    }).catch(() => {});
    return successResponse(res, 201, 'Plan created', data);
});

export const updatePlan = handle(async (req, res) => {
    const oldPlan = await service.getPlanById(req.params.id);
    const data = await service.updatePlan(req.params.id, req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_PLAN',
        entityType: 'plans',
        entityId: req.params.id,
        entityName: data?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: {
            entity_id: req.params.id,
            old_value: oldPlan ? { name: oldPlan.name, price_per_student: oldPlan.price_per_student, description: oldPlan.description, max_students: oldPlan.max_students } : null,
            new_value: { name: data?.name, price_per_student: data?.price_per_student, description: data?.description, max_students: data?.max_students },
        },
    }).catch(() => {});
    return successResponse(res, 200, 'Plan updated', data);
});

export const updatePlanStatus = handle(async (req, res) => {
    const { status } = req.body || {};
    if (!status) throw new AppError('status is required', 400);
    const oldPlan = await service.getPlanById(req.params.id);
    await service.updatePlanStatus(req.params.id, status);
    const plan = await service.getPlans().then((r) => r.data.find((p) => String(p.id) === String(req.params.id)));
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_PLAN_STATUS',
        entityType: 'plans',
        entityId: req.params.id,
        entityName: plan?.name || oldPlan?.name,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: {
            entity_id: req.params.id,
            plan_name: plan?.name || oldPlan?.name,
            old_status: oldPlan?.status,
            new_status: status,
        },
    }).catch(() => {});
    return successResponse(res, 200, 'Plan status updated', plan);
});

export const updatePlanFeatures = handle(async (req, res) => {
    const { features } = req.body || {};
    if (!features || typeof features !== 'object') throw new AppError('features object is required', 400);
    const data = await service.updatePlanFeatures(req.params.id, features);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_PLAN_FEATURES',
        entityType: 'plans',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { entity_id: req.params.id, features: data },
    }).catch(() => {});
    return successResponse(res, 200, 'Plan features updated', { features: data });
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
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'RENEW_SUBSCRIPTION',
        entityType: 'billing',
        entityId: req.params.school_id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { plan_id: req.body?.plan_id, duration_months: req.body?.duration_months, payment_ref: req.body?.payment_ref },
    }).catch(() => {});
    return successResponse(res, 200, 'Subscription renewed');
});

export const assignPlan = handle(async (req, res) => {
    await service.assignPlan(req.params.school_id, req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'ASSIGN_PLAN',
        entityType: 'billing',
        entityId: req.params.school_id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { plan_id: req.body?.plan_id },
    }).catch(() => {});
    return successResponse(res, 200, 'Plan assigned');
});

export const resolveOverdue = handle(async (req, res) => {
    await service.resolveOverdue(req.params.school_id, req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'RESOLVE_OVERDUE',
        entityType: 'billing',
        entityId: req.params.school_id,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { action: req.body?.action, payment_ref: req.body?.payment_ref },
    }).catch(() => {});
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

export const toggleSchoolFeature = handle(async (req, res) => {
    const { school_id, feature_key } = req.params;
    const { is_enabled } = req.body || {};
    await service.toggleSchoolFeature(school_id, feature_key, !!is_enabled);
    return successResponse(res, 200, 'Feature updated');
});

// ── Hardware ───────────────────────────────────────────────────────────────
export const getHardware = handle(async (req, res) => {
    const { page, limit, school_id, device_type, status, search } = req.query;
    const result = await service.getHardware({
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 50,
        school_id: school_id || undefined,
        device_type: device_type || undefined,
        status: status || undefined,
        search: search || undefined,
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

export const registerHardware = handle(async (req, res) => {
    const data = await service.registerHardware(req.body);
    return successResponse(res, 201, 'Device registered', data);
});

export const updateHardware = handle(async (req, res) => {
    const data = await service.updateHardware(req.params.id, req.body);
    if (!data) throw new AppError('Device not found', 404);
    return successResponse(res, 200, 'Device updated', data);
});

export const pingDevice = handle(async (req, res) => {
    const data = await service.pingDevice(req.params.id);
    if (!data) throw new AppError('Device not found', 404);
    return successResponse(res, 200, 'Ping successful', data);
});

export const deleteDevice = handle(async (req, res) => {
    await service.deleteDevice(req.params.id);
    return successResponse(res, 200, 'Device deleted');
});

// ── Admins ─────────────────────────────────────────────────────────────────
export const getSuperAdmins = handle(async (req, res) => {
    const data = await service.getSuperAdmins();
    return successResponse(res, 200, 'OK', data.data);
});

export const addSuperAdmin = handle(async (req, res) => {
    const data = await service.addSuperAdmin(req.body);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'CREATE_SUPER_ADMIN',
        entityType: 'super_admin',
        entityId: data?.id,
        entityName: data?.email,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 201, 'Admin added', data);
});

export const updateSuperAdmin = handle(async (req, res) => {
    const data = await service.updateSuperAdmin(req.params.id, req.body);
    if (!data) throw new AppError('Admin not found', 404);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'UPDATE_SUPER_ADMIN',
        entityType: 'super_admin',
        entityId: req.params.id,
        entityName: data?.email,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Admin updated', data);
});

export const removeSuperAdmin = handle(async (req, res) => {
    await service.removeSuperAdmin(req.params.id);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'REMOVE_SUPER_ADMIN',
        entityType: 'super_admin',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Admin removed');
});

export const changePassword = handle(async (req, res) => {
    const userId = req.user?.userId;
    if (!userId) throw new AppError('Not authenticated', 401);
    const { current_password, new_password } = req.body || {};
    await service.changePassword(userId, current_password, new_password);
    auditService.logAudit({
        actorId: userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'CHANGE_PASSWORD',
        entityType: 'super_admin',
        entityId: userId,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Password changed successfully');
});

export const resetSuperAdminPassword = handle(async (req, res) => {
    const { new_password } = req.body || {};
    await service.resetSuperAdminPassword(req.params.id, new_password);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'RESET_SUPER_ADMIN_PASSWORD',
        entityType: 'super_admin',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Password reset successfully');
});

// ── Audit ─────────────────────────────────────────────────────────────────
export const getAuditLogs = handle(async (req, res) => {
    const { type } = req.params;
    const { page, limit, search, date_from, date_to } = req.query;
    const result = await service.getAuditLogs(type, {
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 50,
        search: search || undefined,
        date_from: date_from || undefined,
        date_to: date_to || undefined,
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
    const { page, limit } = req.query;
    const data = await service.getSecurityEvents({
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 30,
    });
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

// ── Exports ────────────────────────────────────────────────────────────────
export const exportDashboard = handle(async (req, res) => {
    const csv = await service.exportDashboardReport();
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="dashboard-report.csv"');
    return res.send(csv);
});

export const exportSchoolsCsv = handle(async (req, res) => {
    const { search, status, plan_id, country, state, city } = req.query;
    const csv = await service.exportSchools({ search, status, plan_id, country, state, city });
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="schools.csv"');
    return res.send(csv);
});

export const exportBillingCsv = handle(async (req, res) => {
    const { status, search } = req.query;
    const csv = await service.exportBilling({ status, search });
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="billing.csv"');
    return res.send(csv);
});

// ── Hardware alert ─────────────────────────────────────────────────────────
export const alertSchool = handle(async (req, res) => {
    const { message } = req.body || {};
    const data = await service.alertSchool(req.params.id, message, req.user?.userId);
    return successResponse(res, 200, 'Alert sent', data);
});

// ── Security mutations ─────────────────────────────────────────────────────
export const revokeDevice = handle(async (req, res) => {
    await service.revokeDevice(req.params.id, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'REVOKE_DEVICE',
        entityType: 'security',
        entityId: req.params.id,
        ipAddress: req.ip || req.connection?.remoteAddress,
    }).catch(() => {});
    return successResponse(res, 200, 'Device revoked');
});

export const blockIpHandler = handle(async (req, res) => {
    const { ip_address, reason } = req.body || {};
    if (!ip_address) throw new AppError('ip_address is required', 400);
    await service.blockIp(ip_address, reason, req.user?.userId);
    auditService.logAudit({
        actorId: req.user?.userId,
        actorName: req.user?.first_name ? `${req.user.first_name} ${req.user.last_name || ''}`.trim() : req.user?.email,
        actorRole: req.user?.role || 'super_admin',
        action: 'BLOCK_IP',
        entityType: 'security',
        entityName: ip_address,
        ipAddress: req.ip || req.connection?.remoteAddress,
        extra: { blocked_ip: ip_address, reason },
    }).catch(() => {});
    return successResponse(res, 200, 'IP blocked');
});

// ── Infra ─────────────────────────────────────────────────────────────────
export const getInfraStatus = handle(async (req, res) => {
    const data = await service.getInfraStatus();
    return successResponse(res, 200, 'OK', data.data);
});

// ── Notifications ───────────────────────────────────────────────────────────
export const getUnreadNotificationCount = handle(async (req, res) => {
    const data = await service.getUnreadNotificationCount();
    return successResponse(res, 200, 'OK', data);
});

export const getNotifications = handle(async (req, res) => {
    const { page, limit } = req.query;
    const result = await service.getNotifications({
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 20,
    });
    return successResponse(res, 200, 'OK', result);
});

export const markNotificationRead = handle(async (req, res) => {
    await service.markNotificationRead(req.params.id);
    return successResponse(res, 200, 'Notification marked as read');
});

export const markAllNotificationsRead = handle(async (req, res) => {
    await service.markAllNotificationsRead();
    return successResponse(res, 200, 'All notifications marked as read');
});
