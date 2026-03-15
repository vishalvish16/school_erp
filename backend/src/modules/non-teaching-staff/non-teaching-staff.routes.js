/**
 * Non-Teaching Staff Routes — /api/school/non-teaching/*
 * All routes require: verifyAccessToken + requireSchoolAdmin
 * Static paths are always placed before parameterized /:id paths to prevent route conflicts.
 */
import express from 'express';
import rateLimit from 'express-rate-limit';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireSchoolAdmin } from '../../middleware/school-admin-guard.middleware.js';
import * as ctrl from './non-teaching-staff.controller.js';
import {
    validate,
    createRoleSchema,
    updateRoleSchema,
    createStaffSchema,
    updateStaffSchema,
    updateStaffStatusSchema,
    createStaffLoginSchema,
    resetPasswordSchema,
    addQualificationSchema,
    updateQualificationSchema,
    addDocumentSchema,
    bulkAttendanceSchema,
    correctAttendanceSchema,
    reviewLeaveSchema,
    applyLeaveSchema,
} from './non-teaching-staff.validation.js';

// Rate limiters for sensitive write operations
const passwordOpLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10,                   // max 10 password operations per 15 min per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: 'Too many password operations. Please try again later.' },
});

const bulkAttendanceLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 60,                   // max 60 bulk submissions per 15 min per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: 'Too many bulk attendance requests. Please try again later.' },
});

const router = express.Router();

// All routes require authentication + school admin portal type
router.use(verifyAccessToken, requireSchoolAdmin);

// ── Roles ──────────────────────────────────────────────────────────────────
router.get('/roles',                    ctrl.getRoles);
router.post('/roles',                   validate(createRoleSchema), ctrl.createRole);
router.put('/roles/:roleId',            validate(updateRoleSchema), ctrl.updateRole);
router.patch('/roles/:roleId/toggle',   ctrl.toggleRole);
router.delete('/roles/:roleId',         ctrl.deleteRole);

// ── Staff static paths (BEFORE /:id parameterized routes) ──────────────────
router.get('/staff/suggest-employee-no', ctrl.suggestEmployeeNo);
router.get('/staff/export',              ctrl.exportStaff);

// School-wide leave routes — BEFORE /:id routes to avoid conflict
router.get('/leaves',                   ctrl.getLeaves);
router.get('/leaves/summary',           ctrl.getLeaveSummary);
router.put('/leaves/:leaveId/review',   validate(reviewLeaveSchema), ctrl.reviewLeave);
router.put('/leaves/:leaveId/cancel',   ctrl.cancelLeave);

// Attendance static routes — BEFORE /:id routes
router.get('/attendance',               ctrl.getAttendanceForDate);
router.post('/attendance/bulk',         bulkAttendanceLimiter, validate(bulkAttendanceSchema), ctrl.bulkMarkAttendance);
router.get('/attendance/report',        ctrl.getAttendanceReport);

// ── Staff CRUD ─────────────────────────────────────────────────────────────
router.get('/staff',                    ctrl.getStaff);
router.post('/staff',                   validate(createStaffSchema), ctrl.createStaff);

// Parameterized /:id routes
router.get('/staff/:id',                ctrl.getStaffById);
router.put('/staff/:id',                validate(updateStaffSchema), ctrl.updateStaff);
router.delete('/staff/:id',             ctrl.deleteStaff);
router.patch('/staff/:id/status',       validate(updateStaffStatusSchema), ctrl.updateStaffStatus);
router.post('/staff/:id/create-login',  passwordOpLimiter, validate(createStaffLoginSchema), ctrl.createStaffLogin);
router.post('/staff/:id/reset-password', passwordOpLimiter, validate(resetPasswordSchema), ctrl.resetStaffPassword);

// ── Qualifications ─────────────────────────────────────────────────────────
router.get('/staff/:id/qualifications',               ctrl.getQualifications);
router.post('/staff/:id/qualifications',              validate(addQualificationSchema), ctrl.addQualification);
router.put('/staff/:id/qualifications/:qualId',       validate(updateQualificationSchema), ctrl.updateQualification);
router.delete('/staff/:id/qualifications/:qualId',    ctrl.deleteQualification);

// ── Documents ──────────────────────────────────────────────────────────────
router.get('/staff/:id/documents',                    ctrl.getDocuments);
router.post('/staff/:id/documents',                   validate(addDocumentSchema), ctrl.addDocument);
router.put('/staff/:id/documents/:docId/verify',      ctrl.verifyDocument);
router.delete('/staff/:id/documents/:docId',          ctrl.deleteDocument);

// ── Attendance correction (by attendance record id) ────────────────────────
router.put('/attendance/:id',                         validate(correctAttendanceSchema), ctrl.correctAttendance);

// ── Per-staff leaves ───────────────────────────────────────────────────────
router.get('/staff/:id/leaves',                       ctrl.getStaffLeaves);
router.post('/staff/:id/leaves',                      validate(applyLeaveSchema), ctrl.applyLeaveForStaff);

export default router;
