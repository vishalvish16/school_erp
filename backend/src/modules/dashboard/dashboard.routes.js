import { Router } from 'express';
import { getDashboardDataController } from './dashboard.controller.js';
import { verifyAccessToken, restrictTo } from '../../middleware/auth.middleware.js';

const router = Router();

// Endpoint strictly protected by global token authentication and scoped to Platform level roles
router.get(
    '/',
    verifyAccessToken,
    restrictTo('PLATFORM'),
    getDashboardDataController
);

export default router;
