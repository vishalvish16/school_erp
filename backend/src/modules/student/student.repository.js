/**
 * Student Portal Repository — Prisma queries for student portal.
 * All queries are scoped to studentId/schoolId from req.student.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function findByUserId(userId) {
    return prisma.student.findFirst({
        where: {
            userId,
            deletedAt: null,
            status: 'ACTIVE',
        },
    });
}

export async function findProfileById(studentId, schoolId) {
    return prisma.student.findFirst({
        where: { id: studentId, schoolId, deletedAt: null },
        include: {
            class_:  { select: { id: true, name: true, numeric: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function getTodayAttendance(studentId, date) {
    const dayStart = new Date(date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(date);
    dayEnd.setHours(23, 59, 59, 999);

    return prisma.attendance.findFirst({
        where: {
            studentId,
            date: { gte: dayStart, lte: dayEnd },
        },
    });
}

export async function getAttendanceByMonth(studentId, year, month) {
    const start = new Date(year, month - 1, 1);
    const end   = new Date(year, month, 0, 23, 59, 59, 999);

    return prisma.attendance.findMany({
        where: {
            studentId,
            date: { gte: start, lte: end },
        },
        orderBy: { date: 'asc' },
    });
}

export async function getAttendanceSummary(studentId, year, month) {
    const start = new Date(year, month - 1, 1);
    const end   = new Date(year, month, 0, 23, 59, 59, 999);

    const records = await prisma.attendance.findMany({
        where: {
            studentId,
            date: { gte: start, lte: end },
        },
    });

    const summary = { present: 0, absent: 0, late: 0, halfDay: 0 };
    for (const r of records) {
        switch (r.status) {
            case 'PRESENT': summary.present++; break;
            case 'ABSENT':  summary.absent++; break;
            case 'LATE':   summary.late++; break;
            case 'HALF_DAY': summary.halfDay++; break;
        }
    }
    return summary;
}

export async function getFeeDues(studentId, schoolId, academicYear) {
    const student = await prisma.student.findFirst({
        where: { id: studentId, schoolId, deletedAt: null },
        select: { classId: true },
    });
    if (!student?.classId) return { dues: [], totalDue: 0 };

    const structures = await prisma.feeStructure.findMany({
        where: {
            schoolId,
            academicYear,
            isActive: true,
            OR: [
                { classId: null },
                { classId: student.classId },
            ],
        },
    });

    const paymentsByHead = {};
    const payments = await prisma.feePayment.findMany({
        where: { studentId, schoolId, academicYear },
    });
    for (const p of payments) {
        paymentsByHead[p.feeHead] = (paymentsByHead[p.feeHead] || 0) + Number(p.amount);
    }

    const dues = [];
    let totalDue = 0;
    for (const s of structures) {
        const amount = Number(s.amount);
        const paid = paymentsByHead[s.feeHead] || 0;
        const balance = Math.max(0, amount - paid);
        if (balance > 0) {
            const dueDate = s.dueDay
                ? new Date(new Date().getFullYear(), new Date().getMonth(), s.dueDay)
                : null;
            dues.push({
                feeHead:  s.feeHead,
                amount,
                dueDate:  dueDate ? dueDate.toISOString().split('T')[0] : null,
                paid,
                balance,
            });
            totalDue += balance;
        }
    }
    return { dues, totalDue };
}

export async function getFeePayments(studentId, schoolId, page, limit) {
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
        prisma.feePayment.findMany({
            where: { studentId, schoolId },
            skip,
            take: limit,
            orderBy: { paymentDate: 'desc' },
            select: {
                id: true,
                feeHead: true,
                amount: true,
                paymentDate: true,
                receiptNo: true,
                paymentMode: true,
            },
        }),
        prisma.feePayment.count({ where: { studentId, schoolId } }),
    ]);

    return {
        data: data.map((p) => ({
            id: p.id,
            feeHead: p.feeHead,
            amount: Number(p.amount),
            paymentDate: p.paymentDate.toISOString().split('T')[0],
            receiptNo: p.receiptNo,
            paymentMode: p.paymentMode,
        })),
        pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
}

export async function getFeePaymentByReceiptNo(studentId, schoolId, receiptNo) {
    return prisma.feePayment.findFirst({
        where: { studentId, schoolId, receiptNo },
    });
}

export async function getTimetable(classId, sectionId, schoolId) {
    const entries = await prisma.timetable.findMany({
        where: {
            schoolId,
            classId,
            ...(sectionId && { sectionId }),
        },
        orderBy: [{ dayOfWeek: 'asc' }, { periodNo: 'asc' }],
    });

    const staffIds = [...new Set(entries.map((e) => e.staffId).filter(Boolean))];
    const staffMap = {};
    if (staffIds.length > 0) {
        const staffList = await prisma.staff.findMany({
            where: { id: { in: staffIds } },
            select: { id: true, firstName: true, lastName: true },
        });
        for (const s of staffList) {
            staffMap[s.id] = `${s.firstName} ${s.lastName}`.trim();
        }
    }

    return entries.map((e) => ({
        dayOfWeek:  e.dayOfWeek,
        periodNo:   e.periodNo,
        subject:    e.subject,
        startTime:  e.startTime,
        endTime:    e.endTime,
        room:       e.room || null,
        staffName:  e.staffId ? (staffMap[e.staffId] || null) : null,
    }));
}

export async function getNotices(schoolId, page, limit) {
    const skip = (page - 1) * limit;
    const now = new Date();

    const where = {
        schoolId,
        deletedAt: null,
        publishedAt: { lte: now },
        AND: [
            {
                OR: [
                    { expiresAt: null },
                    { expiresAt: { gt: now } },
                ],
            },
            {
                OR: [
                    { targetRole: 'student' },
                    { targetRole: 'all' },
                    { targetRole: null },
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
            select: {
                id: true,
                title: true,
                body: true,
                publishedAt: true,
                expiresAt: true,
                isPinned: true,
            },
        }),
        prisma.schoolNotice.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function getNoticeById(id, schoolId) {
    const now = new Date();
    return prisma.schoolNotice.findFirst({
        where: {
            id,
            schoolId,
            deletedAt: null,
            publishedAt: { lte: now },
            AND: [
                {
                    OR: [
                        { expiresAt: null },
                        { expiresAt: { gt: now } },
                    ],
                },
                {
                    OR: [
                        { targetRole: 'student' },
                        { targetRole: 'all' },
                        { targetRole: null },
                    ],
                },
            ],
        },
    });
}

export async function getStudentDocuments(studentId) {
    return prisma.studentDocument.findMany({
        where: { studentId, deletedAt: null },
        select: {
            id: true,
            documentType: true,
            documentName: true,
            fileUrl: true,
            fileSizeKb: true,
            verified: true,
            verifiedAt: true,
        },
    });
}
