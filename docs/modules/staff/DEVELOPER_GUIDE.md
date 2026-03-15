# Non-Teaching Staff — Developer Guide

Version: 1.0
Date: 2026-03-15

---

## 1. Architecture Overview

The Non-Teaching Staff module follows the same layered pattern used throughout the Vidyron backend:

```
HTTP Request
    |
    v
non-teaching-staff.routes.js       (middleware chain: verifyAccessToken → requireSchoolAdmin → validate → controller)
    |
    v
non-teaching-staff.controller.js   (HTTP extraction only — pulls school_id from req.user, delegates to service)
    |
    v
non-teaching-staff.service.js      (all business logic, toApiFormat helpers, audit logging)
    |
    v
non-teaching-staff.repository.js   (all Prisma queries, scoped by schoolId)
    |
    v
PostgreSQL (via Prisma ORM)
```

This module is independent of the teaching staff module (`Staff`, `StaffLeave`, etc.) and uses its own set of database tables prefixed `non_teaching_staff_*`. The two staff modules share the same `users` table for portal login accounts and the same auth middleware stack.

The Flutter side follows:

```
School Admin Screen
    |
    v
NonTeachingStaffProvider (Riverpod StateNotifierProvider)
    |
    v
NonTeachingStaffService (Dio HTTP calls, endpoint constants from api_config.dart)
    |
    v
Backend /api/school/non-teaching/*
```

---

## 2. Role System Design

### Why a custom role system

Indian schools use highly varied terminology for the same operational functions. The platform provides a small set of well-known **system roles** (seeded once per platform deploy, `school_id = null`, `is_system = true`) that the platform logic can rely on for category-based access decisions. Schools can then create **custom roles** (`school_id = <their UUID>`, `is_system = false`) to match their local terminology.

### System Roles vs. Custom Roles

| Property | System Role | Custom Role |
|----------|------------|-------------|
| `school_id` | `null` | School UUID |
| `is_system` | `true` | `false` |
| Can be updated | No | Yes (`display_name`, `description` only) |
| Can be deleted | No | Yes (if no staff assigned) |
| Can be toggled | No | Yes |
| Visible to all schools | Yes | This school only |

### Role Categories

Every role (system or custom) belongs to exactly one of these five categories. The category cannot be changed after creation. It determines the staff member's access tier in the staff portal:

| Category | Typical Roles | Portal Access |
|----------|--------------|---------------|
| `ADMIN_SUPPORT` | Office Clerk, Receptionist, Peon | Basic staff portal |
| `FINANCE` | Fee Clerk, Cashier, Accountant | Finance-related views |
| `LIBRARY` | Librarian, Library Assistant | Library module views |
| `LABORATORY` | Lab Assistant, Science Technician | Lab module views |
| `GENERAL` | Security Guard, Sweeper, Driver | General portal only |

### Role Code Uniqueness

- System role codes are unique globally (`schoolId = null, code` is unique).
- Custom role codes are unique per school (`schoolId + code` composite unique constraint in `non_teaching_staff_roles`).
- When creating a custom role, the service checks both tables to prevent a school from shadowing a system code.

---

## 3. Database Tables

Six tables make up this module. All are added in the Prisma schema under `backend/prisma/schema.prisma`.

### Entity Relationship Summary

```
School (1) ──< NonTeachingStaffRole (N)    [school custom roles; system roles have school_id = null]
School (1) ──< NonTeachingStaff (N)
NonTeachingStaffRole (1) ──< NonTeachingStaff (N)
NonTeachingStaff (1) ──<< NonTeachingStaffAttendance (N)   [one record per staff per day]
NonTeachingStaff (1) ──<< NonTeachingStaffLeave (N)
NonTeachingStaff (1) ──<< NonTeachingStaffDocument (N)
NonTeachingStaff (1) ──<< NonTeachingStaffQualification (N)
User (1) ──< NonTeachingStaff (0..1)       [optional portal login link]
```

### non_teaching_staff_roles

