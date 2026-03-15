/**
 * Parent Portal Repository — Prisma queries for parent module.
 * All queries scoped to parentId and schoolId from req.parent.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function findParentById(id, schoolId) {
    return prisma.parent.findFirst({
        where: { id, schoolId, deletedAt: null, isActive: true },
        include: { school: { select: { id: true, name: true } } },
    });
}

export async function updateParent(id, schoolId, data) {
    return prisma.parent.update({
        where: { id },
        data: { ...data, updatedAt: new Date() },
        include: { school: { select: { id: true, name: true } } },
    });
}

export async function findChildrenByParentId(parentId, schoolId) {
    return prisma.student.findMany({
        where: {
            schoolId,
            deletedAt: null,
            parentLinks: {
                some: { parentId },
            },
        },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
        orderBy: [{ rollNo: 'asc' }, { lastName: 'asc' }],
    });
}

export async function findChildByIdForParent(studentId, parentId, schoolId) {
    const student = await prisma.student.findFirst({
        where: {
            id: studentId,
            schoolId,
            deletedAt: null,
            parentLinks: {
                some: { parentId },
            },
        },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
            parentLinks: {
                where: { parentId },
                select: { relation: true },
            },
        },
    });
    return student;
}

export async function findAttendanceByStudentMonth(studentId, schoolId, monthStart, monthEnd, limit = 31) {
    return prisma.attendance.findMany({
        where: {
            studentId,
            schoolId,
            date: { gte: monthStart, lte: monthEnd },
        },
        orderBy: { date: 'desc' },
        take: limit,
    });
}

export async function findFeePaymentsByStudent(studentId, schoolId, academicYear) {
    return prisma.feePayment.findMany({
        where: {
            studentId,
            schoolId,
            ...(academicYear && { academicYear }),
        },
        orderBy: { paymentDate: 'desc' },
    });
}

export async function findFeeStructureByClass(classId, schoolId, academicYear) {
    return prisma.feeStructure.findMany({
        where: {
            schoolId,
            OR: [{ classId }, { classId: null }],
            ...(academicYear && { academicYear }),
            isActive: true,
        },
        orderBy: { feeHead: 'asc' },
    });
}

export async function findNoticesForParent(schoolId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const now = new Date();

    const where = {
        schoolId,
        deletedAt: null,
        OR: [
            { targetRole: 'parent' },
            { targetRole: 'all' },
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
            take: limit,
            orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }],
        }),
        prisma.schoolNotice.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function getDashboardStats(parentId, schoolId) {
    const children = await findChildrenByParentId(parentId, schoolId);
    const childrenIds = children.map((c) => c.id);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(today);
    todayEnd.setHours(23, 59, 59, 999);

    const year = `${today.getFullYear()}-${String(today.getFullYear() + 1).slice(-2)}`;

    let todaysAttendance = { present: 0, absent: 0, late: 0 };
    if (childrenIds.length > 0) {
        const att = await prisma.attendance.groupBy({
            by: ['status'],
            where: {
                studentId: { in: childrenIds },
                schoolId,
                date: { gte: today, lte: todayEnd },
            },
            _count: { id: true },
        });
        for (const row of att) {
            const c = row._count.id;
            if (row.status === 'PRESENT') todaysAttendance.present = c;
            else if (row.status === 'ABSENT') todaysAttendance.absent = c;
            else if (row.status === 'LATE') todaysAttendance.late = c;
        }
    }

    const noticesResult = await findNoticesForParent(schoolId, 1, 5);
    const recentNotices = noticesResult.data;

    let feeDues = 0;
    if (children.length > 0) {
        const structures = await prisma.feeStructure.findMany({
            where: {
                schoolId,
                isActive: true,
                academicYear: year,
                OR: [
                    ...children.map((c) => ({ classId: c.classId })),
                    { classId: null },
                ],
            },
        });
        const payments = await prisma.feePayment.findMany({
            where: {
                studentId: { in: childrenIds },
                schoolId,
                academicYear: year,
            },
        });
        const totalDue = structures.reduce((s, f) => s + Number(f.amount), 0);
        const totalPaid = payments.reduce((s, p) => s + Number(p.amount), 0);
        feeDues = Math.max(0, totalDue - totalPaid);
    }

    return {
        childrenCount: children.length,
        todaysAttendance,
        recentNotices,
        feeDues,
    };
}

export async function findNoticeById(id, schoolId) {
    const now = new Date();
    return prisma.schoolNotice.findFirst({
        where: {
            id,
            schoolId,
            deletedAt: null,
            OR: [
                { targetRole: 'parent' },
                { targetRole: 'all' },
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
