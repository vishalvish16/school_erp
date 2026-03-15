/**
 * Non-Teaching Staff Service — business logic layer.
 * All DB calls via repository. schoolId always comes from JWT — never user input.
 */
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/response.js';
import { logger } from '../../config/logger.js';
import * as repo from './non-teaching-staff.repository.js';
import * as auditService from '../audit/audit.service.js';

// ── API Format Helpers ─────────────────────────────────────────────────────

function toRoleApiFormat(r) {
    if (!r) return null;
    return {
        id:           r.id,
        school_id:    r.schoolId,
        code:         r.code,
        display_name: r.displayName,
        category:     r.category,
        is_system:    r.isSystem,
        description:  r.description,
        is_active:    r.isActive,
        staff_count:  r._count?.staff ?? undefined,
        created_at:   r.createdAt,
        updated_at:   r.updatedAt,
    };
}

function toNTStaffApiFormat(s) {
    if (!s) return null;
    return {
        id:                      s.id,
        school_id:               s.schoolId,
        user_id:                 s.userId,
        has_login:               s.userId !== null,
        employee_no:             s.employeeNo,
        first_name:              s.firstName,
        last_name:               s.lastName,
        full_name:               `${s.firstName} ${s.lastName}`,
        gender:                  s.gender,
        date_of_birth:           s.dateOfBirth,
        phone:                   s.phone,
        email:                   s.email,
        department:              s.department,
        designation:             s.designation,
        qualification:           s.qualification,
        join_date:               s.joinDate,
        employee_type:           s.employeeType,
        salary_grade:            s.salaryGrade,
        address:                 s.address,
        city:                    s.city,
        state:                   s.state,
        blood_group:             s.bloodGroup,
        emergency_contact_name:  s.emergencyContactName,
        emergency_contact_phone: s.emergencyContactPhone,
        photo_url:               s.photoUrl,
        is_active:               s.isActive,
        created_at:              s.createdAt,
        updated_at:              s.updatedAt,
        role: s.role ? toRoleApiFormat(s.role) : null,
        user: s.user
            ? {
                  id:         s.user.id,
                  is_active:  s.user.isActive,
                  email:      s.user.email,
                  last_login: s.user.lastLogin,
              }
            : null,
    };
}

function toAttendanceApiFormat(a) {
    if (!a) return null;
    return {
        id:             a.id,
        school_id:      a.schoolId,
        staff_id:       a.staffId,
        date:           a.date,
        status:         a.status,
        check_in_time:  a.checkInTime,
        check_out_time: a.checkOutTime,
        marked_by:      a.markedBy,
        remarks:        a.remarks,
        created_at:     a.createdAt,
        updated_at:     a.updatedAt,
    };
}

function toLeaveApiFormat(l) {
    if (!l) return null;
    return {
        id:           l.id,
        school_id:    l.schoolId,
        staff_id:     l.staffId,
        applied_by:   l.appliedBy,
        reviewed_by:  l.reviewedBy,
        leave_type:   l.leaveType,
        from_date:    l.fromDate,
        to_date:      l.toDate,
        total_days:   l.totalDays,
        reason:       l.reason,
        status:       l.status,
        reviewed_at:  l.reviewedAt,
        admin_remark: l.adminRemark,
        created_at:   l.createdAt,
        updated_at:   l.updatedAt,
        staff: l.staff ? {
            id:          l.staff.id,
            first_name:  l.staff.firstName,
            last_name:   l.staff.lastName,
            employee_no: l.staff.employeeNo,
        } : null,
    };
}

function toDocumentApiFormat(d) {
    if (!d) return null;
    return {
        id:            d.id,
        school_id:     d.schoolId,
        staff_id:      d.staffId,
        uploaded_by:   d.uploadedBy,
        verified_by:   d.verifiedBy,
        document_type: d.documentType,
        document_name: d.documentName,
        file_url:      d.fileUrl,
        file_size_kb:  d.fileSizeKb,
        mime_type:     d.mimeType,
        verified:      d.verified,
        verified_at:   d.verifiedAt,
        created_at:    d.createdAt,
    };
}

