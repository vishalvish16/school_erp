import { Router } from 'express';
import * as schoolController from './school.controller.js';
import * as schoolValidation from './school.validation.js';
import { verifyAccessToken, restrictTo } from '../../middleware/auth.middleware.js';
import { verifySubscription } from '../../middleware/subscriptionGuard.middleware.js';

const router = Router();

/**
 * Routes for school-level operations. 
 * Accessible by PLATFORM admins (super admins) and SCHOOL admins.
 */

// Global middleware for all routes in this module
router.use(verifyAccessToken, verifySubscription);

router.post('/students',
    restrictTo('SCHOOL', 'PLATFORM', 'SUPER_ADMIN'),
    schoolValidation.validate(schoolValidation.createStudentSchema),
    schoolController.createStudent
);

router.post('/teachers',
    restrictTo('SCHOOL', 'PLATFORM', 'SUPER_ADMIN'),
    schoolValidation.validate(schoolValidation.createTeacherSchema),
    schoolController.createTeacher
);

router.post('/branches',
    restrictTo('SCHOOL', 'PLATFORM', 'SUPER_ADMIN'),
    schoolValidation.validate(schoolValidation.createBranchSchema),
    schoolController.createBranch
);

export default router;
