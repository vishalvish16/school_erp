/**
 * Student Report Service — business logic for student report endpoints.
 * Standalone module — does not import from school-admin or staff modules.
 */
import { AppError } from '../../utils/response.js';
import { getIO } from '../../socket.js';
import { sendFcmToTokens } from '../fcm/fcm.service.js';
import * as fcmRepo from '../fcm/fcm.repository.js';
import * as repo from './student-report.repository.js';

// ── Helpers ──────────────────────────────────────────────────────────────────

function calcPercentage(present, total) {
    if (total === 0) return 0;
    return Math.round((present / total) * 100 * 10) / 10;
}

function summariseAttendance(records) {
    let present = 0;
    let absent  = 0;
    let late    = 0;

    for (const r of records) {
        const s = r.status?.toUpperCase();
        if (s === 'PRESENT')  present++;
        else if (s === 'ABSENT') absent++;
        else if (s === 'LATE')   late++;
    }

    const total = present + absent + late;
    return { present, absent, late, total, percentage: calcPercentage(present, total) };
}

function getMonthRange(monthStr) {
    // monthStr format: "YYYY-MM"
    const [year, month] = monthStr.split('-').map(Number);
    const start = new Date(Date.UTC(year, month - 1, 1));
    const end   = new Date(Date.UTC(year, month, 0)); // last day of month
    return { start, end };
}

function getCurrentMonthStr() {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    return `${y}-${m}`;
}

function formatDate(d) {
    if (!d) return null;
    const dt = new Date(d);
    return dt.toISOString().slice(0, 10);
}

// ── Student Report Summary ───────────────────────────────────────────────────

export async function getStudentReport({ studentId, schoolId }) {
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    // Current month attendance
    const monthStr = getCurrentMonthStr();
    const { start, end } = getMonthRange(monthStr);
    const attendanceRecords = await repo.findAttendanceByMonth(studentId, schoolId, start, end);
    const attendanceThisMonth = summariseAttendance(attendanceRecords);

    // Fees
    const feeSummary       = await repo.aggregateFeePayments(studentId, schoolId);
    const totalFeeStructure = await repo.aggregateFeeStructuresForClass(student.class_?.id, schoolId);
    const totalFeesDue     = Math.max(0, totalFeeStructure - feeSummary.totalPaid);

    // Notices count
    const noticesSentCount = await repo.countStudentNotices(studentId, schoolId);

    return {
        student: {
            id:             student.id,
            firstName:      student.firstName,
            lastName:       student.lastName,
            fullName:       `${student.firstName} ${student.lastName}`,
            admissionNo:    student.admissionNo,
            photoUrl:       student.photoUrl || null,
            dateOfBirth:    formatDate(student.dateOfBirth),
            gender:         student.gender,
            bloodGroup:     student.bloodGroup || null,
            address:        student.address || null,
            status:         student.status,
            admissionDate:  formatDate(student.admissionDate),
            rollNo:         student.rollNo || null,
            parentName:     student.parentName || null,
            parentPhone:    student.parentPhone || null,
            parentEmail:    student.parentEmail || null,
            parentRelation: student.parentRelation || null,
            class_:         student.class_ || null,
            section:        student.section || null,
        },
        stats: {
            attendanceThisMonth,
            totalFeesDue,
            totalFeesPaid: feeSummary.totalPaid,
            noticesSentCount,
        },
    };
}

// ── Student Attendance by Month ──────────────────────────────────────────────

export async function getStudentAttendance({ studentId, schoolId, month }) {
    const monthStr = month || getCurrentMonthStr();

    // Validate format
    if (!/^\d{4}-\d{2}$/.test(monthStr)) {
        throw new AppError('Invalid month format. Use YYYY-MM', 400);
    }

    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const { start, end } = getMonthRange(monthStr);
    const records = await repo.findAttendanceByMonth(studentId, schoolId, start, end);
    const summary = summariseAttendance(records);

    return {
        month: monthStr,
        summary,
        records: records.map((r) => ({
            date:    formatDate(r.date),
            status:  r.status,
            remarks: r.remarks || null,
        })),
    };
}

// ── Student Annual Attendance ────────────────────────────────────────────────