function toQualificationApiFormat(q) {
    if (!q) return null;
    return {
        id:                  q.id,
        school_id:           q.schoolId,
        staff_id:            q.staffId,
        degree:              q.degree,
        institution:         q.institution,
        board_or_university: q.boardOrUniversity,
        year_of_passing:     q.yearOfPassing,
        grade_or_percentage: q.gradeOrPercentage,
        is_highest:          q.isHighest,
        created_at:          q.createdAt,
        updated_at:          q.updatedAt,
    };
}

// ── Roles ──────────────────────────────────────────────────────────────────

export async function getRoles({ schoolId, includeInactive }) {
    if (!schoolId) throw new AppError('School context required', 400);
    const flag = includeInactive === 'true' || includeInactive === true;
    const rows = await repo.findRoles({ schoolId, includeInactive: flag });
    return rows.map(toRoleApiFormat);
}

export async function createRole({ schoolId, userId, data }) {
    if (!schoolId) throw new AppError('School context required', 400);

    const validCategories = ['FINANCE', 'LIBRARY', 'LABORATORY', 'ADMIN_SUPPORT', 'GENERAL'];
    if (!validCategories.includes(data.category)) {
        throw new AppError(`Invalid category. Must be one of: ${validCategories.join(', ')}`, 400);
    }

    const existing = await repo.findRoleByCode(data.code, schoolId);
    if (existing) throw new AppError('A role with this code already exists in your school', 409);

    const systemConflict = await repo.findSystemRoleByCode(data.code);
    if (systemConflict) throw new AppError('Role code conflicts with a system role', 409);

    const role = await repo.createRole({
        code:        data.code,
        displayName: data.display_name,
        category:    data.category,
        description: data.description || null,
        schoolId,
        isSystem:    false,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_ROLE_CREATE',
        entityType: 'non_teaching_staff_roles',
        entityId:   role.id,
        entityName: role.displayName,
        extra:      { code: role.code, category: role.category, schoolId },
    }).catch(() => {});

    return toRoleApiFormat(role);
}

export async function updateRole({ roleId, schoolId, userId, data }) {
    const role = await repo.findRoleById(roleId, schoolId);
    if (!role) throw new AppError('Role not found', 404);
    if (role.isSystem) throw new AppError('System roles cannot be modified', 403);

    const updateData = {};
    if (data.display_name !== undefined) updateData.displayName = data.display_name;
    if (data.description  !== undefined) updateData.description  = data.description;

    const updated = await repo.updateRole(roleId, schoolId, updateData);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_ROLE_UPDATE',
        entityType: 'non_teaching_staff_roles',
        entityId:   roleId,
        entityName: updated.displayName,
        extra:      { schoolId, changes: data },
    }).catch(() => {});

    return toRoleApiFormat(updated);
}

export async function toggleRole({ roleId, schoolId, userId }) {
    const role = await repo.findRoleById(roleId, schoolId);
    if (!role) throw new AppError('Role not found', 404);
    if (role.isSystem) throw new AppError('System roles cannot be toggled', 403);

    const updated = await repo.toggleRole(roleId, schoolId, role.isActive);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_ROLE_TOGGLE',
        entityType: 'non_teaching_staff_roles',
        entityId:   roleId,
        entityName: role.displayName,
        extra:      { schoolId, newIsActive: updated.isActive },
    }).catch(() => {});

    return toRoleApiFormat(updated);
}

export async function deleteRole({ roleId, schoolId, userId }) {
    const role = await repo.findRoleById(roleId, schoolId);
    if (!role) throw new AppError('Role not found', 404);
    if (role.isSystem) throw new AppError('System roles cannot be deleted', 403);

    const staffCount = await repo.countStaffByRole(roleId, schoolId);
    if (staffCount > 0) {
        throw new AppError(
            `Cannot delete role with ${staffCount} active staff assigned. Reassign them first.`,
            409
        );
    }

    const result = await repo.deleteRole(roleId, schoolId);
    if (!result || result.count === 0) throw new AppError('Role not found or already deleted', 404);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_ROLE_DELETE',
        entityType: 'non_teaching_staff_roles',
        entityId:   roleId,
        entityName: role.displayName,
        extra:      { schoolId },
    }).catch(() => {});

    return { deleted: true };
}

