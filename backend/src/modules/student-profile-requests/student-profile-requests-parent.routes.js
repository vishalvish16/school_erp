/**
 * Parent-side routes for Student Profile Update Requests.
 * Mounted at: /api/parent/student-profile-requests
 * All routes require: verifyAccessToken + requireParent
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireParent } from '../../middleware/parent-guard.middleware.js';
import * as ctrl from './student-profile-requests.controller.js';
import { validate, submitRequestSchema } from './student-profile-requests.validation.js';

const router = express.Router();

router.use(verifyAccessToken, requireParent);

// POST /  — Submit a profile update request
router.post('/', validate(submitRequestSchema), ctrl.submitRequest);

// GET /   — List parent's submitted requests
router.get('/', ctrl.getParentRequests);

export default router;
