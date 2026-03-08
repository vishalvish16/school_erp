import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const convertBigInts = (obj) => {
    return JSON.parse(
        JSON.stringify(obj, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value
        )
    );
};

export const createSchool = async (data) => {
    const mappedData = { ...data };
    if (mappedData.status !== undefined) {
        mappedData.isActive = mappedData.status === 'ACTIVE';
        delete mappedData.status;
    }
    if (mappedData.phone !== undefined) {
        mappedData.contactPhone = mappedData.phone;
        delete mappedData.phone;
    }

    if (!mappedData.subdomain) {
        mappedData.subdomain = (mappedData.schoolCode || mappedData.name).toLowerCase().replace(/[^a-z0-9]/g, '');
    }

    const created = await prisma.school.create({
        data: {
            ...mappedData,
            planId: BigInt(mappedData.planId)
        },
        include: { plan: true }
    });
    created.status = created.isActive ? 'ACTIVE' : 'SUSPENDED';
    return convertBigInts(created);
};

const SORT_FIELD_MAP = {
    schoolCode: 'schoolCode',
    name: 'name',
    planId: 'planId',
    isActive: 'isActive',
    subscriptionEnd: 'subscriptionEnd',
    createdAt: 'createdAt'
};

export const getSchools = async (where, skip, take, sortBy = 'createdAt', sortOrder = 'desc') => {
    const orderField = SORT_FIELD_MAP[sortBy] || 'createdAt';
    const orderBy = { [orderField]: sortOrder };

    // Run count and fetch concurrently
    const [schools, total] = await Promise.all([
        prisma.school.findMany({
            where,
            skip,
            take,
            orderBy,
            include: { plan: true }
        }),
        prisma.school.count({ where })
    ]);

    if (!schools.length) {
        return { data: [], total, skip, take };
    }

    // Optimization: Avoid N+1 mapping using a single group-by aggregation
    const schoolIds = schools.map(s => s.id);
    const userRoleCounts = await prisma.user.groupBy({
        by: ['schoolId', 'roleId'],
        where: { schoolId: { in: schoolIds } },
        _count: { id: true }
    });

    const roleIds = [...new Set(userRoleCounts.map(u => u.roleId))];
    const roles = await prisma.role.findMany({
        where: { id: { in: roleIds }, name: { in: ['STUDENT', 'TEACHER'] } },
        select: { id: true, name: true }
    });

    const roleMap = new Map(roles.map(r => [r.id.toString(), r.name]));

    const countsMap = new Map();
    schoolIds.forEach(id => {
        countsMap.set(id.toString(), { studentCount: 0, teacherCount: 0 });
    });

    for (const record of userRoleCounts) {
        const sId = record.schoolId.toString();
        const roleName = roleMap.get(record.roleId.toString());
        if (roleName === 'STUDENT') {
            countsMap.get(sId).studentCount += record._count.id;
        } else if (roleName === 'TEACHER') {
            countsMap.get(sId).teacherCount += record._count.id;
        }
    }

    const enrichedSchools = schools.map(school => ({
        ...school,
        status: school.isActive ? 'ACTIVE' : 'SUSPENDED',
        studentCount: countsMap.get(school.id.toString()).studentCount,
        teacherCount: countsMap.get(school.id.toString()).teacherCount
    }));

    return {
        data: convertBigInts(enrichedSchools),
        total,
        skip,
        take
    };
};

