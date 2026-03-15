/**
 * Middleware: Restrict access to Staff portal only.
 * Requires req.user.portal_type === 'staff'.
 * Performs a live DB lookup to ensure the Staff record is active and not deleted.
 * Attaches req.staff (the Staff record) — all downstream queries MUST use
 * req.staff.schoolId for tenant isolation instead of req.user.school_id.
 *
 * Extended to also accept Non-Teaching Staff records:
 * - If found as teaching staff:     req.staff, req.isNonTeaching = false
 * - If found as non-teaching staff: req.staff, req.ntStaff, req.isNonTeaching = true
 */
import { PrismaClient } from '@prisma/client';
import { AppError } from '../utils/response.js';

const prisma = new PrismaClient();

export const requireStaff = async (req, res, next) => {
    try {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        const portalType = req.user.portal_type || req.user.portalType;
        if (portalType !== 'staff') {
            return next(new AppError('Staff portal access required', 403));
        }

        const userId = req.user.userId || req.user.id;
        if (!userId) {
            return next(new AppError('Invalid token payload. Please log in again.', 403));
        }

        // Live DB lookup — check teaching staff first
        const staffRecord = await prisma.staff.findFirst({
            where: {
                userId,
                isActive:  true,
                deletedAt: null,
            },
        });

        if (staffRecord) {
            req.staff         = staffRecord;
            req.isNonTeaching = false;
            // Ensure school_id is normalised for downstream access
            req.user.school_id = staffRecord.schoolId;
            return next();
        }

        // If not found as teaching staff, check non-teaching staff
        const ntStaff = await prisma.nonTeachingStaff.findFirst({
            where: {
                userId,
                deletedAt: null,
                isActive:  true,
            },
            include: {
                role:   true,
                school: true,
            },
        });

        if (ntStaff) {
            req.staff = {
                id:       ntStaff.id,
                schoolId: ntStaff.schoolId,
                userId:   ntStaff.userId,
                ...ntStaff,
            };
            req.ntStaff       = ntStaff;
            req.isNonTeaching = true;
            // Ensure school_id is normalised for downstream access
            req.user.school_id = ntStaff.schoolId;
            return next();
        }

        return next(new AppError('Staff account not found or inactive. Access denied.', 403));
    } catch (error) {
        next(error);
    }
};
