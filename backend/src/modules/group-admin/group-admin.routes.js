import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireGroupAdmin } from '../../middleware/group-admin-guard.middleware.js';
import * as ctrl from './group-admin.controller.js';

const router = express.Router();
router.use(verifyAccessToken, requireGroupAdmin);

router.get('/dashboard/stats', ctrl.getDashboardStats);
router.get('/schools', ctrl.getSchools);
router.get('/schools/:id', ctrl.getSchoolDetail);
router.get('/reports/attendance', ctrl.getAttendanceReport);
router.get('/reports/fees', ctrl.getFeesReport);
router.get('/reports/performance', ctrl.getPerformanceReport);
router.get('/reports/comparison', ctrl.getSchoolComparison);
router.get('/profile', ctrl.getProfile);
router.post('/profile/send-otp', ctrl.sendProfileOtp);
router.put('/profile', ctrl.updateProfile);
router.put('/change-password', ctrl.changePassword);
router.get('/notifications/unread-count', ctrl.getUnreadNotificationCount);
router.get('/notifications', ctrl.getNotifications);
router.put('/notifications/:id/read', ctrl.markNotificationRead);

// Students
router.get('/students/stats', ctrl.getStudentStats);

// Notices
router.get('/notices', ctrl.getNotices);
router.post('/notices', ctrl.createNotice);
router.put('/notices/:id', ctrl.updateNotice);
router.delete('/notices/:id', ctrl.deleteNotice);

// Alert Rules
router.get('/alerts', ctrl.getAlertRules);
router.post('/alerts', ctrl.createAlertRule);
router.put('/alerts/:id', ctrl.updateAlertRule);
router.delete('/alerts/:id', ctrl.deleteAlertRule);

export default router;
