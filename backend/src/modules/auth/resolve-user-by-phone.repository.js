/**
 * Resolve user by phone — find school(s) for parent/student
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const toStr = (v) => (v == null ? null : String(v));

/**
 * Find user(s) by phone. User has schoolId, role. Role name can be STUDENT, TEACHER, etc.
 * For parent: may be guardian table in future — for now we look for any user with phone + school
 */
export const resolveUserByPhone = async (phone, userType) => {
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

    const first = validUsers[0];
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

    if (validUsers.length === 1) {
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
    const schools = validUsers.map((u) => ({
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
