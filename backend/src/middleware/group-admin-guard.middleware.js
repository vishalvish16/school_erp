import { PrismaClient } from '@prisma/client';
import { AppError } from '../utils/response.js';

const prisma = new PrismaClient();

export const requireGroupAdmin = async (req, res, next) => {
  try {
    const user = req.user;
    if (!user) return next(new AppError('Unauthorized', 401));

    // Accept either role-based or portal_type-based check
    const isGroupAdmin = user.role === 'group_admin' || user.portalType === 'group_admin' || user.portal_type === 'group_admin';
    if (!isGroupAdmin) {
      return next(new AppError('Access denied. Group admin privileges required.', 403));
    }

    // Look up which group this admin manages
    const group = await prisma.schoolGroup.findFirst({
      where: { groupAdminUserId: user.userId, deletedAt: null }
    });

    if (!group) {
      return next(new AppError('No group assigned to this account.', 403));
    }

    if (group.status === 'INACTIVE') {
      return next(new AppError('Your group account is inactive.', 403));
    }

    req.groupId = group.id;
    req.group = group;
    next();
  } catch (error) {
    next(error);
  }
};
