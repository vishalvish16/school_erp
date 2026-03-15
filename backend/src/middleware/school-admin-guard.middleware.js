/**
 * Middleware: Restrict access to School Admin portal only.
 * Requires req.user.portal_type === 'school_admin'
 * Also validates that school_id is present in the JWT payload.
 */
import { AppError } from '../utils/response.js';

export const requireSchoolAdmin = (req, res, next) => {
    if (!req.user) {
        return next(new AppError('Authentication required', 401));
    }

    const portalType = req.user.portal_type || req.user.portalType;
    if (portalType !== 'school_admin') {
        return next(new AppError('School Admin access required', 403));
    }

    const schoolId = req.user.school_id || req.user.schoolId;
    if (!schoolId) {
        return next(new AppError('No school context in token. Please log in again.', 403));
    }

    // Normalise to snake_case so downstream code always reads req.user.school_id
    req.user.school_id = schoolId;

    next();
};
