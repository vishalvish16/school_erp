/**
 * Non-Teaching Staff Repository — all Prisma queries.
 * Every query is scoped to schoolId from JWT — no cross-school access possible.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ── Roles ──────────────────────────────────────────────────────────────────

export async function findRoles({ schoolId, includeInactive = false }) {
    const where = {
        OR: [
            { schoolId },
            { schoolId: null },
        ],
    };
    if (!includeInactive) {
        where.isActive = true;
    }
    return prisma.nonTeachingStaffRole.findMany({
        where,
        include: {
            _count: { select: { staff: true } },
        },
        orderBy: [
            { isSystem: 'asc' },
            { category: 'asc' },
            { displayName: 'asc' },
        ],
    });
}

export async function findRoleById(roleId, schoolId) {
    return prisma.nonTeachingStaffRole.findFirst({
        where: {
            id: roleId,
            OR: [
                { schoolId },
                { schoolId: null },
            ],
        },
    });
}

export async function findRoleByCode(code, schoolId) {
    return prisma.nonTeachingStaffRole.findFirst({
        where: { code, schoolId },
    });
}

export async function findSystemRoleByCode(code) {
    return prisma.nonTeachingStaffRole.findFirst({
        where: { code, schoolId: null, isSystem: true },
    });
}

export async function createRole(data) {
    return prisma.nonTeachingStaffRole.create({ data });
}

export async function updateRole(roleId, schoolId, data) {
    // schoolId ensures only school-owned (non-system) roles can be modified
    await prisma.nonTeachingStaffRole.updateMany({
        where: { id: roleId, schoolId, isSystem: false },
        data,
    });
    return prisma.nonTeachingStaffRole.findFirst({ where: { id: roleId, schoolId } });
}

export async function toggleRole(roleId, schoolId, currentIsActive) {
    await prisma.nonTeachingStaffRole.updateMany({
        where: { id: roleId, schoolId, isSystem: false },
        data:  { isActive: !currentIsActive },
    });
    return prisma.nonTeachingStaffRole.findFirst({ where: { id: roleId, schoolId } });
}

export async function deleteRole(roleId, schoolId) {
    // Only delete school-owned non-system roles
    return prisma.nonTeachingStaffRole.deleteMany({
        where: { id: roleId, schoolId, isSystem: false },
    });
}

export async function countStaffByRole(roleId, schoolId) {
    return prisma.nonTeachingStaff.count({
        where: { roleId, schoolId, deletedAt: null },
    });
}

// ── Staff ──────────────────────────────────────────────────────────────────

export async function findStaff({
    schoolId,
    page      = 1,
    limit     = 20,
    search,
    roleId,
    category,
    department,
    employeeType,
    isActive,
    sortBy    = 'firstName',
    sortOrder = 'asc',
}) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        deletedAt: null,
    };

    if (search) {
        where.OR = [
            { firstName:  { contains: search, mode: 'insensitive' } },
            { lastName:   { contains: search, mode: 'insensitive' } },
            { email:      { contains: search, mode: 'insensitive' } },
            { employeeNo: { contains: search, mode: 'insensitive' } },
            { phone:      { contains: search, mode: 'insensitive' } },
        ];
    }

    if (roleId)       where.roleId       = roleId;
    if (department)   where.department   = { contains: department, mode: 'insensitive' };
    if (employeeType) where.employeeType = employeeType;
    if (isActive !== undefined && isActive !== '') {
        where.isActive = isActive === 'true' || isActive === true;
    }

    // If category filter, join through role
    if (category) {
        where.role = { category };
    }

    const allowedSortFields = ['firstName', 'lastName', 'employeeNo', 'joinDate', 'createdAt', 'department'];
    const safeSort = allowedSortFields.includes(sortBy) ? sortBy : 'firstName';
    const safeOrder = sortOrder === 'desc' ? 'desc' : 'asc';

    const [data, total] = await Promise.all([
        prisma.nonTeachingStaff.findMany({
            where,
            skip,
            take:     limit,
            orderBy:  { [safeSort]: safeOrder },
            include:  { role: true },
        }),
        prisma.nonTeachingStaff.count({ where }),
    ]);

    return {
        data,
        pagination: {
            page,
            limit,
            total,
            total_pages: Math.ceil(total / limit),
        },
    };
}

export async function findStaffById(id, schoolId) {
    return prisma.nonTeachingStaff.findFirst({
        where: { id, schoolId, deletedAt: null },
        include: {
            role: true,
            user: {
                select: {
                    id:          true,
                    isActive:    true,
                    email:       true,
                    lastLogin:   true,
                },
            },
        },
    });
}

export async function findStaffByEmail(email, schoolId) {
    return prisma.nonTeachingStaff.findFirst({
        where: { email, schoolId, deletedAt: null },
    });
}

export async function findStaffByEmployeeNo(employeeNo, schoolId) {
    return prisma.nonTeachingStaff.findFirst({
        where: { employeeNo, schoolId, deletedAt: null },
    });
}

export async function createStaff(data) {
    return prisma.nonTeachingStaff.create({ data });
}

export async function updateStaff(id, schoolId, data) {
    // Use updateMany to atomically scope by both id and schoolId (tenant isolation)
    await prisma.nonTeachingStaff.updateMany({
        where: { id, schoolId },
        data:  { ...data, updatedAt: new Date() },
    });
    // Return the updated record with role included (same shape as findStaffById)
    return prisma.nonTeachingStaff.findFirst({
        where:   { id, schoolId },
        include: { role: true },
    });
}

export async function softDeleteStaff(id, schoolId) {
    // Use updateMany to atomically scope by both id and schoolId (tenant isolation)
    return prisma.nonTeachingStaff.updateMany({
        where: { id, schoolId },
        data:  { deletedAt: new Date(), isActive: false },
    });
}

export async function generateEmployeeNo(schoolId) {
    const year  = new Date().getFullYear();
    const count = await prisma.nonTeachingStaff.count({
        where: {
            schoolId,
            createdAt: { gte: new Date(`${year}-01-01`) },
            deletedAt: null,
        },
    });
    return `NTS-${year}-${String(count + 1).padStart(3, '0')}`;
}

export async function validateStaffBelongToSchool(schoolId, staffIds) {
    const count = await prisma.nonTeachingStaff.count({
        where: {
            id:        { in: staffIds },
            schoolId,
            deletedAt: null,
        },
    });
    return count === staffIds.length;
}

export async function findUserByEmail(email) {
    return prisma.user.findFirst({ where: { email, deletedAt: null } });
}

export async function findRoleByName(name) {
    return prisma.role.findFirst({ where: { name } });
}

export async function createUserAndLinkStaff({ staff, passwordHash, schoolId, roleId }) {
    return prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
            data: {
                email:      staff.email,
                passwordHash,
                schoolId,
                firstName:  staff.firstName || null,
                lastName:   staff.lastName  || null,
                phone:      staff.phone     || null,
                roleId,
            },
            // Select only safe fields — never return passwordHash
            select: {
                id:        true,
                email:     true,
                schoolId:  true,
                firstName: true,
                lastName:  true,
                phone:     true,
                isActive:  true,
                createdAt: true,
            },
        });
        // Scope update by both id AND schoolId to prevent TOCTOU cross-tenant link
        const updated = await tx.nonTeachingStaff.updateMany({
            where: { id: staff.id, schoolId },
            data:  { userId: newUser.id },
        });
        if (!updated.count) {
            throw new Error('Staff record not found for this school during login creation');
        }
        return { user: newUser };
    });
}

export async function updateUserPassword(userId, passwordHash) {
    return prisma.user.update({
        where: { id: userId },
        data:  { passwordHash },
    });
}

// ── Qualifications ─────────────────────────────────────────────────────────

export async function findQualifications(staffId, schoolId) {
    return prisma.nonTeachingStaffQualification.findMany({
        where:   { staffId, schoolId },
        orderBy: { createdAt: 'desc' },
    });
}

export async function createQualification(data) {
    return prisma.nonTeachingStaffQualification.create({ data });
}

export async function unsetHighestQualification(staffId, schoolId) {
    return prisma.nonTeachingStaffQualification.updateMany({
        where: { staffId, schoolId, isHighest: true },
        data:  { isHighest: false },
    });
}

export async function updateQualification(qualId, staffId, schoolId, data) {
    await prisma.nonTeachingStaffQualification.updateMany({
        where: { id: qualId, staffId, schoolId },
        data,
    });
    return prisma.nonTeachingStaffQualification.findFirst({ where: { id: qualId, staffId, schoolId } });
}

export async function deleteQualification(qualId, staffId, schoolId) {
    return prisma.nonTeachingStaffQualification.deleteMany({
        where: { id: qualId, staffId, schoolId },
    });
}

export async function findQualificationById(qualId, staffId, schoolId) {
    return prisma.nonTeachingStaffQualification.findFirst({
        where: { id: qualId, staffId, schoolId },
    });
}

// ── Documents ──────────────────────────────────────────────────────────────

export async function findDocuments(staffId, schoolId) {
    return prisma.nonTeachingStaffDocument.findMany({
        where:   { staffId, schoolId, deletedAt: null },
        orderBy: { createdAt: 'desc' },
    });
}

export async function createDocument(data) {
    return prisma.nonTeachingStaffDocument.create({ data });
}

export async function softDeleteDocument(docId, staffId, schoolId) {
    // Use updateMany to atomically scope by docId + staffId + schoolId (tenant isolation)
    return prisma.nonTeachingStaffDocument.updateMany({
        where: { id: docId, staffId, schoolId, deletedAt: null },
        data:  { deletedAt: new Date() },
    });
}

export async function verifyDocument(docId, staffId, schoolId, verifiedBy) {
    // Use updateMany to atomically scope by docId + staffId + schoolId (tenant isolation)
    await prisma.nonTeachingStaffDocument.updateMany({
        where: { id: docId, staffId, schoolId, deletedAt: null },
        data:  { verified: true, verifiedBy, verifiedAt: new Date() },
    });
    return prisma.nonTeachingStaffDocument.findFirst({ where: { id: docId, staffId, schoolId } });
}

export async function findDocumentById(docId, staffId, schoolId) {
    return prisma.nonTeachingStaffDocument.findFirst({
        where: { id: docId, staffId, schoolId, deletedAt: null },
    });
}

// ── Attendance ─────────────────────────────────────────────────────────────

export async function findAttendanceForDate({ schoolId, date, department, category }) {
    const staffWhere = {
        schoolId,
        deletedAt: null,
        isActive:  true,
    };
    if (department) staffWhere.department = { contains: department, mode: 'insensitive' };
    if (category)   staffWhere.role = { category };

    const dateObj = new Date(date);

    const [staffList, attendances] = await Promise.all([
        prisma.nonTeachingStaff.findMany({
            where:   staffWhere,
            include: { role: true },
            orderBy: { firstName: 'asc' },
        }),
        prisma.nonTeachingStaffAttendance.findMany({
            where: {
                schoolId,
                date: dateObj,
            },
        }),
    ]);

    // Build a map of existing attendance records by staffId
    const attendanceMap = {};
    for (const a of attendances) {
        attendanceMap[a.staffId] = a;
    }

    // Merge: each staff entry with their attendance status (null if not yet marked)
    return staffList.map((s) => ({
        staff:      s,
        attendance: attendanceMap[s.id] || null,
    }));
}

export async function upsertAttendanceBulk({ schoolId, userId, date, records }) {
    const dateObj = new Date(date);
    let created = 0;
    let updated = 0;

    await prisma.$transaction(
        records.map((r) =>
            prisma.nonTeachingStaffAttendance.upsert({
                where:  { staffId_date: { staffId: r.staffId, date: dateObj } },
                update: {
                    status:       r.status,
                    checkInTime:  r.checkInTime  || null,
                    checkOutTime: r.checkOutTime || null,
                    remarks:      r.remarks      || null,
                    markedBy:     userId,
                },
                create: {
                    staffId:      r.staffId,
                    schoolId,
                    date:         dateObj,
                    status:       r.status,
                    checkInTime:  r.checkInTime  || null,
                    checkOutTime: r.checkOutTime || null,
                    remarks:      r.remarks      || null,
                    markedBy:     userId,
                },
            })
        )
    );

    // Count created vs updated by checking existing records before operation
    // For simplicity, return total processed
    return { processed: records.length };
}

export async function findAttendanceById(id, schoolId) {
    return prisma.nonTeachingStaffAttendance.findFirst({
        where: { id, schoolId },
    });
}

export async function correctAttendance(id, schoolId, data, userId) {
    await prisma.nonTeachingStaffAttendance.updateMany({
        where: { id, schoolId },
        data:  {
            ...data,
            markedBy: userId,
        },
    });
    return prisma.nonTeachingStaffAttendance.findFirst({ where: { id, schoolId } });
}

export async function getMonthlyAttendanceSummary({ schoolId, startDate, endDate, staffId, department }) {
    const where = {
        schoolId,
        date: { gte: startDate, lte: endDate },
    };
    if (staffId) where.staffId = staffId;

    // If department filter, join staff
    if (department) {
        where.staff = { department: { contains: department, mode: 'insensitive' } };
    }

    const records = await prisma.nonTeachingStaffAttendance.findMany({
        where,
        include: {
            staff: { include: { role: true } },
        },
        orderBy: [{ staffId: 'asc' }, { date: 'asc' }],
    });

    // Aggregate totals
    const summary = { present: 0, absent: 0, half_day: 0, on_leave: 0, late: 0, holiday: 0 };
    const byStaff = {};

    for (const r of records) {
        const statusKey = r.status.toLowerCase();
        if (statusKey in summary) summary[statusKey]++;
        else summary[statusKey] = (summary[statusKey] || 0) + 1;

        if (!byStaff[r.staffId]) {
            byStaff[r.staffId] = {
                staff_id:   r.staffId,
                first_name: r.staff.firstName,
                last_name:  r.staff.lastName,
                employee_no: r.staff.employeeNo,
                role:       r.staff.role ? { id: r.staff.role.id, display_name: r.staff.role.displayName } : null,
                present:    0,
                absent:     0,
                half_day:   0,
                on_leave:   0,
                late:       0,
                holiday:    0,
            };
        }
        const staffEntry = byStaff[r.staffId];
        if (statusKey in staffEntry) staffEntry[statusKey]++;
    }

    return { summary, by_staff: Object.values(byStaff) };
}

// ── Leaves ─────────────────────────────────────────────────────────────────

export async function findLeaves({ schoolId, page = 1, limit = 20, status, staffId, leaveType, fromDate, toDate }) {
    const skip  = (page - 1) * limit;
    const where = { schoolId };

    if (status)    where.status    = status;
    if (staffId)   where.staffId   = staffId;
    if (leaveType) where.leaveType = leaveType;
    if (fromDate)  where.fromDate  = { gte: new Date(fromDate) };
    if (toDate)    where.toDate    = { lte: new Date(toDate) };

    const [data, total] = await Promise.all([
        prisma.nonTeachingStaffLeave.findMany({
            where,
            skip,
            take:    limit,
            orderBy: { createdAt: 'desc' },
            include: {
                staff: {
                    include: { role: true },
                },
            },
        }),
        prisma.nonTeachingStaffLeave.count({ where }),
    ]);

    return {
        data,
        pagination: {
            page,
            limit,
            total,
            total_pages: Math.ceil(total / limit),
        },
    };
}

export async function findLeaveById(leaveId, schoolId) {
    return prisma.nonTeachingStaffLeave.findFirst({
        where: { id: leaveId, schoolId },
        include: { staff: true },
    });
}

export async function findOverlappingLeave(staffId, schoolId, fromDate, toDate) {
    return prisma.nonTeachingStaffLeave.findFirst({
        where: {
            staffId,
            schoolId,
            status: { in: ['PENDING', 'APPROVED'] },
            AND: [
                { fromDate: { lte: toDate   } },
                { toDate:   { gte: fromDate } },
            ],
        },
    });
}

export async function createLeave(data) {
    return prisma.nonTeachingStaffLeave.create({ data });
}

export async function updateLeave(leaveId, schoolId, data) {
    // schoolId scopes the update to the correct tenant — prevents cross-school leave modification
    await prisma.nonTeachingStaffLeave.updateMany({
        where: { id: leaveId, schoolId },
        data,
    });
    return prisma.nonTeachingStaffLeave.findFirst({ where: { id: leaveId, schoolId } });
}

export async function getLeaveSummary({ schoolId, staffId, startDate, endDate }) {
    const where = { schoolId };
    if (staffId)   where.staffId  = staffId;
    if (startDate) where.fromDate = { gte: startDate };
    if (endDate)   where.toDate   = { lte: endDate };

    const rows = await prisma.nonTeachingStaffLeave.groupBy({
        by:    ['leaveType'],
        where,
        _sum:  { totalDays: true },
        _count: { id: true },
    });

    return rows.map((r) => ({
        leave_type:  r.leaveType,
        total_days:  r._sum.totalDays,
        total_count: r._count.id,
    }));
}

export async function findStaffLeaves({ staffId, schoolId, page = 1, limit = 20, status, leaveType, fromDate, toDate }) {
    const skip  = (page - 1) * limit;
    const where = { staffId, schoolId };

    if (status)    where.status    = status;
    if (leaveType) where.leaveType = leaveType;
    if (fromDate)  where.fromDate  = { gte: new Date(fromDate) };
    if (toDate)    where.toDate    = { lte: new Date(toDate) };

    const [data, total] = await Promise.all([
        prisma.nonTeachingStaffLeave.findMany({
            where,
            skip,
            take:    limit,
            orderBy: { createdAt: 'desc' },
        }),
        prisma.nonTeachingStaffLeave.count({ where }),
    ]);

    return {
        data,
        pagination: {
            page,
            limit,
            total,
            total_pages: Math.ceil(total / limit),
        },
    };
}
