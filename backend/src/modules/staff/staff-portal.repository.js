/**
 * Staff Portal Repository — all Prisma queries for the staff portal.
 * Every query is scoped to schoolId from req.staff.schoolId — no cross-school access possible.
 */

import prisma from '../../config/prisma.js';

// ── Dashboard ──────────────────────────────────────────────────────────────────

export async function getStaffDashboardStats(schoolId, staffRecord) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(today);
    todayEnd.setHours(23, 59, 59, 999);

    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const monthEnd   = new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59, 999);

    const [
        feeCollectedToday,
        feeCollectedThisMonth,
        noticesCount,
        recentPayments,
    ] = await Promise.all([
        prisma.feePayment.aggregate({
            where: { schoolId, paymentDate: { gte: today, lte: todayEnd } },
            _sum: { amount: true },
        }),
        prisma.feePayment.aggregate({
            where: { schoolId, paymentDate: { gte: monthStart, lte: monthEnd } },
            _sum: { amount: true },
        }),
        prisma.schoolNotice.count({
            where: {
                schoolId,
                deletedAt: null,
                OR: [
                    { targetRole: 'all' },
                    { targetRole: 'staff' },
                    { targetRole: null },
                ],
            },
        }),
        prisma.feePayment.findMany({
            where: { schoolId },
            orderBy: { createdAt: 'desc' },
            take: 10,
            select: {
                id:          true,
                feeHead:     true,
                amount:      true,
                paymentMode: true,
                receiptNo:   true,
                paymentDate: true,
                createdAt:   true,
                studentId:   true,
            },
        }),
    ]);

    // Enrich recent payments with student names
    const studentIds = [...new Set(recentPayments.map((p) => p.studentId))];
    const students = await prisma.student.findMany({
        where: { id: { in: studentIds }, schoolId, deletedAt: null },
        select: { id: true, firstName: true, lastName: true },
    });
    const studentMap = Object.fromEntries(students.map((s) => [s.id, `${s.firstName} ${s.lastName}`]));

    const enrichedPayments = recentPayments.map((p) => ({
        id:           p.id,
        student_name: studentMap[p.studentId] ?? 'Unknown',
        fee_head:     p.feeHead,
        amount:       Number(p.amount),
        payment_mode: p.paymentMode,
        receipt_no:   p.receiptNo,
        payment_date: p.paymentDate,
        created_at:   p.createdAt,
    }));

    return {
        my_name:                 `${staffRecord.firstName} ${staffRecord.lastName}`,
        my_designation:          staffRecord.designation,
        fee_collected_today:     Number(feeCollectedToday._sum.amount ?? 0),
        fee_collected_this_month: Number(feeCollectedThisMonth._sum.amount ?? 0),
        notices_count:           noticesCount,
        recent_payments:         enrichedPayments,
    };
}

// ── Fee Payments ───────────────────────────────────────────────────────────────

