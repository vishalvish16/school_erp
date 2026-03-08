/**
 * 2FA (TOTP) Service — setup, enable, disable, verify
 */
import { generateSecret, verify, generateURI } from 'otplib';
import { PrismaClient } from '@prisma/client';
import { AppError } from '../../utils/response.js';
import * as jwtUtils from '../../utils/jwt.js';
import * as smartRepo from './smart-login.repository.js';
import crypto from 'crypto';

const prisma = new PrismaClient();
import bcrypt from 'bcrypt';

const ISSUER = 'VIDYRON Super Admin';

/** Setup 2FA — generate secret and otpauth URI (does not enable yet) */
export const setup2fa = async (userId) => {
    const user = await prisma.user.findUnique({
        where: { id: BigInt(userId) },
        select: { id: true, email: true, mfaEnabled: true },
    });
    if (!user) throw new AppError('User not found', 404);
    if (user.mfaEnabled) throw new AppError('2FA is already enabled', 400);

    const secret = generateSecret();
    const uri = generateURI({
        issuer: ISSUER,
        label: user.email,
        secret,
    });

    // Store secret temporarily (not enabled) — we'll overwrite on enable after verification
    await prisma.user.update({
        where: { id: user.id },
        data: { mfaSecret: secret },
    });

    return {
        secret,
        otpauth_uri: uri,
        // For manual entry if QR scan fails
        manual_entry_key: secret,
    };
};

/** Enable 2FA — verify TOTP code then set mfaEnabled */
export const enable2fa = async (userId, totpCode) => {
    const user = await prisma.user.findUnique({
        where: { id: BigInt(userId) },
        select: { id: true, mfaSecret: true, mfaEnabled: true },
    });
    if (!user) throw new AppError('User not found', 404);
    if (user.mfaEnabled) throw new AppError('2FA is already enabled', 400);
    if (!user.mfaSecret) throw new AppError('Run setup first', 400);

    const isValid = await verify({ secret: user.mfaSecret, token: totpCode });
    if (!isValid) throw new AppError('Invalid verification code', 400);

    await prisma.user.update({
        where: { id: user.id },
        data: { mfaEnabled: true },
    });

    return { success: true };
};

/** Disable 2FA — require password confirmation */
export const disable2fa = async (userId, password) => {
    const user = await prisma.user.findUnique({
        where: { id: BigInt(userId) },
        select: { id: true, passwordHash: true, mfaEnabled: true },
    });
    if (!user) throw new AppError('User not found', 404);
    if (!user.mfaEnabled) throw new AppError('2FA is not enabled', 400);

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new AppError('Invalid password', 401);

    await prisma.user.update({
        where: { id: user.id },
        data: { mfaEnabled: false, mfaSecret: null },
    });

    return { success: true };
};

/** Get 2FA status for current user */
export const get2faStatus = async (userId) => {
    const user = await prisma.user.findUnique({
        where: { id: BigInt(userId) },
        select: { mfaEnabled: true },
    });
    if (!user) throw new AppError('User not found', 404);
    return { mfa_enabled: user.mfaEnabled };
};

/** Verify TOTP and complete login — used after password step when mfaEnabled */
export const verify2faAndCompleteLogin = async (input) => {
    const { temp_token, totp_code, device_fingerprint } = input;

    const decoded = jwtUtils.verifyTempToken(temp_token);
    const userId = decoded.userId ? BigInt(decoded.userId) : null;
    if (!userId) throw new AppError('Invalid or expired verification session', 400);

    const user = await prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
    });
    if (!user) throw new AppError('User not found', 404);
    if (!user.mfaEnabled || !user.mfaSecret) throw new AppError('2FA not configured', 400);

    const isValid = await verify({ secret: user.mfaSecret, token: totp_code });
    if (!isValid) throw new AppError('Invalid verification code', 400);

    // TOTP valid — now check device (same logic as smart-login after password)
    const fingerprint = device_fingerprint || '';
    let requiresOtp = true;
    try {
        const device = fingerprint ? await smartRepo.findRegisteredDeviceRaw(user.id, fingerprint) : null;
        if (device && device.is_trusted && device.trusted_until && new Date(device.trusted_until) > new Date()) {
            requiresOtp = false;
        }
    } catch (_) {}

    const isPlatformAdmin = !user.schoolId && (user.role?.roleType === 'PLATFORM');
    const isPlatformUser = !user.schoolId;
    const effectivePortal = (isPlatformAdmin || isPlatformUser) ? 'super_admin' : 'school_admin';

    if (!requiresOtp) {
        const accessToken = jwtUtils.generateAccessToken({
            userId: user.id.toString(),
            email: user.email,
            role: user.role?.roleType || 'SCHOOL',
            school_id: user.schoolId ? user.schoolId.toString() : null,
            portal_type: effectivePortal,
        });
        const refreshToken = jwtUtils.generateRefreshToken({
            userId: user.id.toString(),
            school_id: user.schoolId ? user.schoolId.toString() : null,
        });
        return {
            success: true,
            requires_device_otp: false,
            session_token: accessToken,
            refresh_token: refreshToken,
            portal_type: effectivePortal,
            user: {
                user_id: user.id.toString(),
                first_name: user.firstName,
                last_name: user.lastName,
                email: user.email,
                role: user.role?.roleType,
                school_id: user.schoolId ? user.schoolId.toString() : null,
            },
        };
    }

    // Need device OTP
    const otpCode = crypto.randomInt(100000, 999999).toString();
    const otpRecord = await smartRepo.createOtpVerification({
        userId: user.id,
        phone: user.phone,
        email: user.email,
        otpCode,
        otpType: 'device_verify',
        deviceFingerprint: fingerprint,
    });
    console.log(`[DEV] OTP for ${user.phone || user.email}: ${otpCode}`);

    return {
        success: true,
        requires_device_otp: true,
        otp_session_id: otpRecord.id,
        expires_in: 120,
        masked_phone: user.phone ? `+91 ${user.phone.slice(-4).padStart(user.phone.length - 4, 'X')}` : null,
        portal_type: effectivePortal,
    };
};
