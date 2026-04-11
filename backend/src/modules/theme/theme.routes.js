/**
 * Theme Routes
 *
 * Super Admin:  GET/PUT /api/platform/theme
 *               POST    /api/platform/theme/apply
 * School portal: GET   /api/school/theme
 * Parent portal: GET   /api/parent/theme
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireSuperAdmin } from '../../middleware/super-admin-guard.middleware.js';
import * as ctrl from './theme.controller.js';
import { validateBody, saveThemeSchema, applyThemeSchema } from './theme.validation.js';

// ── Super Admin theme routes ──────────────────────────────────────────────────
export const superAdminThemeRouter = express.Router();
superAdminThemeRouter.use(verifyAccessToken, requireSuperAdmin);
superAdminThemeRouter.get('/', ctrl.getSuperAdminTheme);
superAdminThemeRouter.put('/', validateBody(saveThemeSchema), ctrl.saveSuperAdminTheme);
superAdminThemeRouter.post('/apply', validateBody(applyThemeSchema), ctrl.applyThemeToPortals);

// ── School portal theme (school_admin / staff / teacher / student) ────────────
export const schoolThemeRouter = express.Router();
schoolThemeRouter.use(verifyAccessToken);
schoolThemeRouter.get('/', ctrl.getSchoolPortalTheme);

// ── Parent portal theme ───────────────────────────────────────────────────────
export const parentThemeRouter = express.Router();
parentThemeRouter.use(verifyAccessToken);
parentThemeRouter.get('/', ctrl.getParentTheme);

export default superAdminThemeRouter;
