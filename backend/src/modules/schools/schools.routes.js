import { Router } from 'express';
import * as schoolController from './schools.controller.js';
import * as schoolValidation from './schools.validation.js';
import { verifyAccessToken, restrictTo } from '../../middleware/auth.middleware.js';

const router = Router();

// Middleware to ensure all School platform APIs are accessed by PLATFORM admins
const isPlatformAdmin = restrictTo('PLATFORM', 'SUPER_ADMIN');

// Apply auth & role checks
router.use(verifyAccessToken, isPlatformAdmin);

router.post('/',
    schoolValidation.validate(schoolValidation.createSchoolSchema),
    schoolController.createSchool
);

router.get('/',
    schoolValidation.validate(schoolValidation.getSchoolsQuerySchema),
    schoolController.getSchools
);

router.get('/:id',
    schoolValidation.validate(schoolValidation.schoolIdParamSchema),
    schoolController.getSchoolById
);

router.put('/:id',
    schoolValidation.validate(schoolValidation.updateSchoolSchema),
    schoolController.updateSchool
);

router.delete('/:id',
    schoolValidation.validate(schoolValidation.schoolIdParamSchema),
    schoolController.deleteSchool
);

router.post('/:id/assign-plan',
    schoolValidation.validate(schoolValidation.assignPlanSchema),
    schoolController.assignPlan
);

export default router;
