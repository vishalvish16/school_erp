import * as authService from './auth.service.js';
import * as smartLoginService from './smart-login.service.js';
import { successResponse, AppError } from '../../utils/response.js';

export const loginController = async (req, res, next) => {
    try {
        const { identifier, email, password, portal_type, school_id, device_fingerprint, device_meta } = req.body;
        const loginEmail = identifier || email;
        if (!loginEmail || !password) {
            return next(new AppError('Email and password are required', 400));
        }

        // Platform login always uses smart login (device verification)
        if (!device_fingerprint || String(device_fingerprint).trim() === '') {
            return next(new AppError('Device fingerprint is required for platform login', 400));
        }

        const ip = req.ip || req.connection?.remoteAddress || null;
        const result = await smartLoginService.smartLogin({
            identifier: loginEmail,
            password,
            portal_type: portal_type || 'school_admin',
            school_id: school_id || null,
            device_fingerprint,
            device_meta: device_meta || {},
            ip_address: ip
        });
        let data;
        if (result.requires_2fa) {
            data = {
                requires_2fa: true,
                temp_token: result.temp_token,
                expires_in: result.expires_in,
                ...(result.portal_type && { portal_type: result.portal_type }),
            };
        } else if (result.requires_otp) {
            data = {
                requires_otp: true,
                otp_session_id: result.otp_session_id,
                expires_in: result.expires_in,
                masked_phone: result.masked_phone,
                masked_email: result.masked_email,
                otp_sent_to: result.otp_sent_to,
                ...(result.portal_type && { portal_type: result.portal_type }),
                ...(result.dev_otp && { dev_otp: result.dev_otp }),
            };
        } else {
            data = {
                access_token: result.session_token,
                refresh_token: result.refresh_token,
                user: result.user,
                ...(result.portal_type && { portal_type: result.portal_type }),
            };
        }
        return successResponse(res, 200, 'Login successful', data);
    } catch (error) {
        next(error);
    }
};

export const forgotPasswordController = async (req, res, next) => {
    try {
        const { email } = req.body;
        // Get the frontend origin from request headers, fallback to localhost for safety
        const origin = req.headers.origin || 'http://localhost:3000';
        const result = await authService.forgotPassword(email, origin);
        return successResponse(res, 200, result.message);
    } catch (error) {
        next(error);
    }
};

export const resetPasswordController = async (req, res, next) => {
    try {
        const { token, newPassword } = req.body;
        const result = await authService.resetPassword(token, newPassword);
        return successResponse(res, 200, result.message);
    } catch (error) {
        next(error);
    }
};