| Column | PostgreSQL Type | Constraints | Notes |
|--------|----------------|-------------|-------|
| `id` | `uuid` | PK | |
| `school_id` | `uuid` | FK(schools), nullable | `null` for system roles |
| `code` | `varchar(50)` | UNIQUE(school_id, code) | Uppercase letters and underscores |
| `display_name` | `varchar(100)` | NOT NULL | Human-readable name shown in UI |
| `category` | `staff_role_category_enum` | NOT NULL | `FINANCE`, `LIBRARY`, `LABORATORY`, `ADMIN_SUPPORT`, `GENERAL` |
| `is_system` | `boolean` | NOT NULL, DEFAULT false | Platform seed records have `true` |
| `description` | `text` | nullable | |
| `is_active` | `boolean` | NOT NULL, DEFAULT true | |
| `created_at` | `timestamptz` | DEFAULT now() | |
| `updated_at` | `timestamptz` | auto-updated | |

Indexes: `school_id`.

### non_teaching_staff

| Column | PostgreSQL Type | Constraints | Notes |
|--------|----------------|-------------|-------|
| `id` | `uuid` | PK | |
| `school_id` | `uuid` | FK(schools), NOT NULL | Tenant isolation key |
| `user_id` | `uuid` | FK(users), UNIQUE, nullable | Set when portal login is created |
| `role_id` | `uuid` | FK(non_teaching_staff_roles), NOT NULL | Cascade Restrict — role cannot be deleted while staff exists |
| `employee_no` | `varchar(50)` | UNIQUE(school_id, employee_no) | Auto-generated if not provided |
| `first_name` | `varchar(100)` | NOT NULL | |
| `last_name` | `varchar(100)` | NOT NULL | |
| `gender` | `varchar(10)` | NOT NULL | `MALE`, `FEMALE`, `OTHER` |
| `date_of_birth` | `date` | nullable | |
| `phone` | `varchar(20)` | nullable | |
| `email` | `varchar(255)` | NOT NULL | UNIQUE per school enforced in service layer |
| `department` | `varchar(100)` | nullable | |
| `designation` | `varchar(100)` | nullable | |
| `qualification` | `varchar(255)` | nullable | Short summary; detailed records in qualifications table |
| `join_date` | `date` | NOT NULL | |
| `employee_type` | `varchar(30)` | DEFAULT 'PERMANENT' | `PERMANENT`, `CONTRACT`, `PART_TIME`, `DAILY_WAGE` |
| `salary_grade` | `varchar(50)` | nullable | |
| `address` | `text` | nullable | |
| `city` | `varchar(100)` | nullable | |
| `state` | `varchar(100)` | nullable | |
| `blood_group` | `varchar(5)` | nullable | |
| `emergency_contact_name` | `varchar(100)` | nullable | |
| `emergency_contact_phone` | `varchar(20)` | nullable | |
| `photo_url` | `text` | nullable | |
| `is_active` | `boolean` | DEFAULT true | |
| `deleted_at` | `timestamptz` | nullable | Soft delete marker |
| `created_at` | `timestamptz` | DEFAULT now() | |
| `updated_at` | `timestamptz` | auto-updated | |

Indexes: `school_id`, `(school_id, role_id)`, `(school_id, is_active)`.

### non_teaching_staff_attendance

| Column | PostgreSQL Type | Constraints | Notes |
|--------|----------------|-------------|-------|
| `id` | `uuid` | PK | |
| `school_id` | `uuid` | FK(schools), NOT NULL | |
| `staff_id` | `uuid` | FK(non_teaching_staff), NOT NULL | |
| `date` | `date` | NOT NULL | |
| `status` | `non_teaching_attendance_status_enum` | NOT NULL | `PRESENT`, `ABSENT`, `HALF_DAY`, `ON_LEAVE`, `HOLIDAY`, `LATE` |
| `check_in_time` | `varchar(8)` | nullable | Format `HH:MM` |
| `check_out_time` | `varchar(8)` | nullable | Format `HH:MM` |
| `marked_by` | `uuid` | FK(users), NOT NULL | Admin who last saved/corrected this record |
| `remarks` | `varchar(255)` | nullable | |
| `created_at` | `timestamptz` | DEFAULT now() | |
| `updated_at` | `timestamptz` | auto-updated | |

Unique constraint: `(staff_id, date)` — one record per staff per day, enforced at DB level.
Indexes: `(school_id, date)`, `(school_id, staff_id)`.

The upsert key in Prisma is `staffId_date` (maps to the `@@unique([staffId, date])` constraint).

### non_teaching_staff_leaves

