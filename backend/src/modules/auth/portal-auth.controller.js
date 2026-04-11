/**
 * Portal-specific auth controllers: verify-2fa, group-admin login, qr-login
 */
import { successResponse, AppError } from '../../utils/response.js';
import * as smartLoginService from './smart-login.service.js';
import * as twoFaService from './two-fa.service.js';
import * as authService from './auth.service.js';
import prisma from '../../config/prisma.js';

/** POST /auth/super-admin/verify-2fa */
export const verify2faController = async (req, res, next) => {
    try {
        const { totp_code, temp_token, device_fingerprint, device_meta } = req.body;
        const meta = device_meta || {};
        meta.ip_address = meta.ip_address || req.ip || req.connection?.remoteAddress;
        const result = await twoFaService.verify2faAndCompleteLogin({
            temp_token,
            totp_code,
            device_fingerprint,
            device_meta: meta,
        });
        return successResponse(res, 200, '2FA verified', result);
    } catch (error) {
        next(error);
    }
};

/** POST /auth/group-admin/login */
export const groupAdminLoginController = async (req, res, next) => {
    try {
        const { identifier, password, group_id, device_fingerprint, device_meta, trust_device } = req.body;
        const ip = req.ip || req.headers['x-forwarded-for'] || '127.0.0.1';

        const result = await smartLoginService.smartLogin({
            identifier,
            password,
            group_id,
            deviceFingerprint: device_fingerprint || `anon_${Date.now()}`,
            deviceMeta: device_meta || {},
            ipAddress: ip,
            portalType: 'group_admin',
            trustDevice: trust_device || false
        });

        if (result.requires_otp) {
            const data = {
                requires_otp: true,
                otp_session_id: result.otp_session_id,
                masked_phone: result.masked_phone,
                masked_email: result.masked_email,
                otp_sent_to: result.otp_sent_to
            };
            if (result.dev_otp) data.dev_otp = result.dev_otp;
            return successResponse(res, 200, 'OTP required', data);
        }

        if (result.session_token) {
            const group = await prisma.schoolGroup.findFirst({
                where: { groupAdminUserId: result.user.user_id },
                select: { id: true, name: true, slug: true }
            });
            return successResponse(res, 200, 'Login successful', {
                access_token: result.session_token,
                refresh_token: result.refresh_token,
                user: result.user,
                group: group ? { id: group.id, name: group.name, slug: group.slug } : null
            });
        }

        return successResponse(res, 200, 'Login initiated', result);
    } catch (error) {
        next(error);
    }
};

/** POST /auth/group-admin/forgot-password */
export const groupAdminForgotPasswordController = async (req, res, next) => {
    try {
        const { email } = req.body;
        const origin = req.headers.origin || req.headers.referer || 'http://localhost:3000';
        const result = await authService.forgotPassword(email, origin);
        return successResponse(res, 200, result.message || 'Reset instructions sent', result);
    } catch (error) {
        next(error);
    }
};

/** POST /auth/group-admin/reset-password */
export const groupAdminResetPasswordController = async (req, res, next) => {
    try {
        const { token, new_password } = req.body;
        const result = await authService.resetPassword(token, new_password);
        return successResponse(res, 200, result.message || 'Password reset successfully', result);
    } catch (error) {
        next(error);
    }
};

/** POST /auth/qr-login */
export const qrLoginController = async (req, res, next) => {
    try {
        const { qr_token, school_id, device_fingerprint, device_meta } = req.body;
        // TODO: Decode qr_token (JWT/signed), extract user_id, verify school, check expiry
        // TODO: Device check, driver vehicle assignment
        // Stub: return session
        const accessToken = jwtUtils.generateAccessToken({
            userId: '1',
            email: 'staff@school.in',
            role: 'SCHOOL',
            school_id: String(school_id)
        });
        return successResponse(res, 200, 'QR login successful', {
            session_token: accessToken,
            user_profile: { user_id: '1', first_name: 'Staff', last_name: 'User', email: 'staff@school.in' },
            role: 'teacher',
            vehicle_id: null
        });
    } catch (error) {
        next(error);
    }
};