export const getSchoolById = async (id) => {
    const school = await prisma.school.findUnique({
        where: { id: BigInt(id) },
        include: {
            plan: true,
            subscriptions: {
                include: { plan: true },
                orderBy: { createdAt: 'desc' }
            }
        }
    });

    if (!school) return null;

    // Separate active subscription from history
    const activeSubscription = school.subscriptions.find(s => s.status === 'ACTIVE');
    const subscriptionHistory = school.subscriptions;

    const enrichedSchool = {
        ...school,
        active_subscription: activeSubscription ? {
            subscription_id: activeSubscription.id.toString(),
            plan_id: activeSubscription.planId.toString(),
            plan_name: activeSubscription.plan.name,
            billing_cycle: activeSubscription.billingCycle,
            start_date: activeSubscription.startDate,
            end_date: activeSubscription.endDate,
            status: activeSubscription.status
        } : null,
        subscription_history: subscriptionHistory.map(s => ({
            subscription_id: s.id.toString(),
            plan_id: s.planId.toString(),
            plan_name: s.plan.name,
            billing_cycle: s.billingCycle,
            start_date: s.startDate,
            end_date: s.endDate,
            status: s.status,
            created_at: s.createdAt
        }))
    };

    // Remove the flat subscriptions array from the root to keep response clean
    delete enrichedSchool.subscriptions;

    // Single query for specific counts to avoid sequential or nested roundtrips
    const userRoleCounts = await prisma.user.groupBy({
        by: ['roleId'],
        where: { schoolId: BigInt(id) },
        _count: { id: true }
    });

    let studentCount = 0;
    let teacherCount = 0;

    if (userRoleCounts.length > 0) {
        const roleIds = userRoleCounts.map(u => u.roleId);
        const roles = await prisma.role.findMany({
            where: { id: { in: roleIds }, name: { in: ['STUDENT', 'TEACHER'] } },
            select: { id: true, name: true }
        });
        const roleMap = new Map(roles.map(r => [r.id.toString(), r.name]));

        for (const record of userRoleCounts) {
            const roleName = roleMap.get(record.roleId.toString());
            if (roleName === 'STUDENT') studentCount += record._count.id;
            else if (roleName === 'TEACHER') teacherCount += record._count.id;
        }
    }

    enrichedSchool.status = enrichedSchool.isActive ? 'ACTIVE' : 'SUSPENDED';
    return convertBigInts({ ...enrichedSchool, studentCount, teacherCount });
};

export const updateSchool = async (id, data) => {
    const mappedData = { ...data };
    if (mappedData.status !== undefined) {
        mappedData.isActive = mappedData.status === 'ACTIVE';
        delete mappedData.status;
    }
    if (mappedData.phone !== undefined) {
        mappedData.contactPhone = mappedData.phone;
        delete mappedData.phone;
    }

    const updated = await prisma.school.update({
        where: { id: BigInt(id) },
        data: {
            ...mappedData,
            ...(mappedData.planId ? { planId: BigInt(mappedData.planId) } : {})
        },
        include: { plan: true }
    });
    updated.status = updated.isActive ? 'ACTIVE' : 'SUSPENDED';
    return convertBigInts(updated);
};

export const deleteSchool = async (id) => {
    const updated = await prisma.school.update({
        where: { id: BigInt(id) },
        data: { isActive: false }
    });
    return convertBigInts(updated);
};

/**
 * Public school search — name, city, state, or code (case insensitive)
 * Only active schools with non-expired subscription
 * Returns only safe public fields (no subdomain, admin, billing)
 */
export const searchSchoolsPublic = async (q, limit = 10) => {
    const term = `%${q}%`;
    const schools = await prisma.school.findMany({
        where: {
            isActive: true,
            AND: [
                {
                    OR: [
                        { name: { contains: q, mode: 'insensitive' } },
                        { schoolCode: { contains: q, mode: 'insensitive' } },
                        ...(q.length >= 2 ? [
                            { city: { contains: q, mode: 'insensitive' } },
                            { state: { contains: q, mode: 'insensitive' } }
                        ] : [])
                    ]
                },
                {
                    OR: [
                        { subscriptionEnd: null },
                        { subscriptionEnd: { gte: new Date() } }
                    ]
                }
            ]
        },
        select: {
            id: true,
            name: true,
            schoolCode: true,
            city: true,
            state: true,
            isActive: true
        },
        orderBy: { name: 'asc' },
        take: limit
    });

    // Prisma orderBy with conditional is tricky — use simple name asc
    const sorted = schools.sort((a, b) => {
        const aStarts = a.name.toLowerCase().startsWith(q.toLowerCase());
        const bStarts = b.name.toLowerCase().startsWith(q.toLowerCase());
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.name.localeCompare(b.name);
    });

    return sorted.map(s => ({
        id: s.id.toString(),
        name: s.name,
        code: s.schoolCode,
        city: s.city || '',
        state: s.state || '',
        board: '', // Schema has no board — extend later if needed
        type: 'school',
        logo_url: null,
        is_active: s.isActive
    }));
};

export const findByCode = async (schoolCode, excludeId = null) => {
    const where = { schoolCode };
    if (excludeId) {
        where.id = { not: BigInt(excludeId) };
    }
    const school = await prisma.school.findFirst({
        where,
        select: { id: true, schoolCode: true }
    });
    return school ? convertBigInts(school) : null;
};

export const suspendExpiredSubscriptions = async () => {
    const suspended = await prisma.school.updateMany({
        where: {
            subscriptionEnd: { lt: new Date() },
            isActive: true
        },
        data: {
            isActive: false
        }
    });
    return suspended.count;
};
