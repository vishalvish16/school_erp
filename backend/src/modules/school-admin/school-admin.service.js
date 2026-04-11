/**
 * School Admin Service — business logic for all school-admin routes.
 * All methods receive schoolId from JWT (never from user input).
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/response.js';
import { logger } from '../../config/logger.js';
import * as repo from './school-admin.repository.js';
import * as auditService from '../audit/audit.service.js';
import * as fcmRepo from '../fcm/fcm.repository.js';
import { sendFcmToTokens } from '../fcm/fcm.service.js';
import { getIO } from '../../socket.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Dashboard ─────────────────────────────────────────────────────────────────

export async function getDashboardStats({ schoolId }) {
    if (!schoolId) throw new AppError('School context required', 400);
    return repo.getDashboardStats(schoolId);
}

// ── Academic Years ────────────────────────────────────────────────────────────

export async function getAcademicYears({ schoolId }) {
    return repo.findAcademicYears(schoolId);
}

// ── Students ──────────────────────────────────────────────────────────────────

/** Convert Prisma student (camelCase) to API snake_case for Flutter compatibility */
function toStudentApiFormat(s) {
    if (!s) return null;
    return {
        id:              s.id,
        school_id:       s.schoolId,
        admission_no:    s.admissionNo,
        first_name:      s.firstName,
        last_name:       s.lastName,
        gender:          s.gender,
        date_of_birth:   s.dateOfBirth,
        blood_group:     s.bloodGroup,
        phone:           s.phone,
        email:           s.email,
        address:         s.address,
        photo_url:       s.photoUrl,
        class_id:        s.classId ?? s.class_?.id ?? null,
        class_name:      s.class_?.name ?? null,
        section_id:      s.sectionId ?? s.section?.id ?? null,
        section_name:    s.section?.name ?? null,
        roll_no:         s.rollNo,
        status:          s.status ?? 'ACTIVE',
        admission_date:  s.admissionDate,
        parent_name:     s.parentName,
        parent_phone:    s.parentPhone,
        parent_email:    s.parentEmail,
        parent_relation: s.parentRelation,
        user_id:         s.userId ?? null,
        created_at:      s.createdAt,
    };
}

export async function getStudents({ schoolId, page, limit, search, classId, sectionId, status }) {
    const result = await repo.findStudents({ schoolId, page, limit, search, classId, sectionId, status });
    if (process.env.NODE_ENV !== 'production' && (result?.pagination?.total === 0)) {
        const raw = await repo.debugStudentCount(schoolId);
        if (raw.total > 0 || raw.active > 0) {
            logger.warn(`[getStudents] Prisma returned 0 but raw DB has total=${raw.total} active=${raw.active} for schoolId=${schoolId}`);
        }
    }
    return {
        data:       (result.data || []).map(toStudentApiFormat).filter(Boolean),
        pagination: result.pagination,
    };
}

export async function getStudentById({ id, schoolId }) {
    const student = await repo.findStudentById(id, schoolId);
    if (!student) throw new AppError('Student not found', 404);
    return toStudentApiFormat(student);
}

export async function createStudent({ schoolId, userId, data }) {
    let admissionNo = (data.admissionNo || '').trim();
    if (!admissionNo) {
        admissionNo = await repo.generateAdmissionNo(schoolId, data.firstName, data.lastName);
    }
    const existing = await repo.findStudentByAdmissionNo(admissionNo, schoolId);
    if (existing) throw new AppError('Admission number already exists in this school', 409);

    const student = await repo.createStudent({ schoolId, ...data, admissionNo });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STUDENT_CREATE',
        entityType: 'students',
        entityId:   student.id,
        entityName: `${student.firstName} ${student.lastName}`,
        extra:      { admissionNo: student.admissionNo },
    }).catch(() => {});

    return student;
}

export async function updateStudent({ id, schoolId, userId, data }) {
    const existing = await repo.findStudentById(id, schoolId);
    if (!existing) throw new AppError('Student not found', 404);

    // Admission number is permanent — never update it
    const { admissionNo: _drop, ...updateData } = data;
    const updated = await repo.updateStudent(id, schoolId, updateData);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STUDENT_UPDATE',
        entityType: 'students',
        entityId:   id,
        entityName: `${updated.firstName} ${updated.lastName}`,
    }).catch(() => {});

    return updated;
}

export async function deleteStudent({ id, schoolId, userId }) {
    const existing = await repo.findStudentById(id, schoolId);
    if (!existing) throw new AppError('Student not found', 404);

    await repo.softDeleteStudent(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STUDENT_DELETE',
        entityType: 'students',
        entityId:   id,
        entityName: `${existing.firstName} ${existing.lastName}`,
    }).catch(() => {});
}

export async function createStudentLogin({ studentId, schoolId, userId, password }) {
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);
    if (student.status !== 'ACTIVE') throw new AppError('Student is not active', 400);
    if (student.userId) throw new AppError('Student already has a portal login', 409);

    const phone = student.phone || student.parentPhone;
    if (!phone || !phone.trim()) {
        throw new AppError('Student must have phone or parent phone to create login', 400);
    }

    const studentRole = await repo.findRoleByName('STUDENT') || await repo.findRoleByName('student');
    if (!studentRole) throw new AppError('STUDENT role not found. Add it to roles table.', 500);

    const baseEmail = `student_${(student.admissionNo || '').replace(/[^a-zA-Z0-9]/g, '_')}@portal.vidyron.in`;
    let email = baseEmail;
    let suffix = 0;
    while (await repo.findUserByEmail(email)) {
        suffix++;
        email = `${baseEmail.replace('@', `_${suffix}@`)}`;
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await repo.createUserForStaff({
        email,
        passwordHash,
        schoolId,
        firstName: student.firstName,
        lastName:  student.lastName,
        phone:     phone.trim(),
        roleId:    studentRole.id,
    });

    await repo.updateStudentUserId(studentId, user.id);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STUDENT_LOGIN_CREATE',
        entityType: 'student',
        entityId:   studentId,
        entityName: `${student.firstName} ${student.lastName}`,
    }).catch(() => {});

    return { message: 'Portal login created. Student can log in with their phone and OTP.' };
}

