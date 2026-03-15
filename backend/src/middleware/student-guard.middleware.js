/**
 * Middleware: Restrict access to Student portal only.
 * Requires req.user.portal_type === 'student'.
 * Performs a live DB lookup to ensure the Student record is active and not deleted.
 * Attaches req.student (the Student record) — all downstream queries MUST use
 * req.student.schoolId for tenant isolation instead of req.user.school_id.
 */
import { PrismaClient } from '@prisma/client';
import { AppError } from '../utils/response.js';

const prisma = new PrismaClient();

export const requireStudent = async (req, res, next) => {
    try {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        const portalType = req.user.portal_type || req.user.portalType;
        if (portalType !== 'student') {
            return next(new AppError('Student portal access required', 403));
        }

        const userId = req.user.userId || req.user.id;
        if (!userId) {
            return next(new AppError('Invalid token payload. Please log in again.', 403));
        }

        const studentRecord = await prisma.student.findFirst({
            where: {
                userId,
                deletedAt: null,
                status: 'ACTIVE',
            },
        });

        if (!studentRecord) {
            return next(new AppError('Student account not found or inactive. Access denied.', 403));
        }

        req.student = studentRecord;
        req.user.school_id = studentRecord.schoolId;
        return next();
    } catch (error) {
        next(error);
    }
};
