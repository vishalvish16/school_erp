/**
 * Middleware: Restrict access to Parent portal only.
 * Requires req.user.portal_type === 'parent' and req.user.parent_id.
 * Performs a live DB lookup to ensure the Parent record is active and not deleted.
 * Attaches req.parent (the Parent record) — all downstream queries use
 * req.parent.schoolId for tenant isolation.
 */
import { AppError } from '../utils/response.js';

import prisma from '../config/prisma.js';

export const requireParent = async (req, res, next) => {
    try {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        const portalType = req.user.portal_type || req.user.portalType;
        if (portalType !== 'parent') {
            return next(new AppError('Parent portal access required', 403));
        }

        const parentId = req.user.parent_id || req.user.parentId;
        if (!parentId) {
            return next(new AppError('Invalid token payload. Please log in again.', 403));
        }

        const parentRecord = await prisma.parent.findFirst({
            where: {
                id: parentId,
                isActive: true,
                deletedAt: null,
            },
            include: { school: true },
        });

        if (!parentRecord) {
            return next(new AppError('Parent account not found or inactive', 403));
        }

        req.parent = parentRecord;
        req.user.school_id = parentRecord.schoolId;
        return next();
    } catch (error) {
        next(error);
    }
};