export async function resetStudentPassword({ studentId, schoolId, userId, newPassword }) {
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);
    if (!student.userId) throw new AppError('Student has no portal login. Create one first.', 400);

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await repo.updateUserPassword(student.userId, passwordHash);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STUDENT_PASSWORD_RESET',
        entityType: 'student',
        entityId:   studentId,
        entityName: `${student.firstName} ${student.lastName}`,
    }).catch(() => {});

    return { message: 'Password reset successfully.' };
}

// ── Staff ─────────────────────────────────────────────────────────────────────

export async function getStaff({ schoolId, page, limit, search, designation, isActive }) {
    const isActiveFilter = isActive !== undefined
        ? isActive === 'true' || isActive === true
        : undefined;
    return repo.findStaff({ schoolId, page, limit, search, designation, isActive: isActiveFilter });
}

export async function getStaffById({ id, schoolId }) {
    const staff = await repo.findStaffById(id, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    return staff;
}

export async function getSuggestedEmployeeNo({ schoolId, firstName, lastName }) {
    return repo.getNextEmployeeNo(schoolId, firstName || '', lastName || '');
}

export async function checkEmployeeNoAvailability({ schoolId, employeeNo, excludeStaffId }) {
    const trimmed = (employeeNo || '').trim();
    if (!trimmed) return { available: false, message: 'Employee number is required' };
    const taken = await repo.isEmployeeNoTaken(trimmed, schoolId, excludeStaffId || null);
    return { available: !taken, message: taken ? 'Already in use' : 'Available' };
}

export async function createStaff({ schoolId, userId, data }) {
    let employeeNo = (data.employeeNo || '').trim().toUpperCase();
    if (!employeeNo) {
        employeeNo = await repo.getNextEmployeeNo(schoolId, data.firstName, data.lastName);
    }
    const taken = await repo.isEmployeeNoTaken(employeeNo, schoolId);
    if (taken) throw new AppError('Employee number already exists in this school', 409);

    const { createLogin, password, ...staffData } = data;
    let newUserId = null;

    if (createLogin) {
        if (!password || password.length < 8) {
            throw new AppError('Password is required (min 8 characters) when creating login account', 400);
        }
    }

    if (createLogin && password) {
        const existingUser = await repo.findUserByEmail(data.email);
        if (existingUser) throw new AppError('A user account with this email already exists. Use a different email or create login later from staff profile.', 409);

        const staffRole = await repo.findRoleByName('staff')
            || await repo.findRoleByName('teacher')
            || await repo.findRoleByName('school_admin');
        if (!staffRole) throw new AppError('Staff role not found. Add a role named "staff" in the roles table.', 500);

        const passwordHash = await bcrypt.hash(password, 12);
        const user = await repo.createUserForStaff({
            email: data.email,
            passwordHash,
            schoolId,
            firstName: data.firstName,
            lastName: data.lastName,
            phone: data.phone || null,
            roleId: staffRole.id,
        });
        newUserId = user.id;
    }

    const staff = await repo.createStaff({
        schoolId,
        ...staffData,
        employeeNo,
        ...(newUserId && { userId: newUserId }),
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_CREATE',
        entityType: 'staff',
        entityId:   staff.id,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { employeeNo, hasLogin: !!newUserId },
    }).catch(() => {});

    return staff;
}

export async function createStaffLogin({ staffId, schoolId, userId, password }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    if (staff.userId) throw new AppError('Staff already has a login account', 409);

    const existingUser = await repo.findUserByEmail(staff.email);
    if (existingUser) throw new AppError('A user account with this email already exists. Staff cannot have duplicate email.', 409);

    const staffRole = await repo.findRoleByName('staff')
        || await repo.findRoleByName('teacher')
        || await repo.findRoleByName('school_admin');
    if (!staffRole) throw new AppError('Staff role not found. Add a role named "staff" in the roles table.', 500);

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await repo.createUserForStaff({
        email: staff.email,
        passwordHash,
        schoolId,
        firstName: staff.firstName,
        lastName: staff.lastName,
        phone: staff.phone || null,
        roleId: staffRole.id,
    });

    await repo.updateStaffUserId(staffId, user.id);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_LOGIN_CREATE',
        entityType: 'staff',
        entityId:   staffId,
        entityName: `${staff.firstName} ${staff.lastName}`,
    }).catch(() => {});

    return { message: 'Login account created. Staff can now log in with their email and the password you set.' };
}

export async function resetStaffPassword({ staffId, schoolId, userId, newPassword }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    if (!staff.userId) throw new AppError('Staff has no login account. Create one first.', 400);

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await repo.updateUserPassword(staff.userId, passwordHash);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_PASSWORD_RESET',
        entityType: 'staff',
        entityId:   staffId,
        entityName: `${staff.firstName} ${staff.lastName}`,
    }).catch(() => {});

    return { message: 'Password reset successfully.' };
}

export async function updateStaff({ id, schoolId, userId, data }) {
    const existing = await repo.findStaffById(id, schoolId);
    if (!existing) throw new AppError('Staff member not found', 404);

    if (data.employeeNo) {
        const newNo = data.employeeNo.trim().toUpperCase();
        const existingNo = (existing.employeeNo || '').toUpperCase();
        if (newNo !== existingNo) {
            const taken = await repo.isEmployeeNoTaken(newNo, schoolId, id);
            if (taken) throw new AppError('Employee number already exists in this school', 409);
        }
        data = { ...data, employeeNo: data.employeeNo.trim().toUpperCase() };
    }

    const updated = await repo.updateStaff(id, schoolId, data);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_UPDATE',
        entityType: 'staff',
        entityId:   id,
    }).catch(() => {});

    return updated;
}

