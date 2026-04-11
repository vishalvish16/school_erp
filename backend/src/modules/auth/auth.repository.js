
import prisma from '../../config/prisma.js';

export const findUserByEmail = async (email) => {
    return prisma.user.findUnique({
        where: { email },
        include: {
            role: true
        }
    });
};

export const updateUserResetToken = async (email, token, expiry) => {
    return prisma.user.update({
        where: { email },
        data: {
            resetPasswordToken: token,
            resetPasswordExpires: expiry
        }
    });
};

export const findUserByResetToken = async (token) => {
    return prisma.user.findFirst({
        where: {
            resetPasswordToken: token,
            resetPasswordExpires: {
                gt: new Date()
            }
        }
    });
};

export const updateUserPassword = async (userId, hashedPassword) => {
    return prisma.user.update({
        where: { id: userId },
        data: {
            passwordHash: hashedPassword,
            resetPasswordToken: null,
            resetPasswordExpires: null
        }
    });
};

export const updateUserFailedAttempts = async (userId, failedCount, lockedUntil) => {
    return prisma.user.update({
        where: { id: userId },
        data: {
            failedLoginAttempts: failedCount,
            lockedUntil: lockedUntil || null
        }
    });
};

export const findUserById = async (userId) => {
    return prisma.user.findUnique({
        where: { id: userId },
        include: { role: true }
    });
};
