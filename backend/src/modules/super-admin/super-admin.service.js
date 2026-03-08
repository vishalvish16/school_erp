/**
 * Super Admin Service — dashboard, schools, plans, billing
 * Uses existing Prisma schema (School, PlatformPlan, SchoolSubscription)
 */
import { PrismaClient } from '@prisma/client';
import * as schoolsRepo from '../schools/schools.repository.js';
import * as plansRepo from '../plans/plans.repository.js';
import * as subscriptionRepo from '../subscription/subscription.repository.js';

const prisma = new PrismaClient();

const toStr = (v) => (v != null ? String(v) : null);

/** Map School + plan to Flutter SuperAdminSchoolModel format */
const mapSchoolToResponse = (s) => {
    const raw = s.status || (s.isActive === false ? 'SUSPENDED' : 'ACTIVE');
    const status = raw === 'SUSPENDED' ? 'suspended' : raw === 'ACTIVE' ? 'active' : String(raw).toLowerCase();
    return {
        id: toStr(s.id),
        name: s.name || '',
        code: s.schoolCode || s.code || '',
        board: s.board || 'CBSE',
        school_type: s.school_type || 'private',
        status,
        subdomain: s.subdomain || null,
        city: s.city || null,
        state: s.state || null,
        phone: s.contactPhone || s.phone || null,
        email: s.contactEmail || s.email || null,
        logo_url: s.logo_url || null,
        group_id: s.group_id || null,
        plan: s.plan
            ? {
                id: toStr(s.plan.id),
                name: s.plan.name,
                slug: s.plan.slug || s.plan.name?.toLowerCase?.()?.replace(/\s+/g, '-') || '',
                price_per_student: parseFloat(s.plan.priceMonthly || s.plan.price_per_student || 0),
                icon_emoji: s.plan.icon_emoji || '📦',
            }
            : null,
        student_limit: s.student_limit ?? 500,
        student_count: s.studentCount ?? s.student_count ?? 0,
        overdue_days: s.overdue_days ?? 0,
        subscription_end: s.subscriptionEnd || s.subscription_end || null,
        features: s.features || {},
    };
};

/** Map PlatformPlan to Flutter PlanModel format */
const mapPlanToResponse = (p, extra = {}) => ({
    id: toStr(p.id),
    name: p.name,
    slug: p.slug || p.name?.toLowerCase?.()?.replace(/\s+/g, '-') || '',
    description: p.description || null,
    price_per_student: parseFloat(p.priceMonthly || p.price_per_student || 0),
    icon_emoji: p.icon_emoji || '📦',
    color_hex: p.color_hex || '#00D2FF',
    max_students: p.maxStudents ?? p.max_students ?? null,
    support_level: p.support_level || 'standard',
    status: p.isActive === false ? 'inactive' : (p.status || 'active'),
    sort_order: p.sort_order ?? 0,
    school_count: extra.school_count ?? extra.active_school_count ?? 0,
    mrr: extra.mrr ?? 0,
});