export async function getStudentAttendanceAnnual({ studentId, schoolId }) {
    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    // Academic year: June of previous year to May of current year
    const now   = new Date();
    const year  = now.getMonth() >= 5 ? now.getFullYear() : now.getFullYear() - 1; // June = month index 5
    const yearStart = new Date(Date.UTC(year, 5, 1));       // June 1
    const yearEnd   = new Date(Date.UTC(year + 1, 4, 31));  // May 31

    const records = await repo.findAttendanceForYear(studentId, schoolId, yearStart, yearEnd);
    const overall = summariseAttendance(records);

    // Group by YYYY-MM
    const monthMap = new Map();
    for (const r of records) {
        const d = new Date(r.date);
        const key = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
        if (!monthMap.has(key)) monthMap.set(key, []);
        monthMap.get(key).push(r);
    }

    const byMonth = [];
    for (const [month, recs] of monthMap.entries()) {
        byMonth.push({ month, ...summariseAttendance(recs) });
    }

    // Sort chronologically
    byMonth.sort((a, b) => a.month.localeCompare(b.month));

    return { overall, byMonth };
}

// ── Student Fees Report ──────────────────────────────────────────────────────

export async function getStudentFees({ studentId, schoolId, page, limit }) {
    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const [feeSummary, paymentsResult] = await Promise.all([
        repo.aggregateFeePayments(studentId, schoolId),
        repo.findFeePayments(studentId, schoolId, { page, limit }),
    ]);

    return {
        summary: {
            totalPaid:     feeSummary.totalPaid,
            paymentsCount: feeSummary.paymentsCount,
        },
        payments: paymentsResult.data.map((p) => ({
            id:          p.id,
            receiptNo:   p.receiptNo,
            amount:      Number(p.amount),
            paymentDate: formatDate(p.paymentDate),
            paymentMode: p.paymentMode,
            feeHead:     p.feeHead,
            remarks:     p.remarks || null,
        })),
        total:       paymentsResult.total,
        page,
        total_pages: Math.ceil(paymentsResult.total / limit),
    };
}

// ── Student Notices List ─────────────────────────────────────────────────────

export async function getStudentNotices({ studentId, schoolId, page, limit }) {
    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const result = await repo.findStudentNotices(studentId, schoolId, { page, limit });

    return {
        notices: result.data.map((n) => ({
            id:            n.id,
            subject:       n.subject,
            message:       n.message,
            priority:      n.priority,
            targetStudent: n.targetStudent,
            targetParent:  n.targetParent,
            sentBy: {
                id:   n.sentBy.id,
                name: [n.sentBy.firstName, n.sentBy.lastName].filter(Boolean).join(' ') || 'Unknown',
            },
            createdAt: n.createdAt,
        })),
        total:       result.total,
        page,
        total_pages: Math.ceil(result.total / limit),
    };
}

// ── Send Special Notice ──────────────────────────────────────────────────────

export async function sendStudentNotice({ studentId, schoolId, userId, data }) {
    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const targetStudent = data.targetStudent !== undefined ? data.targetStudent : true;
    const targetParent = data.targetParent !== undefined ? data.targetParent : false;

    const notice = await repo.createStudentNotice({
        schoolId,
        studentId,
        sentByUserId:  userId,
        subject:       data.subject,
        message:       data.message,
        priority:      data.priority || 'NORMAL',
        targetStudent,
        targetParent,
    });

    // Emit real-time event so parent/student clients can refresh
    try {
        const io = getIO();
        io.to(`school:${schoolId}`).emit('notice:new', {
            type:         'student_notice',
            studentId,
            targetStudent,
            targetParent,
            notice:       {
                id:        `stn-${notice.id}`,
                subject:   notice.subject,
                message:   data.message,
                priority:  data.priority || 'NORMAL',
                createdAt: notice.createdAt?.toISOString?.() || new Date().toISOString(),
            },
        });
    } catch (err) {
        // Socket emit failure should not fail the request
    }

    // FCM push — foreground, background, terminated
    try {
        const { parentTokens, studentTokens } = await fcmRepo.getTokensForStudentNotice({
            studentId,
            schoolId,
            targetStudent,
            targetParent,
        });
        const baseData = { type: 'student_notice', noticeId: `stn-${notice.id}` };
        if (parentTokens.length > 0) {
            await sendFcmToTokens(parentTokens, {
                title: data.subject,
                body: (data.message || '').slice(0, 100),
                data: { ...baseData, portal: 'parent', route: '/parent/notices' },
            });
        }
        if (studentTokens.length > 0) {
            await sendFcmToTokens(studentTokens, {
                title: data.subject,
                body: (data.message || '').slice(0, 100),
                data: { ...baseData, portal: 'student', route: '/student/notices' },
            });
        }
    } catch (err) {
        // FCM failure should not fail the request
    }

    return notice;
}
