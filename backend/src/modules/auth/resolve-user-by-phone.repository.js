/**
 * Resolve user by phone — find school(s) for parent/student
 */
import { randomUUID } from 'crypto';
import * as parentResolve from './resolve-parent-by-phone.repository.js';
import * as parentOtpStore from './parent-otp.store.js';

import prisma from '../../config/prisma.js';

const toStr = (v) => (v == null ? null : String(v));

/**
 * Find user(s) by phone. User has schoolId, role. Role name can be STUDENT, TEACHER, etc.
 * For parent: uses Parent model — lookup or create from Student's parentPhone.
 */
export const resolveUserByPhone = async (phone, userType, schoolId = null) => {
    if (userType === 'parent') {
        return parentResolve.resolveParentByPhone(phone, schoolId);
    }
    // Normalize: extract last 10 digits for Indian mobile
    const digits = phone.replace(/\D/g, '').slice(-10);
    if (digits.length < 10) return null;

    const users = await prisma.user.findMany({
        where: {
            OR: [
                { phone: { endsWith: digits } },
                { phone: { contains: digits } }
            ],
            isActive: true,
            deletedAt: null,
            schoolId: { not: null }
        },
        include: {
            school: {
                select: {
                    id: true,
                    name: true,
                    code: true,
                    city: true,
                    state: true,
                    status: true,
                    subscriptionEnd: true
                }
            },
            role: { select: { name: true } }
        }
    });

    if (!users.length) return null;

    // Filter by subscription active
    const now = new Date();
    const validUsers = users.filter(
        (u) => u.school && u.school.status === 'ACTIVE' && (!u.school.subscriptionEnd || u.school.subscriptionEnd >= now)
    );

    if (!validUsers.length) return null;

    let usersToUse = validUsers;
    if (userType === 'student') {
        const filtered = validUsers.filter(
            (u) => (u.role?.name || '').toUpperCase() === 'STUDENT'
        );
        if (filtered.length === 0) return null;
        usersToUse = filtered;
    }

    const first = usersToUse[0];
    const schoolPayload = {
        id: toStr(first.school.id),
        name: first.school.name,
        code: first.school.code,
        city: first.school.city || '',
        state: first.school.state || '',
        board: '',
        type: 'school',
        logo_url: null,
        is_active: first.school.status === 'ACTIVE'
    };

    const userName = [first.firstName, first.lastName].filter(Boolean).join(' ') || first.email;
    const maskedPhone = first.phone ? '*'.repeat(Math.max(0, first.phone.length - 4)) + first.phone.slice(-4) : '****';

    // Create real OTP session (reuse parent OTP store, differentiated by userType)
    const otpCode = String(Math.floor(100000 + Math.random() * 900000));
    const otpSessionId = randomUUID();
    parentOtpStore.set(otpSessionId, {
        userId: first.id,
        schoolId: first.schoolId,
        phone: first.phone || phone,
        otpCode,
        expiresAt: new Date(Date.now() + 2 * 60 * 1000),
        attempts: 0,
        userType: 'student',
    });
    console.log(`[DEV] Student OTP for ${first.phone || phone}: ${otpCode}`);

    if (usersToUse.length === 1) {
        return {
            school: schoolPayload,
            schools: [schoolPayload],
            user: {
                id: toStr(first.id),
                name: userName,
                role: first.role?.name || 'Student',
                school_id: toStr(first.schoolId)
            },
            otp_session_id: otpSessionId,
            masked_phone: maskedPhone,
            ...(process.env.NODE_ENV !== 'production' && { dev_otp: otpCode }),
        };
    }

    // Multiple schools — return all
    const schools = usersToUse.map((u) => ({
        id: toStr(u.school.id),
        name: u.school.name,
        code: u.school.code,
        city: u.school.city || '',
        state: u.school.state || '',
        board: '',
        type: 'school',
        logo_url: null,
        is_active: u.school.status === 'ACTIVE'
    }));

    return {
        school: schoolPayload,
        schools: [...new Map(schools.map((s) => [s.id, s])).values()],
        user: {
            id: toStr(first.id),
            name: userName,
            role: first.role?.name || 'Student',
            school_id: toStr(first.schoolId)
        },
        otp_session_id: otpSessionId,
        masked_phone: maskedPhone,
        ...(process.env.NODE_ENV !== 'production' && { dev_otp: otpCode }),
    };
};

