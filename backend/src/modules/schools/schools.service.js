import * as schoolRepo from './schools.repository.js';
import * as subRepo from './schools.subscription.repository.js';
import { AppError } from '../../utils/response.js';

// Clean architecture audit mocker
const logAudit = async (action, details) => {
    // Audit implementation, e.g. inserting to AuditLog table or publishing to event bus
    console.log(`[AUDIT LOG] ${action}: `, JSON.stringify(details));
};

export const createSchool = async (data, adminUser) => {
    const existingCode = await schoolRepo.findByCode(data.schoolCode);
    if (existingCode) {
        throw new AppError('School code already exists', 400);
    }

    const school = await schoolRepo.createSchool(data);

    await logAudit('CREATE_SCHOOL', { schoolId: school.id, triggeredBy: adminUser.id });
    return school;
};

export const getSchools = async (query) => {
    // Scalable auto-suspend background sync 
    // Lazily ensures expired get suspended without blocking reads
    schoolRepo.suspendExpiredSubscriptions().catch(err => console.error('Auto suspend failed', err));

    const page = parseInt(query.page, 10) || 1;
    const limit = parseInt(query.limit, 10) || 10;
    const skip = (page - 1) * limit;

    const where = {};
    if (query.search) {
        where.name = { contains: query.search, mode: 'insensitive' };
    }
    if (query.status) {
        where.isActive = query.status === 'ACTIVE';
    }

    const { data: schools, total } = await schoolRepo.getSchools(where, skip, limit);

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

export const getSchoolById = async (id) => {
    const school = await schoolRepo.getSchoolById(id);
    if (!school) {
        throw new AppError('School not found', 404);
    }
    return school;
};

export const updateSchool = async (id, data, adminUser) => {
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

    await logAudit('UPDATE_SCHOOL', { schoolId: id, triggeredBy: adminUser.id, changes: data });
    return updated;
};

export const deleteSchool = async (id, adminUser) => {
    const school = await schoolRepo.getSchoolById(id);
    if (!school) {
        throw new AppError('School not found', 404);
    }

    // Perform soft delete
    const deleted = await schoolRepo.deleteSchool(id);

    await logAudit('SUSPEND_SCHOOL', { schoolId: id, triggeredBy: adminUser.id });
    return deleted;
};

export const assignPlan = async (schoolId, data, adminUser) => {
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
        triggeredBy: adminUser.id
    });

    return subscription;
};
