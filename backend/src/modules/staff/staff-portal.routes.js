/**
 * Staff Portal Routes — /api/staff/*
 * All routes require: verifyAccessToken + requireStaff
 * requireStaff performs a live DB lookup and attaches req.staff.
 * All tenant scoping uses req.staff.schoolId — never req.user.school_id.
 *
 * Specific (non-parameterised) paths are always placed before /:id paths
 * to prevent route conflicts.
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireStaff } from '../../middleware/staff-guard.middleware.js';
import * as ctrl from './staff-portal.controller.js';
import {
    validate,
    createFeePaymentSchema,
    updateUserProfileSchema,
    sendOtpSchema,
    changePasswordSchema,
    applyLeaveSchema,
} from './staff-portal.validation.js';

const router = express.Router();

// All routes require authentication + staff portal type + active staff record
router.use(verifyAccessToken, requireStaff);

// ── Dashboard ──────────────────────────────────────────────────────────────────
router.get('/dashboard/stats', ctrl.getDashboardStats);

// ── Fee Payments ───────────────────────────────────────────────────────────────
// Specific sub-paths before /:id to avoid route conflicts
router.get('/fees/summary',          ctrl.getFeeSummary);
router.get('/fees/structures',       ctrl.getFeeStructures);
router.get('/fees/payments',         ctrl.getFeePayments);
router.post('/fees/payments',        validate(createFeePaymentSchema), ctrl.createFeePayment);
router.get('/fees/payments/:id',     ctrl.getFeePaymentById);

// ── Students (read-only) ───────────────────────────────────────────────────────
router.get('/classes',               ctrl.getClasses);
router.get('/students',              ctrl.getStudents);
router.get('/students/:id',          ctrl.getStudentById);

// ── Notices (read-only) ────────────────────────────────────────────────────────
router.get('/notices',               ctrl.getNotices);
router.get('/notices/:id',           ctrl.getNoticeById);

// ── Notifications ──────────────────────────────────────────────────────────────
// Specific sub-paths before /:id
router.get('/notifications/unread-count',   ctrl.getUnreadNotificationCount);
router.put('/notifications/read-all',       ctrl.markAllNotificationsRead);
router.get('/notifications',                ctrl.getNotifications);
router.put('/notifications/:id/read',       ctrl.markNotificationRead);

// ── Profile ────────────────────────────────────────────────────────────────────
router.get('/profile',                      ctrl.getProfile);
router.put('/profile/user',                 validate(updateUserProfileSchema), ctrl.updateUserProfile);
router.post('/profile/send-otp',            validate(sendOtpSchema), ctrl.sendOtp);

// ── Auth ───────────────────────────────────────────────────────────────────────
router.post('/auth/change-password',        validate(changePasswordSchema), ctrl.changePassword);

// ── Non-Teaching Staff Self-Service (my/) ─────────────────────────────────────
// These routes work for both teaching and non-teaching staff.
// req.isNonTeaching flag (set by requireStaff guard) determines which DB model is queried.
router.get('/my/profile',                   ctrl.getMyProfile);
router.get('/my/attendance',                ctrl.getMyAttendance);
router.get('/my/leaves',                    ctrl.getMyLeaves);
router.post('/my/leaves',                   validate(applyLeaveSchema), ctrl.applyMyLeave);
router.put('/my/leaves/:leaveId/cancel',    ctrl.cancelMyLeave);
router.get('/my/leave-summary',             ctrl.getMyLeaveSummary);
router.get('/my/payslip',                   ctrl.getPayslipPlaceholder);

export default router;
