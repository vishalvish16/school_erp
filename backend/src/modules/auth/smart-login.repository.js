/**
 * Smart Login Repository — raw SQL for registered_devices, auth_sessions, otp_verifications
 * Tables are in platform schema (from migration add_smart_login_20260307.sql)
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/** Find school by subdomain */
export const findSchoolBySubdomain = async (subdomain) => {
    return prisma.school.findFirst({
        where: {
            subdomain: subdomain.toLowerCase().trim(),
            isActive: true
        },
        select: {
            id: true,
            name: true,
            schoolCode: true,
            subdomain: true,
            city: true,
            country: true,
            subscriptions: {
                where: { status: 'active' },
                take: 1,
                select: { id: true }
            }
        }
    });
};

/** Find user by email or phone + school_id + portal_type */
export const findUserByIdentifier = async (identifier, schoolId, portalType) => {
    const isEmail = identifier.includes('@');
    const where = {
        isActive: true,
        deletedAt: null
    };
    if (isEmail) {
        where.email = identifier;
    } else {
        where.phone = identifier;
    }
    if (schoolId) where.schoolId = BigInt(schoolId);
    if (portalType === 'super_admin') {
        where.schoolId = null;
    }

    return prisma.user.findFirst({
        where,
        include: { role: true, school: true }
    });
};

/** Coerce id to DB format (UUID string or BigInt number) */
const toId = (v) => (v == null ? null : typeof v === 'string' && v.match(/^[0-9a-f-]{36}$/i) ? v : Number(v));

/** Find registered device by user_id and fingerprint — BigInt first (Prisma) */
export const findRegisteredDeviceRaw = async (userId, fingerprint) => {
    if (!fingerprint) return null;
    const uidNum = userId != null ? Number(userId) : null;
    const isUuid = typeof userId === 'string' && /^[0-9a-f-]{36}$/i.test(userId);
    try {
        const result = await prisma.$queryRawUnsafe(
            `SELECT * FROM registered_devices 
             WHERE user_id = $1::bigint AND device_fingerprint = $2 
             LIMIT 1`,
            uidNum,
            fingerprint
        );
        return Array.isArray(result) ? result[0] : null;
    } catch (_) {
        if (isUuid) {
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
        }
        return null;
    }
};

/** Insert or update registered device (trust) — BigInt first (Prisma) */
export const insertRegisteredDevice = async (data) => {
    const uidNum = data.userId != null ? Number(data.userId) : null;
    const sidNum = data.schoolId != null ? Number(data.schoolId) : null;
    const isUuid = typeof data.userId === 'string' && /^[0-9a-f-]{36}$/i.test(data.userId);
    try {
        const result = await prisma.$queryRawUnsafe(`
            INSERT INTO registered_devices 
            (user_id, school_id, device_fingerprint, device_name, device_type, browser, os, ip_address, city, country, is_trusted, trusted_at, trusted_until, last_used_at)
            VALUES ($1::bigint, $2::bigint, $3, $4, $5, $6, $7, $8::inet, $9, $10, true, NOW(), NOW() + INTERVAL '30 days', NOW())
            RETURNING id
        `, uidNum, sidNum, data.deviceFingerprint, data.deviceName || null, data.deviceType || 'unknown', data.browser || null, data.os || null, data.ipAddress || null, data.city || null, data.country || null);
        return Array.isArray(result) ? result[0] : result;
    } catch (e) {
        if (isUuid) {
            try {
                const result = await prisma.$queryRawUnsafe(`
                    INSERT INTO registered_devices 
                    (user_id, school_id, device_fingerprint, device_name, device_type, browser, os, ip_address, city, country, is_trusted, trusted_at, trusted_until, last_used_at)
                    VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8::inet, $9, $10, true, NOW(), NOW() + INTERVAL '30 days', NOW())
                    RETURNING id
                `, data.userId, data.schoolId ? toId(data.schoolId) : null, data.deviceFingerprint, data.deviceName || null, data.deviceType || 'unknown', data.browser || null, data.os || null, data.ipAddress || null, data.city || null, data.country || null);
                return Array.isArray(result) ? result[0] : result;
            } catch (_) {
                throw e;
            }
        }
        throw e;
    }
};

/** Update existing device to trusted — BigInt first */
export const trustDevice = async (userId, fingerprint, meta) => {
    const uidNum = userId != null ? Number(userId) : null;
    const isUuid = typeof userId === 'string' && /^[0-9a-f-]{36}$/i.test(userId);
    try {
        await prisma.$executeRawUnsafe(`
            UPDATE registered_devices 
            SET is_trusted = true, trusted_at = NOW(), trusted_until = NOW() + INTERVAL '30 days', last_used_at = NOW(),
                device_name = COALESCE($4, device_name), device_type = COALESCE($5, device_type), browser = COALESCE($6, browser), os = COALESCE($7, os)
            WHERE user_id = $1::bigint AND device_fingerprint = $2
        `, uidNum, fingerprint, null, meta?.deviceName, meta?.deviceType, meta?.browser, meta?.os);
    } catch (_) {
        if (isUuid) {
            try {
                await prisma.$executeRawUnsafe(`
                    UPDATE registered_devices 
                    SET is_trusted = true, trusted_at = NOW(), trusted_until = NOW() + INTERVAL '30 days', last_used_at = NOW(),
                        device_name = COALESCE($4, device_name), device_type = COALESCE($5, device_type), browser = COALESCE($6, browser), os = COALESCE($7, os)
                    WHERE user_id = $1::uuid AND device_fingerprint = $2
                `, userId, fingerprint, null, meta?.deviceName, meta?.deviceType, meta?.browser, meta?.os);
            } catch (_) {}
        }
    }
};

