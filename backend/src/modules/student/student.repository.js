/**
 * Student Portal Repository — Prisma queries for student portal.
 * All queries are scoped to studentId/schoolId from req.student.
 */

import prisma from '../../config/prisma.js';

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

export async function getNotices(studentId, schoolId, page, limit) {
    const now = new Date();

    // 1. School notices (targetRole: student, all, or null)
    const schoolWhere = {
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

    // 2. Student notices for this student (targetStudent = true)
    const [schoolNotices, studentNotices] = await Promise.all([
        prisma.schoolNotice.findMany({
            where: schoolWhere,
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
        prisma.studentNotice.findMany({
            where: {
                schoolId,
                studentId,
                targetStudent: true,
            },
            orderBy: { createdAt: 'desc' },
            select: {
                id: true,
                subject: true,
                message: true,
                priority: true,
                createdAt: true,
            },
        }),
    ]);

    // Merge and normalize
    const schoolMapped = schoolNotices.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        publishedAt: n.publishedAt,
        expiresAt: n.expiresAt,
        isPinned: n.isPinned,
    }));

    const studentMapped = studentNotices.map((n) => ({
        id: `stn-${n.id}`,
        title: n.subject,
        body: n.message,
        publishedAt: n.createdAt,
        expiresAt: null,
        isPinned: false,
    }));

    const merged = [...schoolMapped, ...studentMapped].sort((a, b) => {
        const dateA = a.publishedAt ? new Date(a.publishedAt) : new Date(0);
        const dateB = b.publishedAt ? new Date(b.publishedAt) : new Date(0);
        return dateB - dateA;
    });

    const total = merged.length;
    const skip = (page - 1) * limit;
    const data = merged.slice(skip, skip + limit);

    return {
        data,
        pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
}

export async function getNoticeById(id, studentId, schoolId) {
    const now = new Date();

    // StudentNotice: id format "stn-{uuid}"
    if (id.startsWith('stn-')) {
        const rawId = id.slice(4);
        const notice = await prisma.studentNotice.findFirst({
            where: {
                id: rawId,
                schoolId,
                studentId,
                targetStudent: true,
            },
            include: {
                sentBy: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
        if (!notice) return null;
        return {
            id: `stn-${notice.id}`,
            title: notice.subject,
            body: notice.message,
            publishedAt: notice.createdAt,
            expiresAt: null,
            isPinned: false,
            source: 'student',
            priority: notice.priority,
            sentBy: notice.sentBy
                ? {
                      id: notice.sentBy.id,
                      name: [notice.sentBy.firstName, notice.sentBy.lastName].filter(Boolean).join(' ') || 'Unknown',
                  }
                : null,
        };
    }

    const notice = await prisma.schoolNotice.findFirst({
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
    return notice ? { ...notice, source: 'school' } : null;
}

export async function getStudentDocuments(studentId, schoolId) {
    return prisma.studentDocument.findMany({
        where: { studentId, schoolId, deletedAt: null },
        orderBy: { createdAt: 'desc' },
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

export async function findActiveDrivers(schoolId) {
    return prisma.driver.findMany({
        where: {
            schoolId,
            tripActive: true,
            deletedAt: null,
            isActive: true,
        },
        include: {
            vehicle: { select: { vehicleNo: true } },
        },
    });
}
