/**
 * Smart Login Repository — raw SQL for registered_devices, auth_sessions, otp_verifications
 * Updated to use UUID user IDs matching the actual database
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/** Find group by slug or id */
export const findGroupBySlugOrId = async (slugOrId) => {
    if (!slugOrId || String(slugOrId).trim() === '') return null;
    const val = String(slugOrId).trim().toLowerCase();
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(val);
    try {
        const group = await prisma.schoolGroup.findFirst({
            where: isUuid
                ? { id: val, deletedAt: null }
                : { slug: { equals: val, mode: 'insensitive' }, deletedAt: null },
            select: { id: true, name: true, slug: true, status: true }
        });
        return group && group.status === 'ACTIVE' ? group : null;
    } catch (_) {
        return null;
    }
};

/** Find school by subdomain (checks subdomain column, falls back to code) */
export const findSchoolBySubdomain = async (subdomain) => {
    const results = await prisma.$queryRawUnsafe(
        `SELECT id, name, code, subdomain, status FROM schools 
         WHERE (LOWER(COALESCE(subdomain, code)) = LOWER($1)) AND status = 'ACTIVE' LIMIT 1`,
        subdomain
    );
    const school = Array.isArray(results) ? results[0] : null;
    if (!school) return null;
    return {
        id: school.id,
        name: school.name,
        schoolCode: school.code,
        subdomain: school.subdomain || school.code,
        isActive: school.status === 'ACTIVE',
    };
};

/** Find group admin user by email and group_id. Returns { user, groupHasNoAdmin } */
export const findGroupAdminUserWithGroupCheck = async (identifier, groupId) => {
    if (!groupId || !String(identifier || '').trim()) return { user: null, groupHasNoAdmin: false };
    const email = String(identifier).trim().toLowerCase();
    const group = await prisma.schoolGroup.findFirst({
        where: { id: String(groupId).trim(), deletedAt: null, status: 'ACTIVE' },
        select: { groupAdminUserId: true }
    });
    if (!group) return { user: null, groupHasNoAdmin: false };
    if (!group.groupAdminUserId) return { user: null, groupHasNoAdmin: true };
    const user = await prisma.user.findFirst({
        where: {
            id: group.groupAdminUserId,
            isActive: true,
            deletedAt: null,
            email: { equals: email, mode: 'insensitive' }
        },
        include: { role: true, school: true }
    });
    return { user, groupHasNoAdmin: false };
};

/** Find group admin user (legacy - returns user only) */
export const findGroupAdminUser = async (identifier, groupId) => {
    const result = await findGroupAdminUserWithGroupCheck(identifier, groupId);
    return result?.user ?? null;
};

/** Normalize phone for matching: strip non-digits, return last 10 digits */
function normalizePhoneForMatch(val) {
    if (!val || typeof val !== 'string') return null;
    const digits = val.replace(/\D/g, '');
    if (digits.length < 10) return null;
    return digits.slice(-10);
}

/** Find user by email or phone + school_id + portal_type */
export const findUserByIdentifier = async (identifier, schoolId, portalType) => {
    const trimmed = String(identifier || '').trim();
    if (!trimmed) return null;

    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed);
    const phoneSuffix = normalizePhoneForMatch(trimmed);

    const baseWhere = {
        isActive: true,
        deletedAt: null,
        ...(schoolId ? { schoolId } : {}),
        ...(portalType === 'super_admin' ? { schoolId: null } : {}),
    };

    if (isEmail) {
        return prisma.user.findFirst({
            where: { ...baseWhere, email: { equals: trimmed, mode: 'insensitive' } },
            include: { role: true, school: true },
        });
    }

    if (phoneSuffix) {
        const users = await prisma.user.findMany({
            where: { ...baseWhere, phone: { not: null } },
            include: { role: true, school: true },
        });
        for (const u of users) {
            const uSuffix = normalizePhoneForMatch(u.phone);
            if (uSuffix && uSuffix === phoneSuffix) return u;
        }
        return null;
    }

    return prisma.user.findFirst({
        where: { ...baseWhere, email: { equals: trimmed, mode: 'insensitive' } },
        include: { role: true, school: true },
    });
};

