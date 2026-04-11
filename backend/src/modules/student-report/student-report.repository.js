/**
 * Student Report Repository — all Prisma queries for student report endpoints.
 * Every query is scoped to schoolId — no cross-school access possible.
 * This module is standalone and does NOT import from school-admin or staff modules.
 */

import prisma from '../../config/prisma.js';

// ── Student Profile ──────────────────────────────────────────────────────────

export async function findStudentById(studentId, schoolId) {
    return prisma.student.findFirst({
        where: { id: studentId, schoolId, deletedAt: null },
        select: {
            id:             true,
            firstName:      true,
            lastName:       true,
            admissionNo:    true,
            photoUrl:       true,
            dateOfBirth:    true,
            gender:         true,
            bloodGroup:     true,
            address:        true,
            status:         true,
            admissionDate:  true,
            rollNo:         true,
            parentName:     true,
            parentPhone:    true,
            parentEmail:    true,
            parentRelation: true,
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

// ── Attendance ───────────────────────────────────────────────────────────────

export async function findAttendanceByMonth(studentId, schoolId, monthStart, monthEnd) {
    return prisma.attendance.findMany({
        where: {
            studentId,
            schoolId,
            date: { gte: monthStart, lte: monthEnd },
        },
        select: {
            date:    true,
            status:  true,
            remarks: true,
        },
        orderBy: { date: 'asc' },
    });
}

export async function findAttendanceForYear(studentId, schoolId, yearStart, yearEnd) {
    return prisma.attendance.findMany({
        where: {
            studentId,
            schoolId,
            date: { gte: yearStart, lte: yearEnd },
        },
        select: {
            date:   true,
            status: true,
        },
        orderBy: { date: 'asc' },
    });
}

// ── Fees ─────────────────────────────────────────────────────────────────────

export async function findFeePayments(studentId, schoolId, { page = 1, limit = 20 }) {
    const skip = (page - 1) * limit;
    const where = { studentId, schoolId };

    const [data, total] = await Promise.all([
        prisma.feePayment.findMany({
            where,
            skip,
            take: limit,
            orderBy: { paymentDate: 'desc' },
            select: {
                id:          true,
                receiptNo:   true,
                amount:      true,
                paymentDate: true,
                paymentMode: true,
                feeHead:     true,
                remarks:     true,
            },
        }),
        prisma.feePayment.count({ where }),
    ]);

    return { data, total };
}

export async function aggregateFeePayments(studentId, schoolId) {
    const result = await prisma.feePayment.aggregate({
        where: { studentId, schoolId },
        _sum:   { amount: true },
        _count: { id: true },
    });
    return {
        totalPaid:     Number(result._sum.amount ?? 0),
        paymentsCount: result._count.id,
    };
}

export async function aggregateFeeStructuresForClass(classId, schoolId) {
    if (!classId) return 0;
    const result = await prisma.feeStructure.aggregate({
        where: { schoolId, classId, isActive: true },
        _sum: { amount: true },
    });
    return Number(result._sum.amount ?? 0);
}

// ── Student Notices ──────────────────────────────────────────────────────────

export async function findStudentNotices(studentId, schoolId, { page = 1, limit = 20 }) {
    const skip = (page - 1) * limit;
    const where = { studentId, schoolId };

    const [data, total] = await Promise.all([
        prisma.studentNotice.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
            select: {
                id:            true,
                subject:       true,
                message:       true,
                priority:      true,
                targetStudent: true,
                targetParent:  true,
                createdAt:     true,
                sentBy: {
                    select: {
                        id:        true,
                        firstName: true,
                        lastName:  true,
                    },
                },
            },
        }),
        prisma.studentNotice.count({ where }),
    ]);

    return { data, total };
}

export async function countStudentNotices(studentId, schoolId) {
    return prisma.studentNotice.count({ where: { studentId, schoolId } });
}

export async function createStudentNotice(data) {
    return prisma.studentNotice.create({
        data,
        select: {
            id:        true,
            subject:   true,
            createdAt: true,
        },
    });
}
