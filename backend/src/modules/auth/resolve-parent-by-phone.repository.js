/**
 * Resolve Parent by phone — find or create Parent for parent portal login.
 * Used when user_type === 'parent' in resolve-user-by-phone.
 */
import { randomUUID } from 'crypto';
import * as parentOtpStore from './parent-otp.store.js';

import prisma from '../../config/prisma.js';

/** Normalize phone to E.164: +91 + 10 digits */
export function normalizePhone(phone) {
    const digits = String(phone || '').replace(/\D/g, '').slice(-10);
    if (digits.length < 10) return null;
    return '+91' + digits;
}

/** Mask phone for response: ****543210 */
function maskPhone(phone) {
    if (!phone || phone.length < 4) return '****';
    return '*'.repeat(Math.max(0, phone.length - 4)) + phone.slice(-4);
}

/** Build school payload for response */
function toSchoolPayload(school) {
    return {
        id: school.id,
        name: school.name,
        code: school.code,
        city: school.city || '',
        state: school.state || '',
        board: school.board || '',
        type: 'school',
        logo_url: school.logoUrl || null,
        is_active: school.status === 'ACTIVE',
    };
}

/**
 * Resolve parent by phone. Returns { school, user, otp_session_id, masked_phone }
 * or null if not found.
 * @param {string} phone - Raw or normalized phone
 * @param {string|null} schoolId - Optional school_id from step 2 (when user picks from multiple)
 */
export async function resolveParentByPhone(phone, schoolId = null) {
    const normalizedPhone = normalizePhone(phone);
    if (!normalizedPhone) return null;

    const digits = normalizedPhone.replace(/\D/g, '').slice(-10);

    // 1. Look up Parent first: try normalized + raw variants (school admin may have stored "9876543210")
    let parent = null;
    let school = null;
    const phoneVariants = [normalizedPhone];
    if (digits.length === 10) phoneVariants.push(digits);

    const parentWhere = (sid) => ({
        ...(sid && { schoolId: sid }),
        OR: phoneVariants.map((p) => ({ phone: p })),
        deletedAt: null,
        isActive: true,
    });

    const findParent = async (sid) => {
        const candidates = await prisma.parent.findMany({
            where: parentWhere(sid),
            include: { school: true, _count: { select: { links: true } } },
        });
        if (candidates.length === 0) return null;
        // Prefer parent with linked children (avoids duplicate-parent scenario)
        candidates.sort((a, b) => (b._count?.links ?? 0) - (a._count?.links ?? 0));
        const { _count, ...p } = candidates[0];
        return p;
    };

    if (schoolId) {
        parent = await findParent(schoolId);
        if (parent) school = parent.school;
    }

    if (!parent) {
        parent = await findParent(null);
        if (parent) school = parent.school;
    }

    // 2. If Parent found — create OTP session, return
    if (parent && school) {
        if (school.status !== 'ACTIVE') return null;
        const now = new Date();
        if (school.subscriptionEnd && new Date(school.subscriptionEnd) < now) return null;

        const otpCode = String(Math.floor(100000 + Math.random() * 900000));
        const otpSessionId = randomUUID();
        parentOtpStore.set(otpSessionId, {
            parentId: parent.id,
            schoolId: parent.schoolId,
            phone: normalizedPhone,
            otpCode,
            expiresAt: new Date(Date.now() + 2 * 60 * 1000),
            attempts: 0,
        });
        console.log(`[DEV] Parent OTP for ${normalizedPhone}: ${otpCode}`);

        const userName = [parent.firstName, parent.lastName].filter(Boolean).join(' ') || 'Parent';
        return {
            schools: [toSchoolPayload(school)],
            school: toSchoolPayload(school),
            user: {
                id: parent.id,
                name: userName,
                school_id: parent.schoolId,
            },
            otp_session_id: otpSessionId,
            masked_phone: maskPhone(normalizedPhone),
            ...(process.env.NODE_ENV !== 'production' && { dev_otp: otpCode }),
        };
    }

    // 3. Parent not found — look up Student by parentPhone
    const student = await prisma.student.findFirst({
        where: {
            schoolId: schoolId || undefined,
            deletedAt: null,
            OR: [
                { parentPhone: { endsWith: digits } },
                { parentPhone: { contains: digits } },
            ],
        },
        include: {
            school: true,
            class_: true,
            section: true,
        },
    });

    if (!student || !student.school) return null;
    school = student.school;
    if (school.status !== 'ACTIVE') return null;
    const now = new Date();
    if (school.subscriptionEnd && new Date(school.subscriptionEnd) < now) return null;

    // 4. Create Parent from Student's parent fields
    const parentName = (student.parentName || 'Parent').trim().split(/\s+/);
    const firstName = parentName[0] || 'Parent';
    const lastName = parentName.slice(1).join(' ') || '';

    parent = await prisma.parent.upsert({
        where: {
            schoolId_phone: {
                schoolId: student.schoolId,
                phone: normalizedPhone,
            },
        },
        create: {
            schoolId: student.schoolId,
            firstName,
            lastName,
            phone: normalizedPhone,
            email: student.parentEmail || null,
            relation: student.parentRelation || 'Guardian',
            isActive: true,
        },
        update: {
            firstName,
            lastName,
            email: student.parentEmail || parent?.email,
            relation: student.parentRelation || parent?.relation,
        },
        include: { school: true },
    });

    // 5. Create StudentParent link if not exists
    await prisma.studentParent.upsert({
        where: {
            studentId_parentId: {
                studentId: student.id,
                parentId: parent.id,
            },
        },
        create: {
            studentId: student.id,
            parentId: parent.id,
            relation: student.parentRelation || 'Guardian',
            isPrimary: true,
        },
        update: {},
    });

    // 6. Create OTP session and return
    const otpCode = String(Math.floor(100000 + Math.random() * 900000));
    const otpSessionId = randomUUID();
    parentOtpStore.set(otpSessionId, {
        parentId: parent.id,
        schoolId: parent.schoolId,
        phone: normalizedPhone,
        otpCode,
        expiresAt: new Date(Date.now() + 2 * 60 * 1000),
        attempts: 0,
    });
    console.log(`[DEV] Parent OTP for ${normalizedPhone}: ${otpCode}`);

    const userName = [parent.firstName, parent.lastName].filter(Boolean).join(' ') || 'Parent';
    return {
        schools: [toSchoolPayload(school)],
        school: toSchoolPayload(school),
        user: {
            id: parent.id,
            name: userName,
            school_id: parent.schoolId,
        },
        otp_session_id: otpSessionId,
        masked_phone: maskPhone(normalizedPhone),
        ...(process.env.NODE_ENV !== 'production' && { dev_otp: otpCode }),
    };
}
