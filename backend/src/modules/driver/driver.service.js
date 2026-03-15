/**
 * Driver Service — business logic for driver portal routes.
 */
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/response.js';
import { driverRepository } from './driver.repository.js';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

function formatDate(date) {
  if (!date) return null;
  const d = new Date(date);
  return d.toISOString().slice(0, 10);
}

class DriverService {
  async getDashboardStats(driver) {
    const vehicle = driver.vehicle;
    const route = vehicle?.route;
    const stops = route?.stops || [];

    return {
      driver: {
        id: driver.id,
        firstName: driver.firstName,
        lastName: driver.lastName,
        photoUrl: driver.photoUrl,
      },
      school: driver.school
        ? {
            id: driver.school.id,
            name: driver.school.name,
            logoUrl: driver.school.logoUrl,
          }
        : null,
      vehicle: vehicle
        ? {
            id: vehicle.id,
            vehicleNo: vehicle.vehicleNo,
            capacity: vehicle.capacity,
          }
        : null,
      route: route
        ? {
            id: route.id,
            name: route.name,
            stopCount: stops.length,
          }
        : null,
      studentCount: 0,
      tripStatus: 'NOT_STARTED',
    };
  }

  async getProfile(driverId, schoolId) {
    const driver = await driverRepository.findByIdWithRelations(driverId, schoolId);
    if (!driver) throw new AppError('Driver not found', 404);

    const vehicle = driver.vehicle;
    const route = vehicle?.route;
    const stops = route?.stops || [];

    return {
      driver: {
        id: driver.id,
        employeeNo: driver.employeeNo,
        firstName: driver.firstName,
        lastName: driver.lastName,
        gender: driver.gender,
        dateOfBirth: formatDate(driver.dateOfBirth),
        phone: driver.phone,
        email: driver.email,
        licenseNumber: driver.licenseNumber,
        licenseExpiry: formatDate(driver.licenseExpiry),
        photoUrl: driver.photoUrl,
        address: driver.address,
        emergencyContactName: driver.emergencyContactName,
        emergencyContactPhone: driver.emergencyContactPhone,
        isActive: driver.isActive,
      },
      vehicle: vehicle
        ? {
            id: vehicle.id,
            vehicleNo: vehicle.vehicleNo,
            capacity: vehicle.capacity,
          }
        : null,
      route: route
        ? {
            id: route.id,
            name: route.name,
            stopCount: stops.length,
          }
        : null,
      user: driver.user
        ? {
            userId: driver.user.id,
            email: driver.user.email,
            lastLogin: driver.user.lastLogin ? driver.user.lastLogin.toISOString() : null,
          }
        : null,
    };
  }

  async updateProfile(driverId, schoolId, data) {
    const updates = {};
    if (data.phone !== undefined) updates.phone = data.phone?.trim() || null;
    if (data.emergencyContactName !== undefined) updates.emergencyContactName = data.emergencyContactName?.trim() || null;
    if (data.emergencyContactPhone !== undefined) updates.emergencyContactPhone = data.emergencyContactPhone?.trim() || null;
    if (data.address !== undefined) updates.address = data.address?.trim() || null;

    if (Object.keys(updates).length === 0) {
      const driver = await prisma.driver.findFirst({
        where: { id: driverId, schoolId, deletedAt: null },
        include: {
          school: { select: { id: true, name: true, logoUrl: true } },
          vehicle: {
            include: {
              route: { include: { stops: true } },
            },
          },
          user: { select: { id: true, email: true, lastLogin: true } },
        },
      });
      return this.getProfile(driver.id, schoolId);
    }

    await driverRepository.update(driverId, schoolId, updates);
    return this.getProfile(driverId, schoolId);
  }

  async changePassword(driverId, schoolId, userId, currentPassword, newPassword) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true },
    });
    if (!user) throw new AppError('User not found', 404);

    const driver = await prisma.driver.findFirst({
      where: { id: driverId, schoolId, userId },
    });
    if (!driver) throw new AppError('Driver not found', 404);

    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) throw new AppError('Current password is incorrect', 401);

    const hash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash: hash, passwordChangedAt: new Date(), mustChangePassword: false },
    });
  }
}

export const driverService = new DriverService();
