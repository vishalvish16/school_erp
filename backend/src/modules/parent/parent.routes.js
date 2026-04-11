/**
 * Parent Portal Routes — /api/parent/*
 * All routes require: verifyAccessToken + requireParent
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireParent } from '../../middleware/parent-guard.middleware.js';
import { validate } from '../auth/auth.validation.js';
import * as ctrl from './parent.controller.js';
import { updateParentProfileSchema, changePasswordSchema } from './parent.validation.js';

const router = express.Router();

router.use(verifyAccessToken, requireParent);

router.get('/dashboard', ctrl.getDashboard);
router.get('/profile', ctrl.getProfile);
router.patch('/profile', validate(updateParentProfileSchema), ctrl.updateProfile);
router.get('/children', ctrl.getChildren);
router.get('/children/:studentId', ctrl.getChildById);
router.get('/children/:studentId/bus', ctrl.getBusLocation);
router.get('/children/:studentId/attendance/summary', ctrl.getChildAttendanceSummary);
router.get('/children/:studentId/attendance', ctrl.getChildAttendance);
router.get('/children/:studentId/fees', ctrl.getChildFees);
router.get('/children/:studentId/timetable', ctrl.getChildTimetable);
router.get('/children/:studentId/documents', ctrl.getChildDocuments);
router.get('/notices', ctrl.getNotices);
router.get('/notices/:id', ctrl.getNoticeById);
router.get('/notifications/unread-count', ctrl.getUnreadNotificationCount);
router.get('/notifications', ctrl.getNotifications);
router.put('/notifications/:id/read', ctrl.markNotificationRead);
router.post('/fcm/register', ctrl.registerFcmToken);
router.post('/auth/change-password', validate(changePasswordSchema), ctrl.changePassword);

export default router;
