/**
 * Parent Portal Service — business logic for all parent routes.
 * All methods receive parentId and schoolId from req.parent.
 */
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/response.js';
import * as repo from './parent.repository.js';
import * as ntRepo from './parent-notifications.repository.js';
import * as auditService from '../audit/audit.service.js';

import prisma from '../../config/prisma.js';

function toProfileResponse(parent) {
    return {
        id: parent.id,
        firstName: parent.firstName,
        lastName: parent.lastName,
        phone: parent.phone,
        email: parent.email,
        relation: parent.relation,
        schoolId: parent.schoolId,
        schoolName: parent.school?.name || '',
    };
}

function toChildSummary(student) {
    return {
        id: student.id,
        admissionNo: student.admissionNo,
        firstName: student.firstName,
        lastName: student.lastName,
        class: student.class_?.name || '',
        section: student.section?.name || '',
        rollNo: student.rollNo,
        photoUrl: student.photoUrl,
    };
}

function toChildDetail(student) {
    const link = student.parentLinks?.[0];
    return {
        ...toChildSummary(student),
        dateOfBirth: student.dateOfBirth,
        bloodGroup: student.bloodGroup,
        address: student.address,
        parentRelation: link?.relation || student.parentRelation,
    };
}

export async function getProfile({ parentId, schoolId }) {
    const parent = await repo.findParentById(parentId, schoolId);
    if (!parent) throw new AppError('Parent not found', 404);
    return toProfileResponse(parent);
}

export async function updateProfile({ parentId, schoolId, data }) {
    const parent = await repo.findParentById(parentId, schoolId);
    if (!parent) throw new AppError('Parent not found', 404);

    const updateData = {};
    if (data.firstName !== undefined) updateData.firstName = data.firstName;
    if (data.lastName !== undefined) updateData.lastName = data.lastName;
    if (data.email !== undefined) updateData.email = data.email;

    if (Object.keys(updateData).length === 0) {
        return toProfileResponse(parent);
    }

    const updated = await repo.updateParent(parentId, schoolId, updateData);

    auditService.logAudit({
        actorId: null, // Parents have no users.id; actor_id FK references users(id)
        actorName: `${updated.firstName} ${updated.lastName}`.trim() || 'Parent',
        actorRole: 'parent',
        action: 'PARENT_PROFILE_UPDATE',
        entityType: 'parent',
        entityId: parentId,
        extra: { parentId, schoolId, updates: updateData },
    }).catch(() => {});

    return toProfileResponse(updated);
}

export async function getChildren({ parentId, schoolId }) {
    const students = await repo.findChildrenByParentId(parentId, schoolId);
    return { children: students.map(toChildSummary) };
}

export async function getChildById({ studentId, parentId, schoolId }) {
    const student = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!student) throw new AppError('Child not found', 404);
    return toChildDetail(student);
}

export async function getChildAttendance({ studentId, parentId, schoolId, month, limit = 31 }) {
    const child = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!child) throw new AppError('Child not found', 404);

    let monthStart, monthEnd;
    if (month) {
        const [y, m] = month.split('-').map(Number);
        monthStart = new Date(y, m - 1, 1);
        monthEnd = new Date(y, m, 0, 23, 59, 59, 999);
    } else {
        const now = new Date();
        monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    }

    const attendances = await repo.findAttendanceByStudentMonth(studentId, schoolId, monthStart, monthEnd, limit);
    return {
        attendances: attendances.map((a) => ({
            date: a.date.toISOString().slice(0, 10),
            status: a.status,
            remarks: a.remarks,
        })),
    };
}

export async function getChildFees({ studentId, parentId, schoolId, academicYear }) {
    const child = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!child) throw new AppError('Child not found', 404);

    const year = academicYear || `${new Date().getFullYear()}-${String(new Date().getFullYear() + 1).slice(-2)}`;
    const [feePayments, feeStructure] = await Promise.all([
        repo.findFeePaymentsByStudent(studentId, schoolId, year),
        repo.findFeeStructureByClass(child.classId, schoolId, year),
    ]);

    return {
        feePayments: feePayments.map((p) => ({
            id: p.id,
            feeHead: p.feeHead,
            amount: String(Number(p.amount)),
            paymentDate: p.paymentDate.toISOString().slice(0, 10),
            receiptNo: p.receiptNo,
            paymentMode: p.paymentMode,
        })),
        feeStructure: feeStructure.map((f) => ({
            feeHead: f.feeHead,
            amount: String(Number(f.amount)),
            frequency: f.frequency,
        })),
    };
}

export async function getNotices({ parentId, schoolId, page, limit }) {
    const result = await repo.findNoticesForParent(parentId, schoolId, page, limit);
    return {
        notices: result.data.map((n) => ({
            id: n.id,
            title: n.title,
            body: n.body,
            isPinned: n.isPinned ?? false,
            publishedAt: n.publishedAt?.toISOString() || n.createdAt?.toISOString() || null,
            expiresAt: n.expiresAt?.toISOString() || null,
            source: n.source || 'school',
            priority: n.priority || null,
        })),
        pagination: result.pagination,
    };
}

