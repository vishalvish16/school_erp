/**
 * Smart Login Service — device fingerprinting, OTP, trusted devices
 */
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import * as jwtUtils from '../../utils/jwt.js';
import { AppError } from '../../utils/response.js';
import * as authRepository from './auth.repository.js';
import * as smartRepo from './smart-login.repository.js';

const MAX_LOGIN_ATTEMPTS_PER_IP = 5;
const LOGIN_ATTEMPT_WINDOW_MINUTES = 15;
const MAX_OTP_PER_PHONE_PER_HOUR = 3;
const ACCOUNT_LOCKOUT_MINUTES = 30;
const MAX_FAILED_PASSWORD_ATTEMPTS = 5;

/** Resolve subdomain to school/group identity */
export const resolveSubdomain = async (subdomain) => {
    const sanitized = String(subdomain || '').replace(/[^a-z0-9\-]/gi, '').toLowerCase().slice(0, 50);
    if (!sanitized) throw new AppError('Invalid subdomain', 400);

    const school = await smartRepo.findSchoolBySubdomain(sanitized);
    if (!school) throw new AppError('School not found', 404);

    const studentCount = school.subscriptions?.[0] ? 0 : 0; // Could join school_subscriptions for count
    return {
        type: 'school',
        id: school.id.toString(),
        name: school.name,
        code: school.schoolCode,
        logo_url: null,
        board: '',
        student_count: studentCount,
        active: school.isActive
    };
};

/** Smart login with device fingerprinting */
export const smartLogin = async (input) => {
    const { identifier, password, portal_type, school_id, device_fingerprint, device_meta } = input;
    const ip = input.ip_address || input.ipAddress || null;

    // Rate limiting
    if (ip) {
        const recentAttempts = await smartRepo.countRecentLoginAttemptsByIp(ip, LOGIN_ATTEMPT_WINDOW_MINUTES);
        if (recentAttempts >= MAX_LOGIN_ATTEMPTS_PER_IP) {
            await smartRepo.logLoginAttempt(identifier, ip, false);
            throw new AppError(`Too many login attempts. Try again in ${LOGIN_ATTEMPT_WINDOW_MINUTES} minutes.`, 429);
        }
    }

    const user = await smartRepo.findUserByIdentifier(identifier, school_id, portal_type);
    if (!user) {
        await smartRepo.logLoginAttempt(identifier, ip, false);
        throw new AppError('Invalid email or password', 401);
    }

    if (!user.isActive) {
        await smartRepo.logLoginAttempt(identifier, ip, false);
        throw new AppError('Account is inactive. Please contact support.', 403);
    }

    // Account lockout
    if (user.lockedUntil && new Date(user.lockedUntil) > new Date()) {
        await smartRepo.logLoginAttempt(identifier, ip, false);
        throw new AppError('Account temporarily locked. Try again later.', 423);
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
        const failedCount = (user.failedLoginAttempts || 0) + 1;
        const lockUntil = failedCount >= MAX_FAILED_PASSWORD_ATTEMPTS
            ? new Date(Date.now() + ACCOUNT_LOCKOUT_MINUTES * 60 * 1000)
            : null;
        await authRepository.updateUserFailedAttempts(user.id, failedCount, lockUntil);
        await smartRepo.logLoginAttempt(identifier, ip, false);
        throw new AppError('Invalid email or password', 401);
    }

    // Reset failed attempts on success
    await authRepository.updateUserFailedAttempts(user.id, 0, null);
    await smartRepo.logLoginAttempt(identifier, ip, true);

    const meta = device_meta || {};
    const fingerprint = device_fingerprint || '';
    const isPlatformAdmin = !user.schoolId && (user.role?.roleType === 'PLATFORM');
    const isPlatformUser = !user.schoolId; // school_id null = platform-level (fallback when role.roleType missing)

    // Super Admin with 2FA enabled — require TOTP before device check
    if (user.mfaEnabled && (portal_type === 'super_admin' || isPlatformAdmin || isPlatformUser)) {
        const tempToken = jwtUtils.generateTempToken({
            userId: user.id.toString(),
            email: user.email,
        });
        return {
            success: true,
            requires_2fa: true,
            temp_token: tempToken,
            expires_in: 300,
        ...((portal_type === 'super_admin' || isPlatformUser) && { portal_type: 'super_admin' }),
        };
    }

    // Check trusted device
    let requiresOtp = true;
    let device = null;
    try {
        device = fingerprint ? await smartRepo.findRegisteredDeviceRaw(user.id, fingerprint) : null;
        if (device && device.is_trusted && device.trusted_until && new Date(device.trusted_until) > new Date()) {
            requiresOtp = false;
        }
    } catch (_) {
        // Tables might not exist yet
    }

    if (!requiresOtp) {
        const effectivePortal = (portal_type === 'super_admin' || isPlatformAdmin || isPlatformUser) ? 'super_admin' : (portal_type || 'school_admin');
        const accessToken = jwtUtils.generateAccessToken({
            userId: user.id.toString(),
            email: user.email,
            role: user.role?.roleType || 'SCHOOL',
            school_id: user.schoolId ? user.schoolId.toString() : null,
            portal_type: effectivePortal
        });
        const refreshToken = jwtUtils.generateRefreshToken({
            userId: user.id.toString(),
            school_id: user.schoolId ? user.schoolId.toString() : null
        });
        return {
            success: true,
            requires_otp: false,
            session_token: accessToken,
            refresh_token: refreshToken,
            portal_type: effectivePortal,
            user: {
                user_id: user.id.toString(),
                first_name: user.firstName,
                last_name: user.lastName,
                email: user.email,
                role: user.role?.roleType,
                school_id: user.schoolId ? user.schoolId.toString() : null
            }
        };
    }

    // Send OTP
    const otpCode = crypto.randomInt(100000, 999999).toString();
    let otpRecord = null;
    try {
        otpRecord = await smartRepo.createOtpVerification({
            userId: user.id,
            phone: user.phone,
            email: user.email,
            otpCode,
            otpType: 'device_verify',
            deviceFingerprint: fingerprint
        });
        // TODO: Send SMS via existing SMS provider - for now log
        console.log(`[DEV] OTP for ${user.phone || user.email}: ${otpCode}`);
    } catch (e) {
        console.error('[Smart Login] OTP creation failed:', e.message);
        throw new AppError(
            'Device verification is temporarily unavailable. Please run: psql -d school_erp -f database/migrations/fix_smart_login_bigint.sql',
            503
        );
    }

    return {
        success: true,
        requires_otp: true,
        otp_session_id: otpRecord.id,
        expires_in: 120,
        masked_phone: user.phone ? `+91 ${user.phone.slice(-4).padStart(user.phone.length - 4, 'X')}` : null,
        ...((portal_type === 'super_admin' || isPlatformUser) && { portal_type: 'super_admin' })
    };
};