export async function deleteStaff({ id, schoolId, userId }) {
    const existing = await repo.findStaffById(id, schoolId);
    if (!existing) throw new AppError('Staff member not found', 404);

    await repo.softDeleteStaff(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_DELETE',
        entityType: 'staff',
        entityId:   id,
    }).catch(() => {});
}

export async function updateStaffStatus({ id, schoolId, userId, data }) {
    const existing = await repo.findStaffById(id, schoolId);
    if (!existing) throw new AppError('Staff member not found', 404);

    // Cannot deactivate a class teacher — must reassign first
    if (data.isActive === false || data.isActive === 'false') {
        const sections = await repo.findClassesByClassTeacher(id, schoolId);
        if (sections.length > 0) {
            throw new AppError(
                `Cannot deactivate: staff is a class teacher for ${sections.length} section(s). Reassign class teacher first.`,
                409
            );
        }
    }

    const updated = await repo.updateStaff(id, schoolId, { isActive: data.isActive });

    // Also deactivate linked user if deactivating
    if ((data.isActive === false || data.isActive === 'false') && existing.userId) {
        await repo.updateUser(existing.userId, { isActive: false });
    }

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_STATUS_UPDATE',
        entityType: 'staff',
        entityId:   id,
        extra:      { isActive: data.isActive, reason: data.reason },
    }).catch(() => {});

    return { isActive: updated.isActive };
}

export async function exportStaff({ schoolId, search, designation, department, isActive, employeeType }) {
    const isActiveFilter = isActive !== undefined
        ? isActive === 'true' || isActive === true
        : undefined;

    const allStaff = await repo.findAllStaffForExport({
        schoolId,
        search,
        designation,
        department,
        isActive: isActiveFilter,
        employeeType,
    });

    // Build CSV
    const header = [
        'Employee No', 'First Name', 'Last Name', 'Gender', 'Designation',
        'Department', 'Employee Type', 'Email', 'Phone', 'Join Date',
        'Experience Years', 'Is Active', 'Qualification',
    ].join(',');

    const rows = allStaff.map((s) => [
        s.employeeNo,
        `"${s.firstName}"`,
        `"${s.lastName}"`,
        s.gender,
        s.designation,
        s.department || '',
        s.employeeType,
        s.email,
        s.phone || '',
        s.joinDate ? new Date(s.joinDate).toISOString().split('T')[0] : '',
        s.experienceYears ?? '',
        s.isActive ? 'Yes' : 'No',
        `"${(s.qualification || '').replace(/"/g, '""')}"`,
    ].join(','));

    return [header, ...rows].join('\n');
}

// ── Staff Qualifications ───────────────────────────────────────────────────────

export async function getStaffQualifications({ staffId, schoolId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    return repo.findQualificationsByStaffId(staffId, schoolId);
}

export async function addQualification({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    // If marking as highest, unset all others first
    if (data.isHighest) {
        await repo.unsetHighestQualification(staffId, schoolId);
    }

    const qual = await repo.createQualification({ staffId, schoolId, ...data });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_QUALIFICATION_ADD',
        entityType: 'staff_qualifications',
        entityId:   qual.id,
        extra:      { staffId, degree: data.degree },
    }).catch(() => {});

    return qual;
}

export async function updateQualification({ staffId, qualId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const qual = await repo.findQualificationById(qualId, staffId, schoolId);
    if (!qual) throw new AppError('Qualification not found', 404);

    // If marking as highest, unset all others first
    if (data.isHighest) {
        await repo.unsetHighestQualification(staffId, schoolId);
    }

    const updated = await repo.updateQualification(qualId, staffId, schoolId, data);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_QUALIFICATION_UPDATE',
        entityType: 'staff_qualifications',
        entityId:   qualId,
        extra:      { staffId },
    }).catch(() => {});

    return updated;
}

export async function deleteQualification({ staffId, qualId, schoolId, userId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const qual = await repo.findQualificationById(qualId, staffId, schoolId);
    if (!qual) throw new AppError('Qualification not found', 404);

    await repo.deleteQualification(qualId, staffId, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_QUALIFICATION_DELETE',
        entityType: 'staff_qualifications',
        entityId:   qualId,
        extra:      { staffId },
    }).catch(() => {});
}

// ── Staff Documents ───────────────────────────────────────────────────────────

