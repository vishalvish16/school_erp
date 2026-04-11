/**
 * Verify Student OTP — validate OTP session, fetch Student via User.id, issue JWT
 */
import { AppError } from '../../utils/response.js';
import * as jwtUtils from '../../utils/jwt.js';
import * as otpStore from './parent-otp.store.js';
import { normalizePhone } from './resolve-parent-by-phone.repository.js';
import * as auditService from '../audit/audit.service.js';

import prisma from '../../config/prisma.js';

export async function verifyStudentOtp({ otp_session_id, otp, phone, school_id }) {
    const sess = otpStore.get(otp_session_id);
    if (!sess) {
        throw new AppError('Invalid or expired OTP session. Please try again.', 400);
    }

    if (sess.userType !== 'student') {
        throw new AppError('Invalid session type.', 400);
    }

    if (sess.attempts >= 3) {
        throw new AppError('Too many attempts. Please request a new OTP.', 429);
    }

    if (sess.otpCode !== String(otp).trim()) {
        otpStore.incrementAttempts(otp_session_id);
        throw new AppError('Invalid OTP code', 400);
    }

    otpStore.markUsed(otp_session_id);

    const normalizedPhone = normalizePhone(phone);
    if (!normalizedPhone) {
        throw new AppError('Invalid phone number', 400);
    }

    // Find the Student linked to this User account
    const student = await prisma.student.findFirst({
        where: {
            userId: sess.userId,
            schoolId: school_id,
            deletedAt: null,
            status: 'ACTIVE',
        },
        include: {
            class_: { select: { name: true } },
            section: { select: { name: true } },
        },
    });

    if (!student) {
        throw new AppError('Student account not found or inactive. Contact your school admin.', 404);
    }

    const payload = {
        userId: sess.userId,
        studentId: student.id,
        school_id: student.schoolId,
        portal_type: 'student',
        email: student.email || `student_${student.id}@vidyron.local`,
    };

    const accessToken = jwtUtils.generateStudentAccessToken(payload);

    auditService.logAudit({
        actorId: student.id,
        actorRole: 'student',
        action: 'STUDENT_LOGIN',
        entityType: 'student',
        entityId: student.id,
        extra: { schoolId: student.schoolId },
    }).catch(() => {});

    return {
        access_token: accessToken,
        refresh_token: null,
        portal_type: 'student',
        student: {
            id: student.id,
            firstName: student.firstName,
            lastName: student.lastName,
            admissionNo: student.admissionNo,
            className: student.class_?.name || null,
            sectionName: student.section?.name || null,
        },
    };
}
