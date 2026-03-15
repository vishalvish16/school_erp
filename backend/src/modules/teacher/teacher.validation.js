/**
 * Joi validation schemas for the Teacher module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

// ── Attendance ─────────────────────────────────────────────────────────────────

export const markAttendanceSchema = Joi.object({
    section_id: Joi.string().uuid().required(),
    date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
    records: Joi.array()
        .items(
            Joi.object({
                student_id: Joi.string().uuid().required(),
                status: Joi.string().valid('PRESENT', 'ABSENT', 'LATE', 'HALF_DAY').required(),
                remarks: Joi.string().max(255).optional().allow(null, ''),
            })
        )
        .min(1)
        .required(),
});

// ── Homework ───────────────────────────────────────────────────────────────────

export const createHomeworkSchema = Joi.object({
    class_id: Joi.string().uuid().required(),
    section_id: Joi.string().uuid().optional().allow(null),
    subject: Joi.string().max(100).required(),
    title: Joi.string().min(2).max(255).required(),
    description: Joi.string().max(5000).optional().allow(null, ''),
    due_date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
    attachment_urls: Joi.array().items(Joi.string().uri()).max(10).optional().default([]),
});

export const updateHomeworkSchema = Joi.object({
    title: Joi.string().min(2).max(255).optional(),
    description: Joi.string().max(5000).optional().allow(null, ''),
    due_date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).optional(),
    attachment_urls: Joi.array().items(Joi.string().uri()).max(10).optional(),
}).min(1);

export const updateHomeworkStatusSchema = Joi.object({
    status: Joi.string().valid('REVIEWED', 'CANCELLED').required(),
});

// ── Class Diary ────────────────────────────────────────────────────────────────

export const createDiarySchema = Joi.object({
    class_id: Joi.string().uuid().required(),
    section_id: Joi.string().uuid().optional().allow(null),
    subject: Joi.string().max(100).required(),
    date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
    period_no: Joi.number().integer().min(1).max(12).optional().allow(null),
    topic_covered: Joi.string().min(2).max(500).required(),
    description: Joi.string().max(5000).optional().allow(null, ''),
    page_from: Joi.string().max(20).optional().allow(null, ''),
    page_to: Joi.string().max(20).optional().allow(null, ''),
    homework_given: Joi.string().max(500).optional().allow(null, ''),
    remarks: Joi.string().max(2000).optional().allow(null, ''),
});

export const updateDiarySchema = Joi.object({
    topic_covered: Joi.string().min(2).max(500).optional(),
    description: Joi.string().max(5000).optional().allow(null, ''),
    period_no: Joi.number().integer().min(1).max(12).optional().allow(null),
    page_from: Joi.string().max(20).optional().allow(null, ''),
    page_to: Joi.string().max(20).optional().allow(null, ''),
    homework_given: Joi.string().max(500).optional().allow(null, ''),
    remarks: Joi.string().max(2000).optional().allow(null, ''),
}).min(1);

// ── Generic validate middleware ───────────────────────────────────────────────

export const validate = (schema) => (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (error) {
        const details = error.details.map((d) => d.message).join('; ');
        return next(new AppError(`Validation error: ${details}`, 422));
    }
    req.body = value;
    next();
};