// ── Dashboard ─────────────────────────────────────────────────────────────
export const getDashboardStats = async () => {
    const now = new Date();
    const expiringEnd = new Date(now);
    expiringEnd.setDate(expiringEnd.getDate() + 7);

    const [
        totalSchools,
        activeSchools,
        trialSchools,
        suspendedSchools,
        totalUsers,
        planCounts,
        schoolsExpiring,
        schoolsOverdue,
        recentSchools,
        activeSchoolsWithPlans,
    ] = await Promise.all([
        prisma.school.count(),
        prisma.school.count({ where: { isActive: true } }),
        prisma.school.count({
            where: {
                isActive: true,
                subscriptionEnd: { gte: now },
            },
        }),
        prisma.school.count({ where: { isActive: false } }),
        prisma.user.count({ where: { schoolId: { not: null } } }),
        prisma.school.groupBy({
            by: ['planId'],
            where: { isActive: true },
            _count: { id: true },
        }),
        prisma.school.findMany({
            where: {
                isActive: true,
                subscriptionEnd: { gte: now, lte: expiringEnd },
            },
            include: { plan: true },
            take: 10,
            orderBy: { subscriptionEnd: 'asc' },
        }),
        prisma.school.findMany({
            where: {
                isActive: true,
                subscriptionEnd: { lt: now },
            },
            include: { plan: true },
            take: 10,
        }),
        prisma.school.findMany({
            where: {},
            include: { plan: true },
            orderBy: { createdAt: 'desc' },
            take: 5,
        }),
        prisma.school.findMany({
            where: { isActive: true },
            select: { plan: { select: { priceMonthly: true } } },
        }),
    ]);

    const mrr = activeSchoolsWithPlans.reduce(
        (sum, s) => sum + (s.plan?.priceMonthly ? parseFloat(s.plan.priceMonthly) : 0),
        0
    );
    const arr = mrr * 12;

    const planIds = [...new Set(planCounts.map((p) => p.planId.toString()))];
    const plans = await prisma.platformPlan.findMany({
        where: { id: { in: planIds.map((id) => BigInt(id)) } },
    });
    const planMap = new Map(plans.map((p) => [p.id.toString(), p]));
    const planDistribution = planCounts.map((pc) => {
        const plan = planMap.get(pc.planId.toString());
        const count = pc._count.id;
        const planMrr = plan ? parseFloat(plan.priceMonthly || 0) * count : 0;
        return {
            plan_id: pc.planId.toString(),
            plan_name: plan?.name || 'Unknown',
            plan_icon: plan?.icon_emoji || null,
            school_count: count,
            percentage: totalSchools > 0 ? (count / totalSchools) * 100 : 0,
            mrr: planMrr,
        };
    });

    return {
        total_schools: totalSchools,
        active_schools: activeSchools,
        trial_schools: trialSchools,
        suspended_schools: suspendedSchools,
        total_students: totalUsers,
        total_groups: 0,
        mrr,
        arr,
        schools_expiring_7_days: schoolsExpiring.map(mapSchoolToResponse),
        schools_overdue: schoolsOverdue.map(mapSchoolToResponse),
        recent_schools: recentSchools.map(mapSchoolToResponse),
        plan_distribution: planDistribution,
    };
};

// ── Schools ────────────────────────────────────────────────────────────────
export const getSchools = async (opts = {}) => {
    const { page = 1, limit = 20, search, status, plan_id, state, group_id } = opts;
    const skip = (page - 1) * limit;
    const where = {};

    if (search && search.trim()) {
        where.OR = [
            { name: { contains: search.trim(), mode: 'insensitive' } },
            { schoolCode: { contains: search.trim(), mode: 'insensitive' } },
            { city: { contains: search.trim(), mode: 'insensitive' } },
            { state: { contains: search.trim(), mode: 'insensitive' } },
        ];
    }
    if (status === 'active') where.isActive = true;
    else if (status === 'suspended') where.isActive = false;
    if (plan_id) where.planId = BigInt(plan_id);
    if (state) where.state = { contains: state, mode: 'insensitive' };

    const result = await schoolsRepo.getSchools(where, skip, limit);
    const data = (result.data || []).map(mapSchoolToResponse);
    const total = result.total ?? 0;
    return {
        data,
        pagination: {
            page,
            limit,
            total,
            total_pages: Math.ceil(total / limit) || 1,
        },
    };
};

export const getSchoolById = async (id) => {
    const school = await schoolsRepo.getSchoolById(id);
    if (!school) return null;
    return mapSchoolToResponse(school);
};

