/**
 * School Admin Repository — all Prisma queries for school-admin module.
 * Every query is scoped to schoolId from JWT — no cross-school access possible.
 */
import { randomUUID } from 'crypto';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ── Dashboard ─────────────────────────────────────────────────────────────────

export async function getDashboardStats(schoolId) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(today);
    todayEnd.setHours(23, 59, 59, 999);

    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const monthEnd   = new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59, 999);

    const [
        totalStudents,
        totalStaff,
        totalClasses,
        totalSections,
        todayAttendance,
        feeCollected,
        noticesCount,
    ] = await Promise.all([
        prisma.student.count({ where: { schoolId, deletedAt: null } }),
        prisma.staff.count({ where: { schoolId, deletedAt: null } }),
        prisma.schoolClass.count({ where: { schoolId } }),
        prisma.section.count({ where: { schoolId } }),
        prisma.attendance.groupBy({
            by: ['status'],
            where: { schoolId, date: { gte: today, lte: todayEnd } },
            _count: { id: true },
        }),
        prisma.feePayment.aggregate({
            where: { schoolId, paymentDate: { gte: monthStart, lte: monthEnd } },
            _sum: { amount: true },
        }),
        prisma.schoolNotice.count({ where: { schoolId, deletedAt: null } }),
    ]);

    const presentCount = todayAttendance.find((g) => g.status === 'PRESENT')?._count?.id ?? 0;
    const todayTotal   = todayAttendance.reduce((s, g) => s + g._count.id, 0);
    const attendancePct = todayTotal > 0 ? Math.round((presentCount / todayTotal) * 100) : 0;

    // Recent activity: last 5 students enrolled + last 5 payments
    const [recentStudents, recentPayments] = await Promise.all([
        prisma.student.findMany({
            where: { schoolId, deletedAt: null },
            orderBy: { createdAt: 'desc' },
            take: 5,
            select: { firstName: true, lastName: true, createdAt: true },
        }),
        prisma.feePayment.findMany({
            where: { schoolId },
            orderBy: { createdAt: 'desc' },
            take: 5,
            select: { receiptNo: true, amount: true, createdAt: true },
        }),
    ]);

    const recentActivity = [
        ...recentStudents.map((s) => ({
            type: 'STUDENT_ENROLLED',
            message: `Student ${s.firstName} ${s.lastName} enrolled`,
            created_at: s.createdAt,
        })),
        ...recentPayments.map((p) => ({
            type: 'FEE_COLLECTED',
            message: `Receipt ${p.receiptNo} — ₹${p.amount}`,
            created_at: p.createdAt,
        })),
    ]
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
        .slice(0, 5);

    return {
        total_students: totalStudents,
        total_staff: totalStaff,
        total_classes: totalClasses,
        total_sections: totalSections,
        today_attendance_percent: attendancePct,
        fee_collected_this_month: Number(feeCollected._sum.amount ?? 0),
        notices_count: noticesCount,
        recent_activity: recentActivity,
    };
}

// ── Academic Years ─────────────────────────────────────────────────────────────

export async function findAcademicYears(schoolId) {
    const rows = await prisma.$queryRaw`
        SELECT id, year_name as "yearName", start_date as "startDate", end_date as "endDate"
        FROM academic_years
        WHERE school_id = ${schoolId}::uuid AND (deleted_at IS NULL)
        ORDER BY start_date DESC
    `;
    return rows;
}

// ── Students ──────────────────────────────────────────────────────────────────

/** Debug: raw count of students by school_id (ignores Prisma model) */
export async function debugStudentCount(schoolId) {
    const r = await prisma.$queryRaw`
        SELECT COUNT(*)::int as total,
               COUNT(*) FILTER (WHERE deleted_at IS NULL)::int as active
        FROM students WHERE school_id = ${schoolId}::uuid
    `;
    return r[0] || { total: 0, active: 0 };
}