export async function getNoticeById({ id, parentId, schoolId }) {
    const notice = await repo.findNoticeById(id, parentId, schoolId);
    if (!notice) throw new AppError('Notice not found', 404);
    return {
        id: notice.id,
        title: notice.title,
        body: notice.body,
        isPinned: notice.isPinned ?? false,
        publishedAt: notice.publishedAt?.toISOString() || notice.createdAt?.toISOString() || null,
        expiresAt: notice.expiresAt?.toISOString() || null,
        source: notice.source || 'school',
        priority: notice.priority || null,
        sentBy: notice.sentBy || null,
    };
}

export async function registerFcmToken({ fcmToken, portalType, parentId, schoolId }) {
    const { upsertToken } = await import('../fcm/fcm.repository.js');
    await upsertToken({
        fcmToken,
        portalType,
        parentId,
        studentId: null,
        schoolId,
    });
}

export async function changePassword({ userId, parentId, currentPassword, newPassword }) {
    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, passwordHash: true },
    });
    if (!user) throw new AppError('User not found', 404);

    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) throw new AppError('Current password is incorrect', 401);

    const hash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
        where: { id: userId },
        data: { passwordHash: hash },
    });

    auditService.logAudit({
        actorId: userId || null, // Use userId when parent has User record; else null
        actorRole: 'parent',
        action: 'PARENT_CHANGE_PASSWORD',
        entityType: 'user',
        entityId: userId,
        extra: { parentId },
    }).catch(() => {});
}

export async function getChildAttendanceSummary({ studentId, parentId, schoolId, month }) {
    const child = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!child) throw new AppError('Child not found', 404);

    let monthStart, monthEnd;
    if (month) {
        const [y, m] = month.split('-').map(Number);
        monthStart = new Date(y, m - 1, 1);
        monthEnd = new Date(y, m, 0, 23, 59, 59, 999);
    } else {
        const now = new Date();
        monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    }

    const summary = await repo.findAttendanceSummaryByStudentMonth(studentId, schoolId, monthStart, monthEnd);

    const monthStr = month || `${monthStart.getFullYear()}-${String(monthStart.getMonth() + 1).padStart(2, '0')}`;
    return { month: monthStr, ...summary };
}

export async function getChildTimetable({ studentId, parentId, schoolId }) {
    const child = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!child) throw new AppError('Child not found', 404);

    const slots = await repo.findTimetableForStudent(studentId, schoolId);
    return { slots };
}

export async function getChildDocuments({ studentId, parentId, schoolId }) {
    const child = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!child) throw new AppError('Child not found', 404);

    const documents = await repo.findDocumentsByStudent(studentId, schoolId);
    return { documents };
}

export async function getBusForStudent({ parentId, studentId, schoolId }) {
    // Verify student belongs to this parent
    const studentLink = await repo.findChildByIdForParent(studentId, parentId, schoolId);
    if (!studentLink) throw new AppError('Student not found or not linked to this parent', 404);

    const result = await repo.getBusForStudent(studentId, schoolId);
    const { vehicle, tripStatus } = result;

    if (!vehicle) return { hasBus: false };

    const driver = vehicle.driver;
    const loc = vehicle.locationCurrent;

    return {
        hasBus: true,
        vehicle: {
            id: vehicle.id,
            vehicleNo: vehicle.vehicleNo,
            driverName: driver ? `${driver.firstName} ${driver.lastName}`.trim() : null,
            driverPhone: driver?.phone || null,
        },
        tripStatus,
        location: loc
            ? {
                  lat: Number(loc.lat),
                  lng: Number(loc.lng),
                  speed: loc.speed ?? null,
                  heading: loc.heading ?? null,
                  updatedAt: loc.updatedAt.toISOString(),
              }
            : null,
    };
}

export async function getDashboard({ parentId, schoolId }) {
    const stats = await repo.getDashboardStats(parentId, schoolId);
    return {
        childrenCount: stats.childrenCount,
        todaysAttendance: stats.todaysAttendance,
        recentNotices: stats.recentNotices.map((n) => ({
            id: n.id,
            title: n.title,
            body: n.body,
            isPinned: n.isPinned,
            publishedAt: n.publishedAt?.toISOString() || null,
            expiresAt: n.expiresAt?.toISOString() || null,
        })),
        feeDues: stats.feeDues,
    };
}

// ── Notifications ─────────────────────────────────────────────────────────────

export async function getNotifications({ parentId, schoolId, page = 1, limit = 20 }) {
    const result = await ntRepo.findByParent({ parentId, schoolId, page, limit });
    const data = (result.data || []).map((row) => ({
        id: row.id,
        type: row.type,
        title: row.title,
        body: row.body,
        is_read: row.is_read,
        link: row.link,
        entity_type: row.entity_type,
        entity_id: row.entity_id,
        created_at: row.created_at?.toISOString?.() || row.created_at,
    }));
    return {
        data,
        pagination: {
            page: result.page,
            limit,
            total: result.total,
            total_pages: result.total_pages,
        },
    };
}

export async function getUnreadNotificationCount({ parentId, schoolId }) {
    const count = await ntRepo.countUnread(parentId, schoolId);
    return { count };
}

export async function markNotificationRead({ id, parentId, schoolId }) {
    await ntRepo.markRead(id, parentId, schoolId);
}
