import { AppError } from '../../utils/response.js';

import prisma from '../../config/prisma.js';

const convertBigInts = (obj) => {
    return JSON.parse(
        JSON.stringify(obj, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value
        )
    );
};

export const createSchool = async (data) => {
    const code = data.schoolCode || data.code || `SCH${Date.now().toString(36).toUpperCase()}`;
    const subdomainVal = (data.subdomain || data.code || '').trim().toLowerCase().replace(/[^a-z0-9-]/g, '');
    const mappedData = {
        name: data.name || 'New School',
        code,
        subdomain: subdomainVal || code.toLowerCase().replace(/[^a-z0-9-]/g, ''),
        email: data.contactEmail || data.email || 'admin@school.in',
        phone: data.contactPhone || data.phone || '+910000000000',
        status: data.status === 'ACTIVE' ? 'ACTIVE' : 'ACTIVE',
        subscriptionPlan: ['BASIC', 'STANDARD', 'PREMIUM'].includes(data.subscriptionPlan) ? data.subscriptionPlan : 'BASIC',
        subscriptionStart: data.subscriptionStart || new Date(),
        subscriptionEnd: data.subscriptionEnd || null,
        studentLimit: data.studentLimit !== undefined ? data.studentLimit : 500,
        board: data.board || null,
        address: data.address || null,
        city: data.city || null,
        state: data.state || null,
        country: data.country || 'India',
        timezone: data.timezone || 'Asia/Kolkata'
    };
    const created = await prisma.school.create({ data: mappedData });
    return convertBigInts({ ...created, schoolCode: created.code });
};

const SORT_FIELD_MAP = {
    schoolCode: 'code',
    code: 'code',
    name: 'name',
    planId: 'subscriptionPlan',
    subscriptionPlan: 'subscriptionPlan',
    isActive: 'status',
    status: 'status',
    subscriptionEnd: 'subscriptionEnd',
    createdAt: 'createdAt'
};

const SCHOOL_LIST_SELECT = {
    id: true,
    name: true,
    code: true,
    subdomain: true,
    board: true,
    status: true,
    subscriptionPlan: true,
    subscriptionEnd: true,
    city: true,
    state: true,
    country: true,
    groupId: true,
};

