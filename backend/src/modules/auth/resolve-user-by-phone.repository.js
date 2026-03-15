/**
 * Resolve user by phone — find school(s) for parent/student
 */
import { PrismaClient } from '@prisma/client';
import * as parentResolve from './resolve-parent-by-phone.repository.js';

const prisma = new PrismaClient();

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
                    schoolCode: true,
                    city: true,
                    state: true,
                    isActive: true,
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
        (u) => u.school && u.school.isActive && (!u.school.subscriptionEnd || u.school.subscriptionEnd >= now)
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
        code: first.school.schoolCode,
        city: first.school.city || '',
        state: first.school.state || '',
        board: '',
        type: 'school',
        logo_url: null,
        is_active: first.school.isActive
    };

    const userName = [first.firstName, first.lastName].filter(Boolean).join(' ') || first.email;

    // TODO: Send OTP — integrate with smart-login OTP flow
    // For now return stub otp_session_id
    const otpSessionId = `otp_${Date.now()}_${first.id}`;
    const maskedPhone = first.phone ? first.phone.slice(-4).padStart(first.phone.length, '*') : '****';

    if (usersToUse.length === 1) {
        return {
            schools: [schoolPayload],
            user: {
                id: toStr(first.id),
                name: userName,
                role: first.role?.name || 'User',
                school_id: toStr(first.schoolId)
            },
            otp_session_id: otpSessionId,
            masked_phone: maskedPhone
        };
    }

    // Multiple schools — return all
    const schools = usersToUse.map((u) => ({
        id: toStr(u.school.id),
        name: u.school.name,
        code: u.school.schoolCode,
        city: u.school.city || '',
        state: u.school.state || '',
        board: '',
        type: 'school',
        logo_url: null,
        is_active: u.school.isActive
    }));

    return {
        schools: [...new Map(schools.map((s) => [s.id, s])).values()],
        user: {
            id: toStr(first.id),
            name: userName,
            role: first.role?.name || 'User',
            school_id: toStr(first.schoolId)
        },
        otp_session_id: otpSessionId,
        masked_phone: maskedPhone
    };
};

