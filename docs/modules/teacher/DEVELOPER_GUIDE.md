# Teacher/Staff Module — Developer Guide

## Module Overview

The Teacher/Staff module manages every person employed at a school within the Vidyron platform. It extends the existing `staff` table with ten new columns and introduces four new database tables. The module is implemented as part of the `school-admin` backend module and the `school_admin` Flutter feature folder.

### What was built

- Staff directory: paginated list with search, designation filter, active/inactive filter, and CSV export
- Staff form: 4-tab create/edit screen (Personal, Employment, Contact, Login)
- Staff detail: 6-tab view (Overview, Qualifications, Documents, Subjects, Timetable, Leaves)
- Qualifications CRUD: inline tab with add/edit/delete; `is_highest` auto-management
- Documents store: metadata-only storage with admin verify workflow and document-type deduplication
- Subject assignments: teacher-to-subject-class mapping with uniqueness enforcement
- Timetable view: read-only weekly grid pulled from the existing `timetables` table
- Leave management: school-wide hub with Pending, All Requests, and Summary tabs
- Leave apply: dedicated form for admin to submit leave on behalf of a staff member
- Two utility endpoints: suggest employee number and check employee number availability

---

## File Structure

### Backend

```
backend/src/modules/school-admin/
├── school-admin.controller.js    HTTP handlers for all school-admin endpoints
├── school-admin.service.js       Business logic and orchestration
├── school-admin.repository.js    Database queries via Prisma
├── school-admin.routes.js        Route definitions and validation middleware wiring
└── school-admin.validation.js    Joi schemas for all request bodies
```

Staff-related Joi schemas in `school-admin.validation.js`:

- `createStaffSchema`
- `updateStaffSchema`
- `updateStaffStatusSchema`
- `addQualificationSchema`
- `updateQualificationSchema`
- `addDocumentSchema`
- `addSubjectAssignmentSchema`
- `applyLeaveSchema`
- `reviewLeaveSchema`
- `createStaffLoginSchema`
- `resetStaffPasswordSchema`

### Flutter

```
lib/
├── core/
│   ├── config/api_config.dart                   Endpoint constants
│   └── services/school_admin_service.dart        All API calls for this module
├── models/school_admin/
│   ├── staff_model.dart                          Extended staff model
│   ├── staff_qualification_model.dart
│   ├── staff_document_model.dart
│   ├── staff_subject_assignment_model.dart
│   ├── staff_leave_model.dart
│   └── staff_timetable_model.dart
└── features/school_admin/presentation/
    ├── providers/
    │   └── school_admin_staff_provider.dart       StateNotifier for staff list
    └── screens/
        ├── school_admin_staff_screen.dart         Staff directory (list)
        ├── school_admin_staff_form_screen.dart    4-tab create/edit form
        ├── school_admin_staff_detail_screen.dart  6-tab detail view
        ├── school_admin_leaves_screen.dart        Leave management hub
        └── school_admin_leave_apply_screen.dart   Apply leave form
```

### Database Migrations

```
backend/prisma/migrations/
├── 20260315000001_extend_staff_table/
├── 20260315000002_create_staff_qualifications/
├── 20260315000003_create_staff_documents/
├── 20260315000004_create_staff_subject_assignments/
└── 20260315000005_create_staff_leaves/
```

---

## Database Schema

### Entity Relationship

```
School (1)
  └── Staff (N)
        ├── StaffQualification (N)    -- academic/professional credentials
        ├── StaffDocument (N)         -- ID proof, certificates (soft-deleted)
        ├── StaffSubjectAssignment (N)
        │     ├── SchoolClass (FK)
        │     └── Section? (FK, nullable)
        └── StaffLeave (N)
              ├── User FK applied_by
              └── User FK reviewed_by (nullable)
```

### staff table (extended)

New columns added via migration `20260315000001_extend_staff_table`:

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| address | TEXT | null | Residential address |
| city | VARCHAR(100) | null | |
| state | VARCHAR(100) | null | |
| blood_group | VARCHAR(5) | null | e.g., `O+` |
| emergency_contact_name | VARCHAR(100) | null | Next of kin |
| emergency_contact_phone | VARCHAR(20) | null | Next of kin phone |
| employee_type | VARCHAR(30) | `PERMANENT` | `PERMANENT`, `CONTRACTUAL`, `PART_TIME`, `PROBATION` |
| department | VARCHAR(100) | null | e.g., `Science`, `Administration` |
| experience_years | SMALLINT | null | Prior experience before joining |
| salary_grade | VARCHAR(50) | null | Pay grade reference |