| Column | PostgreSQL Type | Constraints | Notes |
|--------|----------------|-------------|-------|
| `id` | `uuid` | PK | |
| `school_id` | `uuid` | FK(schools), NOT NULL | |
| `staff_id` | `uuid` | FK(non_teaching_staff), NOT NULL | |
| `applied_by` | `uuid` | FK(users), NOT NULL | Admin who created the leave on behalf of staff |
| `reviewed_by` | `uuid` | FK(users), nullable | Admin who approved/rejected |
| `leave_type` | `varchar(30)` | NOT NULL | `CASUAL`, `SICK`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, `COMPENSATORY`, `OTHER` |
| `from_date` | `date` | NOT NULL | |
| `to_date` | `date` | NOT NULL | |
| `total_days` | `smallint` | NOT NULL | Inclusive day count, calculated server-side |
| `reason` | `text` | NOT NULL | |
| `status` | `varchar(20)` | DEFAULT 'PENDING' | `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED` |
| `reviewed_at` | `timestamptz` | nullable | |
| `admin_remark` | `text` | nullable | Required on rejection |
| `created_at` | `timestamptz` | DEFAULT now() | |
| `updated_at` | `timestamptz` | auto-updated | |

Indexes: `school_id`, `staff_id`, `(school_id, status)`, `(school_id, from_date)`.

### non_teaching_staff_documents

| Column | PostgreSQL Type | Constraints | Notes |
|--------|----------------|-------------|-------|
| `id` | `uuid` | PK | |
| `school_id` | `uuid` | FK(schools), NOT NULL | |
| `staff_id` | `uuid` | FK(non_teaching_staff), NOT NULL | |
| `uploaded_by` | `uuid` | FK(users), NOT NULL | Cascade Restrict — uploader record must exist |
| `verified_by` | `uuid` | FK(users), nullable | Admin who verified the document |
| `document_type` | `varchar(50)` | NOT NULL | `AADHAAR`, `PAN`, `DEGREE`, `EXPERIENCE`, `ADDRESS_PROOF`, `PHOTO`, `APPOINTMENT_LETTER`, `OTHER` |
| `document_name` | `varchar(255)` | NOT NULL | |
| `file_url` | `text` | NOT NULL | Must point to approved storage domain |
| `file_size_kb` | `integer` | nullable | |
| `mime_type` | `varchar(100)` | nullable | |
| `verified` | `boolean` | DEFAULT false | |
| `verified_at` | `timestamptz` | nullable | |
| `deleted_at` | `timestamptz` | nullable | Soft delete |
| `created_at` | `timestamptz` | DEFAULT now() | |
| `updated_at` | `timestamptz` | auto-updated | |

Indexes: `school_id`, `staff_id`.

### non_teaching_staff_qualifications

| Column | PostgreSQL Type | Constraints | Notes |
|--------|----------------|-------------|-------|
| `id` | `uuid` | PK | |
| `school_id` | `uuid` | FK(schools), NOT NULL | |
| `staff_id` | `uuid` | FK(non_teaching_staff), NOT NULL | |
| `degree` | `varchar(100)` | NOT NULL | |
| `institution` | `varchar(255)` | NOT NULL | |
| `board_or_university` | `varchar(255)` | nullable | |
| `year_of_passing` | `smallint` | nullable | 1950 to current year |
| `grade_or_percentage` | `varchar(20)` | nullable | |
| `is_highest` | `boolean` | DEFAULT false | Only one record per staff should have `true`; enforced via service-layer unset before set |
| `created_at` | `timestamptz` | DEFAULT now() | |
| `updated_at` | `timestamptz` | auto-updated | |

Indexes: `school_id`, `staff_id`.

---

## 4. Migration Steps

The Non-Teaching Staff models are defined in `backend/prisma/schema.prisma`. After any schema change:

```bash
# From the backend/ directory

# Step 1: Create a new named migration
npx prisma migrate dev --name add_non_teaching_staff_module

# Step 2: Regenerate the Prisma client
npx prisma generate
```

For production deployments, apply pending migrations without prompting:

```bash
npx prisma migrate deploy
```

The migration files are stored under `backend/prisma/migrations/`. The migration for this module should be named with the convention `YYYYMMDDHHMMSS_add_non_teaching_staff_module`.

Enums added by this module:
- `staff_role_category_enum` (`StaffRoleCategory`)
- `non_teaching_attendance_status_enum` (`NonTeachingAttendanceStatus`)

---

## 5. Key Business Rules Enforced in service.js

### Role Management

