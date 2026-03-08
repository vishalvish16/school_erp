/**
 * Middleware: Restrict access to Super Admin portal only.
 * Requires req.user.portal_type === 'super_admin'
 */
import { AppError } from '../utils/response.js';

export const requireSuperAdmin = (req, res, next) => {
    if (!req.user) {
        return next(new AppError('Authentication required', 401));
    }
    if (req.user.portal_type !== 'super_admin') {
        return next(new AppError('Super Admin access required', 403));
    }
    next();
};