export async function getStaffDocuments({ staffId, schoolId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    return repo.findDocumentsByStaffId(staffId, schoolId);
}

export async function addDocument({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    // For non-OTHER types, soft-delete any existing document of same type
    if (data.documentType !== 'OTHER') {
        await repo.softDeleteOldDocumentsByType(staffId, schoolId, data.documentType);
    }

    const doc = await repo.createDocument({
        staffId,
        schoolId,
        uploadedBy: userId,
        ...data,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_DOCUMENT_ADD',
        entityType: 'staff_documents',
        entityId:   doc.id,
        extra:      { staffId, documentType: data.documentType },
    }).catch(() => {});

    return doc;
}

export async function verifyDocument({ staffId, docId, schoolId, userId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const doc = await repo.findDocumentById(docId, staffId, schoolId);
    if (!doc) throw new AppError('Document not found', 404);

    const updated = await repo.verifyDocument(docId, staffId, schoolId, userId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_DOCUMENT_VERIFY',
        entityType: 'staff_documents',
        entityId:   docId,
        extra:      { staffId },
    }).catch(() => {});

    return { verified: updated.verified, verifiedAt: updated.verifiedAt };
}

export async function deleteDocument({ staffId, docId, schoolId, userId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const doc = await repo.findDocumentById(docId, staffId, schoolId);
    if (!doc) throw new AppError('Document not found', 404);

    await repo.softDeleteDocument(docId, staffId, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_DOCUMENT_DELETE',
        entityType: 'staff_documents',
        entityId:   docId,
        extra:      { staffId },
    }).catch(() => {});
}

// ── Subject Assignments ───────────────────────────────────────────────────────

export async function getSubjectAssignments({ staffId, schoolId, academicYear }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    return repo.findSubjectAssignments(staffId, schoolId, academicYear);
}

export async function addSubjectAssignment({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    // Check for conflict — same class/section/subject/academicYear assigned to another active teacher
    const conflict = await repo.checkSubjectAssignmentConflict(
        data.classId,
        data.sectionId || null,
        data.subject,
        data.academicYear,
        schoolId,
        staffId
    );
    if (conflict) {
        throw new AppError(
            `Subject "${data.subject}" is already assigned to another teacher in this class-section for ${data.academicYear}`,
            409
        );
    }

    const assignment = await repo.createSubjectAssignment({ staffId, schoolId, ...data });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_SUBJECT_ASSIGN',
        entityType: 'staff_subject_assignments',
        entityId:   assignment.id,
        extra:      { staffId, subject: data.subject, classId: data.classId },
    }).catch(() => {});

    return assignment;
}

export async function removeSubjectAssignment({ staffId, assignId, schoolId, userId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const assignment = await repo.findSubjectAssignmentById(assignId, staffId, schoolId);
    if (!assignment) throw new AppError('Subject assignment not found', 404);

    await repo.removeSubjectAssignment(assignId, staffId, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_SUBJECT_REMOVE',
        entityType: 'staff_subject_assignments',
        entityId:   assignId,
        extra:      { staffId },
    }).catch(() => {});
}

// ── Staff Timetable ───────────────────────────────────────────────────────────

export async function getStaffTimetable({ staffId, schoolId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const entries = await repo.findTimetableByStaffId(staffId, schoolId);

    const DAY_NAMES = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    // Group by day
    const byDay = {};
    for (const entry of entries) {
        const day = entry.dayOfWeek;
        if (!byDay[day]) byDay[day] = { dayOfWeek: day, dayName: DAY_NAMES[day] || `Day ${day}`, periods: [] };
        byDay[day].periods.push({
            periodNo:    entry.periodNo,
            subject:     entry.subject,
            className:   entry.class_?.name || '',
            sectionName: entry.section?.name || '',
            startTime:   entry.startTime,
            endTime:     entry.endTime,
            room:        entry.room || null,
        });
    }

    const schedule = Object.values(byDay).sort((a, b) => a.dayOfWeek - b.dayOfWeek);
    for (const day of schedule) {
        day.periods.sort((a, b) => a.periodNo - b.periodNo);
    }

    return {
        staffId,
        staffName: `${staff.firstName} ${staff.lastName}`,
        schedule,
    };
}

// ── Leave Management ──────────────────────────────────────────────────────────

export async function getLeaves({ schoolId, page, limit, status, staffId, leaveType, fromDate, toDate, academicYear }) {
    return repo.findLeaves({ schoolId, page, limit, status, staffId, leaveType, fromDate, toDate, academicYear });
}

export async function getLeaveSummary({ schoolId, academicYear, staffId }) {
    // Default academic year: April of current year to March of next year (Indian academic year)
    const resolvedYear = academicYear || getCurrentAcademicYear();
    const counts = await repo.getLeaveCounts(schoolId, resolvedYear, staffId || null);
    return { academic_year: resolvedYear, ...counts };
}

export async function getStaffLeaves({ staffId, schoolId, page, limit, status, academicYear }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    return repo.findLeavesByStaffId(staffId, schoolId, { page, limit, status, academicYear });
}

export async function applyLeave({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const fromDate = new Date(data.fromDate);
    const toDate   = new Date(data.toDate);

    // Validate date order
    if (toDate < fromDate) {
        throw new AppError('to_date must be greater than or equal to from_date', 400);
    }

    // Calculate total days (inclusive)
    const totalDays = Math.round((toDate - fromDate) / (1000 * 60 * 60 * 24)) + 1;

    // Check for overlapping pending/approved leaves (scoped to school to prevent cross-tenant probing)
    const overlap = await repo.findOverlappingLeave(staffId, schoolId, fromDate, toDate);
    if (overlap) {
        throw new AppError('Leave dates overlap with an existing pending or approved leave request', 409);
    }

    const leave = await repo.createLeave({
        staffId,
        schoolId,
        appliedBy: userId,
        leaveType: data.leaveType,
        fromDate,
        toDate,
        totalDays,
        reason: data.reason,
        status: 'PENDING',
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_LEAVE_APPLIED',
        entityType: 'staff_leaves',
        entityId:   leave.id,
        extra:      { staffId, leaveType: data.leaveType, fromDate: data.fromDate, toDate: data.toDate },
    }).catch(() => {});

    return leave;
}

export async function reviewLeave({ leaveId, schoolId, userId, data }) {
    const leave = await repo.findLeaveById(leaveId, schoolId);
    if (!leave) throw new AppError('Leave request not found', 404);

    if (leave.status !== 'PENDING') {
        throw new AppError(`Cannot review a leave that is already ${leave.status}`, 409);
    }

    if (!['APPROVED', 'REJECTED'].includes(data.status)) {
        throw new AppError('status must be APPROVED or REJECTED', 400);
    }

    if (data.status === 'REJECTED' && !data.adminRemark) {
        throw new AppError('adminRemark is required when rejecting a leave', 400);
    }

    const updated = await repo.updateLeaveStatus(leaveId, schoolId, {
        status:     data.status,
        reviewedBy: userId,
        reviewedAt: new Date(),
        adminRemark: data.adminRemark || null,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_LEAVE_REVIEWED',
        entityType: 'staff_leaves',
        entityId:   leaveId,
        extra:      { status: data.status, staffId: leave.staffId },
    }).catch(() => {});

    return updated;
}

export async function cancelLeave({ leaveId, schoolId, userId }) {
    const leave = await repo.findLeaveById(leaveId, schoolId);
    if (!leave) throw new AppError('Leave request not found', 404);

    if (leave.status !== 'PENDING') {
        throw new AppError('Only PENDING leaves can be cancelled', 409);
    }

    // Authorisation: only the staff member who applied the leave OR a school admin may cancel it.
    // The requireSchoolAdmin middleware guarantees the caller holds the school_admin portal role,
    // so all callers reaching this service are already school admins. If this endpoint is ever
    // opened to non-admin staff, re-check: leave.appliedBy === userId.

    const updated = await repo.updateLeaveStatus(leaveId, schoolId, {
        status:     'CANCELLED',
        reviewedBy: userId,
        reviewedAt: new Date(),
        adminRemark: 'Cancelled by admin',
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'STAFF_LEAVE_CANCELLED',
        entityType: 'staff_leaves',
        entityId:   leaveId,
        extra:      { staffId: leave.staffId },
    }).catch(() => {});

    return updated;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function getCurrentAcademicYear() {
    const now   = new Date();
    const month = now.getMonth() + 1; // 1-indexed
    const year  = now.getFullYear();
    // Indian academic year: April (4) to March
    if (month >= 4) {
        return `${year}-${String(year + 1).slice(2)}`;
    }
    return `${year - 1}-${String(year).slice(2)}`;
}

// ── Classes ───────────────────────────────────────────────────────────────────

export async function getClasses({ schoolId }) {
    return repo.findAllClasses(schoolId);
}

export async function createClass({ schoolId, userId, data }) {
    const existing = await repo.findClassByName(data.name, schoolId);
    if (existing) throw new AppError('Class name already exists in this school', 409);

    const schoolClass = await repo.createClass({ schoolId, ...data });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'CLASS_CREATE',
        entityType: 'school_classes',
        entityId:   schoolClass.id,
        entityName: data.name,
    }).catch(() => {});

    return schoolClass;
}

export async function updateClass({ id, schoolId, userId, data }) {
    const existing = await repo.findClassById(id, schoolId);
    if (!existing) throw new AppError('Class not found', 404);

    if (data.name && data.name !== existing.name) {
        const duplicate = await repo.findClassByName(data.name, schoolId);
        if (duplicate) throw new AppError('Class name already exists in this school', 409);
    }

    const updated = await repo.updateClass(id, schoolId, data);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'CLASS_UPDATE',
        entityType: 'school_classes',
        entityId:   id,
    }).catch(() => {});

    return updated;
}

