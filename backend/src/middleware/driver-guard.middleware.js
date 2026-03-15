/**
 * Middleware: Restrict access to Driver portal only.
 * Requires req.user.portal_type === 'driver'.
 * Loads Driver by userId with school, vehicle, vehicle.route (stops).
 * Attaches req.driverId and req.driver.
 */
import { PrismaClient } from '@prisma/client';
import { AppError } from '../utils/response.js';

const prisma = new PrismaClient();

export const requireDriver = async (req, res, next) => {
  try {
    if (!req.user) {
      return next(new AppError('Authentication required', 401));
    }

    const portalType = req.user.portal_type || req.user.portalType;
    if (portalType !== 'driver') {
      return next(new AppError('Driver portal access required', 403));
    }

    const userId = req.user.userId || req.user.id;
    if (!userId) {
      return next(new AppError('Invalid token payload. Please log in again.', 403));
    }

    const schoolId = req.user.school_id || req.user.schoolId;
    if (!schoolId) {
      return next(new AppError('School context required', 403));
    }

    const driver = await prisma.driver.findFirst({
      where: {
        userId,
        schoolId,
        deletedAt: null,
        isActive: true,
      },
      include: {
        school: { select: { id: true, name: true, logoUrl: true } },
        vehicle: {
          include: {
            route: {
              include: { stops: true },
            },
          },
        },
      },
    });

    if (!driver) {
      return next(new AppError('Driver account not found or inactive. Access denied.', 403));
    }

    req.driverId = driver.id;
    req.driver = driver;
    next();
  } catch (error) {
    next(error);
  }
};
