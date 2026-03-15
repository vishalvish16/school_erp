import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireDriver } from '../../middleware/driver-guard.middleware.js';
import * as ctrl from './driver.controller.js';
import { validate, updateProfileSchema, changePasswordSchema } from './driver.validation.js';

const router = express.Router();
router.use(verifyAccessToken, requireDriver);

router.get('/dashboard/stats', ctrl.getDashboardStats);
router.get('/profile', ctrl.getProfile);
router.put('/profile', validate(updateProfileSchema), ctrl.updateProfile);
router.post('/auth/change-password', validate(changePasswordSchema), ctrl.changePassword);

export default router;