export async function deleteClass({ id, schoolId, userId }) {
    const existing = await repo.findClassById(id, schoolId);
    if (!existing) throw new AppError('Class not found', 404);

    await repo.deleteClass(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'CLASS_DELETE',
        entityType: 'school_classes',
        entityId:   id,
    }).catch(() => {});
}

// ── Sections ──────────────────────────────────────────────────────────────────

export async function getSections({ classId, schoolId }) {
    const classRecord = await repo.findClassById(classId, schoolId);
    if (!classRecord) throw new AppError('Class not found', 404);
    return repo.findSectionsByClass(classId, schoolId);
}

export async function createSection({ classId, schoolId, userId, data }) {
    const classRecord = await repo.findClassById(classId, schoolId);
    if (!classRecord) throw new AppError('Class not found', 404);

    const existing = await repo.findSectionByName(data.name, classId);
    if (existing) throw new AppError('Section name already exists for this class', 409);

    if (data.classTeacherId) {
        const staff = await repo.findStaffById(data.classTeacherId, schoolId);
        if (!staff) throw new AppError('Class teacher not found or does not belong to this school', 400);
    }

    const section = await repo.createSection({ schoolId, classId, ...data });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'SECTION_CREATE',
        entityType: 'sections',
        entityId:   section.id,
        entityName: `${classRecord.name} - ${data.name}`,
    }).catch(() => {});

    return section;
}

export async function updateSection({ id, schoolId, userId, data }) {
    const existing = await repo.findSectionById(id, schoolId);
    if (!existing) throw new AppError('Section not found', 404);

    if (data.name && data.name !== existing.name) {
        const duplicate = await repo.findSectionByName(data.name, existing.classId);
        if (duplicate) throw new AppError('Section name already exists for this class', 409);
    }

    const updated = await repo.updateSection(id, schoolId, data);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'SECTION_UPDATE',
        entityType: 'sections',
        entityId:   id,
    }).catch(() => {});

    return updated;
}

export async function deleteSection({ id, schoolId, userId }) {
    const existing = await repo.findSectionById(id, schoolId);
    if (!existing) throw new AppError('Section not found', 404);

    await repo.deleteSection(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'SECTION_DELETE',
        entityType: 'sections',
        entityId:   id,
    }).catch(() => {});
}

// ── Attendance ────────────────────────────────────────────────────────────────

export async function getAttendance({ schoolId, classId, sectionId, date }) {
    if (!date) throw new AppError('date query parameter is required', 400);
    return repo.findAttendanceForDate({ schoolId, classId, sectionId, date });
}

export async function bulkMarkAttendance({ schoolId, userId, sectionId, date, records }) {
    // Validate section belongs to this school
    const section = await repo.findSectionById(sectionId, schoolId);
    if (!section) throw new AppError('Section not found', 404);

    const saved = await Promise.all(
        records.map((r) =>
            repo.upsertAttendanceRecord({
                studentId: r.studentId,
                schoolId,
                sectionId,
                date,
                status:   r.status,
                markedBy: userId,
                remarks:  r.remarks || null,
            })
        )
    );

    return { saved: saved.length, date, section_name: section.name };
}