export const getSchools = async (where, skip, take, sortBy = 'createdAt', sortOrder = 'desc') => {
    const orderField = SORT_FIELD_MAP[sortBy] || 'createdAt';
    const orderBy = { [orderField]: sortOrder };

    const [schools, total] = await Promise.all([
        prisma.school.findMany({
            where,
            skip,
            take,
            orderBy,
            select: SCHOOL_LIST_SELECT,
        }),
        prisma.school.count({ where })
    ]);

    if (!schools.length) {
        return { data: [], total, skip, take };
    }

    const schoolIds = schools.map(s => s.id);
    // Actual enrollment: Student + Staff rows (User role counts miss portal-only records
    // and role name casing like 'teacher' vs 'TEACHER').
    const countsMap = new Map();
    schoolIds.forEach((id) => {
        countsMap.set(id.toString(), { studentCount: 0, teacherCount: 0 });
    });
    if (schoolIds.length) {
        const [studentGroups, staffGroups] = await Promise.all([
            prisma.student.groupBy({
                by: ['schoolId'],
                where: { schoolId: { in: schoolIds }, deletedAt: null },
                _count: { id: true },
            }),
            prisma.staff.groupBy({
                by: ['schoolId'],
                where: { schoolId: { in: schoolIds }, deletedAt: null },
                _count: { id: true },
            }),
        ]);
        for (const row of studentGroups) {
            const sId = row.schoolId?.toString();
            if (sId && countsMap.has(sId)) {
                countsMap.get(sId).studentCount = row._count.id;
            }
        }
        for (const row of staffGroups) {
            const sId = row.schoolId?.toString();
            if (sId && countsMap.has(sId)) {
                countsMap.get(sId).teacherCount = row._count.id;
            }
        }
    }

    const enrichedSchools = schools.map((school) => ({
        ...school,
        schoolCode: school.code,
        status: school.status || 'ACTIVE',
        studentCount: countsMap.get(school.id.toString())?.studentCount ?? 0,
        teacherCount: countsMap.get(school.id.toString())?.teacherCount ?? 0,
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
        where: { id: String(id) }
    });

    if (!school) return null;

    const [studentCount, teacherCount] = await Promise.all([
        prisma.student.count({ where: { schoolId: String(id), deletedAt: null } }),
        prisma.staff.count({ where: { schoolId: String(id), deletedAt: null } }),
    ]);

    return convertBigInts({
        ...school,
        schoolCode: school.code,
        status: school.status || 'ACTIVE',
        studentCount,
        teacherCount,
        active_subscription: school.subscriptionEnd ? {
            plan_name: school.subscriptionPlan,
            end_date: school.subscriptionEnd,
            status: 'ACTIVE'
        } : null,
        subscription_history: []
    });
};

export const updateSchool = async (id, data) => {
    const mappedData = {};
    if (data.name !== undefined) mappedData.name = data.name;
    if (data.code !== undefined) mappedData.code = data.code;
    if (data.schoolCode !== undefined) mappedData.code = data.schoolCode;
    if (data.email !== undefined) mappedData.email = data.email;
    if (data.contactEmail !== undefined) mappedData.email = data.contactEmail;
    if (data.phone !== undefined) mappedData.phone = data.phone;
    if (data.contactPhone !== undefined) mappedData.phone = data.contactPhone;
    if (data.status !== undefined) {
        const s = String(data.status).toUpperCase();
        mappedData.status = s === 'SUSPENDED' ? 'SUSPENDED' : s === 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
    }
    if (data.subscriptionPlan !== undefined) mappedData.subscriptionPlan = data.subscriptionPlan;
    if (data.subscriptionEnd !== undefined) mappedData.subscriptionEnd = data.subscriptionEnd;
    if (data.board !== undefined) mappedData.board = data.board;
    if (data.address !== undefined) mappedData.address = data.address;
    if (data.city !== undefined) mappedData.city = data.city;
    if (data.state !== undefined) mappedData.state = data.state;
    if (data.country !== undefined) mappedData.country = data.country;
    if (data.subdomain !== undefined) mappedData.subdomain = data.subdomain;
    if (data.pin !== undefined) mappedData.pinCode = data.pin || null;
    if (data.pin_code !== undefined) mappedData.pinCode = data.pin_code || null;
    if (data.pinCode !== undefined) mappedData.pinCode = data.pinCode || null;
    if (data.group_id !== undefined) mappedData.groupId = data.group_id || null;
    if (data.groupId !== undefined) mappedData.groupId = data.groupId || null;
    if (data.studentLimit !== undefined) mappedData.studentLimit = data.studentLimit;

    if (Object.keys(mappedData).length === 0) {
        throw new AppError('No valid fields to update. Ensure at least one field is provided.', 400);
    }

    const updated = await prisma.school.update({
        where: { id: String(id) },
        data: mappedData
    });
    return convertBigInts({ ...updated, schoolCode: updated.code });
};

export const deleteSchool = async (id) => {
    const updated = await prisma.school.update({
        where: { id: String(id) },
        data: { status: 'INACTIVE' }
    });
    return convertBigInts(updated);
};

/**
 * Public school search — name, city, state, or code (case insensitive)
 * Only active schools with non-expired subscription
 * Returns only safe public fields (no subdomain, admin, billing)
 */
export const searchSchoolsPublic = async (q, limit = 10) => {
    const schools = await prisma.school.findMany({
        where: {
            status: 'ACTIVE',
            AND: [
                {
                    OR: [
                        { name: { contains: q, mode: 'insensitive' } },
                        { code: { contains: q, mode: 'insensitive' } },
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
        select: { id: true, name: true, code: true, city: true, state: true, status: true },
        orderBy: { name: 'asc' },
        take: limit
    });

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
        code: s.code,
        city: s.city || '',
        state: s.state || '',
        board: '',
        type: 'school',
        logo_url: null,
        is_active: s.status === 'ACTIVE'
    }));
};

/** Check if subdomain is already taken (case-insensitive). Checks subdomain and code. Exclude schoolId when updating. */
export const isSubdomainTaken = async (value, excludeSchoolId = null) => {
    if (!value || typeof value !== 'string') return false;
    const normalized = String(value).trim().toLowerCase();
    if (!/^[a-z0-9-]+$/.test(normalized) || normalized.length < 2) return false;
    const where = {
        OR: [
            { subdomain: { equals: normalized, mode: 'insensitive' } },
            { code: { equals: normalized, mode: 'insensitive' } },
        ],
    };
    if (excludeSchoolId) {
        where.id = { not: String(excludeSchoolId) };
    }
    const school = await prisma.school.findFirst({
        where,
        select: { id: true },
    });
    return !!school;
};

export const findByCode = async (schoolCode, excludeId = null) => {
    const where = { code: schoolCode };
    if (excludeId) {
        where.id = { not: String(excludeId) };
    }
    const school = await prisma.school.findFirst({
        where,
        select: { id: true, code: true }
    });
    return school ? convertBigInts({ ...school, schoolCode: school.code }) : null;
};

export const suspendExpiredSubscriptions = async () => {
    const suspended = await prisma.school.updateMany({
        where: {
            subscriptionEnd: { lt: new Date() },
            status: 'ACTIVE'
        },
        data: { status: 'SUSPENDED' }
    });
    return suspended.count;
};
