import { Router } from 'express';
import * as subscriptionController from './subscription.controller.js';
import * as subscriptionValidation from './subscription.validation.js';
import { verifyAccessToken, restrictTo } from '../../middleware/auth.middleware.js';

const router = Router();

// Only platform and super admin can manage subscriptions
const isPlatformAdmin = restrictTo('PLATFORM', 'SUPER_ADMIN');

router.use(verifyAccessToken, isPlatformAdmin);

router.post('/',
    subscriptionValidation.validate(subscriptionValidation.createSubscriptionSchema),
    subscriptionController.createSubscription
);

router.put('/:id/upgrade',
    subscriptionValidation.validate(subscriptionValidation.upgradeSubscriptionSchema),
    subscriptionController.upgradeSubscription
);

router.get('/school/:school_id',
    subscriptionValidation.validate(subscriptionValidation.getSchoolSubscriptionSchema),
    subscriptionController.getSchoolSubscription
);

router.patch('/:id/toggle-status',
    subscriptionValidation.validate(subscriptionValidation.idParamSchema),
    subscriptionController.toggleSubscriptionStatus
);

router.patch('/:id/extend',
    subscriptionValidation.validate(subscriptionValidation.extendSubscriptionSchema),
    subscriptionController.extendSubscription
);



export default router;
