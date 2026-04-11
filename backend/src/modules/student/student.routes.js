/**
 * Student Portal Routes — /api/student/*
 * All routes require: verifyAccessToken + requireStudent
 * Specific paths MUST come before parameterized paths.
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireStudent } from '../../middleware/student-guard.middleware.js';
import * as ctrl from './student.controller.js';
import { validate, changePasswordSchema } from './student.validation.js';

const router = express.Router();

router.use(verifyAccessToken, requireStudent);

// ── Profile & Dashboard ──────────────────────────────────────────────────────
router.get('/profile',   ctrl.getProfile);
router.get('/dashboard', ctrl.getDashboard);

// ── Attendance (specific paths before :id) ─────────────────────────────────────
router.get('/attendance/summary', ctrl.getAttendanceSummary);
router.get('/attendance',          ctrl.getAttendance);

// ── Fees ──────────────────────────────────────────────────────────────────────
router.get('/fees/dues',            ctrl.getFeeDues);
router.get('/fees/payments',        ctrl.getFeePayments);
router.get('/fees/receipt/:receiptNo', ctrl.getReceiptByReceiptNo);

// ── Timetable ─────────────────────────────────────────────────────────────────
router.get('/timetable', ctrl.getTimetable);

// ── Notices ──────────────────────────────────────────────────────────────────
router.get('/notices',     ctrl.getNotices);
router.get('/notices/:id', ctrl.getNoticeById);

// ── FCM ──────────────────────────────────────────────────────────────────────
router.post('/fcm/register', ctrl.registerFcmToken);

// ── Transport (live driver tracking) ────────────────────────────────────────
router.get('/transport/live', ctrl.getLiveDrivers);

// ── Documents ─────────────────────────────────────────────────────────────────
router.get('/documents', ctrl.getDocuments);

// ── Auth ──────────────────────────────────────────────────────────────────────
router.post('/auth/change-password', validate(changePasswordSchema), ctrl.changePassword);

export default router;