export async function getAttendanceReport({ schoolId, classId, sectionId, month }) {
    if (!month) throw new AppError('month query parameter is required (format: YYYY-MM)', 400);

    const records = await repo.findAttendanceReport({ schoolId, classId, sectionId, month });

    // Aggregate by date
    const byDate = {};
    for (const rec of records) {
        const dateKey = rec.date.toISOString().split('T')[0];
        if (!byDate[dateKey]) byDate[dateKey] = { date: dateKey, present: 0, absent: 0, late: 0 };
        if (rec.status === 'PRESENT') byDate[dateKey].present++;
        else if (rec.status === 'ABSENT') byDate[dateKey].absent++;
        else if (rec.status === 'LATE')   byDate[dateKey].late++;
    }

    const calendar = Object.values(byDate).sort((a, b) => a.date.localeCompare(b.date));

    const summary = {
        present_days: calendar.reduce((s, d) => s + (d.present > 0 ? 1 : 0), 0),
        absent_days:  calendar.reduce((s, d) => s + (d.absent > 0 ? 1 : 0), 0),
        total_days:   calendar.length,
    };

    return { calendar, summary };
}

// ── Fee Structures ────────────────────────────────────────────────────────────

export async function getFeeStructures({ schoolId, academicYear, classId }) {
    return repo.findFeeStructures({ schoolId, academicYear, classId });
}

export async function createFeeStructure({ schoolId, userId, data }) {
    const structure = await repo.createFeeStructure({ schoolId, ...data });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'FEE_STRUCTURE_CREATE',
        entityType: 'fee_structures',
        entityId:   structure.id,
        entityName: data.feeHead,
    }).catch(() => {});

    return structure;
}

export async function updateFeeStructure({ id, schoolId, userId, data }) {
    const existing = await repo.findFeeStructureById(id, schoolId);
    if (!existing) throw new AppError('Fee structure not found', 404);

    const updated = await repo.updateFeeStructure(id, schoolId, data);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'FEE_STRUCTURE_UPDATE',
        entityType: 'fee_structures',
        entityId:   id,
    }).catch(() => {});

    return updated;
}

export async function deleteFeeStructure({ id, schoolId, userId }) {
    const existing = await repo.findFeeStructureById(id, schoolId);
    if (!existing) throw new AppError('Fee structure not found', 404);

    await repo.deleteFeeStructure(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'FEE_STRUCTURE_DELETE',
        entityType: 'fee_structures',
        entityId:   id,
    }).catch(() => {});
}

// ── Fee Payments ──────────────────────────────────────────────────────────────

export async function getFeePayments({ schoolId, page, limit, studentId, month, academicYear }) {
    return repo.findFeePayments({ schoolId, page, limit, studentId, month, academicYear });
}

export async function getFeePaymentById({ id, schoolId }) {
    const payment = await repo.findFeePaymentById(id, schoolId);
    if (!payment) throw new AppError('Fee payment not found', 404);
    return payment;
}

export async function createFeePayment({ schoolId, userId, data }) {
    // Ensure receipt number is unique within the school
    const duplicate = await repo.findFeePaymentByReceiptNo(data.receiptNo, schoolId);
    if (duplicate) throw new AppError('Receipt number already exists', 409);

    const payment = await repo.createFeePayment({
        schoolId,
        collectedBy: userId,
        ...data,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'FEE_PAYMENT_CREATE',
        entityType: 'fee_payments',
        entityId:   payment.id,
        entityName: data.receiptNo,
        extra:      { amount: data.amount, studentId: data.studentId },
    }).catch(() => {});

    return payment;
}

export async function getFeeSummary({ schoolId, month }) {
    const now = new Date();
    const defaultMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const monthToUse = month || defaultMonth;

    const rows = await repo.getFeeSummary({ schoolId, month: monthToUse });

    // Format into grouped summary
    const byFeeHead = {};
    let grandTotal = 0;

    for (const row of rows) {
        const amount = Number(row._sum.amount ?? 0);
        grandTotal += amount;
        if (!byFeeHead[row.feeHead]) {
            byFeeHead[row.feeHead] = { feeHead: row.feeHead, total: 0, breakdown: [] };
        }
        byFeeHead[row.feeHead].total += amount;
        byFeeHead[row.feeHead].breakdown.push({
            paymentMode: row.paymentMode,
            amount,
            count: row._count.id,
        });
    }

    return {
        month: monthToUse,
        grand_total: grandTotal,
        by_fee_head: Object.values(byFeeHead),
    };
}

// ── Timetable ─────────────────────────────────────────────────────────────────

export async function getTimetable({ schoolId, classId, sectionId }) {
    if (!classId) throw new AppError('classId query parameter is required', 400);
    return repo.findTimetable({ schoolId, classId, sectionId });
}

export async function bulkUpdateTimetable({ schoolId, userId, classId, sectionId, entries }) {
    const classRecord = await repo.findClassById(classId, schoolId);
    if (!classRecord) throw new AppError('Class not found', 404);

    const result = await repo.replaceTimetable({ schoolId, classId, sectionId, entries });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'TIMETABLE_UPDATE',
        entityType: 'timetables',
        entityId:   classId,
        entityName: classRecord.name,
        extra:      { entriesCount: entries.length, sectionId },
    }).catch(() => {});

    return result;
}

// ── Notices ───────────────────────────────────────────────────────────────────

export async function getNotices({ schoolId, page, limit, search }) {
    return repo.findNotices({ schoolId, page, limit, search });
}

