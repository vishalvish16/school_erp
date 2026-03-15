/**
 * Super Admin Service — dashboard, schools, plans, billing
 * Uses existing Prisma schema (School, PlatformPlan, SchoolSubscription)
 */
import bcrypt from 'bcrypt';
import { PrismaClient } from '@prisma/client';
import { AppError } from '../../utils/response.js';
import * as schoolsRepo from '../schools/schools.repository.js';
import * as plansRepo from '../plans/plans.repository.js';
import * as subscriptionRepo from '../subscription/subscription.repository.js';
import { gatherInfraStatus } from './infra-status.helper.js';

const prisma = new PrismaClient();

const toStr = (v) => (v != null ? String(v) : null);

const PLAN_NAMES = { BASIC: 'Basic', STANDARD: 'Standard', PREMIUM: 'Premium' };

/** Build plan object from subscriptionPlan enum when plan relation is missing */
const planFromSubscription = (subscriptionPlan) => {
    const plan = String(subscriptionPlan || 'BASIC').toUpperCase();
    const name = PLAN_NAMES[plan] || plan;
    return {
        id: plan,
        name,
        slug: name.toLowerCase(),
        price_per_student: { BASIC: 99, STANDARD: 199, PREMIUM: 499 }[plan] || 0,
        icon_emoji: '📦',
    };
};

/** Map School + plan to Flutter SuperAdminSchoolModel format */
const mapSchoolToResponse = (s) => {
    const raw = s.status || (s.isActive === false ? 'SUSPENDED' : 'ACTIVE');
    const status = raw === 'SUSPENDED' ? 'suspended' : raw === 'ACTIVE' ? 'active' : String(raw).toLowerCase();
    const plan = s.plan
        ? {
            id: toStr(s.plan.id),
            name: s.plan.name,
            slug: s.plan.slug || s.plan.name?.toLowerCase?.()?.replace(/\s+/g, '-') || '',
            price_per_student: parseFloat(s.plan.priceMonthly || s.plan.price_per_student || 0),
            icon_emoji: s.plan.icon_emoji || '📦',
        }
        : planFromSubscription(s.subscriptionPlan);
    const primaryAdmin = s.primaryAdmin ?? null;
    return {
        id: toStr(s.id),
        name: s.name || '',
        code: s.schoolCode || s.code || '',
        board: s.board || 'CBSE',
        school_type: s.school_type || 'private',
        status,
        subdomain: s.subdomain || null,
        country: s.country || null,
        city: s.city || null,
        state: s.state || null,
        pin: s.pinCode || s.pin_code || s.pin || null,
        phone: s.contactPhone || s.phone || null,
        email: s.contactEmail || s.email || null,
        logo_url: s.logo_url || null,
        group_id: s.groupId || s.group_id || null,
        plan,
        student_limit: s.student_limit ?? 500,
        student_count: s.studentCount ?? s.student_count ?? 0,
        overdue_days: s.overdue_days ?? 0,
        subscription_end: s.subscriptionEnd || s.subscription_end || null,
        features: s.features || {},
        primary_admin: primaryAdmin,
    };
};

/** Map PlatformPlan to Flutter PlanModel format */
const mapPlanToResponse = (p, extra = {}) => ({
    id: toStr(p.id),
    name: p.name,
    slug: p.slug || p.name?.toLowerCase?.()?.replace(/\s+/g, '-') || '',
    description: p.description || null,
    price_per_student: parseFloat(p.price ?? p.priceMonthly ?? p.price_per_student ?? 0),
    icon_emoji: p.icon_emoji || '📦',
    color_hex: p.color_hex || '#00D2FF',
    max_students: p.maxUsers ?? p.maxStudents ?? p.max_students ?? null,
    support_level: p.support_level || 'standard',
    status: p.isActive === false ? 'inactive' : (p.status || 'active'),
    sort_order: p.sort_order ?? 0,
    school_count: extra.school_count ?? extra.active_school_count ?? 0,
    mrr: extra.mrr ?? 0,
});

// ── Dashboard ─────────────────────────────────────────────────────────────
const ACTIVE_STATUS = { status: 'ACTIVE' };
const SUSPENDED_STATUS = { status: { in: ['SUSPENDED', 'INACTIVE'] } };

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
    ] = await Promise.all([
        prisma.school.count(),
        prisma.school.count({ where: ACTIVE_STATUS }),
        prisma.school.count({
            where: {
                ...ACTIVE_STATUS,
                subscriptionEnd: { gte: now },
            },
        }),
        prisma.school.count({ where: SUSPENDED_STATUS }),
        prisma.user.count({ where: { schoolId: { not: null } } }),
        prisma.school.groupBy({
            by: ['subscriptionPlan'],
            where: ACTIVE_STATUS,
            _count: { id: true },
        }),
        prisma.school.findMany({
            where: {
                ...ACTIVE_STATUS,
                subscriptionEnd: { gte: now, lte: expiringEnd },
            },
            take: 10,
            orderBy: { subscriptionEnd: 'asc' },
        }),
        prisma.school.findMany({
            where: {
                ...ACTIVE_STATUS,
                subscriptionEnd: { lt: now },
            },
            take: 10,
        }),
        prisma.school.findMany({
            where: {},
            orderBy: { createdAt: 'desc' },
            take: 5,
        }),
    ]);

    // MRR/ARR: use subscriptionPlan enum with approximate prices (schema has no plan relation)
    const planPrices = { BASIC: 99, STANDARD: 199, PREMIUM: 499 };
    const activeSchoolsForMrr = await prisma.school.findMany({
        where: ACTIVE_STATUS,
        select: { subscriptionPlan: true },
    });
    const mrr = activeSchoolsForMrr.reduce(
        (sum, s) => sum + (planPrices[s.subscriptionPlan] || 0),
        0
    );
    const arr = mrr * 12;

    const planDistribution = planCounts.map((pc) => {
        const planName = pc.subscriptionPlan || 'Unknown';
        const count = pc._count.id;
        const planMrr = (planPrices[pc.subscriptionPlan] || 0) * count;
        return {
            plan_id: planName,
            plan_name: planName,
            plan_icon: null,
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
        total_groups: await prisma.schoolGroup.count(),
        mrr,
        arr,
        schools_expiring_7_days: schoolsExpiring.map((s) => mapSchoolToResponse({ ...s, plan: null })),
        schools_overdue: schoolsOverdue.map((s) => mapSchoolToResponse({ ...s, plan: null })),
        recent_schools: recentSchools.map((s) => mapSchoolToResponse({ ...s, plan: null })),
        plan_distribution: planDistribution,
    };
};

// ── Schools ────────────────────────────────────────────────────────────────
export const getSchools = async (opts = {}) => {
    const { page = 1, limit = 20, search, status, plan_id, country, state, city, group_id } = opts;
    const skip = (page - 1) * limit;
    const where = {};

    if (search && search.trim()) {
        where.OR = [
            { name: { contains: search.trim(), mode: 'insensitive' } },
            { code: { contains: search.trim(), mode: 'insensitive' } },
            { city: { contains: search.trim(), mode: 'insensitive' } },
            { state: { contains: search.trim(), mode: 'insensitive' } },
        ];
    }
    if (status === 'active') where.status = 'ACTIVE';
    else if (status === 'suspended') where.status = { in: ['SUSPENDED', 'INACTIVE'] };
    else if (status === 'trial') {
        where.status = 'ACTIVE';
        const trialOr = [
            { subscriptionEnd: null },
            { subscriptionEnd: { gte: new Date() } },
        ];
        if (where.OR) {
            const searchOr = where.OR;
            delete where.OR;
            where.AND = [{ OR: searchOr }, { OR: trialOr }];
        } else {
            where.OR = trialOr;
        }
    } else if (status === 'expiring') {
        const now = new Date();
        const in30Days = new Date(now);
        in30Days.setDate(in30Days.getDate() + 30);
        where.status = 'ACTIVE';
        where.subscriptionEnd = { gte: now, lte: in30Days };
    }
    if (plan_id && plan_id !== 'none' && plan_id !== '') {
        const subscriptionPlan = await mapPlanToSubscriptionPlan(plan_id);
        if (subscriptionPlan) where.subscriptionPlan = subscriptionPlan;
    }
    if (country) where.country = { contains: country, mode: 'insensitive' };
    if (state) where.state = { contains: state, mode: 'insensitive' };
    if (city) where.city = { contains: city, mode: 'insensitive' };
    if (group_id === 'none' || group_id === '') where.groupId = null;
    else if (group_id) where.groupId = group_id;

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
    const [features, primaryAdmin] = await Promise.all([
        getSchoolFeatures(id),
        getPrimarySchoolAdmin(id),
    ]);
    return mapSchoolToResponse({ ...school, features, primaryAdmin });
};

/** Fetch primary school admin (first active user with school_admin role for the school) */
const getPrimarySchoolAdmin = async (schoolId) => {
    const role = await prisma.role.findFirst({ where: { name: 'school_admin' } });
    if (!role) return null;
    const user = await prisma.user.findFirst({
        where: {
            schoolId: String(schoolId),
            roleId: role.id,
            isActive: true,
            deletedAt: null,
        },
        select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
        },
    });
    if (!user) return null;
    const name = [user.firstName, user.lastName].filter(Boolean).join(' ').trim() || user.email;
    return {
        id: toStr(user.id),
        email: user.email || '',
        name,
        mobile: user.phone || '',
        phone: user.phone || '',
    };
};