// ── Staff ──────────────────────────────────────────────────────────────────

export async function getStaff({ schoolId, page, limit, search, roleId, category, department, employeeType, isActive, sortBy, sortOrder }) {
    if (!schoolId) throw new AppError('School context required', 400);
    const result = await repo.findStaff({ schoolId, page, limit, search, roleId, category, department, employeeType, isActive, sortBy, sortOrder });
    return {
        data:       (result.data || []).map(toNTStaffApiFormat),
        pagination: result.pagination,
    };
}

export async function generateEmployeeNo({ schoolId }) {
    if (!schoolId) throw new AppError('School context required', 400);
    const suggested = await repo.generateEmployeeNo(schoolId);
    return { employee_no: suggested };
}

export async function exportStaff({ schoolId, query }) {
    // CSV export stub — returns null to signal caller to send 501
    return null;
}

export async function createStaff({ schoolId, userId, data }) {
    if (!schoolId) throw new AppError('School context required', 400);

    // Auto-generate employeeNo if not provided
    let employeeNo = (data.employee_no || '').trim();
    if (!employeeNo) {
        employeeNo = await repo.generateEmployeeNo(schoolId);
    }

    // Validate roleId — must exist for this school (school custom or system)
    const role = await repo.findRoleById(data.role_id, schoolId);
    if (!role) throw new AppError('Invalid role: role not found for this school', 400);

    // Check email uniqueness within school
    const existingEmail = await repo.findStaffByEmail(data.email, schoolId);
    if (existingEmail) throw new AppError('A staff member with this email already exists in this school', 409);

    // Check employeeNo uniqueness within school
    const existingEmpNo = await repo.findStaffByEmployeeNo(employeeNo, schoolId);
    if (existingEmpNo) throw new AppError('Employee number already exists in this school', 409);

    const staff = await repo.createStaff({
        schoolId,
        roleId:               data.role_id,
        employeeNo,
        firstName:            data.first_name,
        lastName:             data.last_name,
        gender:               data.gender,
        dateOfBirth:          data.date_of_birth ? new Date(data.date_of_birth) : null,
        phone:                data.phone                   || null,
        email:                data.email,
        department:           data.department              || null,
        designation:          data.designation             || null,
        qualification:        data.qualification           || null,
        joinDate:             new Date(data.join_date),
        employeeType:         data.employee_type           || 'PERMANENT',
        salaryGrade:          data.salary_grade            || null,
        address:              data.address                 || null,
        city:                 data.city                   || null,
        state:                data.state                  || null,
        bloodGroup:           data.blood_group             || null,
        emergencyContactName: data.emergency_contact_name  || null,
        emergencyContactPhone: data.emergency_contact_phone || null,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_STAFF_CREATE',
        entityType: 'non_teaching_staff',
        entityId:   staff.id,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { employeeNo, roleId: data.role_id, schoolId },
    }).catch(() => {});

    return toNTStaffApiFormat(staff);
}

