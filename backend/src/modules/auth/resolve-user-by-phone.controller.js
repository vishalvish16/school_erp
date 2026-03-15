/**
 * POST /auth/resolve-user-by-phone
 * Resolve phone number to school + user for parent/student mobile login
 * No auth required
 */
import { successResponse, AppError } from '../../utils/response.js';
import * as resolveRepo from './resolve-user-by-phone.repository.js';

export const resolveUserByPhoneController = async (req, res, next) => {
    try {
        let phone = (req.body.phone || '').toString().trim();
        const userType = req.body.user_type || 'parent';
        const schoolId = req.body.school_id || null;

        // Normalize to E.164-ish (allow +91 or 10 digits)
        if (!phone.startsWith('+')) {
            if (phone.length === 10 && /^\d+$/.test(phone)) {
                phone = '+91' + phone;
            } else if (phone.length === 12 && phone.startsWith('91')) {
                phone = '+' + phone;
            }
        }

        const result = await resolveRepo.resolveUserByPhone(phone, userType, schoolId);

        if (!result) {
            throw new AppError(
                'This number isn\'t registered with any school on Vidyron. Ask your school admin to add you.',
                404
            );
        }

        // Single school (parent returns schools array; legacy User returns schools)
        const school = result.school || (result.schools && result.schools[0]);
        if (school && (!result.schools || result.schools.length === 1)) {
            return successResponse(res, 200, 'School found', {
                school,
                user: result.user,
                otp_session_id: result.otp_session_id,
                masked_phone: result.masked_phone
            });
        }

        // Multiple schools (rare) — return list for picker
        if (result.schools && result.schools.length > 1) {
            return successResponse(res, 200, 'Multiple schools found', {
                schools: result.schools,
                user: result.user,
                otp_session_id: result.otp_session_id,
                masked_phone: result.masked_phone
            });
        }

        throw new AppError('User not found', 404);
    } catch (error) {
        next(error);
    }
};