export const createSchool = async (body) => {
    const code = body.code || `SCH${Date.now().toString(36).toUpperCase()}`;
    const subdomain =
        body.subdomain ||
        (body.name || code).toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 50) ||
        `school-${Date.now()}`;
    const data = {
        ...body,
        name: body.name || 'New School',
        schoolCode: code,
        subdomain,
        planId: body.plan_id || body.planId,
        contactEmail: body.email || body.admin_email,
        contactPhone: body.phone || body.admin_mobile,
        status: 'ACTIVE',
    };
    const created = await schoolsRepo.createSchool(data);
    return mapSchoolToResponse(created);
};

export const updateSchool = async (id, body) => {
    const data = { ...body };
    if (data.plan_id) data.planId = data.plan_id;
    if (data.email) data.contactEmail = data.email;
    if (data.phone) data.contactPhone = data.phone;
    const updated = await schoolsRepo.updateSchool(id, data);
    return mapSchoolToResponse(updated);
};

export const updateSchoolStatus = async (id, status) => {
    const isActive = status === 'active';
    await prisma.school.update({
        where: { id: BigInt(id) },
        data: { isActive },
    });
    const school = await schoolsRepo.getSchoolById(id);
    return school ? mapSchoolToResponse(school) : null;
};

export const updateSchoolSubdomain = async (id, subdomain) => {
    const existing = await prisma.school.findFirst({
        where: { subdomain, id: { not: BigInt(id) } },
    });
    if (existing) throw new Error('Subdomain already in use');
    await prisma.school.update({
        where: { id: BigInt(id) },
        data: { subdomain },
    });
    const school = await schoolsRepo.getSchoolById(id);
    return school ? mapSchoolToResponse(school) : null;
};

// ── Groups ─────────────────────────────────────────────────────────────────
export const getGroups = async () => {
    return { data: [] };
};

export const createGroup = async () => {
    throw new Error('School groups not yet implemented');
};

// ── Plans ──────────────────────────────────────────────────────────────────
export const getPlans = async () => {
    const plans = await plansRepo.getAllPlans({ isActive: true });
    const withCounts = plans.map((p) => ({
        ...mapPlanToResponse(p, { school_count: p.active_school_count || 0 }),
    }));
    return { data: withCounts };
};

export const createPlan = async (body) => {
    const data = {
        name: body.name,
        maxStudents: body.max_students ?? 500,
        maxTeachers: body.max_teachers ?? 50,
        maxBranches: body.max_branches ?? 1,
        priceMonthly: body.price_per_student ?? body.price_monthly ?? 0,
        priceYearly: body.price_yearly ?? null,
        isActive: body.status !== 'inactive',
    };
    const plan = await plansRepo.createPlan(data);
    return mapPlanToResponse(plan);
};

export const updatePlan = async (id, body) => {
    const data = {};
    if (body.name != null) data.name = body.name;
    if (body.max_students != null) data.maxStudents = body.max_students;
    if (body.price_per_student != null) data.priceMonthly = body.price_per_student;
    if (body.status != null) data.isActive = body.status !== 'inactive';
    const plan = await plansRepo.updatePlan(id, data);
    return mapPlanToResponse(plan);
};

export const updatePlanStatus = async (id, status) => {
    const isActive = status === 'active';
    await plansRepo.updatePlanStatus(id, isActive);
    const plan = await plansRepo.findPlanById(id);
    return plan ? mapPlanToResponse(plan) : null;
};

// ── Billing / Subscriptions ─────────────────────────────────────────────────
export const getSubscriptions = async (opts = {}) => {
    const page = opts.page ?? 1;
    const limit = opts.limit ?? 20;
    const skip = (page - 1) * limit;
    const where = opts.status ? { status: opts.status.toUpperCase() } : {};

    const [subs, total] = await Promise.all([
        prisma.schoolSubscription.findMany({
            where,
            include: { school: true, plan: true },
            orderBy: { endDate: 'asc' },
            skip,
            take: limit,
        }),
        prisma.schoolSubscription.count({ where }),
    ]);

    const data = subs.map((s) => ({
        id: toStr(s.id),
        school_id: toStr(s.schoolId),
        school_name: s.school?.name || '',
        plan_id: toStr(s.planId),
        plan_name: s.plan?.name || '',
        status: (s.status || '').toLowerCase(),
        price_per_student: parseFloat(s.plan?.priceMonthly || 0),
        monthly_amount: parseFloat(s.priceAmount || 0),
        student_count: 0,
        duration_months: s.billingCycle === 'YEARLY' ? 12 : 1,
        start_date: s.startDate,
        end_date: s.endDate,
        payment_ref: s.payment_ref || null,
    }));

    return {
        data,
        pagination: {
            page,
            limit,
            total,
            total_pages: Math.ceil(total / limit) || 1,
        },
    };
};

