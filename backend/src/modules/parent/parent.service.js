/**
 * Parent Portal Service — business logic for all parent routes.
 * All methods receive parentId and schoolId from req.parent.
 */
import { AppError } from '../../utils/response.js';
import * as repo from './parent.repository.js';
import * as auditService from '../audit/audit.service.js';

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
        actorId: parentId,
        actorRole: 'parent',
        action: 'PARENT_PROFILE_UPDATE',
        entityType: 'parent',
        entityId: parentId,
        extra: { schoolId, updates: updateData },
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

export async function getNotices({ schoolId, page, limit }) {
    const result = await repo.findNoticesForParent(schoolId, page, limit);
    return {
        notices: result.data.map((n) => ({
            id: n.id,
            title: n.title,
            body: n.body,
            isPinned: n.isPinned,
            publishedAt: n.publishedAt?.toISOString() || null,
            expiresAt: n.expiresAt?.toISOString() || null,
        })),
        pagination: result.pagination,
    };
}

export async function getNoticeById({ id, schoolId }) {
    const notice = await repo.findNoticeById(id, schoolId);
    if (!notice) throw new AppError('Notice not found', 404);
    return {
        id: notice.id,
        title: notice.title,
        body: notice.body,
        isPinned: notice.isPinned,
        publishedAt: notice.publishedAt?.toISOString() || null,
        expiresAt: notice.expiresAt?.toISOString() || null,
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