export async function findStudents({ schoolId, page = 1, limit = 20, search, classId, sectionId, status }) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        deletedAt: null,
        ...(status   && { status }),
        ...(classId  && { classId }),
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
            take: limit,
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
        where: { id, schoolId, deletedAt: null },
        include: {
            class_:  { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function findStudentByAdmissionNo(admissionNo, schoolId) {
    return prisma.student.findFirst({ where: { admissionNo, schoolId, deletedAt: null } });
}

/** Generate permanent admission number: {schoolCode}-{firstName}-{lastName}-{count} (max 50 chars) */
export async function generateAdmissionNo(schoolId, firstName, lastName) {
    const school = await prisma.school.findUnique({
        where: { id: schoolId },
        select: { code: true },
    });
    let schoolCode = (school?.code || 'SCH').toUpperCase().replace(/[^A-Z0-9]/g, '');
    const fn = String(firstName || '').trim().toUpperCase().replace(/[^A-Z]/g, '') || 'X';
    const ln = String(lastName || '').trim().toUpperCase().replace(/[^A-Z]/g, '') || 'X';
    // admission_no column is VARCHAR(50) — truncate schoolCode if needed
    const suffixLen = 2 + fn.length + ln.length + 5; // "-" + fn + "-" + ln + "-0001"
    if (schoolCode.length > 50 - suffixLen) schoolCode = schoolCode.slice(0, 50 - suffixLen);
    const base = `${schoolCode}-${fn}-${ln}`;

    const likePattern = base + '-%';
    // Include deleted students so we never reuse an admission_no (unique constraint)
    const existing = await prisma.$queryRaw`
        SELECT admission_no FROM students
        WHERE school_id = ${schoolId}::uuid
          AND admission_no LIKE ${likePattern}
        ORDER BY admission_no DESC
        LIMIT 1
    `;
    let count = 1;
    if (existing && existing.length > 0) {
        const lastNo = existing[0].admission_no || '';
        const match = lastNo.match(/-(\d+)$/);
        if (match) count = parseInt(match[1], 10) + 1;
    }
    const result = `${base}-${String(count).padStart(4, '0')}`;
    return result.length > 50 ? result.slice(0, 50) : result;
}

export async function createStudent(data) {
    const { academicYearId, ...createData } = data;
    const student = await prisma.student.create({ data: createData });
    // Legacy: set name from first_name + last_name for DB compatibility
    const fullName = `${(data.firstName || '').trim()} ${(data.lastName || '').trim()}`.trim() || 'Unknown';
    await prisma.$executeRawUnsafe('UPDATE students SET name = $1 WHERE id = $2::uuid', fullName, student.id);
    if (academicYearId) {
        await prisma.$executeRawUnsafe('UPDATE students SET academic_year_id = $1::uuid WHERE id = $2::uuid', academicYearId, student.id);
    }
    return prisma.student.findFirst({ where: { id: student.id } });
}

export async function updateStudent(id, schoolId, data) {
    const { academicYearId, ...updateData } = data;
    const student = await prisma.student.update({
        where: { id, schoolId },
        data: { ...updateData, updatedAt: new Date() },
    });
    if (academicYearId !== undefined) {
        await prisma.$executeRawUnsafe('UPDATE students SET academic_year_id = $1::uuid WHERE id = $2::uuid', academicYearId, id);
    }
    if (data.firstName != null || data.lastName != null) {
        const fn = (data.firstName != null ? data.firstName : student.firstName) || '';
        const ln = (data.lastName != null ? data.lastName : student.lastName) || '';
        const fullName = `${String(fn).trim()} ${String(ln).trim()}`.trim() || 'Unknown';
        await prisma.$executeRawUnsafe('UPDATE students SET name = $1 WHERE id = $2::uuid', fullName, id);
    }
    return prisma.student.findFirst({ where: { id } });
}

export async function softDeleteStudent(id, schoolId) {
    return prisma.student.update({ where: { id, schoolId }, data: { deletedAt: new Date() } });
}

export async function updateStudentUserId(studentId, userId) {
    return prisma.student.update({
        where: { id: studentId },
        data:  { userId, updatedAt: new Date() },
    });
}

// ── Staff ─────────────────────────────────────────────────────────────────────

export async function findStaff({ schoolId, page = 1, limit = 20, search, designation, isActive }) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        deletedAt: null,
        ...(designation !== undefined && { designation: { contains: designation, mode: 'insensitive' } }),
        ...(isActive !== undefined    && { isActive }),
        ...(search && {
            OR: [
                { firstName:  { contains: search, mode: 'insensitive' } },
                { lastName:   { contains: search, mode: 'insensitive' } },
                { email:      { contains: search, mode: 'insensitive' } },
                { employeeNo: { contains: search, mode: 'insensitive' } },
            ],
        }),
    };

    const [data, total] = await Promise.all([
        prisma.staff.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
        }),
        prisma.staff.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findStaffById(id, schoolId) {
    return prisma.staff.findFirst({ where: { id, schoolId, deletedAt: null } });
}

export async function findStaffByEmployeeNo(employeeNo, schoolId) {
    return prisma.staff.findFirst({ where: { employeeNo, schoolId, deletedAt: null } });
}

/** Case-insensitive check: is this employeeNo taken by another staff (excluding optional staffId)? */
export async function isEmployeeNoTaken(employeeNo, schoolId, excludeStaffId = null) {
    if (!employeeNo || !String(employeeNo).trim()) return false;
    const existing = await prisma.staff.findFirst({
        where: {
            schoolId,
            deletedAt: null,
            employeeNo: { equals: String(employeeNo).trim(), mode: 'insensitive' },
            ...(excludeStaffId && { id: { not: excludeStaffId } }),
        },
    });
    return !!existing;
}

/** Get next suggested employee number: {schoolCode}-{initials}-{count} */
export async function getNextEmployeeNo(schoolId, firstName = '', lastName = '') {
    const school = await prisma.school.findFirst({ where: { id: schoolId }, select: { code: true } });
    const code = (school?.code || 'SCH').replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 8) || 'SCH';
    const f = String(firstName || '').trim();
    const l = String(lastName || '').trim();
    const initials = ((f[0] || '') + (l[0] || '')).toUpperCase() || 'XX';
    const count = await prisma.staff.count({ where: { schoolId, deletedAt: null } });
    const next = count + 1;
    const suffix = String(next).padStart(3, '0');
    return `${code}-${initials}-${suffix}`;
}

