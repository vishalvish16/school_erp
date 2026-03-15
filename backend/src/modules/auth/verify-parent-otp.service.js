/**
 * Verify Parent OTP — validate OTP session, fetch Parent, issue JWT
 */
import { PrismaClient } from '@prisma/client';
import { AppError } from '../../utils/response.js';
import * as jwtUtils from '../../utils/jwt.js';
import * as parentOtpStore from './parent-otp.store.js';
import { normalizePhone } from './resolve-parent-by-phone.repository.js';
import * as auditService from '../audit/audit.service.js';

const prisma = new PrismaClient();

export async function verifyParentOtp({ otp_session_id, otp, phone, school_id }) {
    const sess = parentOtpStore.get(otp_session_id);
    if (!sess) {
        throw new AppError('Invalid or expired OTP session. Please try again.', 400);
    }

    if (sess.attempts >= 3) {
        throw new AppError('Too many attempts. Please request a new code.', 429);
    }

    if (sess.otpCode !== String(otp).trim()) {
        parentOtpStore.incrementAttempts(otp_session_id);
        throw new AppError('Invalid OTP code', 400);
    }

    parentOtpStore.markUsed(otp_session_id);

    const normalizedPhone = normalizePhone(phone);
    if (!normalizedPhone) {
        throw new AppError('Invalid phone number', 400);
    }

    const parent = await prisma.parent.findFirst({
        where: {
            id: sess.parentId,
            schoolId: school_id,
            phone: normalizedPhone,
            isActive: true,
            deletedAt: null,
        },
        include: { school: true },
    });

    if (!parent) {
        throw new AppError('Parent account not found', 404);
    }

    const payload = {
        parent_id: parent.id,
        school_id: parent.schoolId,
        portal_type: 'parent',
        email: parent.email || `parent_${parent.id}@vidyron.local`,
    };

    const accessToken = jwtUtils.generateParentAccessToken(payload);

    auditService.logAudit({
        actorId: parent.id,
        actorRole: 'parent',
        action: 'PARENT_LOGIN',
        entityType: 'parent',
        entityId: parent.id,
        extra: { schoolId: parent.schoolId },
    }).catch(() => {});

    return {
        access_token: accessToken,
        refresh_token: null,
        portal_type: 'parent',
        parent: {
            id: parent.id,
            firstName: parent.firstName,
            lastName: parent.lastName,
            phone: parent.phone,
            email: parent.email,
        },
    };
}