/** Create OTP verification record — supports both BigInt (Prisma) and UUID */
export const createOtpVerification = async (data) => {
    const uid = data.userId;
    const uidNum = uid != null ? Number(uid) : null;
    const isUuid = typeof uid === 'string' && /^[0-9a-f-]{36}$/i.test(uid);

    // Try BigInt first (matches Prisma users.id / users.user_id)
    try {
        const result = await prisma.$queryRawUnsafe(`
            INSERT INTO otp_verifications 
            (user_id, phone, email, otp_code, otp_type, device_fingerprint, expires_at)
            VALUES ($1::bigint, $2, $3, $4, $5, $6, NOW() + INTERVAL '2 minutes')
            RETURNING id, expires_at
        `, uidNum, data.phone || null, data.email || null, data.otpCode, data.otpType, data.deviceFingerprint || null);
        return Array.isArray(result) ? result[0] : result;
    } catch (e1) {
        if (isUuid) {
            try {
                const result = await prisma.$queryRawUnsafe(`
                    INSERT INTO otp_verifications 
                    (user_id, phone, email, otp_code, otp_type, device_fingerprint, expires_at)
                    VALUES ($1::uuid, $2, $3, $4, $5, $6, NOW() + INTERVAL '2 minutes')
                    RETURNING id, expires_at
                `, uid, data.phone || null, data.email || null, data.otpCode, data.otpType, data.deviceFingerprint || null);
                return Array.isArray(result) ? result[0] : result;
            } catch (_) {
                throw e1;
            }
        }
        throw e1;
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

/** Mark OTP as used and increment attempts */
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

/** Create auth session — BigInt first (Prisma) */
export const createAuthSession = async (data) => {
    const uidNum = data.userId != null ? Number(data.userId) : null;
    const sidNum = data.schoolId != null ? Number(data.schoolId) : null;
    const isUuid = typeof data.userId === 'string' && /^[0-9a-f-]{36}$/i.test(data.userId);
    try {
        const result = await prisma.$queryRawUnsafe(`
            INSERT INTO auth_sessions 
            (user_id, school_id, device_id, session_token, refresh_token, role, portal_type, ip_address, is_active, expires_at)
            VALUES ($1::bigint, $2::bigint, $3::uuid, $4, $5, $6, $7, $8::inet, true, $9::timestamptz)
            RETURNING id, session_token, refresh_token, expires_at
        `, uidNum, sidNum, data.deviceId || null, data.sessionToken, data.refreshToken || null, data.role || null, data.portalType || 'school_admin', data.ipAddress || null, data.expiresAt);
        return Array.isArray(result) ? result[0] : result;
    } catch (_) {
        if (isUuid) {
            try {
                const result = await prisma.$queryRawUnsafe(`
                    INSERT INTO auth_sessions 
                    (user_id, school_id, device_id, session_token, refresh_token, role, portal_type, ip_address, is_active, expires_at)
                    VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6, $7, $8::inet, true, $9::timestamptz)
                    RETURNING id, session_token, refresh_token, expires_at
                `, data.userId, data.schoolId ? toId(data.schoolId) : null, data.deviceId || null, data.sessionToken, data.refreshToken || null, data.role || null, data.portalType || 'school_admin', data.ipAddress || null, data.expiresAt);
                return Array.isArray(result) ? result[0] : result;
            } catch (_) {}
        }
        return null;
    }
};

/** Find auth session by token */
export const findAuthSessionByToken = async (token) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT s.*, u.first_name, u.last_name, u.email, u.role_id
        FROM auth_sessions s
        JOIN users u ON (u.id = s.user_id OR u.user_id = s.user_id)
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
    } catch (_) {}
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
    } catch (_) {}
};

/** Count recent OTP sends by phone */
export const countRecentOtpByPhone = async (phone, minutes = 60) => {
    const result = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int as cnt FROM otp_verifications 
        WHERE phone = $1 AND created_at > NOW() - ($2 || ' minutes')::interval
    `, phone, String(minutes));
    return result?.[0]?.cnt ?? 0;
};

/** Get user's registered devices */
export const getRegisteredDevices = async (userId) => {
    const uid = toId(userId);
    try {
        const result = await prisma.$queryRawUnsafe(`
            SELECT id, device_name, device_type, browser, os, city, trusted_until, last_used_at, is_trusted
            FROM registered_devices WHERE user_id = $1::uuid ORDER BY last_used_at DESC
        `, uid);
        return result || [];
    } catch (_) {
        const result = await prisma.$queryRawUnsafe(`
            SELECT id, device_name, device_type, browser, os, city, trusted_until, last_used_at, is_trusted
            FROM registered_devices WHERE user_id = $1 ORDER BY last_used_at DESC
        `, Number(userId));
        return result || [];
    }
};

/** Remove device trust */
export const removeDeviceTrust = async (deviceId, userId) => {
    const uid = toId(userId);
    try {
        await prisma.$executeRawUnsafe(`
            UPDATE registered_devices 
            SET is_trusted = false, trusted_until = NULL 
            WHERE id = $1::uuid AND user_id = $2::uuid
        `, deviceId, uid);
    } catch (_) {
        await prisma.$executeRawUnsafe(`
            UPDATE registered_devices 
            SET is_trusted = false, trusted_until = NULL 
            WHERE id = $1::uuid AND user_id = $2
        `, deviceId, Number(userId));
    }
};