A partial unique index is also added:
```sql
CREATE UNIQUE INDEX staff_school_email_unique
  ON staff (school_id, email)
  WHERE deleted_at IS NULL;
```

Pre-existing columns include: `id`, `school_id`, `user_id`, `employee_no`, `first_name`, `last_name`, `gender`, `date_of_birth`, `phone`, `email`, `designation`, `subjects[]`, `qualification`, `join_date`, `photo_url`, `is_active`, `deleted_at`, `created_at`, `updated_at`.

### staff_qualifications

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| school_id | UUID | FK → schools.id ON DELETE CASCADE |
| staff_id | UUID | FK → staff.id ON DELETE CASCADE |
| degree | VARCHAR(100) | NOT NULL |
| institution | VARCHAR(255) | NOT NULL |
| board_or_university | VARCHAR(255) | nullable |
| year_of_passing | SMALLINT | nullable |
| grade_or_percentage | VARCHAR(20) | nullable |
| is_highest | BOOLEAN | default false |
| created_at | TIMESTAMPTZ | default now() |
| updated_at | TIMESTAMPTZ | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`

### staff_documents

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| school_id | UUID | FK → schools.id ON DELETE CASCADE |
| staff_id | UUID | FK → staff.id ON DELETE CASCADE |
| document_type | VARCHAR(50) | NOT NULL — `AADHAAR`, `PAN`, `DEGREE`, `EXPERIENCE`, `ADDRESS_PROOF`, `PHOTO`, `OTHER` |
| document_name | VARCHAR(255) | NOT NULL |
| file_url | TEXT | NOT NULL |
| file_size_kb | INTEGER | nullable |
| mime_type | VARCHAR(100) | nullable |
| uploaded_by | UUID | FK → users.id |
| verified | BOOLEAN | default false |
| verified_at | TIMESTAMPTZ | nullable |
| verified_by | UUID | FK → users.id, nullable |
| deleted_at | TIMESTAMPTZ | nullable (soft delete) |
| created_at | TIMESTAMPTZ | default now() |
| updated_at | TIMESTAMPTZ | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`

### staff_subject_assignments

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| school_id | UUID | FK → schools.id ON DELETE CASCADE |
| staff_id | UUID | FK → staff.id ON DELETE CASCADE |
| class_id | UUID | FK → school_classes.id ON DELETE CASCADE |
| section_id | UUID | FK → sections.id ON DELETE SET NULL, nullable |
| subject | VARCHAR(100) | NOT NULL |
| academic_year | VARCHAR(10) | NOT NULL (e.g., `"2025-26"`) |
| is_active | BOOLEAN | default true |
| created_at | TIMESTAMPTZ | default now() |
| updated_at | TIMESTAMPTZ | @updatedAt |

Unique constraint: `(school_id, staff_id, class_id, section_id, subject, academic_year)`
Indexes: `(school_id)`, `(staff_id)`, `(class_id)`

### staff_leaves

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| school_id | UUID | FK → schools.id ON DELETE CASCADE |
| staff_id | UUID | FK → staff.id ON DELETE CASCADE |
| leave_type | VARCHAR(30) | NOT NULL — `CASUAL`, `SICK`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, `OTHER` |
| from_date | DATE | NOT NULL |
| to_date | DATE | NOT NULL |
| total_days | SMALLINT | NOT NULL (calculated server-side) |
| reason | TEXT | NOT NULL |
| status | VARCHAR(20) | default `PENDING` — `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED` |
| applied_by | UUID | FK → users.id |
| reviewed_by | UUID | FK → users.id, nullable |
| reviewed_at | TIMESTAMPTZ | nullable |
| admin_remark | TEXT | nullable |
| created_at | TIMESTAMPTZ | default now() |
| updated_at | TIMESTAMPTZ | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`, `(school_id, status)`, `(school_id, from_date)`

---

## Backend Architecture

All requests follow the same chain:

```
HTTP request
  → verifyAccessToken middleware     (validates JWT, sets req.user)
  → requireSchoolAdmin middleware     (checks portal_type = SCHOOL_ADMIN)
  → validate(schema) middleware       (Joi validation, strips unknown fields)
  → controller function               (extracts params, calls service)
  → service function                  (business rules, orchestrates calls)
  → repository function               (Prisma query, always scoped to school_id)
  → response                          (JSON: { success, data, message })
