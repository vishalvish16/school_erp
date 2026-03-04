import { checkLimit } from '../../core/services/planLimit.service.js';
import { successResponse, AppError } from '../../utils/response.js';

/**
 * Controller for handling school-level entity creation with plan limit enforcement.
 */

export const createStudent = async (req, res, next) => {
    try {
        const { school_id } = req.user;
        if (!school_id) throw new AppError('School context missing in request', 400);

        // 1. Enforce Subscription Limit
        await checkLimit({
            schoolId: school_id,
            entityType: 'STUDENT'
        });

        // 2. Logic for student creation would go here (omitted for brevity as per instructions)
        // Usually: schoolService.createStudent(req.body, school_id)

        return successResponse(res, 201, 'Student created successfully. Plan limit verified.');
    } catch (error) {
        if (error.statusCode === 403) {
            return res.status(403).json({
                success: false,
                message: error.message,
                limit: error.limit,
                current: error.current
            });
        }
        next(error);
    }
};

export const createTeacher = async (req, res, next) => {
    try {
        const { school_id } = req.user;
        if (!school_id) throw new AppError('School context missing in request', 400);

        // 1. Enforce Subscription Limit
        await checkLimit({
            schoolId: school_id,
            entityType: 'TEACHER'
        });

        // 2. Logic for teacher creation would go here

        return successResponse(res, 201, 'Teacher created successfully. Plan limit verified.');
    } catch (error) {
        if (error.statusCode === 403) {
            return res.status(403).json({
                success: false,
                message: error.message,
                limit: error.limit,
                current: error.current
            });
        }
        next(error);
    }
};

export const createBranch = async (req, res, next) => {
    try {
        const { school_id } = req.user;
        if (!school_id) throw new AppError('School context missing in request', 400);

        // 1. Enforce Subscription Limit
        await checkLimit({
            schoolId: school_id,
            entityType: 'BRANCH'
        });

        // 2. Logic for branch creation would go here

        return successResponse(res, 201, 'Branch created successfully. Plan limit verified.');
    } catch (error) {
        if (error.statusCode === 403) {
            return res.status(403).json({
                success: false,
                message: error.message,
                limit: error.limit,
                current: error.current
            });
        }
        next(error);
    }
};