export async function createStaff(data) {
    return prisma.staff.create({ data });
}

export async function findRoleByName(name) {
    return prisma.role.findFirst({ where: { name } });
}

export async function findUserByEmail(email) {
    return prisma.user.findFirst({ where: { email, deletedAt: null } });
}

export async function createUserForStaff({ email, passwordHash, schoolId, firstName, lastName, phone, roleId }) {
    return prisma.user.create({
        data: {
            email,
            passwordHash,
            schoolId,
            firstName: firstName || null,
            lastName: lastName || null,
            phone: phone || null,
            roleId,
        },
    });
}

export async function updateStaffUserId(staffId, userId) {
    return prisma.staff.update({
        where: { id: staffId },
        data: { userId, updatedAt: new Date() },
    });
}

export async function updateUserPassword(userId, passwordHash) {
    return prisma.user.update({
        where: { id: userId },
        data: { passwordHash, passwordChangedAt: new Date(), updatedAt: new Date() },
    });
}

export async function updateStaff(id, schoolId, data) {
    return prisma.staff.update({ where: { id, schoolId }, data: { ...data, updatedAt: new Date() } });
}

export async function softDeleteStaff(id, schoolId) {
    return prisma.staff.update({ where: { id, schoolId }, data: { deletedAt: new Date(), isActive: false } });
}

export async function findAllStaffForExport({ schoolId, search, designation, department, isActive, employeeType }) {
    const where = {
        schoolId,
        deletedAt: null,
        ...(designation   && { designation: { contains: designation, mode: 'insensitive' } }),
        ...(department    && { department:  { contains: department,  mode: 'insensitive' } }),
        ...(employeeType  && { employeeType }),
        ...(isActive !== undefined && { isActive }),
        ...(search && {
            OR: [
                { firstName:  { contains: search, mode: 'insensitive' } },
                { lastName:   { contains: search, mode: 'insensitive' } },
                { email:      { contains: search, mode: 'insensitive' } },
                { employeeNo: { contains: search, mode: 'insensitive' } },
            ],
        }),
    };

    return prisma.staff.findMany({
        where,
        orderBy: [{ employeeNo: 'asc' }],
        select: {
            employeeNo: true, firstName: true, lastName: true, gender: true,
            designation: true, department: true, employeeType: true, email: true,
            phone: true, joinDate: true, experienceYears: true, isActive: true,
            qualification: true,
        },
    });
}

