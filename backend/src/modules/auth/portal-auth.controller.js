/**
 * Portal-specific auth controllers: verify-2fa, group-admin login, qr-login
 */
import { successResponse } from '../../utils/response.js';
import * as smartLoginService from './smart-login.service.js';
import * as twoFaService from './two-fa.service.js';

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
        const { identifier, password, otp_code, group_id, device_fingerprint, device_meta, trust_device } = req.body;
        const ip = req.ip || req.connection?.remoteAddress || null;
        // TODO: Verify user with portal_type group_admin, group_id match
        // TODO: Password or OTP verification, device check
        // Stub: use existing smart login when password provided
        if (password && device_fingerprint) {
            const result = await smartLoginService.smartLogin({
                identifier,
                password,
                portal_type: 'group_admin',
                school_id: null,
                device_fingerprint,
                device_meta: device_meta || {},
                ip_address: ip
            });
            const data = result.requires_otp
                ? { requires_otp: true, otp_session_id: result.otp_session_id, expires_in: result.expires_in, masked_phone: result.masked_phone }
                : { access_token: result.session_token, refresh_token: result.refresh_token, user: result.user, group_id };
            return successResponse(res, 200, 'Login successful', data);
        }
        throw new AppError('Group admin login not fully implemented', 501);
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
