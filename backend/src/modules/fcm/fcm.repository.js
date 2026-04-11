/**
 * FCM Repository — store and query FCM tokens.
 */

import prisma from '../../config/prisma.js';

export async function upsertToken({ fcmToken, portalType, parentId, studentId, schoolId }) {
    return prisma.fcmToken.upsert({
        where: { fcmToken },
        create: {
            fcmToken,
            portalType,
            parentId: parentId || null,
            studentId: studentId || null,
            schoolId,
        },
        update: {
            portalType,
            parentId: parentId || null,
            studentId: studentId || null,
            schoolId,
            updatedAt: new Date(),
        },
    });
}

export async function getTokensForStudentNotice({ studentId, schoolId, targetStudent, targetParent }) {
    const result = { parentTokens: [], studentTokens: [] };
    if (targetStudent) {
        const rows = await prisma.fcmToken.findMany({
            where: { schoolId, studentId, portalType: 'student' },
            select: { fcmToken: true },
        });
        result.studentTokens = rows.map((t) => t.fcmToken);
    }
    if (targetParent) {
        const parentIds = await prisma.studentParent.findMany({
            where: { studentId },
            select: { parentId: true },
        });
        const ids = parentIds.map((p) => p.parentId);
        if (ids.length > 0) {
            const rows = await prisma.fcmToken.findMany({
                where: { schoolId, parentId: { in: ids }, portalType: 'parent' },
                select: { fcmToken: true },
            });
            result.parentTokens = rows.map((t) => t.fcmToken);
        }
    }
    return result;
}

/**
 * Get FCM tokens for a specific parent.
 */
export async function getTokensForParent({ parentId, schoolId }) {
    const rows = await prisma.fcmToken.findMany({
        where: { schoolId, parentId, portalType: 'parent' },
        select: { fcmToken: true },
    });
    return rows.map((t) => t.fcmToken);
}

/**
 * Get FCM tokens for school-wide notice based on targetRole.
 * targetRole: 'parent' | 'student' | 'all' | null
 */
export async function getTokensForSchoolNotice({ schoolId, targetRole }) {
    const result = { parentTokens: [], studentTokens: [] };
    const role = (targetRole || 'all').toLowerCase();

    if (role === 'parent' || role === 'all') {
        const rows = await prisma.fcmToken.findMany({
            where: { schoolId, portalType: 'parent' },
            select: { fcmToken: true },
        });
        result.parentTokens = rows.map((t) => t.fcmToken);
    }
    if (role === 'student' || role === 'all') {
        const rows = await prisma.fcmToken.findMany({
            where: { schoolId, portalType: 'student' },
            select: { fcmToken: true },
        });
        result.studentTokens = rows.map((t) => t.fcmToken);
    }
    return result;
}