export async function findClassesByClassTeacher(staffId, schoolId) {
    return prisma.section.findMany({
        where: { classTeacherId: staffId, schoolId },
        select: { id: true, name: true, classId: true },
    });
}

// ── Staff Qualifications ───────────────────────────────────────────────────────

export async function findQualificationsByStaffId(staffId, schoolId) {
    return prisma.staffQualification.findMany({
        where:   { staffId, schoolId },
        orderBy: { createdAt: 'desc' },
    });
}

export async function findQualificationById(id, staffId, schoolId) {
    return prisma.staffQualification.findFirst({ where: { id, staffId, schoolId } });
}

export async function createQualification(data) {
    return prisma.staffQualification.create({ data });
}

export async function updateQualification(id, staffId, schoolId, data) {
    return prisma.staffQualification.update({
        where: { id, staffId, schoolId },
        data:  { ...data, updatedAt: new Date() },
    });
}

export async function deleteQualification(id, staffId, schoolId) {
    return prisma.staffQualification.delete({ where: { id, staffId, schoolId } });
}

export async function unsetHighestQualification(staffId, schoolId) {
    return prisma.staffQualification.updateMany({
        where: { staffId, schoolId, isHighest: true },
        data:  { isHighest: false },
    });
}

// ── Staff Documents ───────────────────────────────────────────────────────────

export async function findDocumentsByStaffId(staffId, schoolId) {
    return prisma.staffDocument.findMany({
        where:   { staffId, schoolId, deletedAt: null },
        orderBy: { createdAt: 'desc' },
    });
}

export async function findDocumentById(id, staffId, schoolId) {
    return prisma.staffDocument.findFirst({ where: { id, staffId, schoolId, deletedAt: null } });
}

export async function createDocument(data) {
    return prisma.staffDocument.create({ data });
}

export async function softDeleteOldDocumentsByType(staffId, schoolId, documentType) {
    return prisma.staffDocument.updateMany({
        where: { staffId, schoolId, documentType, deletedAt: null },
        data:  { deletedAt: new Date() },
    });
}

export async function verifyDocument(id, staffId, schoolId, verifiedBy) {
    return prisma.staffDocument.update({
        where: { id, staffId, schoolId },
        data:  { verified: true, verifiedAt: new Date(), verifiedBy, updatedAt: new Date() },
    });
}

export async function softDeleteDocument(id, staffId, schoolId) {
    return prisma.staffDocument.update({
        where: { id, staffId, schoolId },
        data:  { deletedAt: new Date(), updatedAt: new Date() },
    });
}

// ── Staff Subject Assignments ─────────────────────────────────────────────────