```

### Route ordering

The routes file places static paths before parameterized paths to prevent Express from misinterpreting named segments. The ordering for staff routes is:

```
GET  /staff                           (list)
GET  /staff/suggest-employee-no       (utility — static, must precede /:id)
GET  /staff/check-employee-no         (utility — static)
GET  /staff/export                    (export — static)
GET  /staff/leaves                    (school-wide leaves — static)
GET  /staff/leaves/summary            (summary — static)
PUT  /staff/leaves/:leaveId/review    (review — static prefix)
PUT  /staff/leaves/:leaveId/cancel    (cancel — static prefix)
POST /staff                           (create)
GET  /staff/:id                       (parameterized — after all statics)
... (all /:id sub-routes follow)
```

This ordering is critical. Adding a new static staff route must be placed before the `POST /staff` line.

---

## Business Rules Reference

The following rules are enforced in the service layer. They represent the authoritative list for code review and testing.

**Staff Core**

1. `employee_no` is case-insensitively unique within a school. The check runs at create and update time.
2. `email` is unique within a school's non-deleted staff records (enforced by the partial unique index `staff_school_email_unique`).
3. `designation` must be one of exactly 11 values: `TEACHER`, `PRINCIPAL`, `VICE_PRINCIPAL`, `HOD`, `CLERK`, `ACCOUNTANT`, `LIBRARIAN`, `LAB_ASSISTANT`, `COUNSELOR`, `SPORTS_COACH`, `OTHER`.
4. Soft delete sets `deleted_at = now()` and `is_active = false`. All findMany queries must include `deletedAt: null` in the Prisma where clause.
5. Deactivating a staff member must also set `is_active = false` on the linked User record.
6. A staff member cannot be soft-deleted if `sections.class_teacher_id` references their ID in any active section. The service checks this before proceeding and returns HTTP 409 with a message instructing the admin to reassign the class teacher first.
7. `photo_url`, when provided, must be a valid HTTPS URI. The Joi schema enforces this with `Joi.string().uri()`.

**Qualifications**

8. Only one qualification per staff member can have `is_highest = true`. When a new qualification is added (or an existing one is updated) with `is_highest: true`, the service runs an update query to set `is_highest = false` on all other qualifications for that staff member before saving the new value.
9. `year_of_passing` must be between 1950 and 2100 (inclusive). The upper bound allows for data entry ahead of time.

**Documents**

10. Only one non-deleted document of each `document_type` is permitted per staff member, except for type `OTHER` where multiple are allowed. When a new document is posted with a type that already has a non-deleted record, the service soft-deletes the existing record before inserting the new one.
11. Accepted file types are `application/pdf`, `image/jpeg`, and `image/png`. This is a client-side constraint enforced in Flutter before upload; the backend does not validate `mime_type` values.
12. Only the SCHOOL_ADMIN role may call `PUT /staff/:staffId/documents/:docId/verify`.

**Subject Assignments**

13. The same `(subject, class_id, section_id, academic_year)` combination cannot be assigned to two active staff members. The service queries for any existing active assignment before inserting and returns HTTP 409 if one is found.
14. `section_id: null` means "all sections of the class." The uniqueness check must treat `null` section correctly — two teachers can only clash if both have `section_id = null` for the same class/subject/year, or both have the same explicit `section_id`.
15. Subject names are free text. The suggested list in the UI is populated from existing timetable records, but the backend does not enforce a controlled vocabulary.

**Leave Management**

16. `from_date` must be today or a future date for non-admin staff applying leave. The Joi schema uses `Joi.date().iso().min(new Date(new Date().setHours(0, 0, 0, 0)))`. School admins applying leave on behalf of a staff member are not subject to this restriction (this distinction is handled at the service layer based on `req.user.role`).
17. `total_days` is calculated as `(to_date - from_date) + 1` inclusive calendar days. Future enhancement: working-day-only count respecting school holiday calendars.
18. A staff member cannot have two PENDING or APPROVED leave records with overlapping date ranges. The service performs an overlap check before inserting and returns HTTP 409 on conflict.
19. Only PENDING leaves can transition to APPROVED or REJECTED. The service validates the current status before updating.
20. Only the staff member (matched via `applied_by === req.user.id`) or a SCHOOL_ADMIN may cancel a PENDING leave.
21. CANCELLED and REJECTED leaves are excluded from the "days taken" count in leave summary calculations.
22. Academic year defaults follow the Indian academic calendar: April 1 of the current year to March 31 of the following year. The default academic year for leave queries is computed server-side.

**Security and Tenant Isolation**

23. Every repository query that touches staff data must include `where: { schoolId: req.user.school_id }`. No endpoint accepts `school_id` from the client.
24. When fetching a staff member by ID (GET /:id and all sub-resources), the service verifies that `staff.school_id === req.user.school_id` and throws a 403 if they do not match.
25. The leave review endpoint (`PUT /staff/leaves/:leaveId/review`) is protected by the `requireSchoolAdmin` middleware. Teacher and clerk roles receive 403.

---

## Flutter Architecture

### State Management

The module uses Riverpod. The pattern differs between the list screen and the detail screens:

**Staff List (`school_admin_staff_provider.dart`)**

```
schoolAdminStaffProvider  →  StateNotifierProvider<StaffListNotifier, StaffListState>
```

The notifier holds: `staff`, `total`, `currentPage`, `totalPages`, `isLoading`, `errorMessage`, `designationFilter`, `isActiveFilter`.

Public methods: `loadStaff()`, `setSearch(String)`, `setDesignationFilter(String?)`, `setActiveFilter(bool?)`, `goToPage(int)`, `createStaff(Map)`, `updateStaff(String, Map)`, `deleteStaff(String)`.

**Staff Detail (`school_admin_staff_detail_screen.dart`)**

Each tab uses an autoDispose family FutureProvider keyed on the staff ID:

```dart
_staffDetailProv     = FutureProvider.autoDispose.family<StaffModel, String>
_staffQualsProv      = FutureProvider.autoDispose.family<List<StaffQualificationModel>, String>
_staffDocsProv       = FutureProvider.autoDispose.family<List<StaffDocumentModel>, String>
_staffSubjectsProv   = FutureProvider.autoDispose.family<List<StaffSubjectAssignmentModel>, String>
_staffTimetableProv  = FutureProvider.autoDispose.family<StaffTimetableModel, String>
_staffLeavesProv     = FutureProvider.autoDispose.family<List<StaffLeaveModel>, String>
```

Mutations (add qualification, verify document, etc.) call the service directly and then call `ref.invalidate(providerName(staffId))` to trigger a fresh fetch.

**Leave Hub (`school_admin_leaves_screen.dart`)**

```
_pendingLeavesProvider   = FutureProvider.autoDispose
_allLeavesProvider       = FutureProvider.autoDispose.family<List<StaffLeaveModel>, _LeavesFilter>
_leaveSummaryProvider    = FutureProvider.autoDispose
```

`_LeavesFilter` is a value-equality class holding `status` and `leaveType` strings.

**Staff Form (`school_admin_staff_form_screen.dart`)**

Uses local `ConsumerStatefulWidget` state — no provider. The form has four `GlobalKey<FormState>` instances (one per tab). All four are validated on final submit.

The `_editStaffProvider` is a `FutureProvider.autoDispose.family<StaffModel?, String?>` that fetches the staff record for pre-population in edit mode; it returns null for create mode.

### Service Layer

All API calls route through `lib/core/services/school_admin_service.dart`. The service uses the Dio client configured in `lib/core/network/dio_client.dart`, which automatically attaches the JWT and handles token refresh.

Key staff-related methods:

```dart
// Staff CRUD
Future<Map<String, dynamic>> getStaff({int page, int limit, String? search, ...})
Future<StaffModel> createStaff(Map<String, dynamic> body)
Future<StaffModel> getStaffById(String id)
Future<StaffModel> updateStaff(String id, Map<String, dynamic> body)
Future<void> deleteStaff(String id)
Future<void> updateStaffStatus(String id, bool isActive, {String? reason})
Future<String> getSuggestedEmployeeNo({String? firstName, String? lastName})
Future<Map<String, dynamic>> checkEmployeeNoAvailability(String empNo, {String? excludeStaffId})
Future<void> createStaffLogin(String staffId, String password)
Future<void> resetStaffPassword(String staffId, String newPassword)