export async function getStaffById({ id, schoolId }) {
    if (!schoolId) throw new AppError('School context required', 400);
    const staff = await repo.findStaffById(id, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    return toNTStaffApiFormat(staff);
}

export async function updateStaff({ id, schoolId, userId, data }) {
    const staff = await repo.findStaffById(id, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const updateData = {};
    if (data.role_id                 !== undefined) updateData.roleId               = data.role_id;
    if (data.first_name              !== undefined) updateData.firstName             = data.first_name;
    if (data.last_name               !== undefined) updateData.lastName              = data.last_name;
    if (data.gender                  !== undefined) updateData.gender                = data.gender;
    if (data.date_of_birth           !== undefined) updateData.dateOfBirth           = data.date_of_birth ? new Date(data.date_of_birth) : null;
    if (data.phone                   !== undefined) updateData.phone                 = data.phone                   || null;
    if (data.email                   !== undefined) updateData.email                 = data.email;
    if (data.department              !== undefined) updateData.department            = data.department              || null;
    if (data.designation             !== undefined) updateData.designation           = data.designation             || null;
    if (data.qualification           !== undefined) updateData.qualification         = data.qualification           || null;
    if (data.join_date               !== undefined) updateData.joinDate              = new Date(data.join_date);
    if (data.employee_type           !== undefined) updateData.employeeType          = data.employee_type;
    if (data.salary_grade            !== undefined) updateData.salaryGrade           = data.salary_grade            || null;
    if (data.address                 !== undefined) updateData.address               = data.address                 || null;
    if (data.city                    !== undefined) updateData.city                  = data.city                    || null;
    if (data.state                   !== undefined) updateData.state                 = data.state                   || null;
    if (data.blood_group             !== undefined) updateData.bloodGroup            = data.blood_group             || null;
    if (data.emergency_contact_name  !== undefined) updateData.emergencyContactName  = data.emergency_contact_name  || null;
    if (data.emergency_contact_phone !== undefined) updateData.emergencyContactPhone = data.emergency_contact_phone || null;

    // Email uniqueness check if email is changing
    if (data.email && data.email !== staff.email) {
        const existingEmail = await repo.findStaffByEmail(data.email, schoolId);
        if (existingEmail && existingEmail.id !== id) {
            throw new AppError('A staff member with this email already exists in this school', 409);
        }
    }

    const updated = await repo.updateStaff(id, schoolId, updateData);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_STAFF_UPDATE',
        entityType: 'non_teaching_staff',
        entityId:   id,
        entityName: `${updated.firstName} ${updated.lastName}`,
        extra:      { schoolId, changes: Object.keys(data) },
    }).catch(() => {});

    return toNTStaffApiFormat(updated);
}

export async function deleteStaff({ id, schoolId, userId }) {
    const staff = await repo.findStaffById(id, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    await repo.softDeleteStaff(id, schoolId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_STAFF_DELETE',
        entityType: 'non_teaching_staff',
        entityId:   id,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { schoolId },
    }).catch(() => {});

    return { deleted: true };
}

export async function updateStaffStatus({ id, schoolId, userId, isActive }) {
    const staff = await repo.findStaffById(id, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const updated = await repo.updateStaff(id, schoolId, { isActive });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_STAFF_STATUS_UPDATE',
        entityType: 'non_teaching_staff',
        entityId:   id,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { schoolId, isActive },
    }).catch(() => {});

    return toNTStaffApiFormat(updated);
}

export async function createStaffLogin({ staffId, schoolId, userId, password }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    if (staff.userId) throw new AppError('Portal login already exists for this staff member', 409);

    // Check no other user has this email
    const existingUser = await repo.findUserByEmail(staff.email);
    if (existingUser) throw new AppError('A user account with this email already exists', 409);

    // Resolve the 'staff' role from the roles table
    const staffRole = await repo.findRoleByName('staff')
        || await repo.findRoleByName('teacher')
        || await repo.findRoleByName('school_admin');
    if (!staffRole) throw new AppError('Staff role not found in system roles table', 500);

    const passwordHash = await bcrypt.hash(password, 12);
    const { user: newUser } = await repo.createUserAndLinkStaff({
        staff,
        passwordHash,
        schoolId,
        roleId: staffRole.id,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_STAFF_LOGIN_CREATE',
        entityType: 'non_teaching_staff',
        entityId:   staffId,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { schoolId, newUserId: newUser.id },
    }).catch(() => {});

    return { message: 'Portal login created successfully', user_id: newUser.id };
}

export async function resetStaffPassword({ staffId, schoolId, userId, newPassword }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);
    if (!staff.userId) throw new AppError('No portal login exists for this staff member', 400);

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await repo.updateUserPassword(staff.userId, passwordHash);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_STAFF_PASSWORD_RESET',
        entityType: 'non_teaching_staff',
        entityId:   staffId,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { schoolId },
    }).catch(() => {});

    return { message: 'Password reset successfully' };
}

