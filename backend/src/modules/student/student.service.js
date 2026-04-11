/**
 * Student Portal Service — business logic for all student portal routes.
 * All methods receive studentId/schoolId from req.student.
 */
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/response.js';
import * as repo from './student.repository.js';
import * as staffRepo from '../staff/staff-portal.repository.js';

function getCurrentAcademicYear() {
    const now  = new Date();
    const month = now.getMonth() + 1;
    const year  = now.getFullYear();
    if (month >= 4) {
        return `${year}-${String(year + 1).slice(-2)}`;
    }
    return `${year - 1}-${String(year).slice(-2)}`;
}

function getDayOfWeekForTimetable(date) {
    const d = new Date(date).getDay();
    return d === 0 ? 7 : d;
}

export async function getProfile({ studentId, schoolId }) {
    const profile = await repo.findProfileById(studentId, schoolId);
    if (!profile) throw new AppError('Student profile not found', 404);

    return {
        id: profile.id,
        admissionNo: profile.admissionNo,
        firstName: profile.firstName,
        lastName: profile.lastName,
        gender: profile.gender,
        dateOfBirth: profile.dateOfBirth?.toISOString?.()?.split('T')[0] ?? profile.dateOfBirth,
        bloodGroup: profile.bloodGroup,
        phone: profile.phone,
        email: profile.email,
        address: profile.address,
        photoUrl: profile.photoUrl,
        classId: profile.classId,
        sectionId: profile.sectionId,
        rollNo: profile.rollNo,
        class: profile.class_ ? { id: profile.class_.id, name: profile.class_.name, numeric: profile.class_.numeric } : null,
        section: profile.section ? { id: profile.section.id, name: profile.section.name } : null,
        parentName: profile.parentName,
        parentPhone: profile.parentPhone,
        parentEmail: profile.parentEmail,
        parentRelation: profile.parentRelation,
    };
}

export async function getDashboard({ studentId, schoolId, student }) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];
    const year = today.getFullYear();
    const month = today.getMonth() + 1;
    const academicYear = getCurrentAcademicYear();

    const [
        todayAttendance,
        attendanceSummary,
        feeDues,
        totalFeePaid,
        todayTimetable,
        recentNotices,
    ] = await Promise.all([
        repo.getTodayAttendance(studentId, today),
        repo.getAttendanceSummary(studentId, year, month),
        repo.getFeeDues(studentId, schoolId, academicYear),
        getTotalFeePaidThisYear(studentId, schoolId, academicYear),
        student.classId && student.sectionId
            ? getTodayTimetableSlots(schoolId, student.classId, student.sectionId, today)
            : [],
        getRecentNotices(studentId, schoolId, 5),
    ]);

    const presentDaysThisMonth = attendanceSummary.present;

    const upcomingDues = (feeDues.dues || []).map((d) => ({
        feeHead: d.feeHead,
        amount: d.balance,
        dueDate: d.dueDate,
    }));

    return {
        todayAttendance: {
            status: todayAttendance?.status ?? null,
            date: todayStr,
        },
        presentDaysThisMonth,
        totalFeePaidThisYear: totalFeePaid,
        upcomingDues,
        todayTimetable,
        recentNotices: recentNotices.map((n) => ({
            id: n.id,
            title: n.title,
            publishedAt: n.publishedAt,
            isPinned: n.isPinned,
        })),
        unreadNoticesCount: 0,
    };
}

async function getTotalFeePaidThisYear(studentId, schoolId, academicYear) {
    const result = await repo.getFeePayments(studentId, schoolId, 1, 10000);
    const payments = result.data || [];
    const inYear = payments.filter((p) => {
        const py = new Date(p.paymentDate).getFullYear();
        const pm = new Date(p.paymentDate).getMonth() + 1;
        const ayStart = parseInt(academicYear.split('-')[0], 10);
        const ayEnd = ayStart + 1;
        if (pm >= 4) return py === ayStart;
        return py === ayEnd;
    });
    return inYear.reduce((sum, p) => sum + (p.amount || 0), 0);
}

async function getTodayTimetableSlots(schoolId, classId, sectionId, date) {
    const dayOfWeek = getDayOfWeekForTimetable(date);
    const entries = await repo.getTimetable(classId, sectionId, schoolId);
    const todaySlots = entries.filter((e) => e.dayOfWeek === dayOfWeek);
    return todaySlots.map((e) => ({
        periodNo:   e.periodNo,
        subject:    e.subject,
        startTime:  e.startTime,
        endTime:    e.endTime,
        room:       e.room,
    }));
}

async function getRecentNotices(studentId, schoolId, limit) {
    const result = await repo.getNotices(studentId, schoolId, 1, limit);
    return result.data || [];
}