// Qualifications
Future<List<StaffQualificationModel>> getStaffQualifications(String staffId)
Future<StaffQualificationModel> addQualification(String staffId, Map<String, dynamic> body)
Future<StaffQualificationModel> updateQualification(String staffId, String qualId, Map<String, dynamic> body)
Future<void> deleteQualification(String staffId, String qualId)

// Documents
Future<List<StaffDocumentModel>> getStaffDocuments(String staffId)
Future<StaffDocumentModel> addDocument(String staffId, Map<String, dynamic> body)
Future<void> verifyDocument(String staffId, String docId)
Future<void> deleteDocument(String staffId, String docId)

// Subject Assignments
Future<List<StaffSubjectAssignmentModel>> getSubjectAssignments(String staffId, {String? academicYear})
Future<StaffSubjectAssignmentModel> addSubjectAssignment(String staffId, Map<String, dynamic> body)
Future<void> removeSubjectAssignment(String staffId, String assignId)
Future<StaffTimetableModel> getStaffTimetable(String staffId)

// Leaves
Future<Map<String, dynamic>> getLeaves({String? status, String? leaveType, int limit, ...})
Future<Map<String, dynamic>> getStaffLeaves(String staffId, {String? status, int page, int limit})
Future<StaffLeaveModel> applyLeave(String staffId, Map<String, dynamic> body)
Future<StaffLeaveModel> reviewLeave(String leaveId, String status, {String? adminRemark})
Future<StaffLeaveModel> cancelLeave(String leaveId)
Future<Map<String, dynamic>> getLeaveSummary({String? academicYear, String? staffId})
```

### API Config Constants

Defined in `lib/core/config/api_config.dart`:

```dart
static const String schoolStaff             = '/api/school/staff';
static const String schoolStaffLeaves       = '/api/school/staff/leaves';
static const String schoolStaffLeaveSummary = '/api/school/staff/leaves/summary';
```

Per-staff sub-resource URLs are constructed dynamically:
```dart
final qualsUrl = '${ApiConfig.schoolStaff}/$staffId/qualifications';
final docsUrl  = '${ApiConfig.schoolStaff}/$staffId/documents';
```

---

## Route Registration

All staff routes are nested under the `school-admin` shell route in `lib/routes/app_router.dart`:

```dart
// Staff directory (already registered)
GoRoute(path: 'staff', builder: (_, __) => const SchoolAdminStaffScreen())

