/**
 * Parent Portal Repository — Prisma queries for parent module.
 * All queries scoped to parentId and schoolId from req.parent.
 */

import prisma from '../../config/prisma.js';

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

export async function findNoticesForParent(parentId, schoolId, page = 1, limit = 20) {
    const now = new Date();

    // 1. School notices (targetRole: parent, all, or null)
    const schoolWhere = {
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

    // 2. Student notices for this parent's children (targetParent = true)
    const children = await prisma.student.findMany({
        where: {
            schoolId,
            deletedAt: null,
            parentLinks: { some: { parentId } },
        },
        select: { id: true },
    });
    const childrenIds = children.map((c) => c.id);

    let studentNotices = [];
    if (childrenIds.length > 0) {
        studentNotices = await prisma.studentNotice.findMany({
            where: {
                schoolId,
                studentId: { in: childrenIds },
                targetParent: true,
            },
            orderBy: { createdAt: 'desc' },
            include: {
                sentBy: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
    }

    const schoolNotices = await prisma.schoolNotice.findMany({
        where: schoolWhere,
        orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }],
    });

    // Merge and normalize: SchoolNotice -> { id, title, body, isPinned, publishedAt, expiresAt, source }
    const schoolMapped = schoolNotices.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        isPinned: n.isPinned,
        publishedAt: n.publishedAt,
        expiresAt: n.expiresAt,
        source: 'school',
    }));

    const studentMapped = studentNotices.map((n) => ({
        id: `stn-${n.id}`,
        title: n.subject,
        body: n.message,
        isPinned: false,
        publishedAt: n.createdAt,
        expiresAt: null,
        source: 'student',
        priority: n.priority,
        createdAt: n.createdAt,
    }));

    // Sort merged list by date (newest first)
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

    const noticesResult = await findNoticesForParent(parentId, schoolId, 1, 5);
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

export async function getBusForStudent(studentId, schoolId) {
    // Find an active trip in the school with vehicle + driver + current location
    const activeTrip = await prisma.driverTrip.findFirst({
        where: { schoolId, status: 'IN_PROGRESS', deletedAt: null },
        orderBy: { startedAt: 'desc' },
        include: {
            vehicle: {
                include: {
                    driver: { select: { firstName: true, lastName: true, phone: true } },
                    locationCurrent: true,
                },
            },
        },
    });

    if (!activeTrip?.vehicle) {
        // Return last known location even if trip not active
        const vehicle = await prisma.vehicle.findFirst({
            where: { schoolId, isActive: true, deletedAt: null },
            include: {
                driver: { select: { firstName: true, lastName: true, phone: true } },
                locationCurrent: true,
            },
            orderBy: { createdAt: 'asc' },
        });
        return { vehicle, tripStatus: 'NOT_STARTED' };
    }

    return { vehicle: activeTrip.vehicle, tripStatus: 'IN_PROGRESS' };
}

export async function findAttendanceSummaryByStudentMonth(studentId, schoolId, monthStart, monthEnd) {
    const records = await prisma.attendance.findMany({
        where: {
            studentId,
            schoolId,
            date: { gte: monthStart, lte: monthEnd },
        },
        select: { status: true },
    });

    const summary = { present: 0, absent: 0, late: 0, halfDay: 0 };
    for (const r of records) {
        if (r.status === 'PRESENT') summary.present++;
        else if (r.status === 'ABSENT') summary.absent++;
        else if (r.status === 'LATE') summary.late++;
        else if (r.status === 'HALF_DAY') summary.halfDay++;
    }
    return { ...summary, total: records.length };
}

export async function findTimetableForStudent(studentId, schoolId) {
    const student = await prisma.student.findFirst({
        where: { id: studentId, schoolId, deletedAt: null },
        select: { sectionId: true, classId: true },
    });
    if (!student?.sectionId && !student?.classId) return [];

    const slots = await prisma.timetable.findMany({
        where: {
            schoolId,
            classId: student.classId,
            ...(student.sectionId ? { sectionId: student.sectionId } : {}),
        },
        orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
    });

    // Fetch staff names for slots that have staffId
    const staffIds = [...new Set(slots.filter((s) => s.staffId).map((s) => s.staffId))];
    let staffMap = {};
    if (staffIds.length > 0) {
        const staffList = await prisma.staff.findMany({
            where: { id: { in: staffIds } },
            select: { id: true, firstName: true, lastName: true },
        });
        for (const s of staffList) {
            staffMap[s.id] = `${s.firstName} ${s.lastName}`.trim();
        }
    }

    return slots.map((s) => ({
        id: s.id,
        day: s.dayOfWeek,
        period: s.periodNo,
        subject: s.subject || 'N/A',
        startTime: s.startTime,
        endTime: s.endTime,
        room: s.room || null,
        teacherName: s.staffId ? staffMap[s.staffId] || null : null,
    }));
}

export async function findDocumentsByStudent(studentId, schoolId) {
    const docs = await prisma.studentDocument.findMany({
        where: { studentId, schoolId, deletedAt: null },
        orderBy: { createdAt: 'desc' },
    });

    return docs.map((d) => ({
        id: d.id,
        type: d.documentType || 'DOCUMENT',
        name: d.documentName || 'Document',
        fileUrl: d.fileUrl,
        fileSizeKb: d.fileSizeKb || null,
        mimeType: d.mimeType || null,
        verified: d.verified || false,
        verifiedAt: d.verifiedAt || null,
        createdAt: d.createdAt,
    }));
}

export async function findNoticeById(id, parentId, schoolId) {
    const now = new Date();

    // StudentNotice: id format "stn-{uuid}"
    if (id.startsWith('stn-')) {
        const rawId = id.slice(4);
        const notice = await prisma.studentNotice.findFirst({
            where: {
                id: rawId,
                schoolId,
                targetParent: true,
                student: {
                    parentLinks: { some: { parentId } },
                },
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
            isPinned: false,
            publishedAt: notice.createdAt,
            expiresAt: null,
            source: 'student',
            priority: notice.priority,
            createdAt: notice.createdAt,
            sentBy: notice.sentBy
                ? {
                      id: notice.sentBy.id,
                      name: [notice.sentBy.firstName, notice.sentBy.lastName].filter(Boolean).join(' ') || 'Unknown',
                  }
                : null,
        };
    }

    // SchoolNotice
    const notice = await prisma.schoolNotice.findFirst({
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
    return notice
        ? {
              ...notice,
              source: 'school',
          }
        : null;
}
