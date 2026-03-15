/**
 * Teacher Routes — /api/teacher/*
 * All routes require: verifyAccessToken + requireTeacher
 * requireTeacher performs a live DB lookup and attaches req.teacher,
 * req.teacherSections, and req.classTeacherSection.
 * All tenant scoping uses req.teacher.schoolId.
 *
 * Specific (non-parameterised) paths are always placed before /:id paths
 * to prevent route conflicts.
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireTeacher } from '../../middleware/teacher-guard.middleware.js';
import * as ctrl from './teacher.controller.js';
import {
    validate,
    markAttendanceSchema,
    createHomeworkSchema,
    updateHomeworkSchema,
    updateHomeworkStatusSchema,
    createDiarySchema,
    updateDiarySchema,
} from './teacher.validation.js';

const router = express.Router();

router.use(verifyAccessToken, requireTeacher);

// ── Dashboard ──────────────────────────────────────────────────────────────────
router.get('/dashboard', ctrl.getDashboard);

// ── Sections ───────────────────────────────────────────────────────────────────
router.get('/sections', ctrl.getSections);

// ── Attendance ─────────────────────────────────────────────────────────────────
router.get('/attendance/report', ctrl.getAttendanceReport);
router.get('/attendance', ctrl.getAttendance);
router.post('/attendance', validate(markAttendanceSchema), ctrl.markAttendance);

// ── Homework ───────────────────────────────────────────────────────────────────
router.get('/homework', ctrl.getHomework);
router.post('/homework', validate(createHomeworkSchema), ctrl.createHomework);
router.get('/homework/:id', ctrl.getHomeworkById);
router.put('/homework/:id', validate(updateHomeworkSchema), ctrl.updateHomework);
router.put('/homework/:id/status', validate(updateHomeworkStatusSchema), ctrl.updateHomeworkStatus);
router.delete('/homework/:id', ctrl.deleteHomework);

// ── Class Diary ────────────────────────────────────────────────────────────────
router.get('/diary', ctrl.getDiaryEntries);
router.post('/diary', validate(createDiarySchema), ctrl.createDiaryEntry);
router.put('/diary/:id', validate(updateDiarySchema), ctrl.updateDiaryEntry);
router.delete('/diary/:id', ctrl.deleteDiaryEntry);

// ── Profile ────────────────────────────────────────────────────────────────────
router.get('/profile', ctrl.getProfile);

export default router;