// Staff detail (already registered)
GoRoute(
  path: 'staff/:id',
  builder: (ctx, state) =>
    SchoolAdminStaffDetailScreen(staffId: state.pathParameters['id']!),
)

// Staff create form (new)
GoRoute(path: 'staff/new', builder: (_, __) => const SchoolAdminStaffFormScreen())

// Staff edit form (new)
GoRoute(
  path: 'staff/:id/edit',
  builder: (ctx, state) =>
    SchoolAdminStaffFormScreen(staffId: state.pathParameters['id']),
)

// Staff timetable (new)
GoRoute(
  path: 'staff/:id/timetable',
  builder: (ctx, state) =>
    SchoolAdminStaffTimetableScreen(staffId: state.pathParameters['id']!),
)

// Leave apply (new)
GoRoute(
  path: 'staff/:id/leave/apply',
  builder: (ctx, state) =>
    SchoolAdminLeaveApplyScreen(staffId: state.pathParameters['id']!),
)

// Leave management hub (new)
GoRoute(path: 'leaves', builder: (_, __) => const SchoolAdminLeavesScreen())
```

**Navigation calls in code:**
```dart
context.go('/school-admin/staff');           // Staff list
context.go('/school-admin/staff/$id');       // Staff detail
context.go('/school-admin/staff/new');       // Create form
context.go('/school-admin/staff/$id/edit');  // Edit form
context.go('/school-admin/staff/$id/leave/apply');
context.go('/school-admin/leaves');
```

---

## Adding a New Field to the Staff Model

Follow these steps when extending the staff profile with an additional column.

### 1. Database migration

Add to `backend/prisma/schema.prisma` in the `Staff` model:

```prisma
newField  String?  @map("new_field")  @db.VarChar(100)
```

Generate and run the migration:

```bash
cd backend
npx prisma migrate dev --name add_new_field_to_staff
```

### 2. Backend validation

Add the field to both `createStaffSchema` and `updateStaffSchema` in `school-admin.validation.js`:

```javascript
newField: Joi.string().max(100).optional().allow(null, ''),
```

### 3. Backend service / repository

If the field should appear in list responses, add it to the `select` object in the list repository query. If it is sensitive (like `salary_grade`), add it only to the detail query's select.

### 4. Flutter model

Update `lib/models/school_admin/staff_model.dart`:

```dart
final String? newField;