export const renewSubscription = async (schoolId, body) => {
    const planId = body.plan_id || body.planId;
    const durationMonths = body.duration_months ?? 12;
    const plan = await plansRepo.findPlanById(planId);
    if (!plan) throw new Error('Plan not found');

    const school = await prisma.school.findUnique({ where: { id: BigInt(schoolId) } });
    if (!school) throw new Error('School not found');

    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setMonth(endDate.getMonth() + durationMonths);

    await prisma.schoolSubscription.create({
        data: {
            schoolId: BigInt(schoolId),
            planId: BigInt(planId),
            startDate,
            endDate,
            billingCycle: durationMonths >= 12 ? 'YEARLY' : 'MONTHLY',
            priceAmount: plan.priceMonthly,
            currency: 'INR',
            status: 'ACTIVE',
        },
    });

    await prisma.school.update({
        where: { id: BigInt(schoolId) },
        data: { subscriptionStart: startDate, subscriptionEnd: endDate, isActive: true },
    });

    return { success: true };
};

export const assignPlan = async (schoolId, body) => {
    const planId = body.plan_id || body.planId;
    await prisma.school.update({
        where: { id: BigInt(schoolId) },
        data: { planId: BigInt(planId) },
    });
    return { success: true };
};

export const resolveOverdue = async (schoolId, body) => {
    const action = body.action || 'paid';
    if (action === 'paid') {
        await renewSubscription(schoolId, { plan_id: body.plan_id, duration_months: 12 });
    } else if (action === 'terminate') {
        await prisma.school.update({
            where: { id: BigInt(schoolId) },
            data: { isActive: false },
        });
    }
    return { success: true };
};

// ── Features (stub) ────────────────────────────────────────────────────────
export const getPlatformFeatures = async () => ({ data: [] });
export const togglePlatformFeature = async () => ({});
export const getSchoolFeatures = async () => ({});
export const toggleSchoolFeature = async () => ({});

// ── Hardware (stub) ─────────────────────────────────────────────────────────
export const getHardware = async (opts = {}) => {
    const page = opts.page ?? 1;
    const limit = opts.limit ?? 50;
    return {
        data: [],
        pagination: { page, limit, total: 0, total_pages: 1 },
    };
};
export const registerHardware = async () => ({});
export const pingDevice = async () => ({});
export const deleteDevice = async () => ({});

// ── Admins (stub) ──────────────────────────────────────────────────────────
export const getSuperAdmins = async () => ({ data: [] });
export const addSuperAdmin = async () => ({});
export const updateSuperAdmin = async () => ({});
export const removeSuperAdmin = async () => ({});

// ── Audit (stub) ───────────────────────────────────────────────────────────
export const getAuditLogs = async (type, opts = {}) => {
    const page = opts.page ?? 1;
    const limit = opts.limit ?? 50;
    return {
        data: [],
        pagination: { page, limit, total: 0, total_pages: 1 },
    };
};

// ── Security (stub) ─────────────────────────────────────────────────────────
export const getSecurityEvents = async () => ({ data: [] });
export const getTrustedDevices = async () => ({ data: [] });
export const revokeDevice = async () => ({});
export const blockIp = async () => ({});

// ── Infra (stub) ─────────────────────────────────────────────────────────────
export const getInfraStatus = async () => ({ data: {} });
