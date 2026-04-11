/**
 * POST /auth/verify-student-otp
 * Verify student OTP session and issue JWT for student portal
 * No auth required
 */
import { successResponse } from '../../utils/response.js';
import { verifyStudentOtp } from './verify-student-otp.service.js';

export const verifyStudentOtpController = async (req, res, next) => {
    try {
        const { otp_session_id, otp, phone, school_id } = req.body;
        const result = await verifyStudentOtp({ otp_session_id, otp, phone, school_id });
        return successResponse(res, 200, 'Student login successful', result);
    } catch (error) {
        next(error);
    }
};