/** Find registered device by user_id and fingerprint */
export const findRegisteredDeviceRaw = async (userId, fingerprint) => {
    if (!fingerprint) return null;
    try {
        const result = await prisma.$queryRawUnsafe(
            `SELECT * FROM registered_devices 
             WHERE user_id = $1::uuid AND device_fingerprint = $2 
             LIMIT 1`,
            String(userId),
            fingerprint
        );
        return Array.isArray(result) ? result[0] : null;
    } catch (_) {
        return null;
    }
};

/** Insert or update registered device (trust) */
export const insertRegisteredDevice = async (data) => {
    try {
        const result = await prisma.$queryRawUnsafe(`
            INSERT INTO registered_devices 
            (user_id, school_id, device_fingerprint, device_name, device_type, browser, os, ip_address, city, country, is_trusted, trusted_at, trusted_until, last_used_at)
            VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8::inet, $9, $10, true, NOW(), NOW() + INTERVAL '30 days', NOW())
            RETURNING id
        `, String(data.userId), data.schoolId ? String(data.schoolId) : null, data.deviceFingerprint, data.deviceName || null, data.deviceType || 'unknown', data.browser || null, data.os || null, data.ipAddress || null, data.city || null, data.country || null);
        return Array.isArray(result) ? result[0] : result;
    } catch (e) {
        throw e;
    }
};

/** Update existing device to trusted */
export const trustDevice = async (userId, fingerprint, meta) => {
    try {
        await prisma.$executeRawUnsafe(`
            UPDATE registered_devices 
            SET is_trusted = true, trusted_at = NOW(), trusted_until = NOW() + INTERVAL '30 days', last_used_at = NOW(),
                device_name = COALESCE($3, device_name), device_type = COALESCE($4, device_type), browser = COALESCE($5, browser), os = COALESCE($6, os)
            WHERE user_id = $1::uuid AND device_fingerprint = $2
        `, String(userId), fingerprint, meta?.deviceName, meta?.deviceType, meta?.browser, meta?.os);
    } catch (_) { }
};

/** Create OTP verification record */
export const createOtpVerification = async (data) => {
    try {
        const result = await prisma.$queryRawUnsafe(`
            INSERT INTO otp_verifications 
            (user_id, phone, email, otp_code, otp_type, device_fingerprint, expires_at)
            VALUES ($1::uuid, $2, $3, $4, $5, $6, NOW() + INTERVAL '2 minutes')
            RETURNING id, expires_at
        `, String(data.userId), data.phone || null, data.email || null, data.otpCode, data.otpType, data.deviceFingerprint || null);
        return Array.isArray(result) ? result[0] : result;
    } catch (e) {
        console.error('[Smart Login] OTP creation failed:', e.message);
        throw e;
    }
};

/** Find OTP by id */
export const findOtpById = async (otpSessionId) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT * FROM otp_verifications 
        WHERE id = $1::uuid AND is_used = false AND attempts < max_attempts AND expires_at > NOW()
    `, otpSessionId);
    return Array.isArray(result) ? result[0] : null;
};

/** Find OTP by id for resend (allows expired) — returns user_id, phone, email */
export const findOtpByIdForResend = async (otpSessionId) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT id, user_id, phone, email, device_fingerprint FROM otp_verifications 
        WHERE id = $1::uuid AND is_used = false
    `, otpSessionId);
    return Array.isArray(result) ? result[0] : null;
};

/** Mark OTP as used */
export const markOtpUsed = async (otpId) => {
    await prisma.$executeRawUnsafe(`
        UPDATE otp_verifications SET is_used = true WHERE id = $1::uuid
    `, otpId);
};

export const incrementOtpAttempts = async (otpId) => {
    await prisma.$executeRawUnsafe(`
        UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = $1::uuid
    `, otpId);
};

