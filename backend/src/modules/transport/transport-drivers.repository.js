/**
 * Transport Drivers Repository — Prisma queries for driver management (school admin).
 */
import bcrypt from 'bcrypt';

import prisma from '../../config/prisma.js';

class TransportDriversRepository {
  async findAll({ schoolId, page = 1, limit = 20, search }) {
    const skip = (page - 1) * limit;

    const where = {
      schoolId,
      deletedAt: null,
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { phone: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
          { licenseNumber: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [data, total] = await Promise.all([
      prisma.driver.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          vehicles: {
            where: { deletedAt: null },
            select: { id: true, vehicleNo: true },
          },
        },
      }),
      prisma.driver.count({ where }),
    ]);

    return {
      data,
      pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  async findById(id, schoolId) {
    return prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
      include: {
        vehicles: {
          where: { deletedAt: null },
          select: { id: true, vehicleNo: true },
        },
        user: {
          select: { id: true, email: true, lastLogin: true },
        },
      },
    });
  }

  async create({ schoolId, driverData, password }) {
    // Find the Driver role
    const driverRole = await prisma.role.findFirst({
      where: { name: 'Driver' },
    });
    if (!driverRole) {
      throw new Error('Driver role not found in roles table. Please seed roles first.');
    }

    // Generate employee number
    const count = await prisma.driver.count({ where: { schoolId } });
    const employeeNo = `DRV-${String(count + 1).padStart(4, '0')}`;

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Generate email if not provided (required by User model)
    const email = driverData.email || `driver-${employeeNo.toLowerCase()}@school-${schoolId.substring(0, 8)}.local`;

    // Use transaction to create both User and Driver
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email,
          passwordHash,
          roleId: driverRole.id,
          schoolId,
          firstName: driverData.firstName,
          lastName: driverData.lastName,
          phone: driverData.phone || null,
          isActive: true,
          mustChangePassword: true,
        },
      });

      const driver = await tx.driver.create({
        data: {
          schoolId,
          userId: user.id,
          employeeNo,
          firstName: driverData.firstName,
          lastName: driverData.lastName,
          gender: driverData.gender,
          phone: driverData.phone || null,
          email,
          licenseNumber: driverData.licenseNumber || null,
          licenseExpiry: driverData.licenseExpiry ? new Date(driverData.licenseExpiry) : null,
          dateOfBirth: driverData.dateOfBirth ? new Date(driverData.dateOfBirth) : null,
          address: driverData.address || null,
          emergencyContactName: driverData.emergencyContactName || null,
          emergencyContactPhone: driverData.emergencyContactPhone || null,
          isActive: true,
        },
      });

      return { driver, userId: user.id };
    });

    return result;
  }

  async update(id, schoolId, data) {
    const existing = await prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
    });
    if (!existing) return null;

    // Build update data, handling date fields
    const updateData = { ...data, updatedAt: new Date() };
    if (data.licenseExpiry) updateData.licenseExpiry = new Date(data.licenseExpiry);
    if (data.dateOfBirth) updateData.dateOfBirth = new Date(data.dateOfBirth);

    return prisma.driver.update({
      where: { id },
      data: updateData,
    });
  }

  async softDelete(id, schoolId) {
    const existing = await prisma.driver.findFirst({
      where: { id, schoolId, deletedAt: null },
    });
    if (!existing) return null;

    // Soft-delete the driver and deactivate the linked user
    return prisma.$transaction(async (tx) => {
      const driver = await tx.driver.update({
        where: { id },
        data: { deletedAt: new Date(), isActive: false },
      });

      if (existing.userId) {
        await tx.user.update({
          where: { id: existing.userId },
          data: { isActive: false },
        });
      }

      return driver;
    });
  }
}

export const transportDriversRepository = new TransportDriversRepository();