/** Verify device OTP */
export const verifyDeviceOtp = async (input) => {
    const { otp_session_id, otp_code, trust_device, device_fingerprint, device_meta, portal_type } = input;

    const otp = await smartRepo.findOtpById(otp_session_id);
    if (!otp) throw new AppError('Invalid or expired OTP session', 400);

    if (otp.attempts >= otp.max_attempts) {
        throw new AppError('Too many attempts. Please request a new code.', 429);
    }

    if (otp.otp_code !== String(otp_code).trim()) {
        await smartRepo.incrementOtpAttempts(otp_session_id);
        throw new AppError('Invalid OTP code', 400);
    }

    await smartRepo.markOtpUsed(otp_session_id);

    const user = await authRepository.findUserById(otp.user_id);
    if (!user) throw new AppError('User not found', 404);

    const meta = device_meta || {};
    let deviceId = null;

    if (trust_device && device_fingerprint) {
        try {
            const existing = await smartRepo.findRegisteredDeviceRaw(otp.user_id, device_fingerprint);
            if (existing) {
                await smartRepo.trustDevice(otp.user_id, device_fingerprint, meta);
                deviceId = existing.id;
            } else {
                const inserted = await smartRepo.insertRegisteredDevice({
                    userId: otp.user_id,
                    schoolId: user.schoolId,
                    deviceFingerprint: device_fingerprint,
                    deviceName: meta.device_name,
                    deviceType: meta.device_type,
                    browser: meta.browser,
                    os: meta.os,
                    ipAddress: meta.ip_address,
                    city: meta.city,
                    country: meta.country
                });
                deviceId = inserted?.id;
            }
        } catch (_) {}
    }

    const isPlatformAdmin = !user.schoolId && (user.role?.roleType === 'PLATFORM');
    const isPlatformUser = !user.schoolId;
    const effectivePortal = (portal_type === 'super_admin' || isPlatformAdmin || isPlatformUser) ? 'super_admin' : 'school_admin';
    const accessToken = jwtUtils.generateAccessToken({
        userId: user.id.toString(),
        email: user.email,
        role: user.role?.roleType || 'SCHOOL',
        school_id: user.schoolId ? user.schoolId.toString() : null,
        portal_type: effectivePortal
    });
    const refreshToken = jwtUtils.generateRefreshToken({
        userId: user.id.toString(),
        school_id: user.schoolId ? user.schoolId.toString() : null
    });

    const expiresAt = new Date(Date.now() + 4 * 60 * 60 * 1000); // 4 hours
    try {
        await smartRepo.createAuthSession({
            userId: user.id,
            schoolId: user.schoolId,
            deviceId,
            sessionToken: accessToken,
            refreshToken,
            role: user.role?.name,
            portalType: effectivePortal,
            ipAddress: meta.ip_address,
            expiresAt
        });
    } catch (_) {}

    return {
        session_token: accessToken,
        refresh_token: refreshToken,
        portal_type: effectivePortal,
        user: {
            user_id: user.id.toString(),
            first_name: user.firstName,
            last_name: user.lastName,
            email: user.email,
            role: user.role?.roleType,
            school_id: user.schoolId ? user.schoolId.toString() : null
        }
    };
};

/** Session check */
export const sessionCheck = async (token) => {
    try {
        const session = await smartRepo.findAuthSessionByToken(token);
        if (session) {
            return {
                user_id: session.user_id?.toString(),
                first_name: session.first_name,
                last_name: session.last_name,
                email: session.email,
                role: session.role
            };
        }
    } catch (_) {}
    return null;
};

/** Logout */
export const logout = async (token, removeDeviceTrust = false) => {
    try {
        await smartRepo.deactivateAuthSession(token);
    } catch (_) {}
};

/** Get my devices */
export const getMyDevices = async (userId) => {
    try {
        const devices = await smartRepo.getRegisteredDevices(userId);
        return devices.map(d => ({
            id: d.id,
            device_name: d.device_name,
            device_type: d.device_type,
            browser: d.browser,
            os: d.os,
            city: d.city,
            trusted_until: d.trusted_until,
            last_used_at: d.last_used_at,
            is_trusted: d.is_trusted
        }));
    } catch (_) {
        return [];
    }
};

/** Remove device trust */
export const removeDevice = async (deviceId, userId) => {
    await smartRepo.removeDeviceTrust(deviceId, userId);
};