// ── Qualifications ─────────────────────────────────────────────────────────

export async function getQualifications({ staffId, schoolId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const rows = await repo.findQualifications(staffId, schoolId);
    return rows.map(toQualificationApiFormat);
}

export async function addQualification({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    // If new qualification is highest, unset all previous highest flags
    if (data.is_highest) {
        await repo.unsetHighestQualification(staffId, schoolId);
    }

    const qual = await repo.createQualification({
        staffId,
        schoolId,
        degree:            data.degree,
        institution:       data.institution,
        boardOrUniversity: data.board_or_university || null,
        yearOfPassing:     data.year_of_passing     || null,
        gradeOrPercentage: data.grade_or_percentage || null,
        isHighest:         data.is_highest          || false,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_QUALIFICATION_ADD',
        entityType: 'non_teaching_staff_qualifications',
        entityId:   qual.id,
        entityName: `${staff.firstName} ${staff.lastName} — ${qual.degree}`,
        extra:      { staffId, schoolId },
    }).catch(() => {});

    return toQualificationApiFormat(qual);
}

export async function updateQualification({ staffId, qualId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const qual = await repo.findQualificationById(qualId, staffId, schoolId);
    if (!qual) throw new AppError('Qualification not found', 404);

    const updateData = {};
    if (data.degree             !== undefined) updateData.degree            = data.degree;
    if (data.institution        !== undefined) updateData.institution       = data.institution;
    if (data.board_or_university !== undefined) updateData.boardOrUniversity = data.board_or_university || null;
    if (data.year_of_passing    !== undefined) updateData.yearOfPassing     = data.year_of_passing     || null;
    if (data.grade_or_percentage !== undefined) updateData.gradeOrPercentage = data.grade_or_percentage || null;
    if (data.is_highest         !== undefined) {
        if (data.is_highest) await repo.unsetHighestQualification(staffId, schoolId);
        updateData.isHighest = data.is_highest;
    }

    const updated = await repo.updateQualification(qualId, staffId, schoolId, updateData);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_QUALIFICATION_UPDATE',
        entityType: 'non_teaching_staff_qualifications',
        entityId:   qualId,
        entityName: `${staff.firstName} ${staff.lastName} — ${updated.degree}`,
        extra:      { staffId, schoolId },
    }).catch(() => {});

    return toQualificationApiFormat(updated);
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
        action:     'NT_QUALIFICATION_DELETE',
        entityType: 'non_teaching_staff_qualifications',
        entityId:   qualId,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { staffId, schoolId },
    }).catch(() => {});

    return { deleted: true };
}

// ── Documents ──────────────────────────────────────────────────────────────

export async function getDocuments({ staffId, schoolId }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const rows = await repo.findDocuments(staffId, schoolId);
    return rows.map(toDocumentApiFormat);
}

export async function addDocument({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const doc = await repo.createDocument({
        staffId,
        schoolId,
        uploadedBy:   userId,
        documentType: data.document_type,
        documentName: data.document_name,
        fileUrl:      data.file_url,
        fileSizeKb:   data.file_size_kb || null,
        mimeType:     data.mime_type    || null,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_DOCUMENT_ADD',
        entityType: 'non_teaching_staff_documents',
        entityId:   doc.id,
        entityName: `${staff.firstName} ${staff.lastName} — ${doc.documentName}`,
        extra:      { staffId, schoolId, documentType: doc.documentType },
    }).catch(() => {});

    return toDocumentApiFormat(doc);
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
        action:     'NT_DOCUMENT_VERIFY',
        entityType: 'non_teaching_staff_documents',
        entityId:   docId,
        entityName: `${staff.firstName} ${staff.lastName} — ${doc.documentName}`,
        extra:      { staffId, schoolId },
    }).catch(() => {});

    return toDocumentApiFormat(updated);
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
        action:     'NT_DOCUMENT_DELETE',
        entityType: 'non_teaching_staff_documents',
        entityId:   docId,
        entityName: `${staff.firstName} ${staff.lastName}`,
        extra:      { staffId, schoolId },
    }).catch(() => {});

    return { deleted: true };
}

