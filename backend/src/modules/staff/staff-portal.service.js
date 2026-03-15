/**
 * Staff Portal Service — business logic for all staff portal routes.
 * All methods receive schoolId from req.staff.schoolId (never from user input).
 */
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/response.js';
import * as repo from './staff-portal.repository.js';
import * as ntRepo from '../non-teaching-staff/non-teaching-staff.repository.js';
import * as auditService from '../audit/audit.service.js';

// ── Dashboard ──────────────────────────────────────────────────────────────────

export async function getDashboardStats({ schoolId, staffRecord }) {
    if (!schoolId) throw new AppError('School context required', 400);
    return repo.getStaffDashboardStats(schoolId, staffRecord);
}

// ── Fee Payments ───────────────────────────────────────────────────────────────

export async function getFeePayments({ schoolId, page, limit, studentId, month, academicYear }) {
    return repo.findFeePayments({ schoolId, page, limit, studentId, month, academicYear });
}

export async function getFeePaymentById({ id, schoolId }) {
    const payment = await repo.findFeePaymentById(id, schoolId);
    if (!payment) throw new AppError('Fee payment not found', 404);
    return payment;
}

export async function createFeePayment({ schoolId, staffId, userId, data }) {
    // Validate that the student belongs to this school
    const student = await repo.findStudentById(data.studentId, schoolId);
    if (!student) throw new AppError('Student not found in this school', 404);

    // Generate server-side receipt number: RCP/{YEAR}/{5-digit-seq}
    const year    = new Date().getFullYear();
    const maxSeq  = await repo.findMaxReceiptSeqForYear(schoolId, year);
    const nextSeq = maxSeq + 1;
    const receiptNo = `RCP/${year}/${String(nextSeq).padStart(5, '0')}`;

    // Double-check there's no collision (race condition safety)
    const duplicate = await repo.findFeePaymentByReceiptNo(receiptNo, schoolId);
    if (duplicate) {
        throw new AppError('Receipt number collision — please try again', 409);
    }

    const payment = await repo.createFeePayment({
        schoolId,
        studentId:   data.studentId,
        feeHead:     data.feeHead,
        academicYear: data.academicYear,
        amount:      data.amount,
        paymentDate: new Date(data.paymentDate),
        paymentMode: data.paymentMode,
        receiptNo,
        collectedBy: userId,
        remarks:     data.remarks ?? null,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'staff',
        action:     'FEE_PAYMENT_CREATE',
        entityType: 'fee_payments',
        entityId:   payment.id,
        entityName: receiptNo,
        extra:      { amount: data.amount, studentId: data.studentId, schoolId },
    }).catch(() => {});

    return payment;
}

export async function getFeeSummary({ schoolId, month }) {
    if (!month) throw new AppError('month query parameter is required (format: YYYY-MM)', 400);

    const rows = await repo.getFeeSummary({ schoolId, month });

    const byFeeHead  = {};
    let   grandTotal = 0;

    for (const row of rows) {
        const amount = Number(row._sum.amount ?? 0);
        grandTotal  += amount;
        if (!byFeeHead[row.feeHead]) {
            byFeeHead[row.feeHead] = { fee_head: row.feeHead, total: 0, breakdown: [] };
        }
        byFeeHead[row.feeHead].total += amount;
        byFeeHead[row.feeHead].breakdown.push({
            payment_mode: row.paymentMode,
            amount,
            count: row._count.id,
        });
    }

    return {
        month,
        grand_total: grandTotal,
        by_fee_head: Object.values(byFeeHead),
    };
}

export async function getFeeStructures({ schoolId, academicYear, classId }) {
    return repo.findFeeStructures({ schoolId, academicYear, classId });
}

// ── Students (read-only) ───────────────────────────────────────────────────────

export async function getStudents({ schoolId, page, limit, search, classId, sectionId }) {
    return repo.findStudents({ schoolId, page, limit, search, classId, sectionId });
}

export async function getStudentById({ id, schoolId }) {
    const student = await repo.findStudentById(id, schoolId);
    if (!student) throw new AppError('Student not found', 404);
    return student;
}

export async function getClasses({ schoolId }) {
    return repo.findAllClasses(schoolId);
}

// ── Notices (read-only) ────────────────────────────────────────────────────────

export async function getNotices({ schoolId, page, limit }) {
    return repo.findNoticesForStaff({ schoolId, page, limit });
}

export async function getNoticeById({ id, schoolId }) {
    const notice = await repo.findNoticeById(id, schoolId);
    if (!notice) throw new AppError('Notice not found', 404);
    return notice;
}

// ── Notifications (stub — no Notification model in schema yet) ────────────────