export async function findFeePayments({ schoolId, page = 1, limit = 20, studentId, month, academicYear }) {
    const skip = (page - 1) * limit;

    let dateFilter = {};
    if (month) {
        const [year, mon] = month.split('-').map(Number);
        dateFilter = {
            paymentDate: {
                gte: new Date(year, mon - 1, 1),
                lte: new Date(year, mon, 0, 23, 59, 59, 999),
            },
        };
    }

    const where = {
        schoolId,
        ...(studentId    && { studentId }),
        ...(academicYear && { academicYear }),
        ...dateFilter,
    };

    const [data, total] = await Promise.all([
        prisma.feePayment.findMany({
            where,
            skip,
            take:    limit,
            orderBy: { paymentDate: 'desc' },
        }),
        prisma.feePayment.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findFeePaymentById(id, schoolId) {
    return prisma.feePayment.findFirst({ where: { id, schoolId } });
}

export async function findFeePaymentByReceiptNo(receiptNo, schoolId) {
    return prisma.feePayment.findFirst({ where: { receiptNo, schoolId } });
}

/**
 * Find the maximum existing receipt sequence number for the given school + year.
 * Receipt format: RCP/{YEAR}/{5-digit-seq}  e.g.  RCP/2026/00001
 */
export async function findMaxReceiptSeqForYear(schoolId, year) {
    // Match receipts that start with RCP/{year}/
    const prefix = `RCP/${year}/`;
    const result = await prisma.feePayment.findMany({
        where: {
            schoolId,
            receiptNo: { startsWith: prefix },
        },
        select: { receiptNo: true },
        orderBy: { receiptNo: 'desc' },
        take: 1,
    });

    if (result.length === 0) return 0;

    const lastReceipt = result[0].receiptNo; // e.g. "RCP/2026/00042"
    const parts = lastReceipt.split('/');
    const seq   = parseInt(parts[2], 10);
    return isNaN(seq) ? 0 : seq;
}

export async function createFeePayment(data) {
    return prisma.feePayment.create({ data });
}

export async function getFeeSummary({ schoolId, month }) {
    const [year, mon] = month.split('-').map(Number);
    const start = new Date(year, mon - 1, 1);
    const end   = new Date(year, mon, 0, 23, 59, 59, 999);

    return prisma.feePayment.groupBy({
        by:    ['feeHead', 'paymentMode'],
        where: { schoolId, paymentDate: { gte: start, lte: end } },
        _sum:   { amount: true },
        _count: { id: true },
    });
}

// ── Fee Structures ─────────────────────────────────────────────────────────────

export async function findFeeStructures({ schoolId, academicYear, classId }) {
    return prisma.feeStructure.findMany({
        where: {
            schoolId,
            ...(academicYear && { academicYear }),
            ...(classId      && { classId }),
        },
        orderBy: { feeHead: 'asc' },
        include: { class_: { select: { id: true, name: true } } },
    });
}

// ── Students (read-only) ───────────────────────────────────────────────────────

export async function findStudents({ schoolId, page = 1, limit = 20, search, classId, sectionId }) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        deletedAt: null,
        ...(classId   && { classId }),
        ...(sectionId && { sectionId }),
        ...(search && {
            OR: [
                { firstName:   { contains: search, mode: 'insensitive' } },
                { lastName:    { contains: search, mode: 'insensitive' } },
                { admissionNo: { contains: search, mode: 'insensitive' } },
                { phone:       { contains: search, mode: 'insensitive' } },
            ],
        }),
    };

    const [data, total] = await Promise.all([
        prisma.student.findMany({
            where,
            skip,
            take:    limit,
            orderBy: { createdAt: 'desc' },
            include: {
                class_:  { select: { id: true, name: true } },
                section: { select: { id: true, name: true } },
            },
        }),
        prisma.student.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findStudentById(id, schoolId) {
    return prisma.student.findFirst({
        where:   { id, schoolId, deletedAt: null },
        include: {
            class_:  { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

// ── Classes (read-only) ────────────────────────────────────────────────────────

export async function findAllClasses(schoolId) {
    const rows = await prisma.schoolClass.findMany({
        where:   { schoolId },
        orderBy: [{ numeric: 'asc' }, { name: 'asc' }],
        include: {
            sections: {
                where:   { isActive: true },
                include: { _count: { select: { students: true } } },
            },
        },
    });
    return rows.map((cls) => ({
        ...cls,
        sections: cls.sections.map((sec) => ({
            ...sec,
            student_count: sec._count?.students ?? 0,
            _count: undefined,
        })),
    }));
}

// ── Notices (read-only, staff-targeted) ───────────────────────────────────────

export async function findNoticesForStaff({ schoolId, page = 1, limit = 20 }) {
    const skip = (page - 1) * limit;
    const now  = new Date();

    const where = {
        schoolId,
        deletedAt: null,
        OR: [
            { targetRole: 'all' },
            { targetRole: 'staff' },
            { targetRole: null },
        ],
        AND: [
            {
                OR: [
                    { expiresAt: null },
                    { expiresAt: { gt: now } },
                ],
            },
        ],
    };

    const [data, total] = await Promise.all([
        prisma.schoolNotice.findMany({
            where,
            skip,
            take:    limit,
            orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
        }),
        prisma.schoolNotice.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findNoticeById(id, schoolId) {
    const now = new Date();
    return prisma.schoolNotice.findFirst({
        where: {
            id,
            schoolId,
            deletedAt: null,
            OR: [
                { targetRole: 'all' },
                { targetRole: 'staff' },
                { targetRole: null },
            ],
            AND: [
                {
                    OR: [
                        { expiresAt: null },
                        { expiresAt: { gt: now } },
                    ],
                },
            ],
        },
    });
}

// ── Profile ────────────────────────────────────────────────────────────────────

export async function findUserById(userId) {
    return prisma.user.findFirst({
        where: { id: userId, deletedAt: null },
        select: {
            id:         true,
            email:      true,
            firstName:  true,
            lastName:   true,
            phone:      true,
            avatarUrl:  true,
            schoolId:   true,
            isActive:   true,
            lastLogin:  true,
            createdAt:  true,
        },
    });
}

export async function findUserWithPasswordHash(userId) {
    return prisma.user.findFirst({
        where:  { id: userId },
        select: { id: true, passwordHash: true },
    });
}

export async function updateUser(userId, data) {
    return prisma.user.update({
        where: { id: userId },
        data:  { ...data, updatedAt: new Date() },
    });
}

export async function findSchoolById(schoolId) {
    return prisma.school.findFirst({ where: { id: schoolId } });
}

export async function findStaffByUserId(userId, schoolId) {
    return prisma.staff.findFirst({
        where: { userId, schoolId, deletedAt: null },
    });
}
