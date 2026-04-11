/**
 * Student Profile Update Requests Repository — Prisma queries.
 * All queries are scoped by schoolId for tenant isolation.
 */

import prisma from '../../config/prisma.js';

// Mapping from camelCase requestedChanges keys to Student model fields
const CHANGE_KEY_TO_STUDENT_FIELD = {
    firstName: 'firstName',
    lastName: 'lastName',
    dateOfBirth: 'dateOfBirth',
    bloodGroup: 'bloodGroup',
    address: 'address',
    parentName: 'parentName',
    parentPhone: 'parentPhone',
    parentEmail: 'parentEmail',
    photoUrl: 'photoUrl',
};

/**
 * Check if a parent is linked to a student via student_parents table.
 */
export async function isParentLinkedToStudent(parentId, studentId) {
    const link = await prisma.studentParent.findUnique({
        where: {
            studentId_parentId: { studentId, parentId },
        },
    });
    return !!link;
}

/**
 * Get student by id and schoolId (for building currentValues snapshot).
 */
export async function findStudentById(studentId, schoolId) {
    return prisma.student.findFirst({
        where: { id: studentId, schoolId, deletedAt: null },
        select: {
            id: true,
            firstName: true,
            lastName: true,
            admissionNo: true,
            dateOfBirth: true,
            bloodGroup: true,
            address: true,
            parentName: true,
            parentPhone: true,
            parentEmail: true,
            photoUrl: true,
        },
    });
}

/**
 * Create a new profile update request.
 */
export async function createRequest({ schoolId, studentId, parentId, requestedChanges, currentValues }) {
    return prisma.studentProfileUpdateRequest.create({
        data: {
            schoolId,
            studentId,
            requestedByParentId: parentId,
            status: 'PENDING',
            requestedChanges,
            currentValues,
        },
        select: {
            id: true,
            status: true,
            createdAt: true,
        },
    });
}

/**
 * Find all requests by parent (optionally filtered by studentId).
 */
export async function findByParent({ parentId, schoolId, studentId, page = 1, limit = 10 }) {
    const skip = (page - 1) * limit;

    const where = {
        requestedByParentId: parentId,
        schoolId,
        ...(studentId && { studentId }),
    };

    const [data, total] = await Promise.all([
        prisma.studentProfileUpdateRequest.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
            include: {
                student: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        admissionNo: true,
                        photoUrl: true,
                    },
                },
            },
        }),
        prisma.studentProfileUpdateRequest.count({ where }),
    ]);

    return {
        requests: data.map((r) => ({
            id: r.id,
            studentId: r.studentId,
            student: r.student,
            status: r.status,
            requestedChanges: r.requestedChanges,
            currentValues: r.currentValues,
            reviewNote: r.reviewNote,
            createdAt: r.createdAt,
            reviewedAt: r.reviewedAt,
        })),
        total,
        page,
        total_pages: Math.ceil(total / limit),
    };
}

/**
 * Find all requests for a school (admin view), optionally filtered by status.
 */
export async function findBySchool({ schoolId, status, page = 1, limit = 20 }) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        ...(status && { status }),
    };

    const [data, total] = await Promise.all([
        prisma.studentProfileUpdateRequest.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
            include: {
                student: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        admissionNo: true,
                        photoUrl: true,
                    },
                },
                requestedByParent: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        phone: true,
                    },
                },
            },
        }),
        prisma.studentProfileUpdateRequest.count({ where }),
    ]);

    return {
        requests: data.map((r) => ({
            id: r.id,
            studentId: r.studentId,
            student: r.student,
            requestedByParent: r.requestedByParent,
            status: r.status,
            requestedChanges: r.requestedChanges,
            currentValues: r.currentValues,
            reviewNote: r.reviewNote,
            createdAt: r.createdAt,
            reviewedAt: r.reviewedAt,
        })),
        total,
        page,
        total_pages: Math.ceil(total / limit),
    };
}

/**
 * Count pending requests for a school.
 */
export async function countPending(schoolId) {
    return prisma.studentProfileUpdateRequest.count({
        where: { schoolId, status: 'PENDING' },
    });
}

/**
 * Find a single request by id and schoolId.
 */
export async function findById(id, schoolId) {
    const r = await prisma.studentProfileUpdateRequest.findFirst({
        where: { id, schoolId },
        include: {
            student: {
                select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    admissionNo: true,
                    photoUrl: true,
                    dateOfBirth: true,
                    bloodGroup: true,
                    address: true,
                    parentName: true,
                    parentPhone: true,
                    parentEmail: true,
                },
            },
            requestedByParent: {
                select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    phone: true,
                    relation: true,
                },
            },
            reviewedByUser: {
                select: {
                    id: true,
                    email: true,
                },
            },
        },
    });

    return r;
}

/**
 * Approve a request: update status + apply changes to the student record in a transaction.
 */
export async function approveRequest({ id, schoolId, reviewedByUserId, note }) {
    return prisma.$transaction(async (tx) => {
        // 1. Fetch the request
        const request = await tx.studentProfileUpdateRequest.findFirst({
            where: { id, schoolId, status: 'PENDING' },
        });

        if (!request) {
            return null; // service layer will throw
        }

        // 2. Build student update payload from requestedChanges
        const studentUpdate = {};
        const changes = request.requestedChanges || {};

        for (const [key, value] of Object.entries(changes)) {
            const studentField = CHANGE_KEY_TO_STUDENT_FIELD[key];
            if (studentField) {
                // Handle dateOfBirth conversion
                if (key === 'dateOfBirth' && value) {
                    studentUpdate[studentField] = new Date(value);
                } else {
                    studentUpdate[studentField] = value;
                }
            }
        }

        // 3. Apply changes to student record
        if (Object.keys(studentUpdate).length > 0) {
            studentUpdate.updatedAt = new Date();
            await tx.student.update({
                where: { id: request.studentId },
                data: studentUpdate,
            });
        }

        // 4. Update request status
        await tx.studentProfileUpdateRequest.update({
            where: { id },
            data: {
                status: 'APPROVED',
                reviewNote: note || null,
                reviewedByUserId,
                reviewedAt: new Date(),
            },
        });

        return true;
    });
}

/**
 * Reject a request: set status to REJECTED without modifying student record.
 */
export async function rejectRequest({ id, schoolId, reviewedByUserId, note }) {
    const request = await prisma.studentProfileUpdateRequest.findFirst({
        where: { id, schoolId, status: 'PENDING' },
    });

    if (!request) {
        return null;
    }

    await prisma.studentProfileUpdateRequest.update({
        where: { id },
        data: {
            status: 'REJECTED',
            reviewNote: note,
            reviewedByUserId,
            reviewedAt: new Date(),
        },
    });

    return true;
}

/**
 * Update student profile photo URL.
 */
export async function updateStudentPhoto(studentId, schoolId, photoUrl) {
    return prisma.student.update({
        where: {
            id: studentId,
            // Prisma unique constraint: use compound if available, otherwise findFirst + update
        },
        data: {
            photoUrl,
            updatedAt: new Date(),
        },
    });
}

/**
 * Check if student belongs to school (for photo upload).
 */
export async function studentBelongsToSchool(studentId, schoolId) {
    const student = await prisma.student.findFirst({
        where: { id: studentId, schoolId, deletedAt: null },
        select: { id: true },
    });
    return !!student;
}