/** Create or ensure school_admin role exists */
const getOrCreateSchoolAdminRole = async () => {
    let role = await prisma.role.findFirst({ where: { name: 'school_admin' } });
    if (!role) {
        role = await prisma.role.create({
            data: { name: 'school_admin', scope: 'SCHOOL', description: 'School Administrator' },
        });
    }
    return role;
};

/** Create a school admin user (used by createSchool and assignSchoolAdmin) */
const createSchoolAdminUser = async (schoolId, { email, name, mobile, password }) => {
    const role = await getOrCreateSchoolAdminRole();
    const emailNorm = String(email || '').trim().toLowerCase();
    if (!emailNorm) throw new Error('Admin email is required');
    const passwordHash = await bcrypt.hash(String(password || 'changeme123'), 10);
    const nameParts = String(name || emailNorm.split('@')[0] || 'Admin').trim().split(/\s+/);
    const firstName = nameParts[0] || 'Admin';
    const lastName = nameParts.slice(1).join(' ') || null;
    const existing = await prisma.user.findUnique({ where: { email: emailNorm } });
    if (existing) {
        if (existing.schoolId === String(schoolId) && existing.roleId === role.id) {
            await prisma.user.update({
                where: { id: existing.id },
                data: { passwordHash, firstName, lastName, phone: mobile || existing.phone, isActive: true, deletedAt: null },
            });
            return prisma.user.findUnique({ where: { id: existing.id } });
        }
        await prisma.user.update({
            where: { id: existing.id },
            data: {
                schoolId: String(schoolId),
                roleId: role.id,
                passwordHash,
                firstName,
                lastName,
                phone: mobile || existing.phone,
                isActive: true,
                deletedAt: null,
            },
        });
        return prisma.user.findUnique({ where: { id: existing.id } });
    }
    return prisma.user.create({
        data: {
            email: emailNorm,
            passwordHash,
            firstName,
            lastName,
            phone: mobile || null,
            schoolId: String(schoolId),
            roleId: role.id,
            isActive: true,
        },
    });
};

/** Assign or create school admin for an existing school */
export const assignSchoolAdmin = async (schoolId, body) => {
    const school = await schoolsRepo.getSchoolById(schoolId);
    if (!school) throw new Error('School not found');
    const email = body.admin_email || body.email;
    const password = body.temp_password || body.password;
    if (!email || !password || password.length < 8) {
        throw new Error('Admin email and password (min 8 chars) are required');
    }
    await createSchoolAdminUser(schoolId, {
        email,
        name: body.admin_name || body.name,
        mobile: body.admin_mobile || body.mobile || body.phone,
        password,
    });
    return getSchoolById(schoolId);
};

/** Reset school admin password */
export const resetSchoolAdminPassword = async (schoolId, userId, newPassword) => {
    const role = await prisma.role.findFirst({ where: { name: 'school_admin' } });
    if (!role) throw new Error('school_admin role not found');
    const user = await prisma.user.findFirst({
        where: { id: String(userId), schoolId: String(schoolId), roleId: role.id },
    });
    if (!user) throw new Error('School admin not found');
    const passwordHash = await bcrypt.hash(String(newPassword), 10);
    await prisma.user.update({
        where: { id: user.id },
        data: { passwordHash, passwordChangedAt: new Date(), mustChangePassword: true },
    });
};

/** Deactivate school admin (soft disable) */
export const deactivateSchoolAdmin = async (schoolId, userId) => {
    const role = await prisma.role.findFirst({ where: { name: 'school_admin' } });
    if (!role) throw new Error('school_admin role not found');
    const user = await prisma.user.findFirst({
        where: { id: String(userId), schoolId: String(schoolId), roleId: role.id },
    });
    if (!user) throw new Error('School admin not found');
    await prisma.user.update({
        where: { id: user.id },
        data: { isActive: false },
    });
};

/** Check if subdomain is available (not taken, valid format) */
export const checkSubdomainAvailable = async (value) => {
    const normalized = String(value || '').trim().toLowerCase();
    if (!normalized || normalized.length < 2) return false;
    if (!/^[a-z0-9-]+$/.test(normalized)) return false;
    const taken = await schoolsRepo.isSubdomainTaken(normalized);
    return !taken;
};

export const createSchool = async (body) => {
    const code = (body.subdomain || body.code || '').trim().toLowerCase() || `SCH${Date.now().toString(36).toUpperCase()}`;
    const planVal = body.plan_id || body.planId;
    const subscriptionPlan = ['BASIC', 'STANDARD', 'PREMIUM'].includes(String(planVal || '').toUpperCase())
        ? String(planVal).toUpperCase()
        : 'BASIC';
    const data = {
        name: body.name || 'New School',
        schoolCode: code,
        contactEmail: body.email || body.admin_email || 'admin@school.in',
        contactPhone: body.phone || body.admin_mobile || '+910000000000',
        status: 'ACTIVE',
        subscriptionPlan,
        subscriptionEnd: body.subscription_end || null,
        ...body,
    };
    const created = await schoolsRepo.createSchool(data);
    const schoolId = created.id?.toString() || created.code;
    const features = body.features || {};
    const keys = Object.keys(features).length > 0
        ? Object.keys(features)
        : DEFAULT_FEATURE_KEYS;
    const featuresMap = {};
    for (const key of keys) {
        const k = String(key).toLowerCase();
        const enabled = features[k] ?? features[key] ?? true;
        featuresMap[k] = !!enabled;
        try {
            await prisma.$executeRaw`
                INSERT INTO school_features (school_id, feature_name, is_enabled)
                VALUES (${schoolId}::uuid, ${k}, ${enabled})
            `;
        } catch (err) {
            if (err?.code !== '23505') throw err;
        }
    }
    // Create school admin user when admin details provided
    if (body.admin_email && body.temp_password && body.temp_password.length >= 8) {
        await createSchoolAdminUser(schoolId, {
            email: body.admin_email.trim().toLowerCase(),
            name: body.admin_name || body.admin_email.split('@')[0],
            mobile: body.admin_mobile || body.phone || '',
            password: body.temp_password,
        });
    }
    const [featuresRes, primaryAdmin] = await Promise.all([
        Promise.resolve(featuresMap),
        getPrimarySchoolAdmin(schoolId),
    ]);
    return mapSchoolToResponse({ ...created, features: featuresRes, primaryAdmin });
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
    const newStatus = status === 'active' ? 'ACTIVE' : 'SUSPENDED';
    await prisma.school.update({
        where: { id: String(id) },
        data: { status: newStatus },
    });
    const school = await schoolsRepo.getSchoolById(id);
    return school ? mapSchoolToResponse(school) : null;
};

export const updateSchoolSubdomain = async (id, subdomain) => {
    const normalized = String(subdomain || '').trim().toLowerCase();
    if (!normalized || !/^[a-z0-9-]+$/.test(normalized)) {
        throw new Error('Invalid subdomain format');
    }
    const taken = await schoolsRepo.isSubdomainTaken(normalized, id);
    if (taken) throw new Error('Subdomain already taken');
    await prisma.school.update({
        where: { id: String(id) },
        data: { subdomain: normalized },
    });
    const school = await schoolsRepo.getSchoolById(id);
    return school ? mapSchoolToResponse(school) : null;
};

// ── Groups ─────────────────────────────────────────────────────────────────
const RESERVED_SLUGS = ['admin', 'api', 'www', 'app', 'docs', 'help', 'support', 'billing', 'status'];

/** Check if group slug is available (not taken, valid format). excludeId = current group when editing */
export const checkGroupSlugAvailable = async (value, excludeId) => {
    const slug = String(value || '').toLowerCase().trim().replace(/[^a-z0-9-]/g, '').slice(0, 100);
    if (!slug || slug.length < 2) return false;
    if (RESERVED_SLUGS.includes(slug)) return false;
    const existing = await prisma.schoolGroup.findFirst({
        where: {
            slug,
            ...(excludeId ? { id: { not: String(excludeId) } } : {}),
        },
    });
    return !existing;
};

const generateSlugFromName = (name) => {
    return String(name || '')
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .slice(0, 100);
};

const mapGroupToResponse = (g) => {
    const schools = (g.schools || []).map((s) => ({
        id: toStr(s.id),
        name: s.name || '',
        code: s.code || '',
        city: s.city || null,
        state: s.state || null,
        status: (s.status || 'ACTIVE').toLowerCase(),
    }));
    const admin = g.groupAdmin ? {
        id: toStr(g.groupAdmin.id),
        first_name: g.groupAdmin.firstName || null,
        last_name: g.groupAdmin.lastName || null,
        email: g.groupAdmin.email || null,
        locked_until: g.groupAdmin.lockedUntil ? g.groupAdmin.lockedUntil.toISOString() : null,
        is_locked: !!(g.groupAdmin.lockedUntil && new Date(g.groupAdmin.lockedUntil) > new Date()),
    } : null;
    return {
        id: toStr(g.id),
        name: g.name || '',
        slug: g.slug || null,
        type: g.type || null,
        description: g.description || null,
        contact_person: g.contactPerson || null,
        contact_email: g.contactEmail || null,
        contact_phone: g.contactPhone || null,
        logo_url: g.logoUrl || null,
        address: g.address || null,
        city: g.city || null,
        state: g.state || null,
        country: g.country || null,
        status: (g.status || 'ACTIVE').toLowerCase(),
        school_count: schools.length,
        student_count: 0,
        mrr: 0,
        admin,
        group_admin: admin,
        schools,
        created_at: g.createdAt || null,
    };
};