export async function createNotice({ schoolId, userId, data }) {
    const notice = await repo.createNotice({
        schoolId,
        createdBy: userId,
        ...data,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NOTICE_CREATE',
        entityType: 'school_notices',
        entityId:   notice.id,
        entityName: data.title,
    }).catch(() => {});

    // Socket.IO — real-time for foreground clients
    try {
        const io = getIO();
        io.to(`school:${schoolId}`).emit('notice:new', {
            type:       'school_notice',
            targetRole: data.targetRole || 'all',
            notice:     {
                id:        notice.id,
                title:     data.title,
                body:      data.body,
                createdAt: notice.createdAt?.toISOString?.() || new Date().toISOString(),
            },
        });
    } catch (err) {
        // Socket emit failure should not fail the request
    }

    // FCM push — foreground, background, terminated (parents/students on mobile)
    try {
        const { parentTokens, studentTokens } = await fcmRepo.getTokensForSchoolNotice({
            schoolId,
            targetRole: data.targetRole,
        });
        const title = data.title || 'New notice';
        const body = (data.body || '').slice(0, 100);
        const baseData = { type: 'notice', noticeId: notice.id };
        if (parentTokens.length > 0) {
            await sendFcmToTokens(parentTokens, {
                title,
                body,
                data: { ...baseData, portal: 'parent', route: '/parent/notices' },
            });
        }
        if (studentTokens.length > 0) {
            await sendFcmToTokens(studentTokens, {
                title,
                body,
                data: { ...baseData, portal: 'student', route: '/student/notices' },
            });
        }
    } catch (err) {
        // FCM failure should not fail the request
    }

    return notice;
}

export async function updateNotice({ id, schoolId, userId, data }) {
    const existing = await repo.findNoticeById(id, schoolId);
    if (!existing) throw new AppError('Notice not found', 404);

    const updated = await repo.updateNotice(id, schoolId, data);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NOTICE_UPDATE',
        entityType: 'school_notices',
        entityId:   id,
    }).catch(() => {});

    return updated;
}

export async function deleteNotice({ id, schoolId, userId }) {
    const existing = await repo.findNoticeById(id, schoolId);
    if (!existing) throw new AppError('Notice not found', 404);

    await repo.softDeleteNotice(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NOTICE_DELETE',
        entityType: 'school_notices',
        entityId:   id,
    }).catch(() => {});
}

// ── Parents ──────────────────────────────────────────────────────────────────

export async function searchParents({ schoolId, page, limit, search }) {
    const result = await repo.findParents({ schoolId, page, limit, search });
    const parents = result.data.map((p) => ({
        id:        p.id,
        firstName: p.firstName,
        lastName:  p.lastName,
        phone:     p.phone,
        email:     p.email,
        relation:  p.relation,
        _count:    { links: p._count?.links ?? 0 },
    }));
    return { parents, pagination: result.pagination };
}

export async function createParent({ schoolId, userId, data }) {
    const { normalizePhone } = await import('../../utils/phone.js');
    const phone = normalizePhone(data.phone) || data.phone;
    if (!phone) throw new AppError('Valid phone number is required', 400);

    // phone must be unique per school
    const existing = await repo.findParentByPhone(phone, schoolId);
    if (existing) throw new AppError('A parent with this phone number already exists in this school', 409);

    const parent = await repo.createParent({
        schoolId,
        firstName: data.firstName,
        lastName:  data.lastName,
        phone,
        email:     data.email || null,
        relation:  data.relation || null,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'PARENT_CREATE',
        entityType: 'parents',
        entityId:   parent.id,
        entityName: `${parent.firstName} ${parent.lastName}`,
    }).catch(() => {});

    return parent;
}

export async function getParentById({ id, schoolId }) {
    const parent = await repo.findParentById(id, schoolId);
    if (!parent) throw new AppError('Parent not found', 404);

    // Format linked children
    const linkedChildren = (parent.links || []).map((link) => ({
        linkId:      link.id,
        studentId:   link.student.id,
        firstName:   link.student.firstName,
        lastName:    link.student.lastName,
        admissionNo: link.student.admissionNo,
        className:   link.student.class_?.name ?? null,
        sectionName: link.student.section?.name ?? null,
        isPrimary:   link.isPrimary,
        linkRelation: link.relation,
    }));

    const { links: _links, ...parentData } = parent;
    return { ...parentData, linkedChildren };
}

export async function updateParent({ id, schoolId, userId, data }) {
    const existing = await repo.findParentById(id, schoolId);
    if (!existing) throw new AppError('Parent not found', 404);

    // phone NOT changeable
    const { phone: _drop, ...updateData } = data;
    const updated = await repo.updateParent(id, schoolId, updateData);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'PARENT_UPDATE',
        entityType: 'parents',
        entityId:   id,
        entityName: `${updated.firstName} ${updated.lastName}`,
    }).catch(() => {});

    return updated;
}

export async function getStudentParents({ studentId, schoolId }) {
    // Verify student exists in school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const links = await repo.findStudentParentLinks(studentId);
    return links.map((link) => ({
        linkId:       link.id,
        parentId:     link.parent.id,
        firstName:    link.parent.firstName,
        lastName:     link.parent.lastName,
        phone:        link.parent.phone,
        email:        link.parent.email,
        relation:     link.parent.relation,
        isPrimary:    link.isPrimary,
        linkRelation: link.relation,
    }));
}