// ── Attendance ─────────────────────────────────────────────────────────────

export async function getAttendanceForDate({ schoolId, date, department, category }) {
    if (!schoolId) throw new AppError('School context required', 400);
    if (!date)     throw new AppError('date query parameter is required', 400);

    const result = await repo.findAttendanceForDate({ schoolId, date, department, category });

    return result.map((entry) => ({
        staff:      toNTStaffApiFormat(entry.staff),
        attendance: toAttendanceApiFormat(entry.attendance),
    }));
}

export async function bulkMarkAttendance({ schoolId, userId, date, records }) {
    if (!schoolId) throw new AppError('School context required', 400);

    const staffIds = records.map((r) => r.staff_id);

    const allBelong = await repo.validateStaffBelongToSchool(schoolId, staffIds);
    if (!allBelong) throw new AppError('Some staff IDs do not belong to this school', 400);

    // Normalise snake_case input to camelCase for repository
    const normalisedRecords = records.map((r) => ({
        staffId:      r.staff_id,
        status:       r.status,
        checkInTime:  r.check_in_time  || null,
        checkOutTime: r.check_out_time || null,
        remarks:      r.remarks        || null,
    }));

    const result = await repo.upsertAttendanceBulk({
        schoolId,
        userId,
        date,
        records: normalisedRecords,
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_ATTENDANCE_BULK_MARK',
        entityType: 'non_teaching_staff_attendance',
        entityId:   null,
        entityName: `Bulk attendance for ${date}`,
        extra:      { schoolId, date, count: records.length },
    }).catch(() => {});

    return result;
}

export async function correctAttendance({ id, schoolId, userId, data }) {
    const record = await repo.findAttendanceById(id, schoolId);
    if (!record) throw new AppError('Attendance record not found', 404);

    const updateData = {};
    if (data.status         !== undefined) updateData.status        = data.status;
    if (data.check_in_time  !== undefined) updateData.checkInTime   = data.check_in_time  || null;
    if (data.check_out_time !== undefined) updateData.checkOutTime  = data.check_out_time || null;
    if (data.remarks        !== undefined) updateData.remarks       = data.remarks        || null;

    const updated = await repo.correctAttendance(id, schoolId, updateData, userId);

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_ATTENDANCE_CORRECT',
        entityType: 'non_teaching_staff_attendance',
        entityId:   id,
        entityName: `Attendance correction`,
        extra:      { schoolId, staffId: record.staffId, date: record.date },
    }).catch(() => {});

    return toAttendanceApiFormat(updated);
}

export async function getAttendanceReport({ schoolId, month, staffId, department }) {
    if (!schoolId) throw new AppError('School context required', 400);
    if (!month)    throw new AppError('month query parameter is required (format: YYYY-MM)', 400);

    const [year, mon] = month.split('-').map(Number);
    if (!year || !mon) throw new AppError('Invalid month format. Use YYYY-MM', 400);

    const startDate = new Date(year, mon - 1, 1);
    const endDate   = new Date(year, mon, 0); // last day of month

    const { summary, by_staff } = await repo.getMonthlyAttendanceSummary({
        schoolId,
        startDate,
        endDate,
        staffId:    staffId    || undefined,
        department: department || undefined,
    });

    return { month, summary, by_staff };
}

// ── Leaves ─────────────────────────────────────────────────────────────────

export async function getLeaves({ schoolId, page, limit, status, staffId, leaveType, fromDate, toDate }) {
    if (!schoolId) throw new AppError('School context required', 400);
    const result = await repo.findLeaves({ schoolId, page, limit, status, staffId, leaveType, fromDate, toDate });
    return {
        data:       (result.data || []).map(toLeaveApiFormat),
        pagination: result.pagination,
    };
}

export async function getLeaveSummary({ schoolId, staffId, academicYear }) {
    if (!schoolId) throw new AppError('School context required', 400);

    let startDate, endDate;
    if (academicYear) {
        // Academic year format: 2025-2026
        const [startYear] = academicYear.split('-').map(Number);
        startDate = new Date(startYear, 3, 1);           // April 1
        endDate   = new Date(startYear + 1, 2, 31);      // March 31 next year
    }

    return repo.getLeaveSummary({ schoolId, staffId: staffId || undefined, startDate, endDate });
}