- **System role protection**: Every mutating role operation (`updateRole`, `toggleRole`, `deleteRole`) checks `role.isSystem === true` and throws a 403 before touching the database.
- **Delete guard**: Before deleting a role, `countStaffByRole` is called. If the count is greater than zero, deletion is blocked with a 409 that tells the caller exactly how many staff to reassign.
- **Code conflict check**: `createRole` checks both `findRoleByCode` (school's own roles) and `findSystemRoleByCode` (platform roles) to prevent shadowing.

### Staff Management

- **Email uniqueness**: Checked per school on create and on update when the email is changing.
- **Employee number**: Auto-generated using `generateEmployeeNo` if the caller omits `employee_no`. Format: `NTS-{YEAR}-{NNN}`.
- **Soft delete**: `deleteStaff` sets `deleted_at` and `is_active = false`. All `findMany` queries include `deletedAt: null` in their `where` clause, so soft-deleted records are invisible to the application.

### Login Creation

- The transaction in `createUserAndLinkStaff` creates the `users` record and sets `nonTeachingStaff.userId` atomically. The update uses `updateMany` scoped by both `staff.id` and `schoolId` to prevent a time-of-check/time-of-use cross-school link if concurrent requests somehow target the same user ID.
- `passwordHash` is never returned in select queries from the repository.

### Attendance

- **Bulk validation**: Before the upsert transaction, `validateStaffBelongToSchool` checks that every `staff_id` in the batch belongs to the calling school. If even one ID is foreign, the entire request is rejected with a 400.
- **Upsert semantics**: The Prisma upsert key is the `@@unique([staffId, date])` composite constraint, so re-submitting the same date simply corrects existing records.

### Leaves

- **Overlap check**: Before creating a leave, `findOverlappingLeave` queries for any existing `PENDING` or `APPROVED` leave for the same staff member that overlaps the requested date range. If found, a 409 is returned.
- **Backdating limit**: `from_date` is validated at the Joi layer. The minimum date is computed as `today minus 7 days` at request time, so the cutoff updates automatically each day without code changes.
- **Rejection requires remark**: The service checks `data.status === 'REJECTED' && !data.admin_remark` and throws a 400 before the database write. This is a business rule enforced in service.js, not in the Joi schema, because the schema accepts `admin_remark` as optional (it is genuinely optional for approvals).
- **Status machine**: Only `PENDING` leaves can be reviewed or cancelled. The service checks `leave.status !== 'PENDING'` and throws a 400.

---

## 6. Security Hardening

### Tenant Isolation

Every repository function receives `schoolId` extracted from `req.user.school_id` (set by `requireSchoolAdmin` middleware). No endpoint accepts `school_id` from the request body or query string. All `findMany`, `update`, and `delete` operations include `schoolId` in the `where` clause. The `updateMany` pattern is used deliberately to scope bulk operations atomically by both the record ID and the `schoolId`.

### Password Hashing

Passwords are hashed with `bcrypt` at 12 rounds in `service.js`. The repository's `createUserAndLinkStaff` uses a Prisma `select` that explicitly excludes `password_hash` from the returned user object. `updateUserPassword` only updates the hash field.

### SSRF Prevention on Document URLs

The `addDocumentSchema` Joi validator enforces two layers:
1. The URL scheme must be `https` (blocks `http:`, `javascript:`, `ftp:`, etc.).
2. The URL hostname must exactly match or be a subdomain of one of the approved storage domains: `storage.googleapis.com`, `s3.amazonaws.com`, `vidyron-storage.s3.ap-south-1.amazonaws.com`, `vidyron.in`. Any other host results in a 422.

### Rate Limiting

Two express-rate-limit instances are applied at the route level:
- `passwordOpLimiter`: 10 requests per 15 minutes per IP on `create-login` and `reset-password`. Prevents brute-forcing password creation.
- `bulkAttendanceLimiter`: 60 requests per 15 minutes per IP on the bulk attendance endpoint.

### Input Validation

Joi schemas use `abortEarly: false` and `stripUnknown: true`. Unknown fields in the request body are silently stripped before reaching the service. Validation failures return HTTP 422 with all field-level messages concatenated.

### Sort Field Allowlist

The `findStaff` repository function maintains an explicit allowlist of sortable fields: `['firstName', 'lastName', 'employeeNo', 'joinDate', 'createdAt', 'department']`. Any `sortBy` value not in this list falls back to `firstName`. This prevents SQL injection through dynamic `ORDER BY` clauses.

---

## 7. Staff Portal Guard Extension

When a non-teaching staff member logs in using their portal credentials, they authenticate through the same `auth` module as other users. The `verifyAccessToken` middleware populates `req.user` with the JWT claims, which include the `roleId` from the `users` table.

The `requireSchoolAdmin` middleware (used for all `/api/school/non-teaching/` routes) blocks non-admin users from these management endpoints. The staff portal's self-service routes (`/api/staff/my/`) use a separate, lighter guard that checks `req.user.roleId` against the staff role (resolved via `findRoleByName('staff')` at login creation time).

The `createUserAndLinkStaff` function resolves the appropriate `roleId` by calling `findRoleByName('staff')` (falling back to `teacher`, then `school_admin` if the `staff` role is not yet seeded). This roleId determines what the user can access after login.

---

## 8. API Response Format: camelCase to snake_case Conversion

Prisma returns data in camelCase (following JavaScript conventions). All API responses must use snake_case (following REST API conventions for this project). Each entity type has a dedicated `toXxxApiFormat` helper function at the top of `service.js`:

- `toRoleApiFormat(r)` — converts `NonTeachingStaffRole` Prisma result
- `toNTStaffApiFormat(s)` — converts `NonTeachingStaff` Prisma result (includes nested `role` and `user`)
- `toAttendanceApiFormat(a)` — converts `NonTeachingStaffAttendance`
- `toLeaveApiFormat(l)` — converts `NonTeachingStaffLeave` (includes nested `staff` summary)
- `toDocumentApiFormat(d)` — converts `NonTeachingStaffDocument`
- `toQualificationApiFormat(q)` — converts `NonTeachingStaffQualification`

These helpers also add computed fields such as `has_login` (derived from `userId !== null`) and `full_name` (concatenation of `firstName` and `lastName`).

---

## 9. How to Add a New Custom Role

From the school admin UI or via direct API call:

```
POST /api/school/non-teaching/roles
Authorization: Bearer <school_admin_access_token>
Content-Type: application/json

{
  "code": "SENIOR_LAB_TECHNICIAN",
  "display_name": "Senior Lab Technician",
  "category": "LABORATORY",
  "description": "Manages chemistry and physics lab equipment and consumables"
}
```

Rules to remember:
- `code` must be `UPPERCASE_WITH_UNDERSCORES` only.
- `category` cannot be changed after creation.
- The `code` must not conflict with any platform system role code.

---

## 10. File Structure

```
backend/src/modules/non-teaching-staff/
├── non-teaching-staff.controller.js   HTTP handlers — extract req params, call service, return successResponse
├── non-teaching-staff.service.js      Business logic, toApiFormat helpers, audit log calls
├── non-teaching-staff.repository.js   All Prisma queries — always scoped by schoolId
├── non-teaching-staff.routes.js       Route registration, middleware chain, rate limiters
└── non-teaching-staff.validation.js   Joi schemas for all request bodies + generic validate() middleware

backend/prisma/schema.prisma
    NonTeachingStaffRole               model (lines ~629-647)
    NonTeachingStaff                   model (lines ~649-692)
    NonTeachingStaffAttendance         model (lines ~694-715)
    NonTeachingStaffLeave              model (lines ~717-744)
    NonTeachingStaffDocument           model (lines ~746-771)
    NonTeachingStaffQualification      model (lines ~773-792)
    StaffRoleCategory                  enum
    NonTeachingAttendanceStatus        enum

backend/src/app.js
    import ntStaffRoutes from './modules/non-teaching-staff/non-teaching-staff.routes.js';
    app.use('/api/school/non-teaching', ntStaffRoutes);

lib/core/services/non_teaching_staff_service.dart    Flutter API calls
lib/core/config/api_config.dart                      Endpoint constants
lib/models/non_teaching_staff/                        Dart models
    non_teaching_staff_model.dart
    non_teaching_staff_role_model.dart
    non_teaching_staff_attendance_model.dart
    non_teaching_staff_leave_model.dart
lib/features/non_teaching_staff/
    data/
        non_teaching_staff_provider.dart              Riverpod StateNotifierProvider
    presentation/
        screens/
            non_teaching_staff_screen.dart
            non_teaching_staff_detail_screen.dart
            attendance_screen.dart
            leaves_screen.dart
        widgets/
            staff_form_dialog.dart
            attendance_row_widget.dart
            leave_review_dialog.dart
```

---

## 11. Key Patterns Reference

### Leave Overlap Check

```javascript
// In non-teaching-staff.repository.js
export async function findOverlappingLeave(staffId, schoolId, fromDate, toDate) {
    return prisma.nonTeachingStaffLeave.findFirst({
        where: {
            staffId,
            schoolId,
            status: { in: ['PENDING', 'APPROVED'] },
            AND: [
                { fromDate: { lte: toDate   } },
                { toDate:   { gte: fromDate } },
            ],
        },
    });
}
```

This uses the standard interval overlap condition: two intervals [A, B] and [C, D] overlap if `A <= D AND B >= C`.

### Employee Number Generation

```javascript
// In non-teaching-staff.repository.js
export async function generateEmployeeNo(schoolId) {
    const year  = new Date().getFullYear();
    const count = await prisma.nonTeachingStaff.count({
        where: {
            schoolId,
            createdAt: { gte: new Date(`${year}-01-01`) },
            deletedAt: null,
        },
    });
    return `NTS-${year}-${String(count + 1).padStart(3, '0')}`;
}
```

The counter resets each calendar year. If a manually entered `employee_no` is provided in the request body, auto-generation is skipped.

### Bulk Attendance Upsert

The repository wraps all upsert operations in a single `prisma.$transaction([...])` call (array form). Each item in the `records` array becomes one `upsert` operation. The unique key for the upsert is the Prisma-mapped `staffId_date` constraint name. All operations succeed or all fail together.

### Audit Logging

Every mutating service function calls `auditService.logAudit(...)` after the database write. The call is fire-and-forget (`.catch(() => {})`) so an audit log failure never causes the main operation to fail. Audit action strings used by this module:

| Action | Trigger |
|--------|---------|
| `NT_ROLE_CREATE` | New custom role created |
| `NT_ROLE_UPDATE` | Custom role display_name/description updated |
| `NT_ROLE_TOGGLE` | Custom role active status toggled |
| `NT_ROLE_DELETE` | Custom role deleted |
| `NT_STAFF_CREATE` | New staff member added |
| `NT_STAFF_UPDATE` | Staff profile updated |
| `NT_STAFF_DELETE` | Staff soft-deleted |
| `NT_STAFF_STATUS_UPDATE` | Staff active status changed |
| `NT_STAFF_LOGIN_CREATE` | Portal login created for staff |
| `NT_STAFF_PASSWORD_RESET` | Staff password reset |
| `NT_QUALIFICATION_ADD` | Qualification added |
| `NT_QUALIFICATION_UPDATE` | Qualification updated |
| `NT_QUALIFICATION_DELETE` | Qualification deleted |
| `NT_DOCUMENT_ADD` | Document attached |
| `NT_DOCUMENT_VERIFY` | Document marked as verified |
| `NT_DOCUMENT_DELETE` | Document soft-deleted |
| `NT_ATTENDANCE_BULK_MARK` | Bulk attendance submitted |
| `NT_ATTENDANCE_CORRECT` | Individual attendance record corrected |
| `NT_LEAVE_APPLY` | Leave applied on behalf of staff |
| `NT_LEAVE_APPROVE` | Leave approved |
| `NT_LEAVE_REJECT` | Leave rejected |
| `NT_LEAVE_CANCEL` | Leave cancelled |

---

## 12. Common Issues and Solutions

| Issue | Likely Cause | Solution |
|-------|-------------|----------|
| 401 on all non-teaching endpoints | Access token expired | Re-authenticate and use the new token |
| 403 on role update/delete | Attempting to modify a system role | Check `is_system` field; only custom roles can be modified |
| 409 on role delete | Staff members still assigned to the role | Reassign or deactivate staff first, then retry |
| 409 on staff create | Duplicate email or employee_no | Use `GET /staff/suggest-employee-no` and check existing staff |
| 409 on leave apply | Overlapping leave exists | Cancel or reject the existing overlapping leave first |
| 422 on leave `from_date` | Date is more than 7 days in the past | Backdating limit is enforced at validation time |
| 422 on document `file_url` | URL points to a non-approved domain | Upload to Vidyron S3 bucket and use the returned URL |
| 400 on bulk attendance | Staff ID from a different school in the records array | Validate all staff IDs belong to the current school before submitting |
| 400 on leave rejection | `admin_remark` is empty or missing | Remark is required when rejecting; it is optional when approving |
