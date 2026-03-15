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
router.get('/dashboard/export', ctrl.exportDashboard);

// Schools
router.get('/schools/export', ctrl.exportSchoolsCsv);
router.get('/schools', ctrl.getSchools);
router.get('/schools/check-subdomain', ctrl.checkSubdomainAvailability);
router.get('/schools/:id', ctrl.getSchoolById);
router.post('/schools', ctrl.createSchool);
router.post('/schools/:id/admin/assign', ctrl.assignSchoolAdmin);
router.put('/schools/:id/admin/reset-password', ctrl.resetSchoolAdminPassword);
router.put('/schools/:id/admin/:user_id/deactivate', ctrl.deactivateSchoolAdmin);
router.put('/schools/:id', ctrl.updateSchool);
router.put('/schools/:id/status', ctrl.updateSchoolStatus);
router.put('/schools/:id/subdomain', ctrl.updateSchoolSubdomain);

// Groups
router.get('/groups', ctrl.getGroups);
router.get('/groups/check-slug', ctrl.checkGroupSlugAvailability);
router.post('/groups', ctrl.createGroup);
router.get('/groups/:id', ctrl.getGroupById);
router.put('/groups/:id', ctrl.updateGroup);
router.delete('/groups/:id', ctrl.deleteGroupHandler);
router.post('/groups/:id/admin/assign', ctrl.assignGroupAdminHandler);
router.put('/groups/:id/admin/reset-password', ctrl.resetGroupAdminPasswordHandler);
router.put('/groups/:id/admin/lock', ctrl.lockGroupAdminHandler);
router.put('/groups/:id/admin/unlock', ctrl.unlockGroupAdminHandler);
router.put('/groups/:id/admin/deactivate', ctrl.deactivateGroupAdminHandler);
router.post('/groups/:id/add-school', ctrl.addSchoolToGroup);
router.delete('/groups/:id/remove-school/:school_id', ctrl.removeSchoolFromGroup);

// Plans
router.get('/plans', ctrl.getPlans);
router.post('/plans', ctrl.createPlan);
router.put('/plans/:id', ctrl.updatePlan);
router.put('/plans/:id/status', ctrl.updatePlanStatus);

// Billing
router.get('/billing/export', ctrl.exportBillingCsv);
router.get('/billing/subscriptions', ctrl.getSubscriptions);
router.post('/billing/subscriptions/:school_id/renew', ctrl.renewSubscription);
router.post('/billing/subscriptions/:school_id/assign-plan', ctrl.assignPlan);
router.post('/billing/resolve-overdue/:school_id', ctrl.resolveOverdue);

// Features
router.get('/features/platform', ctrl.getPlatformFeatures);
router.put('/features/platform/:feature_key', ctrl.togglePlatformFeature);
router.get('/features/school/:school_id', ctrl.getSchoolFeatures);
router.put('/features/school/:school_id/:feature_key', ctrl.toggleSchoolFeature);

// Hardware
router.get('/hardware', ctrl.getHardware);
router.post('/hardware', ctrl.registerHardware);
router.put('/hardware/:id', ctrl.updateHardware);
router.put('/hardware/:id/ping', ctrl.pingDevice);
router.post('/hardware/:id/alert-school', ctrl.alertSchool);
router.delete('/hardware/:id', ctrl.deleteDevice);

// Profile (change own password)
router.put('/change-password', ctrl.changePassword);

// Admins (reset-password before :id so it matches correctly)
router.get('/admins', ctrl.getSuperAdmins);
router.post('/admins', ctrl.addSuperAdmin);
router.put('/admins/:id/reset-password', ctrl.resetSuperAdminPassword);
router.put('/admins/:id', ctrl.updateSuperAdmin);
router.delete('/admins/:id', ctrl.removeSuperAdmin);

// Audit
router.get('/audit/:type', ctrl.getAuditLogs);

// Security
router.get('/security/events', ctrl.getSecurityEvents);
router.get('/security/trusted-devices', ctrl.getTrustedDevices);
router.delete('/security/trusted-devices/:id', ctrl.revokeDevice);
router.post('/security/block-ip', ctrl.blockIpHandler);
router.get('/security/2fa/status', ctrl.get2faStatus);
router.post('/security/2fa/setup', ctrl.setup2fa);
router.post('/security/2fa/enable', ctrl.enable2fa);
router.post('/security/2fa/disable', ctrl.disable2fa);

// Infra
router.get('/infra/status', ctrl.getInfraStatus);

// Notifications (order: specific paths before :id)
router.get('/notifications/unread-count', ctrl.getUnreadNotificationCount);
router.get('/notifications', ctrl.getNotifications);
router.put('/notifications/mark-all-read', ctrl.markAllNotificationsRead);
router.put('/notifications/:id/read', ctrl.markNotificationRead);

export default router;