export async function linkParentToStudent({ studentId, schoolId, userId, data }) {
    // Verify student exists in school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    let parent;

    if (data.parentId) {
        // Link existing parent
        parent = await repo.findParentById(data.parentId, schoolId);
        if (!parent) throw new AppError('Parent not found in this school', 404);
    } else if (data.phone) {
        const { normalizePhone } = await import('../../utils/phone.js');
        const phone = normalizePhone(data.phone) || data.phone;
        if (!phone) throw new AppError('Valid phone number is required', 400);

        // Search for existing parent by phone, or create new
        parent = await repo.findParentByPhone(phone, schoolId);
        if (!parent) {
            if (!data.firstName || !data.lastName) {
                throw new AppError('firstName and lastName are required when creating a new parent', 400);
            }
            parent = await repo.createParent({
                schoolId,
                firstName: data.firstName,
                lastName:  data.lastName,
                phone,
                email:     data.email || null,
                relation:  data.relation || null,
            });
        }
    }

    // Check for duplicate link
    const existingLink = await repo.findStudentParentLink(studentId, parent.id);
    if (existingLink) throw new AppError('This parent is already linked to this student', 409);

    // If first parent being linked, auto-set isPrimary=true
    const linkCount = await repo.countStudentParentLinks(studentId);
    const isPrimary = data.isPrimary ?? (linkCount === 0);

    // If setting isPrimary, clear others first
    if (isPrimary && linkCount > 0) {
        await repo.clearPrimaryForStudent(studentId);
    }

    const link = await repo.createStudentParentLink({
        studentId,
        parentId:  parent.id,
        relation:  data.linkRelation,
        isPrimary,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'PARENT_LINK_CREATE',
        entityType: 'student_parents',
        entityId:   link.id,
        extra:      { studentId, parentId: parent.id, relation: data.linkRelation },
    }).catch(() => {});

    return {
        linkId:  link.id,
        parentId: parent.id,
        student: link.student,
        parent:  link.parent,
    };
}

export async function updateParentLink({ studentId, parentId, schoolId, userId, data }) {
    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const link = await repo.findStudentParentLink(studentId, parentId);
    if (!link) throw new AppError('Parent-student link not found', 404);

    const updateData = {};
    if (data.relation !== undefined) updateData.relation = data.relation;

    if (data.isPrimary === true) {
        // Clear all other primaries for this student first
        await repo.clearPrimaryForStudent(studentId);
        updateData.isPrimary = true;
    } else if (data.isPrimary === false) {
        updateData.isPrimary = false;
    }

    const updated = await repo.updateStudentParentLink(link.id, updateData);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'PARENT_LINK_UPDATE',
        entityType: 'student_parents',
        entityId:   link.id,
        extra:      { studentId, parentId },
    }).catch(() => {});

    return updated;
}

export async function unlinkParentFromStudent({ studentId, parentId, schoolId, userId }) {
    // Verify student belongs to school
    const student = await repo.findStudentById(studentId, schoolId);
    if (!student) throw new AppError('Student not found', 404);

    const link = await repo.findStudentParentLink(studentId, parentId);
    if (!link) throw new AppError('Parent-student link not found', 404);

    const wasPrimary = link.isPrimary;
    await repo.deleteStudentParentLink(link.id);

    // If deleted link was primary and other links exist, set next as primary
    if (wasPrimary) {
        const remaining = await repo.countStudentParentLinks(studentId);
        if (remaining > 0) {
            const nextLink = await repo.findFirstStudentParentLink(studentId);
            if (nextLink) {
                await repo.updateStudentParentLink(nextLink.id, { isPrimary: true });
            }
        }
    }

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'PARENT_LINK_DELETE',
        entityType: 'student_parents',
        entityId:   link.id,
        extra:      { studentId, parentId },
    }).catch(() => {});
}

// ── Notifications (stub — no DB model yet) ────────────────────────────────────

export async function getNotifications({ schoolId, page = 1, limit = 20 }) {
    // No Notification model in schema yet; return empty list gracefully
    return {
        data: [],
        pagination: { page, limit, total: 0, total_pages: 0 },
    };
}

export async function getUnreadNotificationCount({ schoolId }) {
    return { unread_count: 0 };
}

export async function markNotificationRead({ id, schoolId }) {
    // No-op until Notification model is added
    return { id, read: true };
}

// ── Profile ───────────────────────────────────────────────────────────────────

export async function getProfile({ userId, schoolId }) {
    const [user, school] = await Promise.all([
        repo.findUserById(userId),
        repo.findSchoolById(schoolId),
    ]);
    if (!user)   throw new AppError('User not found', 404);
    if (!school) throw new AppError('School not found', 404);

    return { user, school };
}

export async function updateUserProfile({ userId, data }) {
    const user = await repo.findUserById(userId);
    if (!user) throw new AppError('User not found', 404);

    const updates = {
        firstName: data.firstName,
        lastName:  data.lastName,
        phone:     data.phone ?? null,
        avatarUrl: data.avatarUrl ?? null,
    };

    if (data.avatar_base64) {
        const avatarsDir = path.join(__dirname, '..', '..', '..', 'uploads', 'avatars');
        if (!fs.existsSync(avatarsDir)) fs.mkdirSync(avatarsDir, { recursive: true });
        const base64 = data.avatar_base64.replace(/^data:image\/\w+;base64,/, '');
        const buf = Buffer.from(base64, 'base64');
        const ext = (data.avatar_base64.match(/^data:image\/(\w+);/) || [null, 'jpeg'])[1] || 'jpeg';
        const filename = `${userId}.${ext}`;
        fs.writeFileSync(path.join(avatarsDir, filename), buf);
        updates.avatarUrl = `/uploads/avatars/${filename}`;
    }

    return repo.updateUser(userId, updates);
}

export async function updateSchoolProfile({ schoolId, userId, data }) {
    const school = await repo.findSchoolById(schoolId);
    if (!school) throw new AppError('School not found', 404);

    const updated = await repo.updateSchool(schoolId, {
        name:    data.name,
        phone:   data.phone,
        email:   data.email,
        address: data.address ?? null,
        city:    data.city ?? null,
        state:   data.state ?? null,
        logoUrl: data.logoUrl ?? null,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'SCHOOL_PROFILE_UPDATE',
        entityType: 'schools',
        entityId:   schoolId,
        entityName: data.name,
    }).catch(() => {});

    return updated;
}

export async function changePassword({ userId, currentPassword, newPassword }) {
    const user = await repo.findUserWithPasswordHash(userId);
    if (!user) throw new AppError('User not found', 404);

    const match = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!match) throw new AppError('Current password is incorrect', 400);

    const hash = await bcrypt.hash(newPassword, 12);
    await repo.updateUser(userId, { passwordHash: hash, passwordChangedAt: new Date() });
}
