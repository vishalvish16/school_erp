/**
 * School Admin Routes — /api/school/*
 * All routes require: verifyAccessToken + requireSchoolAdmin
 * Specific paths always placed before parameterized paths to avoid conflicts.
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireSchoolAdmin } from '../../middleware/school-admin-guard.middleware.js';
import * as ctrl from './school-admin.controller.js';
import {
    validate,
    createStudentSchema,
    updateStudentSchema,
    createStudentLoginSchema,
    resetStudentPasswordSchema,
    createStaffSchema,
    createStaffLoginSchema,
    resetStaffPasswordSchema,
    updateStaffSchema,
    updateStaffStatusSchema,
    addQualificationSchema,
    updateQualificationSchema,
    addDocumentSchema,
    addSubjectAssignmentSchema,
    applyLeaveSchema,
    reviewLeaveSchema,
    createClassSchema,
    updateClassSchema,
    createSectionSchema,
    updateSectionSchema,
    bulkAttendanceSchema,
    createFeeStructureSchema,
    updateFeeStructureSchema,
    createFeePaymentSchema,
    bulkTimetableSchema,
    createNoticeSchema,
    updateNoticeSchema,
    updateUserProfileSchema,
    updateSchoolProfileSchema,
    changePasswordSchema,
} from './school-admin.validation.js';

const router = express.Router();

// All routes require authentication + school_admin portal type
router.use(verifyAccessToken, requireSchoolAdmin);

// ── Dashboard ─────────────────────────────────────────────────────────────────
router.get('/dashboard/stats', ctrl.getDashboardStats);

// ── Academic Years ────────────────────────────────────────────────────────────
router.get('/academic-years', ctrl.getAcademicYears);

// ── Students ──────────────────────────────────────────────────────────────────
router.get('/students',     ctrl.getStudents);
router.post('/students',    validate(createStudentSchema), ctrl.createStudent);
router.get('/students/:id', ctrl.getStudentById);
router.put('/students/:id', validate(updateStudentSchema), ctrl.updateStudent);
router.delete('/students/:id', ctrl.deleteStudent);
router.post('/students/:id/create-login',   validate(createStudentLoginSchema), ctrl.createStudentLogin);
router.post('/students/:id/reset-password', validate(resetStudentPasswordSchema), ctrl.resetStudentPassword);

// ── Staff ─────────────────────────────────────────────────────────────────────
// Static paths MUST come before parameterized /:id routes
router.get('/staff',                     ctrl.getStaff);
router.get('/staff/suggest-employee-no', ctrl.getSuggestedEmployeeNo);
router.get('/staff/check-employee-no',   ctrl.checkEmployeeNoAvailability);
router.get('/staff/export',              ctrl.exportStaff);

// Static leave routes (school-wide) — before /:id to avoid route shadowing
router.get('/staff/leaves',                                      ctrl.getLeaves);
router.get('/staff/leaves/summary',                              ctrl.getLeaveSummary);
router.put('/staff/leaves/:leaveId/review', validate(reviewLeaveSchema), ctrl.reviewLeave);
router.put('/staff/leaves/:leaveId/cancel',                      ctrl.cancelLeave);

router.post('/staff',                    validate(createStaffSchema), ctrl.createStaff);

// Parameterized /:id routes
router.get('/staff/:id',                ctrl.getStaffById);
router.put('/staff/:id',                validate(updateStaffSchema), ctrl.updateStaff);
router.delete('/staff/:id',             ctrl.deleteStaff);
router.put('/staff/:id/status',         validate(updateStaffStatusSchema), ctrl.updateStaffStatus);
router.post('/staff/:id/create-login',  validate(createStaffLoginSchema), ctrl.createStaffLogin);
router.post('/staff/:id/reset-password', validate(resetStaffPasswordSchema), ctrl.resetStaffPassword);

// Qualifications
router.get('/staff/:id/qualifications',               ctrl.getStaffQualifications);
router.post('/staff/:id/qualifications',              validate(addQualificationSchema), ctrl.addQualification);
router.put('/staff/:id/qualifications/:qualId',       validate(updateQualificationSchema), ctrl.updateQualification);
router.delete('/staff/:id/qualifications/:qualId',    ctrl.deleteQualification);

// Documents
router.get('/staff/:id/documents',                    ctrl.getStaffDocuments);
router.post('/staff/:id/documents',                   validate(addDocumentSchema), ctrl.addDocument);
router.put('/staff/:id/documents/:docId/verify',      ctrl.verifyDocument);
router.delete('/staff/:id/documents/:docId',          ctrl.deleteDocument);

// Subject Assignments
router.get('/staff/:id/subject-assignments',              ctrl.getSubjectAssignments);
router.post('/staff/:id/subject-assignments',             validate(addSubjectAssignmentSchema), ctrl.addSubjectAssignment);
router.delete('/staff/:id/subject-assignments/:assignId', ctrl.removeSubjectAssignment);

// Timetable (read-only view)
router.get('/staff/:id/timetable',                    ctrl.getStaffTimetable);

// Per-staff leave routes
router.get('/staff/:id/leaves',                       ctrl.getStaffLeaves);
router.post('/staff/:id/leaves',                      validate(applyLeaveSchema), ctrl.applyLeave);

// ── Classes ───────────────────────────────────────────────────────────────────
router.get('/classes',                          ctrl.getClasses);
router.post('/classes',                         validate(createClassSchema), ctrl.createClass);
router.get('/classes/:classId/sections',        ctrl.getSections);
router.post('/classes/:classId/sections',       validate(createSectionSchema), ctrl.createSection);
router.put('/classes/:id',                      validate(updateClassSchema), ctrl.updateClass);
router.delete('/classes/:id',                   ctrl.deleteClass);

// ── Sections (standalone — for PUT/DELETE by section id) ─────────────────────
router.put('/sections/:id',    validate(updateSectionSchema), ctrl.updateSection);
router.delete('/sections/:id', ctrl.deleteSection);

// ── Attendance ────────────────────────────────────────────────────────────────
// Specific paths before parameterized routes
router.get('/attendance/report', ctrl.getAttendanceReport);
router.get('/attendance',        ctrl.getAttendance);
router.post('/attendance/bulk',  validate(bulkAttendanceSchema), ctrl.bulkMarkAttendance);

// ── Fees ──────────────────────────────────────────────────────────────────────
router.get('/fees/structures',        ctrl.getFeeStructures);
router.post('/fees/structures',       validate(createFeeStructureSchema), ctrl.createFeeStructure);
router.put('/fees/structures/:id',    validate(updateFeeStructureSchema), ctrl.updateFeeStructure);
router.delete('/fees/structures/:id', ctrl.deleteFeeStructure);

router.get('/fees/summary',         ctrl.getFeeSummary);
router.get('/fees/payments',        ctrl.getFeePayments);
router.post('/fees/payments',       validate(createFeePaymentSchema), ctrl.createFeePayment);
router.get('/fees/payments/:id',    ctrl.getFeePaymentById);

// ── Timetable ─────────────────────────────────────────────────────────────────
router.get('/timetable',       ctrl.getTimetable);
router.put('/timetable/bulk',  validate(bulkTimetableSchema), ctrl.bulkUpdateTimetable);

// ── Notices ───────────────────────────────────────────────────────────────────
router.get('/notices',        ctrl.getNotices);
router.post('/notices',       validate(createNoticeSchema), ctrl.createNotice);
router.put('/notices/:id',    validate(updateNoticeSchema), ctrl.updateNotice);
router.delete('/notices/:id', ctrl.deleteNotice);

// ── Notifications (specific paths before :id) ─────────────────────────────────
router.get('/notifications/unread-count', ctrl.getUnreadNotificationCount);
router.get('/notifications',              ctrl.getNotifications);
router.put('/notifications/:id/read',     ctrl.markNotificationRead);

// ── Profile ───────────────────────────────────────────────────────────────────
router.get('/profile',          ctrl.getProfile);
router.put('/profile/user',     validate(updateUserProfileSchema), ctrl.updateUserProfile);
router.put('/profile/school',   validate(updateSchoolProfileSchema), ctrl.updateSchoolProfile);

// ── Auth ──────────────────────────────────────────────────────────────────────
router.post('/auth/change-password', validate(changePasswordSchema), ctrl.changePassword);

export default router;