export const getGroups = async (opts = {}) => {
    const { page = 1, limit = 20, search, status, state } = opts;
    const skip = (page - 1) * limit;
    const where = {};

    if (search && search.trim()) {
        where.name = { contains: search.trim(), mode: 'insensitive' };
    }

    const [groups, total] = await Promise.all([
        prisma.schoolGroup.findMany({
            where,
            include: {
                schools: {
                    where: { status: { not: 'INACTIVE' } },
                    select: {
                        id: true,
                        name: true,
                        code: true,
                        city: true,
                        state: true,
                        status: true,
                    },
                },
                groupAdmin: {
                    select: { id: true, firstName: true, lastName: true, email: true, lockedUntil: true },
                },
            },
            orderBy: { name: 'asc' },
            skip,
            take: limit,
        }),
        prisma.schoolGroup.count({ where }),
    ]);

    const data = groups.map(mapGroupToResponse);

    return {
        data,
        pagination: {
            page,
            limit,
            total,
            total_pages: Math.ceil(total / limit),
        },
    };
};

export const getGroupById = async (id) => {
    const group = await prisma.schoolGroup.findFirst({
        where: { id: String(id) },
        include: {
            schools: {
                where: { status: { not: 'INACTIVE' } },
                select: {
                    id: true,
                    name: true,
                    code: true,
                    city: true,
                    state: true,
                    status: true,
                    subscriptionPlan: true,
                    subscriptionEnd: true,
                },
            },
            groupAdmin: {
                select: { id: true, firstName: true, lastName: true, email: true, phone: true, lockedUntil: true },
            },
        },
    });
    if (!group) throw new AppError('Group not found', 404);

    const schoolIds = (group.schools || []).map(s => s.id);
    const totalUsers = schoolIds.length > 0
        ? await prisma.user.count({ where: { schoolId: { in: schoolIds }, isActive: true, deletedAt: null } })
        : 0;

    const mapped = mapGroupToResponse(group);
    mapped.student_count = totalUsers;
    return mapped;
};

export const createGroup = async (body) => {
    const name = (body?.name || '').trim();
    if (!name) throw new AppError('Group name is required', 400);

    // Validate name uniqueness (case-insensitive)
    const existingName = await prisma.schoolGroup.findFirst({
        where: { name: { equals: name, mode: 'insensitive' } },
    });
    if (existingName) throw new AppError('A group with this name already exists', 409);

    // Generate or validate slug
    let slug = body?.slug ? String(body.slug).toLowerCase().trim().replace(/[^a-z0-9-]/g, '').slice(0, 100) : generateSlugFromName(name);
    if (!slug) throw new AppError('Could not generate a valid slug from the group name', 400);

    if (RESERVED_SLUGS.includes(slug)) {
        throw new AppError(`The slug "${slug}" is reserved and cannot be used`, 400);
    }

    const existingSlug = await prisma.schoolGroup.findFirst({
        where: { slug },
    });
    if (existingSlug) throw new AppError('A group with this slug already exists', 409);

    const group = await prisma.schoolGroup.create({
        data: {
            name,
            slug,
            type: body?.type || null,
            description: body?.description || null,
            contactPerson: body?.contactPerson || body?.contact_person || null,
            contactEmail: body?.contactEmail || body?.contact_email || null,
            contactPhone: body?.contactPhone || body?.contact_phone || null,
            logoUrl: body?.logoUrl || body?.logo_url || null,
            address: body?.address || null,
            city: body?.city || null,
            state: body?.state || null,
            country: body?.country || 'India',
        },
        include: {
            groupAdmin: {
                select: { id: true, firstName: true, lastName: true, email: true, lockedUntil: true },
            },
        },
    });

    return mapGroupToResponse({ ...group, schools: [] });
};

export const updateGroup = async (id, body) => {
    const groupId = String(id);
    const existing = await prisma.schoolGroup.findFirst({ where: { id: groupId } });
    if (!existing) throw new AppError('Group not found', 404);

    const updateData = {};

    if (body?.name !== undefined) {
        const name = (body.name || '').trim();
        if (!name) throw new AppError('Group name is required', 400);
        // Validate name uniqueness excluding current group
        const existingName = await prisma.schoolGroup.findFirst({
            where: { name: { equals: name, mode: 'insensitive' }, id: { not: groupId } },
        });
        if (existingName) throw new AppError('A group with this name already exists', 409);
        updateData.name = name;
    }

    if (body?.slug !== undefined) {
        const slug = String(body.slug).toLowerCase().trim().replace(/[^a-z0-9-]/g, '').slice(0, 100);
        if (RESERVED_SLUGS.includes(slug)) {
            throw new AppError(`The slug "${slug}" is reserved and cannot be used`, 400);
        }
        const existingSlug = await prisma.schoolGroup.findFirst({
            where: { slug, id: { not: groupId } },
        });
        if (existingSlug) throw new AppError('A group with this slug already exists', 409);
        updateData.slug = slug;
    }

    // Optional fields
    if (body?.type !== undefined) updateData.type = body.type;
    if (body?.description !== undefined) updateData.description = body.description;
    if (body?.contactPerson !== undefined || body?.contact_person !== undefined) updateData.contactPerson = body.contactPerson || body.contact_person;
    if (body?.contactEmail !== undefined || body?.contact_email !== undefined) updateData.contactEmail = body.contactEmail || body.contact_email;
    if (body?.contactPhone !== undefined || body?.contact_phone !== undefined) updateData.contactPhone = body.contactPhone || body.contact_phone;
    if (body?.logoUrl !== undefined || body?.logo_url !== undefined) updateData.logoUrl = body.logoUrl || body.logo_url;
    if (body?.address !== undefined) updateData.address = body.address;
    if (body?.city !== undefined) updateData.city = body.city;
    if (body?.state !== undefined) updateData.state = body.state;
    if (body?.country !== undefined) updateData.country = body.country;
    if (body?.status !== undefined) updateData.status = String(body.status).toUpperCase();

    const group = await prisma.schoolGroup.update({
        where: { id: groupId },
        data: updateData,
        include: {
            schools: {
                where: { status: { not: 'INACTIVE' } },
                select: {
                    id: true,
                    name: true,
                    code: true,
                    city: true,
                    state: true,
                    status: true,
                },
            },
            groupAdmin: {
                select: { id: true, firstName: true, lastName: true, email: true, lockedUntil: true },
            },
        },
    });

    return mapGroupToResponse(group);
};

export const deleteGroup = async (id, adminUserId) => {
    const groupId = String(id);
    const group = await prisma.schoolGroup.findFirst({ where: { id: groupId } });
    if (!group) throw new AppError('Group not found', 404);

    // Unlink all member schools
    await prisma.school.updateMany({
        where: { groupId },
        data: { groupId: null },
    });

    // Deactivate group admin if exists
    if (group.groupAdminUserId) {
        try {
            await prisma.user.update({
                where: { id: group.groupAdminUserId },
                data: { isActive: false },
            });
        } catch (_) { /* user may not exist */ }
    }

    // Delete the group
    await prisma.schoolGroup.delete({ where: { id: groupId } });
};

export const assignGroupAdmin = async (groupId, data, adminUserId) => {
    const gid = String(groupId);
    const group = await prisma.schoolGroup.findFirst({ where: { id: gid } });
    if (!group) throw new AppError('Group not found', 404);

    const email = (data?.admin_email || '').trim().toLowerCase();
    if (!email) throw new AppError('admin_email is required', 400);

    // Find or lookup group_admin role
    let groupAdminRole = await prisma.role.findFirst({ where: { name: 'group_admin' } });
    if (!groupAdminRole) {
        groupAdminRole = await prisma.role.create({
            data: { name: 'group_admin', description: 'Group Administrator', scope: 'GLOBAL' },
        });
    }

    let user = await prisma.user.findFirst({
        where: { email: { equals: email, mode: 'insensitive' } }
    });

    if (user) {
        // Verify not super_admin
        const userRole = await prisma.role.findUnique({ where: { id: user.roleId } });
        if (userRole?.name === 'super_admin') {
            throw new AppError('Cannot assign a super admin as group admin', 400);
        }
        // Verify not already managing a different group
        const otherGroup = await prisma.schoolGroup.findFirst({
            where: { groupAdminUserId: user.id, id: { not: gid } },
        });
        if (otherGroup) {
            throw new AppError(`This user is already managing group "${otherGroup.name}"`, 400);
        }
        // Update role to group_admin
        await prisma.user.update({
            where: { id: user.id },
            data: {
                roleId: groupAdminRole.id,
                isActive: true,
                firstName: data?.first_name || user.firstName,
                lastName: data?.last_name || user.lastName,
                phone: data?.phone || user.phone,
                schoolId: null,
            },
        });
    } else {
        // Create new user
        const tempPassword = data?.password || Math.random().toString(36).slice(-10) + 'A1!';
        const hash = await bcrypt.hash(tempPassword, 12);
        user = await prisma.user.create({
            data: {
                email,
                passwordHash: hash,
                roleId: groupAdminRole.id,
                firstName: data?.first_name || null,
                lastName: data?.last_name || null,
                phone: data?.phone || null,
                isActive: true,
                mustChangePassword: !data?.password,
                schoolId: null,
            },
        });
    }

    // Link admin to group
    await prisma.schoolGroup.update({
        where: { id: gid },
        data: { groupAdminUserId: user.id },
    });

    return {
        group_id: gid,
        admin_user_id: toStr(user.id),
        admin_email: user.email,
        admin_name: `${user.firstName || ''} ${user.lastName || ''}`.trim(),
    };
};