export async function getAttendance({ studentId, month }) {
    if (!month) throw new AppError('month query parameter is required (format: YYYY-MM)', 400);
    const [year, mon] = month.split('-').map(Number);
    if (!year || !mon) throw new AppError('Invalid month format. Use YYYY-MM', 400);

    const records = await repo.getAttendanceByMonth(studentId, year, mon);
    return {
        records: records.map((r) => ({
            date: r.date.toISOString().split('T')[0],
            status: r.status,
        })),
        month,
    };
}

export async function getAttendanceSummary({ studentId, month }) {
    const now = new Date();
    const m = month || `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const [year, mon] = m.split('-').map(Number);
    if (!year || !mon) throw new AppError('Invalid month format. Use YYYY-MM', 400);

    const summary = await repo.getAttendanceSummary(studentId, year, mon);
    return {
        month: m,
        present: summary.present,
        absent: summary.absent,
        late: summary.late,
        halfDay: summary.halfDay,
    };
}

export async function getFeeDues({ studentId, schoolId }) {
    const academicYear = getCurrentAcademicYear();
    const result = await repo.getFeeDues(studentId, schoolId, academicYear);
    return {
        academicYear,
        dues: result.dues,
        totalDue: result.totalDue,
    };
}

export async function getFeePayments({ studentId, schoolId, page, limit }) {
    return repo.getFeePayments(studentId, schoolId, page, limit);
}

export async function getReceiptByReceiptNo({ studentId, schoolId, receiptNo }) {
    const payment = await repo.getFeePaymentByReceiptNo(studentId, schoolId, receiptNo);
    if (!payment) throw new AppError('Receipt not found', 404);
    return {
        id: payment.id,
        receiptNo: payment.receiptNo,
        feeHead: payment.feeHead,
        amount: Number(payment.amount),
        paymentDate: payment.paymentDate.toISOString().split('T')[0],
        paymentMode: payment.paymentMode,
        remarks: payment.remarks,
    };
}

export async function getTimetable({ studentId, schoolId, student }) {
    if (!student.classId || !student.sectionId) {
        return { slots: [] };
    }
    const slots = await repo.getTimetable(student.classId, student.sectionId, schoolId);
    return { slots };
}

export async function getNotices({ studentId, schoolId, page, limit }) {
    return repo.getNotices(studentId, schoolId, page, limit);
}

export async function getNoticeById({ id, studentId, schoolId }) {
    const notice = await repo.getNoticeById(id, studentId, schoolId);
    if (!notice) throw new AppError('Notice not found', 404);
    return {
        id: notice.id,
        title: notice.title,
        body: notice.body,
        publishedAt: notice.publishedAt,
        expiresAt: notice.expiresAt,
        isPinned: notice.isPinned ?? false,
        source: notice.source || 'school',
        priority: notice.priority || null,
        sentBy: notice.sentBy || null,
    };
}

export async function getDocuments({ studentId, schoolId }) {
    const docs = await repo.getStudentDocuments(studentId, schoolId);
    return {
        documents: docs.map((d) => ({
            id: d.id,
            document_type: d.documentType,
            document_name: d.documentName,
            file_url: d.fileUrl,
            file_size_kb: d.fileSizeKb,
            verified: d.verified,
            verified_at: d.verifiedAt != null ? d.verifiedAt.toISOString() : null,
        })),
    };
}

export async function getLiveDrivers({ schoolId }) {
    const drivers = await repo.findActiveDrivers(schoolId);
    return drivers.map((d) => ({
        driverId: d.id,
        driverName: `${d.firstName} ${d.lastName}`.trim(),
        vehicleNo: d.vehicle?.vehicleNo || null,
        lat: d.lastLat ? Number(d.lastLat) : null,
        lng: d.lastLng ? Number(d.lastLng) : null,
        updatedAt: d.lastLocationAt?.toISOString() || null,
    }));
}

export async function registerFcmToken({ fcmToken, portalType, studentId, schoolId }) {
    const { upsertToken } = await import('../fcm/fcm.repository.js');
    await upsertToken({
        fcmToken,
        portalType,
        parentId: null,
        studentId,
        schoolId,
    });
}

export async function changePassword({ userId, currentPassword, newPassword }) {
    const user = await staffRepo.findUserWithPasswordHash(userId);
    if (!user) throw new AppError('User not found', 404);

    const match = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!match) throw new AppError('Current password is incorrect', 400);

    const hash = await bcrypt.hash(newPassword, 12);
    await staffRepo.updateUser(userId, { passwordHash: hash, passwordChangedAt: new Date() });
}
