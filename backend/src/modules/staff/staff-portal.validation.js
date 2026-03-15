/**
 * Joi validation schemas for the Staff Portal module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

// ── Fee Payments ───────────────────────────────────────────────────────────────

export const createFeePaymentSchema = Joi.object({
    studentId:    Joi.string().uuid().required(),
    feeHead:      Joi.string().max(100).required(),
    academicYear: Joi.string().max(10).required(),
    amount:       Joi.number().positive().required(),
    paymentDate:  Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
    paymentMode:  Joi.string().valid('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE').required(),
    remarks:      Joi.string().max(255).optional().allow(null, ''),
    // receipt_no is intentionally omitted — it is server-generated only
});

// ── Profile ────────────────────────────────────────────────────────────────────

export const updateUserProfileSchema = Joi.object({
    firstName:     Joi.string().min(1).max(100).optional(),
    lastName:      Joi.string().min(1).max(100).optional(),
    phone:         Joi.string().max(20).optional().allow(null, ''),
    avatarUrl:     Joi.string().uri().optional().allow(null, ''),
    avatar_base64: Joi.string().optional().allow(null, ''),
    // For email/phone change via OTP flow
    email:          Joi.string().email().max(255).optional().allow(null, ''),
    otp_session_id: Joi.string().optional().allow(null, ''),
    otp_code:       Joi.string().length(6).optional().allow(null, ''),
}).min(1);

export const sendOtpSchema = Joi.object({
    type:  Joi.string().valid('email', 'phone').required(),
    value: Joi.string().max(255).required(),
});

// ── Change Password ────────────────────────────────────────────────────────────

export const changePasswordSchema = Joi.object({
    currentPassword: Joi.string().min(8).required(),
    newPassword:     Joi.string().min(8).required(),
});

// ── Non-Teaching Staff Self-Service Leaves ────────────────────────────────────

export const applyLeaveSchema = Joi.object({
    leave_type: Joi.string().valid('CASUAL', 'SICK', 'EARNED', 'MATERNITY', 'PATERNITY', 'UNPAID', 'COMPENSATORY', 'OTHER').required(),
    from_date:  Joi.string().isoDate().required(),
    to_date:    Joi.string().isoDate().required(),
    reason:     Joi.string().min(5).max(1000).required(),
});

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