export const resetGroupAdminPassword = async (groupId, newPassword, adminUserId) => {
    const gid = String(groupId);
    const group = await prisma.schoolGroup.findFirst({ where: { id: gid } });
    if (!group) throw new AppError('Group not found', 404);
    if (!group.groupAdminUserId) throw new AppError('This group has no assigned admin', 400);
    if (!newPassword || newPassword.length < 8) throw new AppError('new_password must be at least 8 characters', 400);

    const hash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
        where: { id: group.groupAdminUserId },
        data: { passwordHash: hash, mustChangePassword: true, passwordChangedAt: new Date() },
    });
};

export const lockGroupAdmin = async (groupId, adminUserId) => {
    const gid = String(groupId);
    const group = await prisma.schoolGroup.findFirst({
        where: { id: gid, deletedAt: null },
        select: { groupAdminUserId: true }
    });
    if (!group) throw new AppError('Group not found', 404);
    if (!group.groupAdminUserId) throw new AppError('This group has no assigned admin', 400);

    const lockUntil = new Date(Date.now() + 30 * 60 * 1000);
    const { updateUserFailedAttempts } = await import('../auth/auth.repository.js');
    await updateUserFailedAttempts(group.groupAdminUserId, 5, lockUntil);
};

export const unlockGroupAdmin = async (groupId, adminUserId) => {
    const gid = String(groupId);
    const group = await prisma.schoolGroup.findFirst({
        where: { id: gid, deletedAt: null },
        select: { groupAdminUserId: true }
    });
    if (!group) throw new AppError('Group not found', 404);
    if (!group.groupAdminUserId) throw new AppError('This group has no assigned admin', 400);

    const { updateUserFailedAttempts } = await import('../auth/auth.repository.js');
    await updateUserFailedAttempts(group.groupAdminUserId, 0, null);
};

export const deactivateGroupAdmin = async (groupId, adminUserId) => {
    const gid = String(groupId);
    const group = await prisma.schoolGroup.findFirst({ where: { id: gid } });
    if (!group) throw new AppError('Group not found', 404);
    if (!group.groupAdminUserId) throw new AppError('This group has no assigned admin', 400);

    await prisma.user.update({
        where: { id: group.groupAdminUserId },
        data: { isActive: false },
    });
    await prisma.schoolGroup.update({
        where: { id: gid },
        data: { groupAdminUserId: null },
    });
};

export const addSchoolToGroup = async (groupId, schoolId) => {
    const groupIdStr = String(groupId);
    const schoolIdStr = String(schoolId);

    const group = await prisma.schoolGroup.findFirst({ where: { id: groupIdStr } });
    if (!group) throw new AppError('Group not found', 404);

    const school = await prisma.school.findUnique({ where: { id: schoolIdStr } });
    if (!school) throw new AppError('School not found', 404);

    await prisma.school.update({
        where: { id: schoolIdStr },
        data: { groupId: groupIdStr },
    });
};

export const removeSchoolFromGroup = async (groupId, schoolId) => {
    const schoolIdStr = String(schoolId);

    const school = await prisma.school.findUnique({ where: { id: schoolIdStr } });
    if (!school) throw new AppError('School not found', 404);
    if (school.groupId !== String(groupId)) throw new AppError('School is not in this group', 400);

    await prisma.school.update({
        where: { id: schoolIdStr },
        data: { groupId: null },
    });
};

// ── Plans ──────────────────────────────────────────────────────────────────
const BUILT_IN_PLAN_NAMES = ['Basic', 'Standard', 'Premium'];
const BUILT_IN_DEFAULTS = { Basic: 99, Standard: 199, Premium: 499 };

/** Ensure Basic, Standard, Premium exist in platform_plans so they can be edited */
const ensureBuiltInPlans = async () => {
    for (const name of BUILT_IN_PLAN_NAMES) {
        const existing = await prisma.platformPlan.findFirst({ where: { name } });
        if (!existing) {
            await prisma.platformPlan.create({
                data: {
                    name,
                    description: null,
                    price: BUILT_IN_DEFAULTS[name] ?? 99,
                    maxBranches: 1,
                    maxUsers: 500,
                    isActive: true,
                },
            });
        }
    }
};

export const getPlans = async () => {
    try {
        await ensureBuiltInPlans();

        const counts = await prisma.school.groupBy({
            by: ['subscriptionPlan'],
            where: { status: 'ACTIVE' },
            _count: { id: true },
        }).catch(() => []);
        const countMap = Object.fromEntries((counts || []).map((c) => [c.subscriptionPlan, c._count.id]));

        const plans = await plansRepo.getAllPlans({});
        const builtInNames = new Set(BUILT_IN_PLAN_NAMES);
        const builtIn = [];
        const custom = [];
        const nameToEnum = { Basic: 'BASIC', Standard: 'STANDARD', Premium: 'PREMIUM' };
        for (const p of plans || []) {
            const mapped = mapPlanToResponse(p, { school_count: p.active_school_count || 0 });
            const schoolCount = countMap[nameToEnum[p.name]] ?? mapped.school_count ?? 0;
            const withCount = { ...mapped, school_count: schoolCount };
            if (builtInNames.has(p.name)) {
                builtIn.push(withCount);
            } else {
                custom.push(withCount);
            }
        }
        builtIn.sort((a, b) => BUILT_IN_PLAN_NAMES.indexOf(a.name) - BUILT_IN_PLAN_NAMES.indexOf(b.name));
        const data = [...builtIn, ...custom];
        return { data };
    } catch (err) {
        // PlatformPlan/SchoolSubscription may not exist in current Prisma schema — use enum fallback
        const msg = err?.message || '';
        if (msg.includes('findMany') || msg.includes('platformPlan') || msg.includes('undefined') || msg.includes('Cannot read properties')) {
            const planEnums = ['BASIC', 'STANDARD', 'PREMIUM'];
            const planNames = { BASIC: 'Basic', STANDARD: 'Standard', PREMIUM: 'Premium' };
            const planPrices = { BASIC: 99, STANDARD: 199, PREMIUM: 499 };
            const counts = await prisma.school.groupBy({
                by: ['subscriptionPlan'],
                where: { status: 'ACTIVE' },
                _count: { id: true },
            });
            const countMap = Object.fromEntries(counts.map((c) => [c.subscriptionPlan, c._count.id]));
            const data = planEnums.map((slug) => mapPlanToResponse({
                id: slug,
                name: planNames[slug] || slug,
                slug,
                priceMonthly: planPrices[slug] || 0,
                maxStudents: 500,
                isActive: true,
                status: 'active',
            }, { school_count: countMap[slug] || 0 }));
            return { data };
        }
        throw err;
    }
};

export const getPlanById = async (id) => {
    const plan = await plansRepo.findPlanById(id);
    return plan ? mapPlanToResponse(plan) : null;
};

export const createPlan = async (body) => {
    const data = {
        name: body.name,
        description: body.description || null,
        price: Number(body.price_per_student ?? body.price_monthly ?? 0),
        maxBranches: body.max_branches ?? 1,
        maxUsers: body.max_students ?? 500,
    };
    const plan = await plansRepo.createPlan(data);
    return mapPlanToResponse(plan);
};

export const updatePlan = async (id, body) => {
    try {
        const data = {};
        if (body.name != null) data.name = body.name;
        if (body.description !== undefined) data.description = body.description || null;
        if (body.price_per_student != null) data.price = Number(body.price_per_student);
        if (body.max_students != null) data.maxUsers = Number(body.max_students);
        if (Object.keys(data).length === 0) {
            throw new AppError('No valid fields to update. Provide at least one of: name, description, price_per_student, max_students.', 400);
        }
        const plan = await plansRepo.updatePlan(id, data);
        return mapPlanToResponse(plan);
    } catch (err) {
        const msg = err?.message || '';
        if (msg.includes('platformPlan') || msg.includes('undefined') || msg.includes('Cannot read properties')) {
            throw new AppError('Plans table is not available. Built-in plans cannot be edited.', 400);
        }
        throw err;
    }
};

export const updatePlanStatus = async (id, status) => {
    try {
        const isActive = status === 'active';
        await plansRepo.updatePlanStatus(id, isActive);
        const plan = await plansRepo.findPlanById(id);
        return plan ? mapPlanToResponse(plan) : null;
    } catch (err) {
        const msg = err?.message || '';
        if (msg.includes('platformPlan') || msg.includes('undefined') || msg.includes('Cannot read properties')) {
            throw new AppError('Plans table is not available. Built-in plans cannot be edited.', 400);
        }
        throw err;
    }
};

// ── Billing / Subscriptions ─────────────────────────────────────────────────
const PLAN_PRICES = { BASIC: 99, STANDARD: 199, PREMIUM: 499 };