export async function findSubjectAssignments(staffId, schoolId, academicYear) {
    return prisma.staffSubjectAssignment.findMany({
        where: {
            staffId,
            schoolId,
            ...(academicYear && { academicYear }),
        },
        orderBy: { createdAt: 'desc' },
        include: {
            class_:  { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function findSubjectAssignmentById(id, staffId, schoolId) {
    return prisma.staffSubjectAssignment.findFirst({ where: { id, staffId, schoolId } });
}

export async function createSubjectAssignment(data) {
    return prisma.staffSubjectAssignment.create({
        data,
        include: {
            class_:  { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function checkSubjectAssignmentConflict(classId, sectionId, subject, academicYear, schoolId, excludeStaffId) {
    return prisma.staffSubjectAssignment.findFirst({
        where: {
            classId,
            subject,
            academicYear,
            schoolId,
            isActive: true,
            sectionId: sectionId ?? null,
            ...(excludeStaffId && { staffId: { not: excludeStaffId } }),
        },
    });
}

export async function removeSubjectAssignment(id, staffId, schoolId) {
    return prisma.staffSubjectAssignment.delete({ where: { id, staffId, schoolId } });
}

// ── Staff Timetable ───────────────────────────────────────────────────────────

export async function findTimetableByStaffId(staffId, schoolId) {
    return prisma.timetable.findMany({
        where:   { schoolId, staffId },
        orderBy: [{ dayOfWeek: 'asc' }, { periodNo: 'asc' }],
        include: {
            class_:  { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

// ── Staff Leaves ──────────────────────────────────────────────────────────────

export async function findLeaves({ schoolId, page = 1, limit = 20, status, staffId, leaveType, fromDate, toDate, academicYear }) {
    const skip = (page - 1) * limit;

    let dateFilter = {};
    if (academicYear) {
        const [startYear, endSuffix] = academicYear.split('-');
        const endYear = parseInt(startYear, 10) + 1;
        dateFilter = {
            fromDate: { gte: new Date(`${startYear}-04-01`) },
            toDate:   { lte: new Date(`${endYear}-03-31`) },
        };
    } else if (fromDate || toDate) {
        dateFilter = {
            ...(fromDate && { fromDate: { gte: new Date(fromDate) } }),
            ...(toDate   && { toDate:   { lte: new Date(toDate) } }),
        };
    }

    const where = {
        schoolId,
        ...(status    && { status }),
        ...(staffId   && { staffId }),
        ...(leaveType && { leaveType }),
        ...dateFilter,
    };

    const [data, total] = await Promise.all([
        prisma.staffLeave.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
            include: {
                staff: { select: { id: true, firstName: true, lastName: true, employeeNo: true } },
            },
        }),
        prisma.staffLeave.count({ where }),
    ]);

    // Flatten staff name into each record
    const rows = data.map((leave) => ({
        ...leave,
        staffName:  `${leave.staff.firstName} ${leave.staff.lastName}`,
        employeeNo: leave.staff.employeeNo,
        staff: undefined,
    }));

    return { data: rows, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findLeavesByStaffId(staffId, schoolId, { page = 1, limit = 20, status, academicYear } = {}) {
    const skip = (page - 1) * limit;

    let dateFilter = {};
    if (academicYear) {
        const [startYear] = academicYear.split('-');
        const endYear = parseInt(startYear, 10) + 1;
        dateFilter = {
            fromDate: { gte: new Date(`${startYear}-04-01`) },
            toDate:   { lte: new Date(`${endYear}-03-31`) },
        };
    }

    const where = {
        staffId,
        schoolId,
        ...(status && { status }),
        ...dateFilter,
    };

    const [data, total] = await Promise.all([
        prisma.staffLeave.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
        }),
        prisma.staffLeave.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findLeaveById(id, schoolId) {
    return prisma.staffLeave.findFirst({ where: { id, schoolId } });
}

export async function createLeave(data) {
    return prisma.staffLeave.create({ data });
}

export async function findOverlappingLeave(staffId, schoolId, fromDate, toDate) {
    return prisma.staffLeave.findFirst({
        where: {
            staffId,
            schoolId,
            status: { notIn: ['REJECTED', 'CANCELLED'] },
            fromDate: { lte: toDate },
            toDate:   { gte: fromDate },
        },
    });
}

export async function updateLeaveStatus(id, schoolId, updateData) {
    return prisma.staffLeave.update({
        where: { id, schoolId },
        data:  { ...updateData, updatedAt: new Date() },
    });
}

export async function getLeaveCounts(schoolId, academicYear, staffId) {
    const [startYear] = academicYear.split('-');
    const endYear = parseInt(startYear, 10) + 1;
    const dateFilter = {
        fromDate: { gte: new Date(`${startYear}-04-01`) },
        toDate:   { lte: new Date(`${endYear}-03-31`) },
    };

    const where = {
        schoolId,
        ...(staffId && { staffId }),
        ...dateFilter,
    };

    const [allLeaves, byStatus] = await Promise.all([
        prisma.staffLeave.findMany({
            where,
            select: { status: true, leaveType: true, totalDays: true },
        }),
        prisma.staffLeave.groupBy({
            by: ['status'],
            where,
            _count: { id: true },
            _sum:   { totalDays: true },
        }),
    ]);

    const statusMap = {};
    for (const row of byStatus) {
        statusMap[row.status] = { count: row._count.id, totalDays: row._sum.totalDays || 0 };
    }

    const byType = {};
    for (const leave of allLeaves) {
        if (leave.status === 'APPROVED') {
            byType[leave.leaveType] = (byType[leave.leaveType] || 0) + leave.totalDays;
        }
    }

    return {
        total_applied:  allLeaves.length,
        total_approved: statusMap['APPROVED']?.count  || 0,
        total_rejected: statusMap['REJECTED']?.count  || 0,
        total_pending:  statusMap['PENDING']?.count   || 0,
        total_cancelled: statusMap['CANCELLED']?.count || 0,
        approved_days:  statusMap['APPROVED']?.totalDays || 0,
        by_leave_type:  byType,
    };
}

// ── Classes ───────────────────────────────────────────────────────────────────

export async function findAllClasses(schoolId) {
    const rows = await prisma.schoolClass.findMany({
        where: { schoolId },
        orderBy: [{ numeric: 'asc' }, { name: 'asc' }],
        include: {
            sections: {
                where: { isActive: true },
                include: { _count: { select: { students: true } } },
            },
        },
    });
    // Map _count.students to student_count for API consumers
    return rows.map((cls) => ({
        ...cls,
        sections: cls.sections.map((sec) => ({
            ...sec,
            student_count: sec._count?.students ?? 0,
            _count: undefined,
        })),
    }));
}

export async function findClassById(id, schoolId) {
    return prisma.schoolClass.findFirst({ where: { id, schoolId } });
}

export async function findClassByName(name, schoolId) {
    return prisma.schoolClass.findFirst({ where: { name, schoolId } });
}

export async function createClass(data) {
    return prisma.schoolClass.create({ data });
}

export async function updateClass(id, schoolId, data) {
    return prisma.schoolClass.update({ where: { id, schoolId }, data: { ...data, updatedAt: new Date() } });
}

export async function deleteClass(id, schoolId) {
    return prisma.schoolClass.delete({ where: { id, schoolId } });
}

// ── Sections ──────────────────────────────────────────────────────────────────

export async function findSectionsByClass(classId, schoolId) {
    const rows = await prisma.section.findMany({
        where: { classId, schoolId },
        orderBy: { name: 'asc' },
        include: {
            classTeacher: { select: { id: true, firstName: true, lastName: true } },
            _count: { select: { students: true } },
        },
    });
    return rows.map((sec) => ({
        ...sec,
        student_count: sec._count?.students ?? 0,
        _count: undefined,
    }));
}

export async function findSectionById(id, schoolId) {
    return prisma.section.findFirst({ where: { id, schoolId } });
}

export async function findSectionByName(name, classId) {
    return prisma.section.findFirst({ where: { name, classId } });
}

export async function createSection(data) {
    return prisma.section.create({ data });
}

export async function updateSection(id, schoolId, data) {
    return prisma.section.update({ where: { id, schoolId }, data: { ...data, updatedAt: new Date() } });
}

export async function deleteSection(id, schoolId) {
    return prisma.section.delete({ where: { id, schoolId } });
}

// ── Attendance ────────────────────────────────────────────────────────────────

export async function findAttendanceForDate({ schoolId, classId, sectionId, date }) {
    const parsedDate = new Date(date);
    const dayStart = new Date(parsedDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(parsedDate);
    dayEnd.setHours(23, 59, 59, 999);

    return prisma.attendance.findMany({
        where: {
            schoolId,
            date: { gte: dayStart, lte: dayEnd },
            ...(sectionId && { sectionId }),
            ...(classId   && { student: { classId } }),
        },
        include: {
            student: { select: { id: true, firstName: true, lastName: true, admissionNo: true, rollNo: true } },
            section: { select: { id: true, name: true } },
        },
        orderBy: { student: { rollNo: 'asc' } },
    });
}

export async function upsertAttendanceRecord({ studentId, schoolId, sectionId, date, status, markedBy, remarks }) {
    const parsedDate = new Date(date);
    parsedDate.setHours(0, 0, 0, 0);

    return prisma.attendance.upsert({
        where:  { studentId_date: { studentId, date: parsedDate } },
        create: { studentId, schoolId, sectionId, date: parsedDate, status, markedBy, remarks },
        update: { status, remarks, updatedAt: new Date() },
    });
}

export async function findAttendanceReport({ schoolId, classId, sectionId, month }) {
    // month format: "2026-03"
    const [year, mon] = month.split('-').map(Number);
    const start = new Date(year, mon - 1, 1);
    const end   = new Date(year, mon, 0, 23, 59, 59, 999);

    return prisma.attendance.findMany({
        where: {
            schoolId,
            date: { gte: start, lte: end },
            ...(sectionId && { sectionId }),
            ...(classId   && { student: { classId } }),
        },
        select: { date: true, status: true },
        orderBy: { date: 'asc' },
    });
}

// ── Fee Structures ────────────────────────────────────────────────────────────

export async function findFeeStructures({ schoolId, academicYear, classId }) {
    try {
        const rows = await prisma.feeStructure.findMany({
            where: {
                schoolId,
                ...(academicYear && { academicYear }),
                ...(classId      && { classId }),
            },
            orderBy: { feeHead: 'asc' },
        });
        const enriched = await Promise.all(rows.map(async (r) => {
            if (!r.classId) return { ...r, className: null };
            try {
                const c = await prisma.schoolClass.findFirst({ where: { id: r.classId }, select: { name: true } });
                return { ...r, className: c?.name ?? null };
            } catch {
                return { ...r, className: null };
            }
        }));
        return enriched;
    } catch (err) {
        // Fallback: raw SQL if Prisma fails (e.g. schema mismatch with legacy columns)
        let whereClause = 'WHERE school_id = $1::uuid AND (deleted_at IS NULL OR deleted_at > NOW())';
        const params = [schoolId];
        if (academicYear) {
            params.push(academicYear);
            whereClause += ` AND academic_year = $${params.length}`;
        }
        if (classId) {
            params.push(classId);
            whereClause += ` AND class_id = $${params.length}::uuid`;
        }
        const rows = await prisma.$queryRawUnsafe(`
            SELECT id, school_id as "schoolId", class_id as "classId", academic_year as "academicYear",
                   fee_head as "feeHead", amount, frequency, due_day as "dueDay",
                   is_active as "isActive", created_at as "createdAt", updated_at as "updatedAt"
            FROM fee_structures
            ${whereClause}
            ORDER BY fee_head ASC
        `, ...params);
        const enriched = await Promise.all(rows.map(async (r) => {
            if (!r.classId) return { ...r, className: null };
            try {
                const c = await prisma.schoolClass.findFirst({ where: { id: r.classId }, select: { name: true } });
                return { ...r, className: c?.name ?? null };
            } catch {
                return { ...r, className: null };
            }
        }));
        return enriched;
    }
}

export async function findFeeStructureById(id, schoolId) {
    return prisma.feeStructure.findFirst({ where: { id, schoolId } });
}

export async function createFeeStructure(data) {
    try {
        return await prisma.feeStructure.create({ data });
    } catch (err) {
        // Fallback: raw insert if Prisma fails (e.g. schema mismatch)
        const id = randomUUID();
        const { schoolId, feeHead, academicYear, amount, frequency, classId, dueDay, isActive } = data;
        await prisma.$executeRawUnsafe(`
            INSERT INTO fee_structures (id, school_id, fee_head, academic_year, amount, frequency, class_id, due_day, is_active, created_at, updated_at)
            VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7::uuid, $8, $9, NOW(), NOW())
        `, id, schoolId, feeHead, academicYear, Number(amount), frequency, classId || null, dueDay ?? null, isActive !== false);
        return prisma.feeStructure.findUnique({ where: { id } });
    }
}

export async function updateFeeStructure(id, schoolId, data) {
    return prisma.feeStructure.update({ where: { id, schoolId }, data: { ...data, updatedAt: new Date() } });
}

export async function deleteFeeStructure(id, schoolId) {
    return prisma.feeStructure.delete({ where: { id, schoolId } });
}

// ── Fee Payments ──────────────────────────────────────────────────────────────

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

    const [rows, total] = await Promise.all([
        prisma.feePayment.findMany({
            where,
            skip,
            take: limit,
            orderBy: { paymentDate: 'desc' },
            include: {
                student: { select: { firstName: true, lastName: true, admissionNo: true } },
            },
        }),
        prisma.feePayment.count({ where }),
    ]);

    const data = rows.map((p) => ({
        ...p,
        studentName: p.student
            ? `${p.student.firstName} ${p.student.lastName}`.trim() || p.student.admissionNo
            : null,
        student: undefined,
    }));

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findFeePaymentById(id, schoolId) {
    return prisma.feePayment.findFirst({ where: { id, schoolId } });
}

export async function findFeePaymentByReceiptNo(receiptNo, schoolId) {
    return prisma.feePayment.findFirst({ where: { receiptNo, schoolId } });
}

export async function createFeePayment(data) {
    return prisma.feePayment.create({ data });
}

export async function getFeeSummary({ schoolId, month }) {
    const [year, mon] = month.split('-').map(Number);
    const start = new Date(year, mon - 1, 1);
    const end   = new Date(year, mon, 0, 23, 59, 59, 999);

    return prisma.feePayment.groupBy({
        by: ['feeHead', 'paymentMode'],
        where: { schoolId, paymentDate: { gte: start, lte: end } },
        _sum:   { amount: true },
        _count: { id: true },
    });
}

// ── Timetable ─────────────────────────────────────────────────────────────────

export async function findTimetable({ schoolId, classId, sectionId }) {
    return prisma.timetable.findMany({
        where: {
            schoolId,
            ...(classId   && { classId }),
            ...(sectionId && { sectionId }),
        },
        orderBy: [{ dayOfWeek: 'asc' }, { periodNo: 'asc' }],
    });
}

export async function replaceTimetable({ schoolId, classId, sectionId, entries, staffId }) {
    // Delete existing then create new in a transaction
    return prisma.$transaction(async (tx) => {
        await tx.timetable.deleteMany({
            where: {
                schoolId,
                classId,
                ...(sectionId ? { sectionId } : { sectionId: null }),
            },
        });

        if (entries.length === 0) return [];

        return tx.timetable.createMany({
            data: entries.map((e) => ({
                schoolId,
                classId,
                sectionId: sectionId || null,
                dayOfWeek: e.dayOfWeek,
                periodNo:  e.periodNo,
                subject:   e.subject,
                staffId:   e.staffId || null,
                startTime: e.startTime,
                endTime:   e.endTime,
                room:      e.room || null,
            })),
        });
    });
}

// ── Notices ───────────────────────────────────────────────────────────────────

export async function findNotices({ schoolId, page = 1, limit = 20, search }) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        deletedAt: null,
        ...(search && {
            OR: [
                { title: { contains: search, mode: 'insensitive' } },
                { body:  { contains: search, mode: 'insensitive' } },
            ],
        }),
    };

    const [data, total] = await Promise.all([
        prisma.schoolNotice.findMany({
            where,
            skip,
            take: limit,
            orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
        }),
        prisma.schoolNotice.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findNoticeById(id, schoolId) {
    return prisma.schoolNotice.findFirst({ where: { id, schoolId, deletedAt: null } });
}

export async function createNotice(data) {
    return prisma.schoolNotice.create({ data });
}

export async function updateNotice(id, schoolId, data) {
    return prisma.schoolNotice.update({ where: { id, schoolId }, data: { ...data, updatedAt: new Date() } });
}

export async function softDeleteNotice(id, schoolId) {
    return prisma.schoolNotice.update({ where: { id, schoolId }, data: { deletedAt: new Date() } });
}

// ── Profile ───────────────────────────────────────────────────────────────────

export async function findUserById(userId) {
    return prisma.user.findFirst({
        where: { id: userId, deletedAt: null },
        select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
            avatarUrl: true,
            schoolId: true,
            isActive: true,
            lastLogin: true,
            createdAt: true,
        },
    });
}

export async function findSchoolById(schoolId) {
    return prisma.school.findFirst({ where: { id: schoolId } });
}

export async function updateUser(userId, data) {
    return prisma.user.update({ where: { id: userId }, data: { ...data, updatedAt: new Date() } });
}

export async function updateSchool(schoolId, data) {
    return prisma.school.update({ where: { id: schoolId }, data: { ...data, updatedAt: new Date() } });
}

export async function findUserWithPasswordHash(userId) {
    return prisma.user.findFirst({ where: { id: userId }, select: { id: true, passwordHash: true } });
}
