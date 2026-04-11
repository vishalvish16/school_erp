/**
 * Student Profile Update Requests Controller — HTTP handlers.
 * Parent-side endpoints use req.parent (from requireParent middleware).
 * School-side endpoints use req.user.school_id (from requireSchoolAdmin middleware).
 */
import { successResponse } from '../../utils/response.js';
import * as service from './student-profile-requests.service.js';

const handle = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res)).catch(next);
};

// ── Parent Endpoints ─────────────────────────────────────────────────────────

/**
 * POST /api/parent/student-profile-requests
 * Parent submits a profile update request for their linked student.
 */
export const submitRequest = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { studentId, requestedChanges } = req.body;

    const data = await service.submitRequest({
        parentId,
        schoolId,
        studentId,
        requestedChanges,
    });

    return successResponse(res, 201, 'Profile update request submitted successfully', data);
});

/**
 * GET /api/parent/student-profile-requests
 * Parent views their submitted requests.
 */
export const getParentRequests = handle(async (req, res) => {
    const { id: parentId, schoolId } = req.parent;
    const { page = 1, limit = 10, studentId } = req.query;

    const data = await service.getParentRequests({
        parentId,
        schoolId,
        studentId: studentId || null,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
    });

    return successResponse(res, 200, 'OK', data);
});

// ── School Admin / Staff Endpoints ───────────────────────────────────────────

/**
 * GET /api/school/student-profile-requests
 * Admin/Staff lists all profile update requests for the school.
 */
export const getSchoolRequests = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const { page = 1, limit = 20, status } = req.query;

    const data = await service.getSchoolRequests({
        schoolId,
        status: status || null,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
    });

    return successResponse(res, 200, 'OK', data);
});

/**
 * GET /api/school/student-profile-requests/pending-count
 * Returns the count of pending requests (for badge display).
 */
export const getPendingCount = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getPendingCount(schoolId);
    return successResponse(res, 200, 'OK', data);
});

/**
 * GET /api/school/student-profile-requests/:id
 * Get a single request by id.
 */
export const getRequestById = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const data = await service.getRequestById({
        id: req.params.id,
        schoolId,
    });
    return successResponse(res, 200, 'OK', data);
});

/**
 * POST /api/school/student-profile-requests/:id/approve
 * Approve a profile update request and apply changes to student record.
 */
export const approveRequest = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId = req.user.userId || req.user.id;
    const { note } = req.body;

    const data = await service.approveRequest({
        id: req.params.id,
        schoolId,
        userId,
        note,
    });

    return successResponse(res, 200, 'Profile update approved and applied', data);
});

/**
 * POST /api/school/student-profile-requests/:id/reject
 * Reject a profile update request.
 */
export const rejectRequest = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const userId = req.user.userId || req.user.id;
    const { note } = req.body;

    const data = await service.rejectRequest({
        id: req.params.id,
        schoolId,
        userId,
        note,
    });

    return successResponse(res, 200, 'Profile update rejected', data);
});

/**
 * POST /api/school/students/:id/profile-photo
 * Upload/update a student's profile photo (school admin action).
 */
export const uploadProfilePhoto = handle(async (req, res) => {
    const schoolId = req.user.school_id;
    const studentId = req.params.id;

    if (!req.file) {
        return successResponse(res, 400, 'No photo file provided');
    }

    // Build the photo URL from the saved file path
    const photoUrl = `/uploads/student-photos/${req.file.filename}`;

    const data = await service.updateStudentPhoto({
        studentId,
        schoolId,
        photoUrl,
    });

    return successResponse(res, 200, 'Profile photo updated', data);
});