/** Fallback: derive subscriptions from School model when SchoolSubscription doesn't exist */
const getSubscriptionsFromSchools = async (opts) => {
    const page = opts.page ?? 1;
    const limit = opts.limit ?? 20;
    const skip = (page - 1) * limit;
    const now = new Date();

    const where = {};
    if (opts.status) {
        const s = String(opts.status).toUpperCase();
        if (s === 'ACTIVE') where.status = 'ACTIVE';
        else if (s === 'SUSPENDED' || s === 'INACTIVE') where.status = { in: ['SUSPENDED', 'INACTIVE'] };
        else if (s === 'EXPIRED') where.subscriptionEnd = { lt: now };
    }
    if (opts.search && String(opts.search).trim()) {
        where.name = { contains: String(opts.search).trim(), mode: 'insensitive' };
    }
    if (opts.expiring_days != null) {
        const days = parseInt(opts.expiring_days, 10) || 30;
        const end = new Date(now);
        end.setDate(end.getDate() + days);
        where.subscriptionEnd = { gte: now, lte: end };
    }

    const [schools, total] = await Promise.all([
        prisma.school.findMany({
            where,
            orderBy: { subscriptionEnd: 'asc' },
            skip,
            take: limit,
        }),
        prisma.school.count({ where }),
    ]);

    const data = schools.map((s) => {
        const plan = String(s.subscriptionPlan || 'BASIC').toUpperCase();
        const planName = PLAN_NAMES[plan] || plan;
        const priceMonthly = PLAN_PRICES[plan] ?? 0;
        const endDate = s.subscriptionEnd || new Date();
        const startDate = s.subscriptionStart || new Date(endDate);
        startDate.setMonth(startDate.getMonth() - 12);
        const isExpired = endDate < now;
        const status = isExpired ? 'expired' : (s.status === 'ACTIVE' ? 'active' : String(s.status || '').toLowerCase());
        return {
            id: toStr(s.id),
            school_id: toStr(s.id),
            school_name: s.name || '',
            plan_id: plan,
            plan_name: planName,
            status,
            price_per_student: priceMonthly,
            monthly_amount: priceMonthly,
            student_count: 0,
            duration_months: 12,
            start_date: startDate,
            end_date: endDate,
            payment_ref: null,
        };
    });

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

export const getSubscriptions = async (opts = {}) => {
    const page = opts.page ?? 1;
    const limit = opts.limit ?? 20;
    const skip = (page - 1) * limit;
    const where = opts.status ? { status: opts.status.toUpperCase() } : {};

    try {
        if (!prisma.schoolSubscription) {
            return getSubscriptionsFromSchools(opts);
        }
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
    } catch (err) {
        const msg = err?.message || '';
        if (msg.includes('findMany') || msg.includes('schoolSubscription') || msg.includes('undefined') || msg.includes('Cannot read properties')) {
            return getSubscriptionsFromSchools(opts);
        }
        throw err;
    }
};

export const renewSubscription = async (schoolId, body) => {
    const planId = body.plan_id || body.planId;
    const durationMonths = body.duration_months ?? 12;
    const schoolIdStr = String(schoolId);
    const school = await prisma.school.findUnique({ where: { id: schoolIdStr } });
    if (!school) throw new Error('School not found');

    const now = new Date();
    // Extend from current end date if subscription is still active; otherwise from today
    const baseDate = school.subscriptionEnd && new Date(school.subscriptionEnd) > now
        ? new Date(school.subscriptionEnd)
        : now;
    const startDate = school.subscriptionEnd && new Date(school.subscriptionEnd) > now
        ? (school.subscriptionStart ? new Date(school.subscriptionStart) : baseDate)
        : now;
    const endDate = new Date(baseDate);
    endDate.setMonth(endDate.getMonth() + durationMonths);

    const subscriptionPlan = await mapPlanToSubscriptionPlan(planId);
    const isEnumPlanId = ['BASIC', 'STANDARD', 'PREMIUM'].includes(String(planId || '').toUpperCase());

    try {
        if (!isEnumPlanId && /^\d+$/.test(String(planId))) {
            const plan = await plansRepo.findPlanById(planId);
            if (!plan) throw new Error('Plan not found');

            const planIdVal = BigInt(planId);
            if (prisma.schoolSubscription) {
                await prisma.schoolSubscription.create({
                    data: {
                        schoolId: schoolIdStr,
                        planId: planIdVal,
                        startDate,
                        endDate,
                        billingCycle: durationMonths >= 12 ? 'YEARLY' : 'MONTHLY',
                        priceAmount: plan.priceMonthly ?? plan.price ?? 0,
                        currency: 'INR',
                        status: 'ACTIVE',
                    },
                });
            }
        }

        await prisma.school.update({
            where: { id: schoolIdStr },
            data: {
                subscriptionPlan,
                subscriptionStart: startDate,
                subscriptionEnd: endDate,
                status: 'ACTIVE',
            },
        });
    } catch (err) {
        const msg = err?.message || '';
        if (
            msg.includes('findUnique') ||
            msg.includes('platformPlan') ||
            msg.includes('schoolSubscription') ||
            msg.includes('undefined') ||
            msg.includes('Cannot read properties') ||
            msg.includes('BigInt') ||
            msg.includes('Cannot convert')
        ) {
            // PlatformPlan/SchoolSubscription may not exist — use subscriptionPlan enum
            await prisma.school.update({
                where: { id: schoolIdStr },
                data: {
                    subscriptionPlan,
                    subscriptionStart: startDate,
                    subscriptionEnd: endDate,
                    status: 'ACTIVE',
                },
            });
        } else {
            throw err;
        }
    }

    return { success: true };
};

/** Map plan_id (string or plan table id) to subscriptionPlan enum */
const mapPlanToSubscriptionPlan = async (planId) => {
    const upper = String(planId || '').toUpperCase();
    if (['BASIC', 'STANDARD', 'PREMIUM'].includes(upper)) return upper;
    try {
        const plan = await plansRepo.findPlanById(planId);
        if (plan?.name) {
            const name = String(plan.name).toUpperCase();
            if (['BASIC', 'STANDARD', 'PREMIUM'].includes(name)) return name;
        }
    } catch (_) {}
    return 'BASIC';
};

export const assignPlan = async (schoolId, body) => {
    const planId = body.plan_id || body.planId;
    const subscriptionPlan = await mapPlanToSubscriptionPlan(planId);
    const updateData = { subscriptionPlan };
    const effectiveDate = body.effective_date || body.subscription_end || body.renewal_date;
    if (effectiveDate) {
        const d = new Date(effectiveDate);
        if (!isNaN(d.getTime())) updateData.subscriptionEnd = d;
    }
    if (body.subscription_start) {
        const startD = new Date(body.subscription_start);
        if (!isNaN(startD.getTime())) updateData.subscriptionStart = startD;
    }
    await prisma.school.update({
        where: { id: String(schoolId) },
        data: updateData,
    });
    return { success: true };
};

export const resolveOverdue = async (schoolId, body) => {
    const schoolIdStr = String(schoolId);
    const action = body.action || 'paid';
    if (action === 'paid') {
        const school = await prisma.school.findUnique({ where: { id: schoolIdStr } });
        const planId = body.plan_id || body.planId || school?.subscriptionPlan || 'BASIC';
        await renewSubscription(schoolId, { plan_id: planId, duration_months: 12, payment_ref: body.payment_ref });
    } else if (action === 'grace_period') {
        const school = await prisma.school.findUnique({ where: { id: schoolIdStr } });
        const now = new Date();
        const endDate = new Date(school?.subscriptionEnd && new Date(school.subscriptionEnd) > now ? school.subscriptionEnd : now);
        endDate.setDate(endDate.getDate() + 7);
        await prisma.school.update({
            where: { id: schoolIdStr },
            data: { subscriptionEnd: endDate, status: 'ACTIVE' },
        });
    } else if (action === 'terminate') {
        await prisma.school.update({
            where: { id: schoolIdStr },
            data: { status: 'SUSPENDED' },
        });
    }
    return { success: true };
};

// ── Features ────────────────────────────────────────────────────────────────
/** Default platform features when DB table is empty (matches Global Feature Flags UI) */
const DEFAULT_PLATFORM_FEATURES = [
    { feature_key: 'rfid_attendance', feature_name: 'RFID Attendance Engine', description: 'All RFID readers across platform', category: 'feature', is_enabled: true },
    { feature_key: 'gps_transport', feature_name: 'GPS Transport Engine', description: 'Live vehicle tracking for all schools', category: 'feature', is_enabled: true },
    { feature_key: 'ai_intelligence', feature_name: 'AI Intelligence Engine', description: 'Anomaly detection and predictions', category: 'feature', is_enabled: true },
    { feature_key: 'parent_app', feature_name: 'Parent Mobile App', description: 'App access for all parents', category: 'feature', is_enabled: true },
    { feature_key: 'chat_system', feature_name: 'Chat System', description: 'In-app messaging globally', category: 'feature', is_enabled: true },
    { feature_key: 'online_payments', feature_name: 'Online Payments', description: 'Razorpay / UPI integration', category: 'feature', is_enabled: true },
    { feature_key: 'biometric', feature_name: 'Biometric Module', description: 'Fingerprint / face recognition', category: 'feature', is_enabled: false },
    { feature_key: 'certificates', feature_name: 'Certificate Generator', description: 'Auto-generate school certificates', category: 'feature', is_enabled: true },
    { feature_key: 'maintenance_mode', feature_name: 'Maintenance Mode', description: 'Shows maintenance page to all users', category: 'system', is_enabled: false },
    { feature_key: 'new_registrations', feature_name: 'New Registrations', description: 'Allow new school onboarding', category: 'system', is_enabled: true },
    { feature_key: 'email_notifications', feature_name: 'Email Notifications', description: 'System email delivery', category: 'system', is_enabled: true },
    { feature_key: 'sms_gateway', feature_name: 'SMS Gateway', description: 'OTP and alert SMS delivery', category: 'system', is_enabled: true },
    { feature_key: 'push_notifications', feature_name: 'Push Notifications', description: 'Mobile push via FCM', category: 'system', is_enabled: true },
    { feature_key: 'ai_auto_alerts', feature_name: 'AI Auto-Alerts', description: 'Proactive AI-generated alerts', category: 'system', is_enabled: true },
];

export const getPlatformFeatures = async () => {
    try {
        const rows = await prisma.$queryRaw`
            SELECT id, feature_key, feature_name, description, category, is_enabled
            FROM platform_features
            ORDER BY category, feature_key
        `;
        if (Array.isArray(rows) && rows.length > 0) {
            const data = rows.map((r) => ({
                id: r.id?.toString?.() ?? String(r.id),
                feature_key: r.feature_key,
                feature_name: r.feature_name,
                description: r.description ?? null,
                category: r.category ?? 'feature',
                is_enabled: r.is_enabled !== false,
            }));
            return { data };
        }
    } catch (err) {
        if (err?.code === '42P01' || err?.message?.includes('does not exist')) {
            return { data: DEFAULT_PLATFORM_FEATURES.map((f, i) => ({
                id: `fallback-${i}`,
                ...f,
            })) };
        }
        throw err;
    }
    return { data: DEFAULT_PLATFORM_FEATURES.map((f, i) => ({ id: `fallback-${i}`, ...f })) };
};

export const togglePlatformFeature = async (featureKey, isEnabled) => {
    const key = String(featureKey || '').trim().toLowerCase();
    if (!key) return;
    try {
        const updated = await prisma.$executeRaw`
            UPDATE platform_features SET is_enabled = ${!!isEnabled}, updated_at = NOW()
            WHERE feature_key = ${key}
        `;
        if (updated === 0) {
            await prisma.$executeRaw`
                INSERT INTO platform_features (feature_key, feature_name, description, category, is_enabled)
                SELECT ${key}, ${key}, '', 'feature', ${!!isEnabled}
                WHERE NOT EXISTS (SELECT 1 FROM platform_features WHERE feature_key = ${key})
            `;
        }
    } catch (err) {
        if (err?.code === '42P01' || err?.message?.includes('does not exist')) {
            return;
        }
        throw err;
    }
};

const DEFAULT_FEATURE_KEYS = ['rfid_attendance', 'gps_transport', 'ai_intelligence', 'parent_app', 'chat_system', 'online_payments', 'certificates', 'attendance', 'fees', 'exams', 'timetable', 'library', 'transport', 'hostel', 'reports'];

export const getSchoolFeatures = async (schoolId) => {
    const id = String(schoolId);
    const rows = await prisma.$queryRaw`
        SELECT feature_name, is_enabled FROM school_features WHERE school_id = ${id}::uuid
    `;
    const map = {};
    for (const r of rows || []) {
        const key = (r.feature_name || '').toString().toLowerCase();
        if (key) map[key] = !!r.is_enabled;
    }
    return map;
};

export const toggleSchoolFeature = async (schoolId, featureKey, isEnabled) => {
    const id = String(schoolId);
    const key = String(featureKey || '').toLowerCase();
    if (!key) return;
    const updated = await prisma.$executeRaw`
        UPDATE school_features SET is_enabled = ${isEnabled}
        WHERE school_id = ${id}::uuid AND feature_name = ${key}
    `;
    if (updated === 0) {
        await prisma.$executeRaw`
            INSERT INTO school_features (school_id, feature_name, is_enabled)
            VALUES (${id}::uuid, ${key}, ${isEnabled})
        `;
    }
};

// ── Hardware ───────────────────────────────────────────────────────────────
const mapHardwareRow = (r) => ({
    id: r.id,
    device_id: r.device_id,
    device_type: r.device_type || 'rfid',
    status: r.status || 'online',
    school_id: r.school_id,
    school_name: r.school_name || null,
    location_label: r.location_label || null,
    firmware_version: r.firmware_version || null,
    ip_address: r.ip_address?.toString?.() ?? r.ip_address ?? null,
    last_ping_at: r.last_ping_at || null,
    created_at: r.created_at || null,
});

export const getHardware = async (opts = {}) => {
    const page = Math.max(1, opts.page ?? 1);
    const limit = Math.min(100, Math.max(1, opts.limit ?? 50));
    const offset = (page - 1) * limit;
    const schoolId = opts.school_id || opts.schoolId;
    const deviceType = opts.device_type || opts.deviceType;
    const status = opts.status;
    const search = (opts.search || '').trim();

    try {
        let whereClause = '1=1';
        const params = [];
        let paramIdx = 1;

        if (schoolId) {
            params.push(schoolId);
            whereClause += ` AND h.school_id = $${paramIdx++}::uuid`;
        }
        if (deviceType) {
            params.push(deviceType);
            whereClause += ` AND h.device_type = $${paramIdx++}`;
        }
        if (status) {
            params.push(status);
            whereClause += ` AND h.status = $${paramIdx++}`;
        }
        if (search) {
            params.push(`%${search}%`);
            whereClause += ` AND (h.device_id ILIKE $${paramIdx} OR h.location_label ILIKE $${paramIdx})`;
            paramIdx++;
        }

        const countResult = await prisma.$queryRawUnsafe(
            `SELECT COUNT(*)::int AS total FROM hardware_devices h WHERE ${whereClause}`,
            ...params
        );
        const total = (countResult?.[0]?.total ?? 0) || 0;

        params.push(limit, offset);
        const rows = await prisma.$queryRawUnsafe(
            `SELECT h.id, h.device_id, h.device_type, h.status, h.school_id, h.location_label,
                    h.firmware_version, h.ip_address, h.last_ping_at, h.created_at, s.name AS school_name
             FROM hardware_devices h
             LEFT JOIN schools s ON s.id = h.school_id
             WHERE ${whereClause}
             ORDER BY h.created_at DESC
             LIMIT $${paramIdx} OFFSET $${paramIdx + 1}`,
            ...params
        );

        const data = (rows || []).map(mapHardwareRow);
        return {
            data,
            pagination: {
                page,
                limit,
                total,
                total_pages: Math.ceil(total / limit) || 1,
            },
        };
    } catch (err) {
        if (err.code === '42P01' || err.message?.includes('does not exist')) {
            return {
                data: [],
                pagination: { page, limit, total: 0, total_pages: 1 },
            };
        }
        throw err;
    }
};

export const registerHardware = async (body) => {
    const deviceId = (body.device_id || body.deviceId || '').trim();
    if (!deviceId) throw new Error('device_id is required');

    const deviceType = (body.device_type || body.deviceType || 'rfid').trim().toLowerCase();
    const schoolId = body.school_id || body.schoolId || null;
    const locationLabel = body.location_label || body.locationLabel || null;
    const firmwareVersion = body.firmware_version || body.firmwareVersion || null;

    const rows = await prisma.$queryRawUnsafe(
        `INSERT INTO hardware_devices (device_id, device_type, status, school_id, location_label, firmware_version)
         VALUES ($1, $2, 'online', $3::uuid, $4, $5)
         RETURNING id, device_id, device_type, status, school_id, location_label, firmware_version, ip_address, last_ping_at, created_at`,
        deviceId,
        deviceType,
        schoolId,
        locationLabel,
        firmwareVersion
    );
    return mapHardwareRow(rows[0] || {});
};

export const updateHardware = async (id, body) => {
    const updates = [];
    const params = [];
    let paramIdx = 1;

    if (body.device_type !== undefined) {
        params.push(body.device_type);
        updates.push(`device_type = $${paramIdx++}`);
    }
    if (body.status !== undefined) {
        params.push(body.status);
        updates.push(`status = $${paramIdx++}`);
    }
    if (body.school_id !== undefined) {
        params.push(body.school_id);
        updates.push(`school_id = $${paramIdx++}::uuid`);
    }
    if (body.location_label !== undefined) {
        params.push(body.location_label);
        updates.push(`location_label = $${paramIdx++}`);
    }
    if (body.firmware_version !== undefined) {
        params.push(body.firmware_version);
        updates.push(`firmware_version = $${paramIdx++}`);
    }

    if (updates.length === 0) return null;

    params.push(id);
    updates.push(`updated_at = NOW()`);

    const rows = await prisma.$queryRawUnsafe(
        `UPDATE hardware_devices SET ${updates.join(', ')} WHERE id = $${paramIdx}::uuid RETURNING *`,
        ...params
    );
    return rows?.[0] ? mapHardwareRow(rows[0]) : null;
};

export const pingDevice = async (id) => {
    const rows = await prisma.$queryRawUnsafe(
        `UPDATE hardware_devices SET last_ping_at = NOW(), status = 'online', updated_at = NOW()
         WHERE id = $1::uuid RETURNING *`,
        id
    );
    return rows?.[0] ? mapHardwareRow(rows[0]) : null;
};

export const deleteDevice = async (id) => {
    await prisma.$executeRawUnsafe(`DELETE FROM hardware_devices WHERE id = $1::uuid`, id);
};

// ── Admins (super admin users: school_id IS NULL) ───────────────────────────
const mapSuperAdminUser = (u) => {
    const name = [u.first_name, u.last_name].filter(Boolean).join(' ') || u.email || '';
    return {
        id: u.id,
        user_id: u.id,
        role: u.role_name || 'super_admin',
        name,
        email: u.email,
        mobile: u.phone || null,
        is_active: u.is_active !== false,
        totp_enabled: u.mfa_enabled === true,
        last_login: u.last_login || null,
        last_login_ip: u.last_login_ip?.toString?.() ?? u.last_login_ip ?? null,
    };
};

export const getSuperAdmins = async () => {
    const rows = await prisma.$queryRawUnsafe(`
        SELECT u.id, u.email, u.first_name, u.last_name, u.phone, u.is_active, u.mfa_enabled,
               u.last_login, u.last_login_ip, r.name AS role_name
        FROM users u
        JOIN roles r ON r.id = u.role_id
        WHERE u.school_id IS NULL AND u.deleted_at IS NULL
        ORDER BY u.created_at ASC
    `);
    return {
        data: (rows || []).map(mapSuperAdminUser),
    };
};

export const addSuperAdmin = async (body) => {
    const email = (body.email || '').trim().toLowerCase();
    if (!email) throw new Error('email is required');

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw new Error('User with this email already exists');

    let platformRole = await prisma.role.findFirst({
        where: {
            scope: 'GLOBAL',
        },
    });
    if (!platformRole) {
        platformRole = await prisma.role.findFirst({
            where: { name: { contains: 'super', mode: 'insensitive' } },
        });
    }
    if (!platformRole) {
        platformRole = await prisma.role.create({
            data: {
                name: 'super_admin',
                scope: 'GLOBAL',
                description: 'Super Administrator',
            },
        });
    }

    const nameParts = (body.name || '').trim().split(/\s+/);
    const firstName = nameParts[0] || '';
    const lastName = nameParts.slice(1).join(' ') || null;
    const tempPassword = body.temp_password || body.tempPassword || null;
    const defaultPassword = 'Password@123';
    const passwordToUse = tempPassword && tempPassword.length >= 8
        ? await bcrypt.hash(tempPassword, 10)
        : await bcrypt.hash(defaultPassword, 10);

    const user = await prisma.user.create({
        data: {
            email,
            passwordHash: passwordToUse,
            firstName: firstName || email.split('@')[0],
            lastName: lastName,
            phone: body.mobile || body.phone || null,
            roleId: platformRole.id,
            isActive: true,
            mustChangePassword: !tempPassword || tempPassword.length < 8,
        },
    });
    return mapSuperAdminUser({ ...user, role_name: platformRole.name });
};

export const updateSuperAdmin = async (id, body) => {
    const updates = {};
    if (body.name !== undefined) {
        const parts = (body.name || '').trim().split(/\s+/);
        updates.firstName = parts[0] || undefined;
        updates.lastName = parts.slice(1).join(' ') || undefined;
    }
    if (body.mobile !== undefined || body.phone !== undefined) {
        updates.phone = body.mobile ?? body.phone ?? undefined;
    }
    if (body.is_active !== undefined) {
        updates.isActive = !!body.is_active;
    }
    if (body.role !== undefined) {
        const role = await prisma.role.findFirst({
            where: {
                OR: [
                    { scope: 'GLOBAL' },
                    { name: { contains: body.role, mode: 'insensitive' } },
                ],
            },
        });
        if (role) updates.roleId = role.id;
    }
    if (Object.keys(updates).length === 0) return null;

    const user = await prisma.user.update({
        where: { id },
        data: updates,
        include: { role: true },
    });
    return mapSuperAdminUser({ ...user, role_name: user.role?.name });
};

export const removeSuperAdmin = async (id) => {
    await prisma.user.update({
        where: { id },
        data: { deletedAt: new Date(), isActive: false },
    });
};

/** Change password for the currently logged-in super admin (requires current password) */
export const changePassword = async (userId, currentPassword, newPassword) => {
    const user = await prisma.user.findFirst({
        where: {
            id: String(userId),
            schoolId: null,
            deletedAt: null,
        },
    });
    if (!user) throw new Error('User not found');

    const valid = await bcrypt.compare(String(currentPassword), user.passwordHash);
    if (!valid) throw new Error('Current password is incorrect');

    const password = (newPassword || '').trim();
    if (password.length < 8) throw new Error('New password must be at least 8 characters');

    const passwordHash = await bcrypt.hash(password, 10);
    await prisma.user.update({
        where: { id: userId },
        data: {
            passwordHash,
            passwordChangedAt: new Date(),
            mustChangePassword: false,
            resetPasswordToken: null,
            resetPasswordExpires: null,
        },
    });
};

/** Reset super admin password to a new value (default: Password@123) */
export const resetSuperAdminPassword = async (id, newPassword) => {
    const user = await prisma.user.findFirst({
        where: {
            id: String(id),
            schoolId: null,
            deletedAt: null,
        },
    });
    if (!user) throw new Error('Admin user not found');

    const password = (newPassword || 'Password@123').trim();
    if (password.length < 8) throw new Error('Password must be at least 8 characters');

    const passwordHash = await bcrypt.hash(password, 10);
    await prisma.user.update({
        where: { id },
        data: {
            passwordHash,
            passwordChangedAt: new Date(),
            mustChangePassword: true,
            resetPasswordToken: null,
            resetPasswordExpires: null,
        },
    });
};

// ── Audit ───────────────────────────────────────────────────────────────────
const ENTITY_TYPE_MAP = {
    'super-admin': null,  // all
    schools: 'schools',
    plans: 'plans',
    billing: 'billing',
    features: 'features',
    security: 'security',
    hardware: 'hardware',
    groups: 'groups',
};

export const getAuditLogs = async (type, opts = {}) => {
    const page = Math.max(1, opts.page ?? 1);
    const limit = Math.min(100, Math.max(1, opts.limit ?? 50));
    const offset = (page - 1) * limit;
    const search = (opts.search || '').trim();
    const dateFrom = opts.date_from || opts.dateFrom;
    const dateTo = opts.date_to || opts.dateTo;
    const entityType = ENTITY_TYPE_MAP[type] ?? null;

    try {
        let whereClause = '1=1';
        const params = [];
        let paramIdx = 1;

        if (entityType) {
            params.push(entityType);
            whereClause += ` AND entity_type = $${paramIdx++}`;
        }
        if (dateFrom) {
            params.push(new Date(dateFrom));
            whereClause += ` AND created_at >= $${paramIdx++}::timestamptz`;
        }
        if (dateTo) {
            params.push(new Date(dateTo));
            whereClause += ` AND created_at <= $${paramIdx++}::timestamptz`;
        }
        if (search) {
            params.push(`%${search}%`);
            whereClause += ` AND (action ILIKE $${paramIdx} OR actor_name ILIKE $${paramIdx} OR entity_name ILIKE $${paramIdx})`;
            paramIdx++;
        }

        const countResult = await prisma.$queryRawUnsafe(
            `SELECT COUNT(*)::int AS total FROM audit_super_admin_logs WHERE ${whereClause}`,
            ...params
        );
        const total = (countResult?.[0]?.total ?? 0) || 0;

        params.push(limit, offset);
        const rows = await prisma.$queryRawUnsafe(
            `SELECT id, actor_id, actor_name, actor_role, action, entity_type, entity_id, entity_name,
                    ip_address, request_data, response_status, created_at
             FROM audit_super_admin_logs
             WHERE ${whereClause}
             ORDER BY created_at DESC
             LIMIT $${paramIdx} OFFSET $${paramIdx + 1}`,
            ...params
        );

        const data = (rows || []).map((r) => ({
            id: r.id,
            action: r.action,
            actor_name: r.actor_name,
            actor_ip: r.ip_address?.toString?.() ?? r.ip_address,
            entity_name: r.entity_name,
            entity_type: r.entity_type,
            description: r.request_data ? JSON.stringify(r.request_data) : null,
            status: r.response_status,
            created_at: r.created_at,
            old_data: r.request_data?.old_value ?? null,
            new_data: r.request_data?.new_value ?? r.request_data ?? null,
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
    } catch (err) {
        if (err.code === '42P01' || err.message?.includes('does not exist')) {
            return {
                data: [],
                pagination: { page, limit, total: 0, total_pages: 1 },
            };
        }
        throw err;
    }
};

// ── Security ─────────────────────────────────────────────────────────────────
export const getSecurityEvents = async ({ page = 1, limit = 30 } = {}) => {
    try {
        const skip = (page - 1) * limit;
        const rows = await prisma.$queryRawUnsafe(`
            SELECT id, actor_name, actor_role, action, entity_type, entity_id, entity_name,
                   ip_address, request_data, response_status, created_at
            FROM audit_super_admin_logs
            WHERE entity_type IN ('security', 'auth', 'super_admin')
               OR action IN ('LOGIN', 'LOGOUT', 'FAILED_LOGIN', '2FA_ENABLED', '2FA_DISABLED',
                             'CHANGE_PASSWORD', 'RESET_SUPER_ADMIN_PASSWORD', 'REVOKE_DEVICE',
                             'BLOCK_IP', 'DEVICE_TRUST', 'DEVICE_REVOKE')
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2
        `, limit, skip);
        const total = await prisma.$queryRawUnsafe(`
            SELECT COUNT(*)::int AS count FROM audit_super_admin_logs
            WHERE entity_type IN ('security', 'auth', 'super_admin')
               OR action IN ('LOGIN', 'LOGOUT', 'FAILED_LOGIN', '2FA_ENABLED', '2FA_DISABLED',
                             'CHANGE_PASSWORD', 'RESET_SUPER_ADMIN_PASSWORD', 'REVOKE_DEVICE',
                             'BLOCK_IP', 'DEVICE_TRUST', 'DEVICE_REVOKE')
        `);
        const data = (rows || []).map((r) => ({
            id: r.id,
            actor_name: r.actor_name || 'System',
            actor_role: r.actor_role || 'super_admin',
            action: r.action,
            entity_type: r.entity_type,
            entity_name: r.entity_name || null,
            ip_address: r.ip_address || null,
            status: r.response_status || 'success',
            description: r.request_data?.description || r.action,
            created_at: r.created_at,
        }));
        return {
            data,
            pagination: { page, limit, total: total[0]?.count ?? 0, total_pages: Math.ceil((total[0]?.count ?? 0) / limit) || 1 },
        };
    } catch (_) {
        return { data: [], pagination: { page: 1, limit, total: 0, total_pages: 1 } };
    }
};

export const getTrustedDevices = async () => {
    try {
        const rows = await prisma.$queryRawUnsafe(`
            SELECT rd.id, rd.device_name, rd.device_type, rd.browser, rd.os, rd.ip_address,
                   rd.city, rd.country, rd.is_trusted, rd.trusted_until, rd.last_used_at,
                   u.email AS user_email, u.first_name, u.last_name
            FROM registered_devices rd
            INNER JOIN users u ON u.id = rd.user_id
            INNER JOIN roles r ON r.id = u.role_id AND r.name = 'super_admin'
            WHERE rd.is_trusted = TRUE
            ORDER BY rd.last_used_at DESC
            LIMIT 50
        `);
        const data = (rows || []).map((r) => ({
            id: r.id,
            device_name: r.device_name || 'Unknown Device',
            device_type: r.device_type || 'unknown',
            browser: r.browser || null,
            os: r.os || null,
            ip_address: r.ip_address || null,
            city: r.city || null,
            country: r.country || null,
            trusted_until: r.trusted_until || null,
            last_used_at: r.last_used_at || null,
            user_email: r.user_email || null,
            user_name: [r.first_name, r.last_name].filter(Boolean).join(' ') || r.user_email || 'Unknown',
        }));
        return { data };
    } catch (_) {
        return { data: [] };
    }
};

export const revokeDevice = async (deviceId, adminUserId) => {
    try {
        await prisma.$executeRawUnsafe(`
            UPDATE registered_devices SET is_trusted = false, trusted_until = NULL
            WHERE id = $1::uuid
        `, String(deviceId));
        if (adminUserId) {
            await prisma.$executeRawUnsafe(`
                INSERT INTO audit_super_admin_logs (actor_id, actor_role, action, entity_type, entity_id, request_data)
                VALUES ($1::uuid, 'super_admin', 'REVOKE_DEVICE', 'security', $2::uuid, '{}')
            `, String(adminUserId), String(deviceId)).catch(() => {});
        }
    } catch (e) {
        throw new AppError('Failed to revoke device', 500);
    }
};

export const blockIp = async (ipAddress, reason, adminUserId) => {
    if (!ipAddress) throw new AppError('ip_address is required', 400);
    try {
        await prisma.$executeRawUnsafe(`
            INSERT INTO blocked_ips (ip_address, reason, blocked_by, is_active)
            VALUES ($1::inet, $2, $3::uuid, TRUE)
            ON CONFLICT (ip_address) WHERE is_active = TRUE DO UPDATE
            SET reason = EXCLUDED.reason, blocked_by = EXCLUDED.blocked_by, blocked_at = NOW()
        `, String(ipAddress), reason || 'Blocked by admin', adminUserId ? String(adminUserId) : null);
        if (adminUserId) {
            await prisma.$executeRawUnsafe(`
                INSERT INTO audit_super_admin_logs (actor_id, actor_role, action, entity_type, entity_name, ip_address, request_data)
                VALUES ($1::uuid, 'super_admin', 'BLOCK_IP', 'security', $2, $3::inet, $4::jsonb)
            `, String(adminUserId), ipAddress, ipAddress, JSON.stringify({ reason })).catch(() => {});
        }
    } catch (e) {
        if (e instanceof AppError) throw e;
        throw new AppError('Failed to block IP', 500);
    }
};

export const alertSchool = async (deviceId, message, adminUserId) => {
    const device = await prisma.$queryRawUnsafe(`
        SELECT rd.id, rd.device_name, rd.device_type, s.id AS school_id, s.name AS school_name
        FROM registered_devices rd
        LEFT JOIN users u ON u.id = rd.user_id
        LEFT JOIN schools s ON s.id = u.school_id
        WHERE rd.id = $1::uuid
    `, String(deviceId)).then((r) => r?.[0] || null).catch(() => null);
    const alertMsg = message || 'Your device has been flagged by the platform administrator.';
    // Log alert as notification
    await prisma.$executeRawUnsafe(`
        INSERT INTO platform_notifications (type, title, body, target_role)
        VALUES ('warning', 'Hardware Alert', $1, 'school_admin')
    `, alertMsg).catch(() => {});
    if (adminUserId) {
        await prisma.$executeRawUnsafe(`
            INSERT INTO audit_super_admin_logs (actor_id, actor_role, action, entity_type, entity_id, entity_name, request_data)
            VALUES ($1::uuid, 'super_admin', 'HARDWARE_ALERT', 'hardware', $2::uuid, $3, $4::jsonb)
        `, String(adminUserId), String(deviceId), device?.school_name || 'Unknown School', JSON.stringify({ message: alertMsg })).catch(() => {});
    }
    return { device_id: deviceId, school_id: device?.school_id, message: alertMsg };
};

// ── Exports ───────────────────────────────────────────────────────────────────
const toCsv = (headers, rows) => {
    const escape = (v) => {
        if (v == null) return '';
        const s = String(v);
        return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s.replace(/"/g, '""')}"` : s;
    };
    const lines = [headers.join(','), ...rows.map((r) => headers.map((h) => escape(r[h])).join(','))];
    return lines.join('\n');
};

export const exportDashboardReport = async () => {
    const stats = await getDashboardStats();
    const headers = ['metric', 'value'];
    const rows = [
        { metric: 'Total Schools', value: stats.total_schools },
        { metric: 'Active Schools', value: stats.active_schools },
        { metric: 'Trial Schools', value: stats.trial_schools },
        { metric: 'Suspended Schools', value: stats.suspended_schools },
        { metric: 'Total Students', value: stats.total_students },
        { metric: 'School Groups', value: stats.total_groups },
        { metric: 'Monthly Revenue (MRR)', value: stats.mrr },
        { metric: 'Annual Revenue (ARR)', value: stats.arr },
        { metric: 'Schools Expiring (7 days)', value: stats.schools_expiring_7_days?.length ?? 0 },
        { metric: 'Schools Overdue', value: stats.schools_overdue?.length ?? 0 },
    ];
    return toCsv(headers, rows);
};

export const exportSchools = async (opts = {}) => {
    const result = await getSchools({ ...opts, page: 1, limit: 10000 });
    const headers = ['name', 'code', 'board', 'school_type', 'city', 'state', 'country', 'status', 'plan', 'student_count', 'student_limit', 'subdomain', 'subscription_end', 'phone', 'email'];
    const rows = result.data.map((s) => ({
        name: s.name,
        code: s.code,
        board: s.board,
        school_type: s.school_type,
        city: s.city,
        state: s.state,
        country: s.country,
        status: s.status,
        plan: s.plan?.name || '',
        student_count: s.student_count,
        student_limit: s.student_limit,
        subdomain: s.subdomain,
        subscription_end: s.subscription_end ? new Date(s.subscription_end).toLocaleDateString('en-IN') : '',
        phone: s.phone,
        email: s.email,
    }));
    return toCsv(headers, rows);
};

export const exportBilling = async (opts = {}) => {
    const result = await getSubscriptions({ ...opts, page: 1, limit: 10000 });
    const headers = ['school_name', 'plan', 'student_count', 'monthly_bill', 'status', 'next_renewal', 'overdue_days'];
    const rows = result.data.map((s) => ({
        school_name: s.school_name,
        plan: s.plan_name,
        student_count: s.student_count,
        monthly_bill: s.monthly_bill,
        status: s.status,
        next_renewal: s.next_renewal ? new Date(s.next_renewal).toLocaleDateString('en-IN') : '',
        overdue_days: s.overdue_days || 0,
    }));
    return toCsv(headers, rows);
};

// ── Infra ────────────────────────────────────────────────────────────────────
export const getInfraStatus = async () => {
    const data = await gatherInfraStatus();
    return { data };
};

// ── Notifications (platform-level for super-admin) ─────────────────────────────
export const getUnreadNotificationCount = async () => {
    try {
        const rows = await prisma.$queryRawUnsafe(`
            SELECT COUNT(*)::int AS count FROM platform_notifications
            WHERE is_read = FALSE AND (target_role = 'super_admin' OR target_role IS NULL)
        `);
        return { count: rows?.[0]?.count ?? 0 };
    } catch (_) {
        return { count: 0 };
    }
};

export const getNotifications = async ({ page = 1, limit = 20 }) => {
    const p = Number(page) || 1;
    const l = Number(limit) || 20;
    const skip = (p - 1) * l;
    try {
        const rows = await prisma.$queryRawUnsafe(`
            SELECT id, type, title, body, is_read, link, created_at
            FROM platform_notifications
            WHERE target_role = 'super_admin' OR target_role IS NULL
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2
        `, l, skip);
        const total = await prisma.$queryRawUnsafe(`
            SELECT COUNT(*)::int AS count FROM platform_notifications
            WHERE target_role = 'super_admin' OR target_role IS NULL
        `);
        return {
            data: (rows || []).map((n) => ({
                id: n.id,
                type: n.type || 'info',
                title: n.title,
                body: n.body,
                is_read: n.is_read,
                link: n.link || null,
                created_at: n.created_at,
            })),
            pagination: { page: p, limit: l, total: total?.[0]?.count ?? 0, total_pages: Math.ceil((total?.[0]?.count ?? 0) / l) || 1 },
        };
    } catch (_) {
        return { data: [], pagination: { page: p, limit: l, total: 0, total_pages: 1 } };
    }
};

export const markNotificationRead = async (id) => {
    try {
        await prisma.$executeRawUnsafe(`UPDATE platform_notifications SET is_read = TRUE WHERE id = $1::uuid`, String(id));
    } catch (_) { }
};

export const markAllNotificationsRead = async () => {
    try {
        await prisma.$executeRawUnsafe(`UPDATE platform_notifications SET is_read = TRUE WHERE target_role = 'super_admin' OR target_role IS NULL`);
    } catch (_) { }
};
