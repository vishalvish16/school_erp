/**
 * Student Profile Update Requests Service — business logic.
 * Validates parent-student links, builds current-value snapshots,
 * and delegates to the repository for persistence.
 * Notifies parent when request is approved or rejected.
 */
import { AppError } from '../../utils/response.js';
import * as repo from './student-profile-requests.repository.js';
import * as parentNotifications from '../parent/parent-notifications.service.js';

// Keys that parents are allowed to request changes for
const ALLOWED_CHANGE_KEYS = new Set([
    'firstName',
    'lastName',
    'dateOfBirth',
    'bloodGroup',
    'address',
    'parentName',
    'parentPhone',
    'parentEmail',
    'photoUrl',
]);

/**
 * Parent submits a profile update request.
 */
export async function submitRequest({ parentId, schoolId, studentId, requestedChanges }) {
    // 1. Validate parent-student link
    const linked = await repo.isParentLinkedToStudent(parentId, studentId);
    if (!linked) {
        throw new AppError('You are not linked to this student', 403);
    }

    // 2. Validate requestedChanges has at least one valid key
    const filteredChanges = {};
    for (const [key, value] of Object.entries(requestedChanges)) {
        if (ALLOWED_CHANGE_KEYS.has(key) && value !== undefined && value !== null) {
            filteredChanges[key] = value;
        }
    }

    if (Object.keys(filteredChanges).length === 0) {
        throw new AppError('At least one valid change field is required', 400);
    }

    // 3. Build currentValues snapshot from student record
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) {
        throw new AppError('Student not found', 404);
    }

    const currentValues = {};
    for (const key of Object.keys(filteredChanges)) {
        currentValues[key] = student[key] ?? null;
    }

    // 4. Create the request
    const result = await repo.createRequest({
        schoolId,
        studentId,
        parentId,
        requestedChanges: filteredChanges,
        currentValues,
    });

    return result;
}

/**
 * Parent views their submitted requests.
 */
export async function getParentRequests({ parentId, schoolId, studentId, page, limit }) {
    return repo.findByParent({ parentId, schoolId, studentId, page, limit });
}

/**
 * Admin/Staff lists all requests for the school.
 */
export async function getSchoolRequests({ schoolId, status, page, limit }) {
    return repo.findBySchool({ schoolId, status, page, limit });
}

/**
 * Get pending request count for badge.
 */
export async function getPendingCount(schoolId) {
    const count = await repo.countPending(schoolId);
    return { count };
}

/**
 * Get a single request by id (admin view).
 */
export async function getRequestById({ id, schoolId }) {
    const request = await repo.findById(id, schoolId);
    if (!request) {
        throw new AppError('Request not found', 404);
    }
    return request;
}

/**
 * Approve a request: apply changes to student record and notify parent.
 */
export async function approveRequest({ id, schoolId, userId, note }) {
    const request = await repo.findById(id, schoolId);
    if (!request) {
        throw new AppError('Request not found', 404);
    }
    if (request.status !== 'PENDING') {
        throw new AppError('Request not found or already reviewed', 404);
    }

    const result = await repo.approveRequest({
        id,
        schoolId,
        reviewedByUserId: userId,
        note,
    });

    if (!result) {
        throw new AppError('Request not found or already reviewed', 404);
    }

    const studentName = request.student
        ? `${request.student.firstName || ''} ${request.student.lastName || ''}`.trim() || 'your child'
        : 'your child';
    parentNotifications.notifyProfileRequestReviewed({
        parentId: request.requestedByParentId,
        schoolId,
        status: 'APPROVED',
        studentName,
        requestId: id,
        reviewNote: note || null,
    }).catch(() => {});

    return null;
}

/**
 * Reject a request and notify parent.
 */
export async function rejectRequest({ id, schoolId, userId, note }) {
    if (!note || note.trim().length === 0) {
        throw new AppError('Rejection note is required', 400);
    }

    const request = await repo.findById(id, schoolId);
    if (!request) {
        throw new AppError('Request not found', 404);
    }
    if (request.status !== 'PENDING') {
        throw new AppError('Request not found or already reviewed', 404);
    }

    const result = await repo.rejectRequest({
        id,
        schoolId,
        reviewedByUserId: userId,
        note: note.trim(),
    });

    if (!result) {
        throw new AppError('Request not found or already reviewed', 404);
    }

    const studentName = request.student
        ? `${request.student.firstName || ''} ${request.student.lastName || ''}`.trim() || 'your child'
        : 'your child';
    parentNotifications.notifyProfileRequestReviewed({
        parentId: request.requestedByParentId,
        schoolId,
        status: 'REJECTED',
        studentName,
        requestId: id,
        reviewNote: note.trim(),
    }).catch(() => {});

    return null;
}

/**
 * Upload / update a student's profile photo (school admin action).
 */
export async function updateStudentPhoto({ studentId, schoolId, photoUrl }) {
    const belongs = await repo.studentBelongsToSchool(studentId, schoolId);
    if (!belongs) {
        throw new AppError('Student not found in this school', 404);
    }

    await repo.updateStudentPhoto(studentId, schoolId, photoUrl);
    return { photoUrl };
}
