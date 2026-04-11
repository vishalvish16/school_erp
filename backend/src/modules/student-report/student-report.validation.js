/**
 * Joi validation schemas for the Student Report module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

// ── Send Student Notice ──────────────────────────────────────────────────────

export const sendStudentNoticeSchema = Joi.object({
    subject:       Joi.string().min(1).max(255).required(),
    message:       Joi.string().min(1).required(),
    priority:      Joi.string().valid('NORMAL', 'URGENT').default('NORMAL'),
    targetStudent: Joi.boolean().default(true),
    targetParent:  Joi.boolean().default(false),
}).custom((value, helpers) => {
    if (!value.targetStudent && !value.targetParent) {
        return helpers.error('any.custom', {
            message: 'At least one of targetStudent or targetParent must be true',
        });
    }
    return value;
});

// ── Generic validate middleware ──────────────────────────────────────────────

export const validate = (schema) => (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (error) {
        const details = error.details.map((d) => d.message).join('; ');
        return next(new AppError(`Validation error: ${details}`, 422));
    }
    req.body = value;
    next();
};
