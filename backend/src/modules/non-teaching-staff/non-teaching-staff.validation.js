/**
 * Joi validation schemas for the Non-Teaching Staff module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

// ── Roles ──────────────────────────────────────────────────────────────────

export const createRoleSchema = Joi.object({
    code: Joi.string()
        .trim()
        .max(50)
        .uppercase()
        .pattern(/^[A-Z_]+$/)
        .required()
        .messages({ 'string.pattern.base': 'Role code must contain only uppercase letters and underscores' }),
    display_name: Joi.string().trim().min(2).max(100).required(),
    category: Joi.string()
        .valid('FINANCE', 'LIBRARY', 'LABORATORY', 'ADMIN_SUPPORT', 'GENERAL')
        .required(),
    description: Joi.string().trim().max(500).allow('', null).optional(),
});

export const updateRoleSchema = Joi.object({
    display_name: Joi.string().trim().min(2).max(100).optional(),
    description:  Joi.string().trim().max(500).allow('', null).optional(),
    // code and category cannot be changed after creation
}).min(1);

// ── Staff ──────────────────────────────────────────────────────────────────

export const createStaffSchema = Joi.object({
    role_id:                 Joi.string().uuid().required(),
    employee_no:             Joi.string().trim().max(50).optional(),
    first_name:              Joi.string().trim().min(1).max(100).required(),
    last_name:               Joi.string().trim().min(1).max(100).required(),
    gender:                  Joi.string().valid('MALE', 'FEMALE', 'OTHER').required(),
    date_of_birth:           Joi.string().isoDate().allow(null, '').optional(),
    phone:                   Joi.string().trim().max(20).allow(null, '').optional(),
    email:                   Joi.string().trim().email().max(255).required(),
    department:              Joi.string().trim().max(100).allow(null, '').optional(),
    designation:             Joi.string().trim().max(100).allow(null, '').optional(),
    qualification:           Joi.string().trim().max(255).allow(null, '').optional(),
    join_date:               Joi.string().isoDate().required(),
    employee_type:           Joi.string().valid('PERMANENT', 'CONTRACT', 'PART_TIME', 'DAILY_WAGE').default('PERMANENT'),
    salary_grade:            Joi.string().trim().max(50).allow(null, '').optional(),
    address:                 Joi.string().trim().allow(null, '').optional(),
    city:                    Joi.string().trim().max(100).allow(null, '').optional(),
    state:                   Joi.string().trim().max(100).allow(null, '').optional(),
    blood_group:             Joi.string().max(5).allow(null, '').optional(),
    emergency_contact_name:  Joi.string().trim().max(100).allow(null, '').optional(),
    emergency_contact_phone: Joi.string().trim().max(20).allow(null, '').optional(),
});

export const updateStaffSchema = createStaffSchema.fork(
    ['role_id', 'first_name', 'last_name', 'gender', 'email', 'join_date'],
    (field) => field.optional()
);

export const updateStaffStatusSchema = Joi.object({
    is_active: Joi.boolean().required(),
});

// ── Login / Password ───────────────────────────────────────────────────────

export const createStaffLoginSchema = Joi.object({
    // trim() prevents whitespace-only passwords; min(8) after trim enforces real length
    password: Joi.string().trim().min(8).max(100).required()
        .messages({ 'string.min': 'Password must be at least 8 characters' }),
});

export const resetPasswordSchema = Joi.object({
    new_password: Joi.string().trim().min(8).max(100).required()
        .messages({ 'string.min': 'Password must be at least 8 characters' }),
});

// ── Qualifications ─────────────────────────────────────────────────────────

export const addQualificationSchema = Joi.object({
    degree:             Joi.string().max(100).required(),
    institution:        Joi.string().max(255).required(),
    board_or_university: Joi.string().max(255).allow(null, '').optional(),
    year_of_passing:    Joi.number().integer().min(1950).max(new Date().getFullYear()).allow(null).optional(),
    grade_or_percentage: Joi.string().max(20).allow(null, '').optional(),
    is_highest:         Joi.boolean().default(false),
});

export const updateQualificationSchema = addQualificationSchema.fork(
    ['degree', 'institution'],
    (f) => f.optional()
);

// ── Documents ──────────────────────────────────────────────────────────────

// Allowed file URL origins — restrict to known safe storage domains to prevent SSRF.
// Add additional bucket URLs here as needed (e.g. custom CDN).
const _allowedFileUrlHosts = [
    'storage.googleapis.com',
    's3.amazonaws.com',
    'vidyron-storage.s3.ap-south-1.amazonaws.com',
    'vidyron.in',
];

export const addDocumentSchema = Joi.object({
    document_type: Joi.string()
        .valid('AADHAAR', 'PAN', 'DEGREE', 'EXPERIENCE', 'ADDRESS_PROOF', 'PHOTO', 'APPOINTMENT_LETTER', 'OTHER')
        .required(),
    document_name: Joi.string().trim().max(255).required(),
    file_url: Joi.string()
        .uri({ scheme: ['https'] })  // only HTTPS — blocks javascript:, http:, ftp:
        .max(2048)
        .custom((value, helpers) => {
            try {
                const { hostname } = new URL(value);
                const allowed = _allowedFileUrlHosts.some(
                    (h) => hostname === h || hostname.endsWith(`.${h}`)
                );
                if (!allowed) {
                    return helpers.error('any.invalid');
                }
            } catch {
                return helpers.error('string.uri');
            }
            return value;
        })
        .messages({ 'any.invalid': 'file_url must point to an approved storage domain' })
        .required(),
    file_size_kb:  Joi.number().integer().min(1).max(5120).allow(null).optional(),
    mime_type:     Joi.string().max(100).allow(null, '').optional(),
});

// ── Attendance ─────────────────────────────────────────────────────────────

export const bulkAttendanceSchema = Joi.object({
    date: Joi.string().isoDate().required(),
    records: Joi.array().items(
        Joi.object({
            staff_id:       Joi.string().uuid().required(),
            status:         Joi.string().valid('PRESENT', 'ABSENT', 'HALF_DAY', 'ON_LEAVE', 'HOLIDAY', 'LATE').required(),
            check_in_time:  Joi.string().pattern(/^\d{2}:\d{2}$/).allow(null, '').optional(),
            check_out_time: Joi.string().pattern(/^\d{2}:\d{2}$/).allow(null, '').optional(),
            remarks:        Joi.string().max(255).allow(null, '').optional(),
        })
    ).min(1).max(500).required(),
});

export const correctAttendanceSchema = Joi.object({
    status:         Joi.string().valid('PRESENT', 'ABSENT', 'HALF_DAY', 'ON_LEAVE', 'HOLIDAY', 'LATE').optional(),
    check_in_time:  Joi.string().pattern(/^\d{2}:\d{2}$/).allow(null, '').optional(),
    check_out_time: Joi.string().pattern(/^\d{2}:\d{2}$/).allow(null, '').optional(),
    remarks:        Joi.string().max(255).allow(null, '').optional(),
}).min(1);

// ── Leaves ─────────────────────────────────────────────────────────────────

export const reviewLeaveSchema = Joi.object({
    status:       Joi.string().valid('APPROVED', 'REJECTED').required(),
    admin_remark: Joi.string().max(500).allow(null, '').optional(),
});

// Backdating limit: staff may backdate at most 7 calendar days.
// The cut-off is computed at validation time so it adjusts daily automatically.
const _maxBackdateDays = 7;

export const applyLeaveSchema = Joi.object({
    leave_type: Joi.string().valid('CASUAL', 'SICK', 'EARNED', 'MATERNITY', 'PATERNITY', 'UNPAID', 'COMPENSATORY', 'OTHER').required(),
    from_date: Joi.string()
        .isoDate()
        .custom((value, helpers) => {
            const minDate = new Date(Date.now() - _maxBackdateDays * 24 * 60 * 60 * 1000);
            const minStr  = minDate.toISOString().split('T')[0];
            if (value < minStr) {
                return helpers.error('any.invalid');
            }
            return value;
        })
        .messages({ 'any.invalid': `from_date cannot be more than ${_maxBackdateDays} days in the past` })
        .required(),
    to_date: Joi.string()
        .isoDate()
        .required(),
    reason: Joi.string().min(5).max(1000).required(),
});

// ── Generic validate middleware ────────────────────────────────────────────

export const validate = (schema) => (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (error) {
        const details = error.details.map((d) => d.message).join('; ');
        return next(new AppError(`Validation error: ${details}`, 422));
    }
    req.body = value;
    next();
};