export async function getNotifications({ userId, schoolId, page = 1, limit = 20 }) {
    // Stub — Notification model not yet in schema. userId + schoolId accepted for future use.
    return {
        data:       [],
        pagination: { page, limit, total: 0, total_pages: 0 },
    };
}

export async function getUnreadNotificationCount({ userId, schoolId }) {
    // Stub — userId + schoolId accepted for future scoped queries
    return { unread_count: 0 };
}

export async function markNotificationRead({ id, userId, schoolId }) {
    // Stub — no-op until Notification model is added to schema
    // userId + schoolId ensure future implementation will be tenant-scoped
    return { id, read: true };
}

export async function markAllNotificationsRead({ userId, schoolId }) {
    // Stub — no-op until Notification model is added to schema
    return { marked: 0 };
}

// ── Profile ────────────────────────────────────────────────────────────────────

export async function getProfile({ userId, schoolId, staffRecord }) {
    const [user, school] = await Promise.all([
        repo.findUserById(userId),
        repo.findSchoolById(schoolId),
    ]);
    if (!user)   throw new AppError('User not found', 404);
    if (!school) throw new AppError('School not found', 404);

    return {
        user,
        staff:  staffRecord,
        school: {
            id:      school.id,
            name:    school.name,
            logoUrl: school.logoUrl,
            email:   school.email,
            phone:   school.phone,
        },
    };
}

export async function updateUserProfile({ userId, data }) {
    const user = await repo.findUserById(userId);
    if (!user) throw new AppError('User not found', 404);

    return repo.updateUser(userId, {
        firstName: data.firstName ?? undefined,
        lastName:  data.lastName  ?? undefined,
        phone:     data.phone     ?? null,
        avatarUrl: data.avatarUrl ?? null,
    });
}

export async function sendOtp({ userId, data }) {
    // Placeholder — real OTP flow will be implemented when OTP module is wired
    // Returns a stub session ID for now
    return {
        otp_session_id: `stub-${Date.now()}`,
        message:        'OTP sent (stub — not yet active)',
    };
}

// ── Change Password ────────────────────────────────────────────────────────────

export async function changePassword({ userId, currentPassword, newPassword }) {
    const user = await repo.findUserWithPasswordHash(userId);
    if (!user) throw new AppError('User not found', 404);

    const match = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!match) throw new AppError('Current password is incorrect', 400);

    const hash = await bcrypt.hash(newPassword, 12);
    await repo.updateUser(userId, { passwordHash: hash, passwordChangedAt: new Date() });
}

// ── Non-Teaching Staff Self-Service ────────────────────────────────────────────

export async function getMyProfile({ userId, schoolId, staffRecord, isNonTeaching }) {
    const [user, school] = await Promise.all([
        repo.findUserById(userId),
        repo.findSchoolById(schoolId),
    ]);
    if (!user)   throw new AppError('User not found', 404);
    if (!school) throw new AppError('School not found', 404);

    const base = {
        user,
        school: {
            id:      school.id,
            name:    school.name,
            logoUrl: school.logoUrl,
            email:   school.email,
            phone:   school.phone,
        },
    };

    if (isNonTeaching) {
        const ntStaff = await ntRepo.findStaffById(staffRecord.id, schoolId);
        const portalAccess = ntStaff?.role
            ? {
                fee_collection:    ntStaff.role.category === 'FINANCE',
                library_dashboard: ntStaff.role.category === 'LIBRARY',
                lab_inventory:     ntStaff.role.category === 'LABORATORY',
              }
            : {};
        // Sanitise ntStaff before returning — remove any sensitive fields that may come from
        // the raw Prisma record (passwordHash never appears on NonTeachingStaff but
        // defensive explicit selection prevents future regressions)
        const safeStaff = ntStaff ? {
            id:                      ntStaff.id,
            school_id:               ntStaff.schoolId,
            employee_no:             ntStaff.employeeNo,
            first_name:              ntStaff.firstName,
            last_name:               ntStaff.lastName,
            full_name:               `${ntStaff.firstName} ${ntStaff.lastName}`,
            gender:                  ntStaff.gender,
            phone:                   ntStaff.phone,
            email:                   ntStaff.email,
            department:              ntStaff.department,
            designation:             ntStaff.designation,
            join_date:               ntStaff.joinDate,
            employee_type:           ntStaff.employeeType,
            is_active:               ntStaff.isActive,
            photo_url:               ntStaff.photoUrl,
            has_login:               ntStaff.userId !== null,
            role: ntStaff.role ? {
                id:           ntStaff.role.id,
                code:         ntStaff.role.code,
                display_name: ntStaff.role.displayName,
                category:     ntStaff.role.category,
            } : null,
            // user sub-object already uses safe select in findStaffById
            user: ntStaff.user ? {
                id:         ntStaff.user.id,
                is_active:  ntStaff.user.isActive,
                email:      ntStaff.user.email,
                last_login: ntStaff.user.lastLogin,
            } : null,
        } : null;
        return { ...base, staff: safeStaff, staff_type: 'non_teaching', portal_access: portalAccess };
    }

    return { ...base, staff: staffRecord, staff_type: 'teaching', portal_access: {} };
}

