/**
 * POST /auth/verify-parent-otp
 * Verify OTP and issue JWT for parent portal (24h expiry)
 * No auth required
 */
import { successResponse } from '../../utils/response.js';
import * as verifyParentOtpService from './verify-parent-otp.service.js';

export const verifyParentOtpController = async (req, res, next) => {
    try {
        const { otp_session_id, otp, phone, school_id } = req.body;
        const result = await verifyParentOtpService.verifyParentOtp({
            otp_session_id,
            otp,
            phone,
            school_id,
        });
        return successResponse(res, 200, 'Login successful', result);
    } catch (error) {
        next(error);
    }
};
