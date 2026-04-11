/**
 * Joi validation schemas for the School Admin module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

// ── Students ──────────────────────────────────────────────────────────────────

export const createStudentSchema = Joi.object({
    firstName:      Joi.string().min(1).max(100).required(),
    lastName:       Joi.string().min(1).max(100).required(),
    gender:         Joi.string().valid('MALE', 'FEMALE', 'OTHER').required(),
    dateOfBirth:    Joi.date().iso().required(),
    admissionNo:    Joi.string().max(50).optional().allow(null, ''),
    admissionDate:  Joi.date().iso().required(),
    academicYearId: Joi.string().uuid().optional().allow(null),
    classId:        Joi.string().uuid().optional().allow(null),
    sectionId:      Joi.string().uuid().optional().allow(null),
    rollNo:         Joi.number().integer().positive().optional().allow(null),
    bloodGroup:     Joi.string().max(5).optional().allow(null, ''),
    phone:          Joi.string().max(20).optional().allow(null, ''),
    email:          Joi.string().email().max(255).optional().allow(null, ''),
    address:        Joi.string().max(500).optional().allow(null, ''),
    photoUrl:       Joi.string().uri().optional().allow(null, ''),
    parentName:     Joi.string().max(200).optional().allow(null, ''),
    parentPhone:    Joi.string().max(20).optional().allow(null, ''),
    parentEmail:    Joi.string().email().max(255).optional().allow(null, ''),
    parentRelation: Joi.string().max(50).optional().allow(null, ''),
    status:         Joi.string().valid('ACTIVE', 'INACTIVE', 'PASSED_OUT', 'TRANSFERRED').optional(),
});

export const updateStudentSchema = Joi.object({
    firstName:      Joi.string().min(1).max(100),
    lastName:       Joi.string().min(1).max(100),
    gender:         Joi.string().valid('MALE', 'FEMALE', 'OTHER'),
    dateOfBirth:    Joi.date().iso(),
    // admissionNo is permanent — not updatable
    admissionDate:  Joi.date().iso(),
    academicYearId: Joi.string().uuid().allow(null),
    classId:        Joi.string().uuid().allow(null),
    sectionId:      Joi.string().uuid().allow(null),
    rollNo:         Joi.number().integer().positive().allow(null),
    bloodGroup:     Joi.string().max(5).allow(null, ''),
    phone:          Joi.string().max(20).allow(null, ''),
    email:          Joi.string().email().max(255).allow(null, ''),
    address:        Joi.string().max(500).allow(null, ''),
    photoUrl:       Joi.string().uri().allow(null, ''),
    parentName:     Joi.string().max(200).allow(null, ''),
    parentPhone:    Joi.string().max(20).allow(null, ''),
    parentEmail:    Joi.string().email().max(255).allow(null, ''),
    parentRelation: Joi.string().max(50).allow(null, ''),
    status:         Joi.string().valid('ACTIVE', 'INACTIVE', 'PASSED_OUT', 'TRANSFERRED'),
}).min(1);

// ── Staff ─────────────────────────────────────────────────────────────────────

export const createStaffSchema = Joi.object({
    firstName:              Joi.string().min(1).max(100).required(),
    lastName:               Joi.string().min(1).max(100).required(),
    gender:                 Joi.string().valid('MALE', 'FEMALE', 'OTHER').required(),
    employeeNo:             Joi.string().max(50).optional().allow('', null),
    email:                  Joi.string().email().max(255).required(),
    phone:                  Joi.string().min(10).max(20).required(),
    designation:            Joi.string().valid(
                                'TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD',
                                'CLERK', 'ACCOUNTANT', 'LIBRARIAN', 'LAB_ASSISTANT',
                                'COUNSELOR', 'SPORTS_COACH', 'OTHER'
                            ).required(),
    joinDate:               Joi.date().iso().required(),
    dateOfBirth:            Joi.date().iso().optional().allow(null),
    subjects:               Joi.array().items(Joi.string().max(100)).max(30).optional(),
    qualification:          Joi.string().max(255).optional().allow(null, ''),
    photoUrl:               Joi.string().uri().optional().allow(null, ''),
    isActive:               Joi.boolean().optional(),
    createLogin:            Joi.boolean().optional(),
    password:               Joi.string().min(8).max(128).optional(),
    // Extended fields from Teacher/Staff spec
    department:             Joi.string().max(100).optional().allow(null, ''),
    employeeType:           Joi.string().valid('PERMANENT', 'CONTRACTUAL', 'PART_TIME', 'PROBATION').optional(),
    address:                Joi.string().max(500).optional().allow(null, ''),
    city:                   Joi.string().max(100).optional().allow(null, ''),
    state:                  Joi.string().max(100).optional().allow(null, ''),
    bloodGroup:             Joi.string().max(5).optional().allow(null, ''),
    emergencyContactName:   Joi.string().max(100).optional().allow(null, ''),
    emergencyContactPhone:  Joi.string().max(20).optional().allow(null, ''),
    experienceYears:        Joi.number().integer().min(0).max(60).optional().allow(null),
    salaryGrade:            Joi.string().max(50).optional().allow(null, ''),
});

export const createStaffLoginSchema = Joi.object({
    password: Joi.string().min(8).max(128).required(),
});

export const resetStaffPasswordSchema = Joi.object({
    newPassword: Joi.string().min(8).max(128).required(),
});

export const createStudentLoginSchema = Joi.object({
    password: Joi.string().min(8).max(128).required(),
});

export const resetStudentPasswordSchema = Joi.object({
    newPassword: Joi.string().min(8).max(128).required(),
});

export const updateStaffSchema = Joi.object({
    firstName:              Joi.string().min(1).max(100),
    lastName:               Joi.string().min(1).max(100),
    gender:                 Joi.string().valid('MALE', 'FEMALE', 'OTHER'),
    employeeNo:             Joi.string().max(50),
    email:                  Joi.string().email().max(255),
    designation:            Joi.string().valid(
                                'TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD',
                                'CLERK', 'ACCOUNTANT', 'LIBRARIAN', 'LAB_ASSISTANT',
                                'COUNSELOR', 'SPORTS_COACH', 'OTHER'
                            ),
    joinDate:               Joi.date().iso(),
    dateOfBirth:            Joi.date().iso().allow(null),
    phone:                  Joi.string().min(10).max(20),
    subjects:               Joi.array().items(Joi.string().max(100)).max(30),
    qualification:          Joi.string().max(255).allow(null, ''),
    photoUrl:               Joi.string().uri().allow(null, ''),
    isActive:               Joi.boolean(),
    // Extended fields from Teacher/Staff spec
    department:             Joi.string().max(100).allow(null, ''),
    employeeType:           Joi.string().valid('PERMANENT', 'CONTRACTUAL', 'PART_TIME', 'PROBATION'),
    address:                Joi.string().max(500).allow(null, ''),
    city:                   Joi.string().max(100).allow(null, ''),
    state:                  Joi.string().max(100).allow(null, ''),
    bloodGroup:             Joi.string().max(5).allow(null, ''),
    emergencyContactName:   Joi.string().max(100).allow(null, ''),
    emergencyContactPhone:  Joi.string().max(20).allow(null, ''),
    experienceYears:        Joi.number().integer().min(0).max(60).allow(null),
    salaryGrade:            Joi.string().max(50).allow(null, ''),
}).min(1);

// ── Classes ───────────────────────────────────────────────────────────────────

export const createClassSchema = Joi.object({
    name:    Joi.string().min(1).max(50).required(),
    numeric: Joi.number().integer().min(1).max(20).optional().allow(null),
});

export const updateClassSchema = Joi.object({
    name:     Joi.string().min(1).max(50),
    numeric:  Joi.number().integer().min(1).max(20).allow(null),
    isActive: Joi.boolean(),
}).min(1);

// ── Sections ──────────────────────────────────────────────────────────────────

export const createSectionSchema = Joi.object({
    name:            Joi.string().min(1).max(10).required(),
    classTeacherId:  Joi.string().uuid().optional().allow(null),
    capacity:        Joi.number().integer().min(1).max(200).optional(),
});

export const updateSectionSchema = Joi.object({
    name:            Joi.string().min(1).max(10),
    classTeacherId:  Joi.string().uuid().allow(null),
    capacity:        Joi.number().integer().min(1).max(200),
    isActive:        Joi.boolean(),
}).min(1);

// ── Attendance ────────────────────────────────────────────────────────────────

export const bulkAttendanceSchema = Joi.object({
    sectionId: Joi.string().uuid().required(),
    date:      Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
    records:   Joi.array().items(
        Joi.object({
            studentId: Joi.string().uuid().required(),
            status:    Joi.string().valid('PRESENT', 'ABSENT', 'LATE', 'HOLIDAY').required(),
            remarks:   Joi.string().max(255).optional().allow(null, ''),
        })
    ).min(1).max(500).required(),
});

// ── Fee Structures ────────────────────────────────────────────────────────────

export const createFeeStructureSchema = Joi.object({
    academicYear: Joi.string().max(10).required(),
    feeHead:      Joi.string().max(100).required(),
    amount:       Joi.number().positive().required(),
    frequency:    Joi.string().valid('MONTHLY', 'QUARTERLY', 'ANNUALLY', 'ANNUAL', 'ONE_TIME').required(),
    classId:      Joi.string().uuid().optional().allow(null),
    dueDay:       Joi.number().integer().min(1).max(31).optional().allow(null),
    isActive:     Joi.boolean().optional(),
});

export const updateFeeStructureSchema = Joi.object({
    academicYear: Joi.string().max(10),
    feeHead:      Joi.string().max(100),
    amount:       Joi.number().positive(),
    frequency:    Joi.string().valid('MONTHLY', 'QUARTERLY', 'ANNUALLY', 'ANNUAL', 'ONE_TIME'),
    classId:      Joi.string().uuid().allow(null),
    dueDay:       Joi.number().integer().min(1).max(31).allow(null),
    isActive:     Joi.boolean(),
}).min(1);

// ── Fee Payments ──────────────────────────────────────────────────────────────

export const createFeePaymentSchema = Joi.object({
    studentId:    Joi.string().uuid().required(),
    feeHead:      Joi.string().max(100).required(),
    academicYear: Joi.string().max(10).required(),
    amount:       Joi.number().positive().required(),
    paymentDate:  Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
    paymentMode:  Joi.string().valid('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE').required(),
    receiptNo:    Joi.string().max(50).required(),
    remarks:      Joi.string().max(255).optional().allow(null, ''),
});

// ── Timetable ─────────────────────────────────────────────────────────────────

export const bulkTimetableSchema = Joi.object({
    classId:   Joi.string().uuid().required(),
    sectionId: Joi.string().uuid().optional().allow(null),
    entries:   Joi.array().items(
        Joi.object({
            dayOfWeek: Joi.number().integer().min(1).max(6).required(),
            periodNo:  Joi.number().integer().min(1).max(20).required(),
            subject:   Joi.string().max(100).required(),
            staffId:   Joi.string().uuid().optional().allow(null),
            startTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
            endTime:   Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
            room:      Joi.string().max(50).optional().allow(null, ''),
        })
    ).min(1).max(60).required(),
});

// ── Notices ───────────────────────────────────────────────────────────────────

export const createNoticeSchema = Joi.object({
    title:       Joi.string().min(1).max(255).required(),
    body:        Joi.string().min(1).max(10000).required(),
    targetRole:  Joi.string().valid('all', 'teacher', 'student', 'parent').optional().allow(null),
    isPinned:    Joi.boolean().optional(),
    publishedAt: Joi.string().isoDate().optional().allow(null),
    expiresAt:   Joi.string().isoDate().optional().allow(null),
});

export const updateNoticeSchema = Joi.object({
    title:       Joi.string().min(1).max(255),
    body:        Joi.string().min(1).max(10000),
    targetRole:  Joi.string().valid('all', 'teacher', 'student', 'parent').allow(null),
    isPinned:    Joi.boolean(),
    publishedAt: Joi.string().isoDate().allow(null),
    expiresAt:   Joi.string().isoDate().allow(null),
}).min(1);

// ── Profile ───────────────────────────────────────────────────────────────────

export const updateUserProfileSchema = Joi.object({
    firstName:     Joi.string().min(1).max(100).required(),
    lastName:      Joi.string().min(1).max(100).required(),
    phone:         Joi.string().max(20).optional().allow(null, ''),
    avatarUrl:     Joi.string().uri().optional().allow(null, ''),
    avatar_base64: Joi.string().max(500000).optional().allow(null, ''), // ~375KB decoded
});

export const updateSchoolProfileSchema = Joi.object({
    name:    Joi.string().min(1).max(255).required(),
    phone:   Joi.string().max(20).required(),
    email:   Joi.string().email().max(255).required(),
    address: Joi.string().max(500).optional().allow(null, ''),
    city:    Joi.string().max(100).optional().allow(null, ''),
    state:   Joi.string().max(100).optional().allow(null, ''),
    logoUrl: Joi.string().uri().optional().allow(null, ''),
});

export const changePasswordSchema = Joi.object({
    currentPassword: Joi.string().min(8).required(),
    newPassword:     Joi.string().min(8).required(),
});

// ── Staff Status Update ────────────────────────────────────────────────────────

export const updateStaffStatusSchema = Joi.object({
    isActive: Joi.boolean().required(),
    reason:   Joi.string().max(500).optional().allow(null, ''),
});

// ── Staff Qualifications ───────────────────────────────────────────────────────

export const addQualificationSchema = Joi.object({
    degree:             Joi.string().max(100).required(),
    institution:        Joi.string().max(255).required(),
    boardOrUniversity:  Joi.string().max(255).optional().allow(null, ''),
    yearOfPassing:      Joi.number().integer().min(1950).max(2100).optional().allow(null),
    gradeOrPercentage:  Joi.string().max(20).optional().allow(null, ''),
    isHighest:          Joi.boolean().default(false),
});

export const updateQualificationSchema = Joi.object({
    degree:             Joi.string().max(100),
    institution:        Joi.string().max(255),
    boardOrUniversity:  Joi.string().max(255).allow(null, ''),
    yearOfPassing:      Joi.number().integer().min(1950).max(2100).allow(null),
    gradeOrPercentage:  Joi.string().max(20).allow(null, ''),
    isHighest:          Joi.boolean(),
}).min(1);

// ── Staff Documents ───────────────────────────────────────────────────────────

export const addDocumentSchema = Joi.object({
    documentType: Joi.string()
        .valid('AADHAAR', 'PAN', 'DEGREE', 'EXPERIENCE', 'ADDRESS_PROOF', 'PHOTO', 'OTHER')
        .required(),
    documentName: Joi.string().max(255).required(),
    fileUrl:      Joi.string().uri().required(),
    fileSizeKb:   Joi.number().integer().min(1).optional().allow(null),
    mimeType:     Joi.string().max(100).optional().allow(null, ''),
});

// ── Subject Assignments ───────────────────────────────────────────────────────

export const addSubjectAssignmentSchema = Joi.object({
    classId:      Joi.string().uuid().required(),
    sectionId:    Joi.string().uuid().optional().allow(null),
    subject:      Joi.string().max(100).required(),
    academicYear: Joi.string().pattern(/^\d{4}-\d{2}$/).required(),
});

// ── Leave Management ──────────────────────────────────────────────────────────

export const applyLeaveSchema = Joi.object({
    leaveType: Joi.string()
        .valid('CASUAL', 'SICK', 'EARNED', 'MATERNITY', 'PATERNITY', 'UNPAID', 'OTHER')
        .required(),
    // fromDate must be today or in the future (prevent backdating leave applications)
    fromDate: Joi.date().iso().min(new Date(new Date().setHours(0, 0, 0, 0))).required()
        .messages({ 'date.min': 'Leave start date cannot be in the past' }),
    toDate:   Joi.date().iso().min(Joi.ref('fromDate')).required(),
    reason:   Joi.string().min(10).max(1000).required(),
});

export const reviewLeaveSchema = Joi.object({
    status:      Joi.string().valid('APPROVED', 'REJECTED').required(),
    adminRemark: Joi.string().when('status', {
        is:        'REJECTED',
        then:      Joi.string().min(1).required(),
        otherwise: Joi.string().optional().allow(null, ''),
    }),
});

// ── Parents ──────────────────────────────────────────────────────────────────

export const createParentSchema = Joi.object({
    firstName: Joi.string().min(1).max(100).required(),
    lastName:  Joi.string().min(1).max(100).required(),
    phone:     Joi.string().min(10).max(20).required(),
    email:     Joi.string().email().optional().allow(null, ''),
    relation:  Joi.string().max(50).optional().allow(null, ''),
});

export const updateParentSchema = Joi.object({
    firstName: Joi.string().min(1).max(100),
    lastName:  Joi.string().min(1).max(100),
    email:     Joi.string().email().optional().allow(null, ''),
    relation:  Joi.string().max(50).optional().allow(null, ''),
}).min(1);

export const linkParentSchema = Joi.object({
    parentId:     Joi.string().uuid().optional(),
    phone:        Joi.string().min(10).max(20).optional(),
    firstName:    Joi.string().min(1).max(100).optional(),
    lastName:     Joi.string().min(1).max(100).optional(),
    email:        Joi.string().email().optional().allow(null, ''),
    relation:     Joi.string().max(50).optional(),
    linkRelation: Joi.string().min(1).max(50).required(),
    isPrimary:    Joi.boolean().optional(),
}).custom((value, helpers) => {
    if (!value.parentId && !value.phone) {
        return helpers.error('any.custom', { message: 'Either parentId or phone is required' });
    }
    return value;
});

export const updateParentLinkSchema = Joi.object({
    relation:  Joi.string().max(50).optional(),
    isPrimary: Joi.boolean().optional(),
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