export async function reviewLeave({ leaveId, schoolId, userId, data }) {
    const leave = await repo.findLeaveById(leaveId, schoolId);
    if (!leave) throw new AppError('Leave application not found', 404);
    if (leave.status !== 'PENDING') throw new AppError('Only pending leaves can be reviewed', 400);

    if (data.status === 'REJECTED' && !data.admin_remark) {
        throw new AppError('Admin remark is required when rejecting leave', 400);
    }

    const updated = await repo.updateLeave(leaveId, schoolId, {
        status:      data.status,
        reviewedBy:  userId,
        reviewedAt:  new Date(),
        adminRemark: data.admin_remark || null,
    });

    const action = data.status === 'APPROVED' ? 'NT_LEAVE_APPROVE' : 'NT_LEAVE_REJECT';
    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action,
        entityType: 'non_teaching_staff_leaves',
        entityId:   leaveId,
        entityName: `Leave for staff ${leave.staffId}`,
        extra:      { schoolId, staffId: leave.staffId, status: data.status },
    }).catch(() => {});

    return toLeaveApiFormat(updated);
}

export async function cancelLeave({ leaveId, schoolId, userId }) {
    const leave = await repo.findLeaveById(leaveId, schoolId);
    if (!leave) throw new AppError('Leave application not found', 404);
    if (leave.status !== 'PENDING') throw new AppError('Only pending leaves can be cancelled', 400);

    const updated = await repo.updateLeave(leaveId, schoolId, { status: 'CANCELLED' });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_LEAVE_CANCEL',
        entityType: 'non_teaching_staff_leaves',
        entityId:   leaveId,
        entityName: `Leave for staff ${leave.staffId}`,
        extra:      { schoolId, staffId: leave.staffId },
    }).catch(() => {});

    return toLeaveApiFormat(updated);
}

export async function getStaffLeaves({ staffId, schoolId, query }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const { page = 1, limit = 20, status, leaveType, fromDate, toDate } = query || {};
    const result = await repo.findStaffLeaves({
        staffId,
        schoolId,
        page:  parseInt(page, 10),
        limit: parseInt(limit, 10),
        status,
        leaveType,
        fromDate,
        toDate,
    });

    return {
        data:       (result.data || []).map(toLeaveApiFormat),
        pagination: result.pagination,
    };
}

export async function applyLeaveForStaff({ staffId, schoolId, userId, data }) {
    const staff = await repo.findStaffById(staffId, schoolId);
    if (!staff) throw new AppError('Staff member not found', 404);

    const fromDate  = new Date(data.from_date);
    const toDate    = new Date(data.to_date);

    if (fromDate > toDate) throw new AppError('from_date must be on or before to_date', 400);

    // Calculate total days (inclusive)
    const msPerDay  = 1000 * 60 * 60 * 24;
    const totalDays = Math.round((toDate - fromDate) / msPerDay) + 1;

    // Check overlapping leaves
    const overlap = await repo.findOverlappingLeave(staffId, schoolId, fromDate, toDate);
    if (overlap) throw new AppError('Staff already has an overlapping leave application for this period', 409);

    const leave = await repo.createLeave({
        staffId,
        schoolId,
        appliedBy: userId,
        leaveType: data.leave_type,
        fromDate,
        toDate,
        totalDays,
        reason:    data.reason,
        status:    'PENDING',
    });

    auditService.logAudit({
        actorId:    userId,
        actorRole:  'school_admin',
        action:     'NT_LEAVE_APPLY',
        entityType: 'non_teaching_staff_leaves',
        entityId:   leave.id,
        entityName: `${staff.firstName} ${staff.lastName} — ${data.leave_type}`,
        extra:      { staffId, schoolId, fromDate: data.from_date, toDate: data.to_date, totalDays },
    }).catch(() => {});

    return toLeaveApiFormat(leave);
}
