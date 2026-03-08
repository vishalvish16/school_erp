/**
 * Super Admin Routes — /api/platform/super-admin/*
 * All routes require: verifyAccessToken + requireSuperAdmin
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireSuperAdmin } from '../../middleware/super-admin-guard.middleware.js';
import * as ctrl from './super-admin.controller.js';

const router = express.Router();

router.use(verifyAccessToken, requireSuperAdmin);

// Dashboard
router.get('/dashboard/stats', ctrl.getDashboardStats);

// Schools
router.get('/schools', ctrl.getSchools);
router.get('/schools/:id', ctrl.getSchoolById);
router.post('/schools', ctrl.createSchool);
router.put('/schools/:id', ctrl.updateSchool);
router.put('/schools/:id/status', ctrl.updateSchoolStatus);
router.put('/schools/:id/subdomain', ctrl.updateSchoolSubdomain);

// Groups
router.get('/groups', ctrl.getGroups);
router.post('/groups', ctrl.createGroup);

// Plans
router.get('/plans', ctrl.getPlans);
router.post('/plans', ctrl.createPlan);
router.put('/plans/:id', ctrl.updatePlan);
router.put('/plans/:id/status', ctrl.updatePlanStatus);

// Billing
router.get('/billing/subscriptions', ctrl.getSubscriptions);
router.post('/billing/subscriptions/:school_id/renew', ctrl.renewSubscription);
router.post('/billing/subscriptions/:school_id/assign-plan', ctrl.assignPlan);
router.post('/billing/resolve-overdue/:school_id', ctrl.resolveOverdue);

// Features
router.get('/features/platform', ctrl.getPlatformFeatures);
router.put('/features/platform/:feature_key', ctrl.togglePlatformFeature);
router.get('/features/school/:school_id', ctrl.getSchoolFeatures);

// Hardware
router.get('/hardware', ctrl.getHardware);

// Admins
router.get('/admins', ctrl.getSuperAdmins);

// Audit
router.get('/audit/:type', ctrl.getAuditLogs);

// Security
router.get('/security/events', ctrl.getSecurityEvents);
router.get('/security/trusted-devices', ctrl.getTrustedDevices);
router.get('/security/2fa/status', ctrl.get2faStatus);
router.post('/security/2fa/setup', ctrl.setup2fa);
router.post('/security/2fa/enable', ctrl.enable2fa);
router.post('/security/2fa/disable', ctrl.disable2fa);

// Infra
router.get('/infra/status', ctrl.getInfraStatus);

export default router;
