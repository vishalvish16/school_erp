import * as schoolRepo from './schools.repository.js';
import * as subRepo from './schools.subscription.repository.js';
import * as auditService from '../audit/audit.service.js';
import { AppError } from '../../utils/response.js';

const buildAuditCtx = (adminUser, opts = {}) => ({
    actorId: adminUser?.userId || adminUser?.id,
    actorName: adminUser?.first_name || adminUser?.email ? `${adminUser.first_name || ''} ${adminUser.last_name || ''}`.trim() || adminUser.email : null,
    actorRole: adminUser?.role || 'super_admin',
    ipAddress: opts.req?.ip || opts.req?.connection?.remoteAddress || null,
});

const logAudit = async (action, details, adminUser, opts = {}) => {
    await auditService.logAudit({
        ...buildAuditCtx(adminUser, opts),
        action,
        entityType: 'schools',
        entityId: details.schoolId,
        entityName: details.schoolName,
        extra: details,
    });
};

export const createSchool = async (data, adminUser, opts = {}) => {
    const existingCode = await schoolRepo.findByCode(data.schoolCode);
    if (existingCode) {
        throw new AppError('School code already exists', 400);
    }

    const school = await schoolRepo.createSchool(data);

    await logAudit('CREATE_SCHOOL', { schoolId: school.id, schoolName: school.name, triggeredBy: adminUser?.userId || adminUser?.id }, adminUser, opts);
    return school;
};

export const getSchools = async (query) => {
    // Scalable auto-suspend background sync 
    schoolRepo.suspendExpiredSubscriptions().catch(err => console.error('Auto suspend failed', err));

    const page = parseInt(query.page, 10) || 1;
    const limit = parseInt(query.limit, 10) || 10;
    const skip = (page - 1) * limit;

    const whereClauses = [];
    // Single search: matches name, schoolCode, or city (case insensitive)
    const searchTerm = (query.search || query.code || query.schoolCode || '').toString().trim();
    if (searchTerm) {
        whereClauses.push({
            OR: [
                { name: { contains: searchTerm, mode: 'insensitive' } },
                { code: { contains: searchTerm, mode: 'insensitive' } },
                { city: { contains: searchTerm, mode: 'insensitive' } }
            ]
        });
    }
    if (query.status) {
        whereClauses.push({ isActive: query.status === 'ACTIVE' });
    }
    if (query.planId) {
        whereClauses.push({ planId: BigInt(query.planId) });
    }
    const where = whereClauses.length > 0 ? { AND: whereClauses } : {};

    const sortBy = query.sortBy || 'createdAt';
    const sortOrder = query.sortOrder || 'desc';

    const { data: schools, total } = await schoolRepo.getSchools(where, skip, limit, sortBy, sortOrder);

    return {
        schools,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit)
        }
    };
};

/**
 * Public school search for mobile app — no auth required
 * Returns only safe public fields
 */
export const searchSchoolsPublic = async (q, limit = 10) => {
    return schoolRepo.searchSchoolsPublic(q, limit);
};

export const getSchoolById = async (id) => {
    const school = await schoolRepo.getSchoolById(id);
    if (!school) {
        throw new AppError('School not found', 404);
    }
    return school;
};

export const updateSchool = async (id, data, adminUser, opts = {}) => {
    const school = await schoolRepo.getSchoolById(id);
    if (!school) {
        throw new AppError('School not found', 404);
    }

    if (data.schoolCode) {
        const existingCode = await schoolRepo.findByCode(data.schoolCode, id);
        if (existingCode) {
            throw new AppError('School code already exists', 400);
        }
    }

    const updated = await schoolRepo.updateSchool(id, data);

    await logAudit('UPDATE_SCHOOL', { schoolId: id, schoolName: updated?.name, triggeredBy: adminUser?.userId || adminUser?.id, changes: data }, adminUser, opts);
    return updated;
};

export const deleteSchool = async (id, adminUser, opts = {}) => {
    const school = await schoolRepo.getSchoolById(id);
    if (!school) {
        throw new AppError('School not found', 404);
    }

    // Perform soft delete
    const deleted = await schoolRepo.deleteSchool(id);

    await logAudit('SUSPEND_SCHOOL', { schoolId: id, schoolName: school?.name, triggeredBy: adminUser?.userId || adminUser?.id }, adminUser, opts);
    return deleted;
};

export const assignPlan = async (schoolId, data, adminUser, opts = {}) => {
    const school = await subRepo.findSchoolById(schoolId);
    if (!school) {
        throw new AppError('School not found', 404);
    }

    const plan = await subRepo.findPlanById(data.plan_id);
    if (!plan) {
        throw new AppError('Plan not found', 404);
    }

    // 2. Deactivate current active subscription
    await subRepo.deactivateActiveSubscriptions(schoolId);

    // 3. Calculate Dates
    const start_date = new Date();
    let end_date = new Date();

    if (data.duration_months) {
        end_date.setMonth(end_date.getMonth() + data.duration_months);
    } else if (data.billing_cycle === 'YEARLY') {
        end_date.setFullYear(end_date.getFullYear() + 1);
    } else {
        end_date.setMonth(end_date.getMonth() + 1);
    }

    // 4. Create new subscription
    const priceAmount = data.billing_cycle === 'YEARLY' ? plan.priceYearly : plan.priceMonthly;

    const subscription = await subRepo.createSubscription({
        schoolId,
        planId: data.plan_id,
        startDate: start_date,
        endDate: end_date,
        billingCycle: data.billing_cycle,
        priceAmount: priceAmount || 0
    });

    await logAudit('ASSIGN_PLAN', {
        schoolId,
        planId: data.plan_id,
        schoolName: school?.name,
        triggeredBy: adminUser?.userId || adminUser?.id
    }, adminUser, opts);

    return subscription;
};