/** Create auth session */
export const createAuthSession = async (data) => {
    try {
        const result = await prisma.$queryRawUnsafe(`
            INSERT INTO auth_sessions 
            (user_id, school_id, device_id, session_token, refresh_token, role, portal_type, ip_address, is_active, expires_at)
            VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6, $7, $8::inet, true, $9::timestamptz)
            RETURNING id, session_token, refresh_token, expires_at
        `, String(data.userId), data.schoolId ? String(data.schoolId) : null, data.deviceId || null, data.sessionToken, data.refreshToken || null, data.role || null, data.portalType || 'school_admin', data.ipAddress || null, data.expiresAt);
        return Array.isArray(result) ? result[0] : result;
    } catch (_) {
        return null;
    }
};

/** Find auth session by token */
export const findAuthSessionByToken = async (token) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT s.*, u.first_name, u.last_name, u.email
        FROM auth_sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.session_token = $1 AND s.is_active = true AND s.expires_at > NOW()
    `, token);
    return Array.isArray(result) ? result[0] : null;
};

/** Deactivate auth session */
export const deactivateAuthSession = async (token) => {
    await prisma.$executeRawUnsafe(`
        UPDATE auth_sessions SET is_active = false WHERE session_token = $1
    `, token);
};

/** Log login attempt */
export const logLoginAttempt = async (identifier, ipAddress, success) => {
    try {
        await prisma.$executeRawUnsafe(`
            INSERT INTO login_attempts (identifier, ip_address, success) VALUES ($1, $2::inet, $3)
        `, identifier, ipAddress || null, success);
    } catch (_) { }
};

/** Count recent login attempts by IP */
export const countRecentLoginAttemptsByIp = async (ipAddress, minutes = 15) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int as cnt FROM login_attempts 
        WHERE ip_address = $1::inet AND created_at > NOW() - ($2 || ' minutes')::interval
    `, ipAddress, String(minutes));
    return result?.[0]?.cnt ?? 0;
};

/** Count recent forgot-password requests by email */
export const countRecentForgotPasswordByEmail = async (email, minutes = 60) => {
    try {
        const result = await prisma.$queryRawUnsafe(`
            SELECT COUNT(*)::int as cnt FROM rate_limit_tracking 
            WHERE identifier = $1 AND action = 'forgot_password' AND created_at > NOW() - ($2 || ' minutes')::interval
        `, email, String(minutes));
        return result?.[0]?.cnt ?? 0;
    } catch (_) {
        return 0;
    }
};

export const trackForgotPasswordRequest = async (email) => {
    try {
        await prisma.$executeRawUnsafe(`
            INSERT INTO rate_limit_tracking (identifier, action) VALUES ($1, 'forgot_password')
        `, email);
    } catch (_) { }
};

/** Count recent OTP sends by phone */
export const countRecentOtpByPhone = async (phone, minutes = 60) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int as cnt FROM otp_verifications 
        WHERE phone = $1 AND created_at > NOW() - ($2 || ' minutes')::interval
    `, phone, String(minutes));
    return result?.[0]?.cnt ?? 0;
};

/** Count recent OTP sends by user (for resend rate limit) */
export const countRecentOtpByUserId = async (userId, minutes = 60) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int as cnt FROM otp_verifications 
        WHERE user_id = $1::uuid AND created_at > NOW() - ($2 || ' minutes')::interval
    `, String(userId), String(minutes));
    return result?.[0]?.cnt ?? 0;
};

/** Get user's registered devices */
export const getRegisteredDevices = async (userId) => {
    try {
        const result = await prisma.$queryRawUnsafe(`
            SELECT id, device_name, device_type, browser, os, city, trusted_until, last_used_at, is_trusted
            FROM registered_devices WHERE user_id = $1::uuid ORDER BY last_used_at DESC
        `, String(userId));
        return result || [];
    } catch (_) {
        return [];
    }
};

/** Remove device trust */
export const removeDeviceTrust = async (deviceId, userId) => {
    try {
        await prisma.$executeRawUnsafe(`
            UPDATE registered_devices 
            SET is_trusted = false, trusted_until = NULL 
            WHERE id = $1::uuid AND user_id = $2::uuid
        `, deviceId, String(userId));
    } catch (_) { }
};