export async function getMyAttendance({ staffId, schoolId, month, isNonTeaching }) {
    if (!month) throw new AppError('month query parameter is required (format: YYYY-MM)', 400);

    const [year, mon] = month.split('-').map(Number);
    if (!year || !mon) throw new AppError('Invalid month format. Use YYYY-MM', 400);

    const startDate = new Date(year, mon - 1, 1);
    const endDate   = new Date(year, mon, 0);

    if (isNonTeaching) {
        const { summary, by_staff } = await ntRepo.getMonthlyAttendanceSummary({
            schoolId,
            startDate,
            endDate,
            staffId,
        });
        return { month, summary, records: by_staff };
    }

    // Teaching staff attendance — return stub (teaching staff module handles its own attendance)
    return {
        month,
        summary: { present: 0, absent: 0, half_day: 0, on_leave: 0 },
        records: [],
        note: 'Teaching staff attendance is managed through the class attendance module',
    };
}

export async function getMyLeaves({ staffId, schoolId, isNonTeaching, page, limit, status }) {
    if (isNonTeaching) {
        const result = await ntRepo.findStaffLeaves({ staffId, schoolId, page, limit, status });
        return {
            data: result.data,
            pagination: result.pagination,
        };
    }
    // Teaching staff leaves — return stub until teaching-staff leave module is wired
    return { data: [], pagination: { page, limit, total: 0, total_pages: 0 } };
}

export async function applyMyLeave({ staffId, schoolId, userId, isNonTeaching, data }) {
    if (!isNonTeaching) {
        throw new AppError('Leave application via this endpoint is only available for non-teaching staff', 400);
    }

    const fromDate  = new Date(data.from_date);
    const toDate    = new Date(data.to_date);

    if (fromDate > toDate) throw new AppError('from_date must be on or before to_date', 400);

    const msPerDay  = 1000 * 60 * 60 * 24;
    const totalDays = Math.round((toDate - fromDate) / msPerDay) + 1;

    const overlap = await ntRepo.findOverlappingLeave(staffId, schoolId, fromDate, toDate);
    if (overlap) throw new AppError('You already have an overlapping leave application for this period', 409);

    const leave = await ntRepo.createLeave({
        staffId,
        schoolId,
        appliedBy: userId,
        leaveType: data.leave_type,
        fromDate,
        toDate,
        totalDays,
        reason:    data.reason,
        status:    'PENDING',
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'staff',
        action:     'NT_LEAVE_SELF_APPLY',
        entityType: 'non_teaching_staff_leaves',
        entityId:   leave.id,
        entityName: `Self leave — ${data.leave_type}`,
        extra:      { staffId, schoolId, fromDate: data.from_date, toDate: data.to_date, totalDays },
    }).catch(() => {});

    return leave;
}

export async function cancelMyLeave({ leaveId, staffId, schoolId, userId, isNonTeaching }) {
    if (!isNonTeaching) {
        throw new AppError('Leave cancellation via this endpoint is only available for non-teaching staff', 400);
    }

    const leave = await ntRepo.findLeaveById(leaveId, schoolId);
    if (!leave) throw new AppError('Leave application not found', 404);
    if (leave.staffId !== staffId) throw new AppError('You can only cancel your own leaves', 403);
    if (leave.status !== 'PENDING') throw new AppError('Only pending leaves can be cancelled', 400);

    const updated = await ntRepo.updateLeave(leaveId, schoolId, { status: 'CANCELLED' });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'staff',
        action:     'NT_LEAVE_SELF_CANCEL',
        entityType: 'non_teaching_staff_leaves',
        entityId:   leaveId,
        entityName: `Self leave cancel`,
        extra:      { staffId, schoolId },
    }).catch(() => {});

    return updated;
}

export async function getMyLeaveSummary({ staffId, schoolId, isNonTeaching, academicYear }) {
    if (!isNonTeaching) {
        return [];
    }

    let startDate, endDate;
    if (academicYear) {
        const [startYear] = academicYear.split('-').map(Number);
        startDate = new Date(startYear, 3, 1);
        endDate   = new Date(startYear + 1, 2, 31);
    }

    return ntRepo.getLeaveSummary({ schoolId, staffId, startDate, endDate });
}
