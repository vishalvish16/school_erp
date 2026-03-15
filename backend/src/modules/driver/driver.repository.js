/**
 * Driver Repository — Prisma queries for the driver portal.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

class DriverRepository {
  async findByIdWithRelations(id, schoolId) {
    return prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
      include: {
        school: { select: { id: true, name: true, logoUrl: true } },
        vehicle: {
          include: {
            route: {
              include: { stops: true },
            },
          },
        },
        user: {
          select: {
            id: true,
            email: true,
            lastLogin: true,
          },
        },
      },
    });
  }

  async update(id, schoolId, data) {
    const existing = await prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
    });
    if (!existing) return null;
    return prisma.driver.update({
      where: { id },
      data: { ...data, updatedAt: new Date() },
    });
  }
}

export const driverRepository = new DriverRepository();