// In fromJson factory:
newField: json['new_field'] as String?,

// In toJson:
if (newField != null) 'new_field': newField,
```

### 5. Flutter form

Add the field to the appropriate tab in `school_admin_staff_form_screen.dart` (or the quick-add dialog in `school_admin_staff_screen.dart`). Include it in the `body` map in the `_submit()` method.

---

## Running Migrations

From the `backend/` directory:

```bash
# Apply all pending migrations to development database
npx prisma migrate dev

# Apply a specific named migration
npx prisma migrate dev --name describe_your_change

# Generate Prisma client after schema change (runs automatically after migrate dev)
npx prisma generate

# Push schema changes to a non-migration database (prototype only, not for production)
npx prisma db push

# View migration history
npx prisma migrate status
```

---

## Error Handling Patterns

### Backend

All service-layer errors use `throw new AppError('message', statusCode)`. The global `errorHandler` middleware in `backend/src/middleware/errorHandler.js` catches these and returns:

```json
{ "success": false, "error": "Human-readable message" }
```

### Flutter

The service layer rethrows Dio exceptions. Screen-level catch blocks extract user-facing messages using the `_extractUserMessage` helper pattern defined in `_StaffFormState`:

```dart
static String _extractUserMessage(Object e) {
  final raw = e.toString();
  final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw);
  if (msgMatch != null) return msgMatch.group(1)!;
  // Strip internal prefixes and reject paths or very long strings
  final cleaned = raw
      .replaceAll('Exception: ', '')
      .replaceAll('DioException [bad response]: ', '');
  if (cleaned.contains('/') || cleaned.contains('\\') || cleaned.length > 200) {
    return 'An error occurred. Please try again.';
  }
  return cleaned;
}
```

This pattern must be used consistently across all staff-related screens to prevent server internals from leaking to the UI.

---

## Security Checklist

Before releasing any change to this module, verify:

- [ ] Every repository query in the staff module includes `schoolId: req.user.school_id`
- [ ] GET /:id verifies `staff.school_id === req.user.school_id` before returning
- [ ] `PUT /staff/leaves/:leaveId/review` is only reachable by SCHOOL_ADMIN role
- [ ] `PUT /staff/:staffId/documents/:docId/verify` is only reachable by SCHOOL_ADMIN role
- [ ] `salary_grade`, `emergency_contact_name`, `emergency_contact_phone` are excluded from the list endpoint response
- [ ] Password fields are cleared from memory after use (see `_submit()` in `school_admin_staff_form_screen.dart`)
- [ ] Audit events are logged for: `CREATE_STAFF`, `UPDATE_STAFF`, `DELETE_STAFF`, `STAFF_LEAVE_APPLIED`, `STAFF_LEAVE_REVIEWED`

---

## Integration Points with Other Modules

| Module | Integration |
|--------|------------|
| Auth | `staff.user_id` links to `users.id`. Creating a staff member with `createLogin: true` creates a User record with role `TEACHER` or `STAFF`. |
| Classes/Sections | `sections.class_teacher_id` references `staff.id`. Soft-deleting a staff member is blocked if they are currently a class teacher. |
| Timetable | `timetables.staff_id` references `staff.id`. The timetable view in this module reads from the timetables table but does not write to it. |
| Attendance | Future: `staff_attendance` will reference `staff.id`. The `employee_type` and `designation` fields will be used for reporting. |
| Exams | Future: `exam_invigilators` and `marks_entry` tables will reference `staff.id`. |
| HR/Payroll | Future: payroll module will use `staff.salary_grade`, `staff.employee_type`, and `staff.join_date` for salary calculation. |
| Communications | Future: the messaging module will target staff via `staff.user_id`. |
