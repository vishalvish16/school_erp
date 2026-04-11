import { AppError } from '../utils/response.js';

import prisma from '../config/prisma.js';

/**
 * Middleware to ensure the school has an active, non-expired subscription.
 * Bypasses for platform-level super admins.
 */
export const verifySubscription = async (req, res, next) => {
    try {
        // 1. Bypass check for PLATFORM/SUPER_ADMIN roles
        // We assume platform admins have global access regardless of a specific school's subscription
        if (req.user && (req.user.role === 'PLATFORM' || req.user.role === 'SUPER_ADMIN')) {
            return next();
        }

        const schoolId = req.user?.school_id;
        if (!schoolId) {
            return next(new AppError('School context missing. Access denied.', 403));
        }

        // 2. Fetch the current active subscription
        const subscription = await prisma.schoolSubscription.findFirst({
            where: {
                schoolId: BigInt(schoolId),
                status: 'ACTIVE',
            },
            orderBy: {
                currentPeriodEnd: 'desc' // Get the most relevant one if multiple exist
            }
        });

        // 3. Validation Logic
        const now = new Date();

        if (!subscription) {
            return next(new AppError('No active subscription found for your school.', 403));
        }

        if (subscription.status !== 'ACTIVE') {
            return next(new AppError('Your school subscription is currently suspended or inactive.', 403));
        }

        if (subscription.currentPeriodEnd < now) {
            return next(new AppError('Your subscription has expired. Please renew to continue.', 403));
        }

        // Subscription is valid
        next();
    } catch (error) {
        next(error);
    }
};
