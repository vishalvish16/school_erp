import { Router } from 'express';
import * as plansController from './plans.controller.js';
import * as plansValidation from './plans.validation.js';
import { verifyAccessToken, restrictTo } from '../../middleware/auth.middleware.js';

const router = Router();

// Allow PLATFORM and SUPER_ADMIN roles
const isPlatformAdmin = restrictTo('PLATFORM', 'SUPER_ADMIN');

router.get('/',
    verifyAccessToken,
    isPlatformAdmin,
    plansValidation.validate(plansValidation.getPlansQuerySchema),
    plansController.getPlans
);

router.post('/',
    verifyAccessToken,
    isPlatformAdmin,
    plansValidation.validate(plansValidation.createPlanSchema),
    plansController.createPlan
);

router.put('/:id',
    verifyAccessToken,
    isPlatformAdmin,
    plansValidation.validate(plansValidation.updatePlanSchema),
    plansController.updatePlan
);

router.delete('/:id',
    verifyAccessToken,
    isPlatformAdmin,
    plansValidation.validate(plansValidation.deletePlanSchema),
    plansController.deletePlan
);

router.patch('/:id/toggle-status',
    verifyAccessToken,
    isPlatformAdmin,
    plansValidation.validate(plansValidation.togglePlanStatusSchema),
    plansController.togglePlanStatus
);

export default router;
