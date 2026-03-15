# BACKEND PROMPT — School Admin Module

## Agent Role
You are the Backend Developer for the Vidyron School ERP platform. Your task is to build the complete Node.js/Express backend module for the School Admin portal under `backend/src/modules/school-admin/`. This module **replaces** the placeholder `backend/src/modules/school/school.routes.js` for the `/api/school/` route prefix.

---

## Project Context

- **Root**: `e:/School_ERP_AI/erp-new-logic/`
- **Backend root**: `e:/School_ERP_AI/erp-new-logic/backend/`
- **API base**: `/api/school/`
- **Auth**: All routes require `verifyAccessToken` + `requireSchoolAdmin` middleware
- **Tenant isolation**: EVERY database query must filter by `schoolId: req.user.school_id`. Never allow cross-school data access.
- **Response format**: `{ success: true, data: {...}, message: "..." }` via `successResponse(res, statusCode, message, data)`
- **Error format**: `throw new AppError('message', statusCode)` — caught by global `errorHandler` middleware
- **Pagination params**: `?page=1&limit=20&search=&sortBy=field&sortOrder=asc`

---

## Prerequisite: Database Schema

The following Prisma models are available after running the DATABASE_PROMPT migration:

| Prisma Model | DB Table | Key fields |
|---|---|---|
| `Student` | `students` | `schoolId`, `admissionNo` (unique/school), `classId?`, `sectionId?`, `status`, `deletedAt` |
| `Staff` | `staff` | `schoolId`, `employeeNo` (unique/school), `userId?`, `designation`, `isActive`, `deletedAt` |
| `SchoolClass` | `school_classes` | `schoolId`, `name` (unique/school), `numeric?`, `isActive` |
| `Section` | `sections` | `schoolId`, `classId`, `name` (unique/class), `classTeacherId?`, `capacity`, `isActive` |
| `Attendance` | `attendances` | `schoolId`, `studentId`, `sectionId`, `date`, `status`, `markedBy` |
| `FeeStructure` | `fee_structures` | `schoolId`, `classId?`, `academicYear`, `feeHead`, `amount`, `frequency`, `isActive` |
| `FeePayment` | `fee_payments` | `schoolId`, `studentId`, `receiptNo` (unique/school), `feeHead`, `paymentDate`, `collectedBy` |
| `SchoolNotice` | `school_notices` | `schoolId`, `title`, `body`, `targetRole?`, `isPinned`, `publishedAt?`, `expiresAt?`, `createdBy`, `deletedAt` |
| `Timetable` | `timetables` | `schoolId`, `classId`, `sectionId?`, `dayOfWeek`, `periodNo`, `subject`, `staffId?`, `startTime`, `endTime` |

---

## Existing Utilities to Import

```js
import { successResponse, AppError } from '../../utils/response.js';
import * as auditService from '../audit/audit.service.js';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
```

`auditService.logAudit(ctx)` signature (fire-and-forget):
```js
auditService.logAudit({
  actorId: req.user?.userId,
  actorName: req.user?.first_name
    ? `${req.user.first_name} ${req.user.last_name || ''}`.trim()
    : req.user?.email,
  actorRole: 'school_admin',
  action: 'ACTION_NAME',           // e.g. CREATE_STUDENT
  entityType: 'students',
  entityId: entity?.id,
  entityName: entity?.name,
  ipAddress: req.ip,
}).catch(() => {});
```

---

## Existing Patterns to Follow

Reference `backend/src/modules/super-admin/super-admin.controller.js` and `backend/src/modules/schools/schools.repository.js` for code style:

- Controllers use an `handle` wrapper: `const handle = (fn) => (req, res, next) => Promise.resolve(fn(req, res)).catch(next);`
- Repository functions take explicit parameters; service functions coordinate business logic; controllers handle HTTP parsing only.
- Pagination: compute `skip = (page - 1) * limit` and return `{ data: [...], pagination: { page, limit, total, total_pages } }`
- Soft delete list queries always add `deletedAt: null` to the `where` clause.

---

## Task 1: Create Middleware File

**File**: `e:/School_ERP_AI/erp-new-logic/backend/src/middleware/school-admin-guard.middleware.js`

```js
import { AppError } from '../utils/response.js';

export const requireSchoolAdmin = (req, res, next) => {
  const user = req.user;
  if (!user) return next(new AppError('Unauthorized', 401));

  const isSchoolAdmin =
    user.role === 'school_admin' ||
    user.portalType === 'school_admin' ||
    user.portal_type === 'school_admin';

  if (!isSchoolAdmin) {
    return next(new AppError('Access denied. School admin privileges required.', 403));
  }

  if (!user.school_id && !user.schoolId) {
    return next(new AppError('No school assigned to this account.', 403));
  }

  // Normalize school_id onto req.user for consistent access downstream
  req.user.school_id = user.school_id || user.schoolId;
  next();
};
```

---

## Task 2: Create Module Files

Create the directory `e:/School_ERP_AI/erp-new-logic/backend/src/modules/school-admin/` with five files:

---

### File 1: `school-admin.validation.js`

Use Joi for all request body validation. Install if needed: `npm install joi`.

Export named validators using this pattern:
```js
import Joi from 'joi';

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) {
    const msg = error.details.map((d) => d.message).join('; ');
    return next(new (await import('../../utils/response.js')).AppError(msg, 400));
  }
  next();
};
```

Define and export these schemas:

**`createStudentSchema`** — required: `firstName`, `lastName`, `gender` (valid: MALE|FEMALE|OTHER), `dateOfBirth` (ISO date string), `admissionNo`, `admissionDate`. Optional: `classId`, `sectionId`, `rollNo`, `bloodGroup`, `phone`, `email`, `address`, `photoUrl`, `parentName`, `parentPhone`, `parentEmail`, `parentRelation`, `status` (valid: ACTIVE|INACTIVE|TRANSFERRED, default ACTIVE).

**`updateStudentSchema`** — same as create but all fields optional.

**`createStaffSchema`** — required: `firstName`, `lastName`, `gender`, `email`, `designation`, `joinDate`, `employeeNo`. Optional: `dateOfBirth`, `phone`, `subjects` (array of strings), `qualification`, `photoUrl`, `isActive` (boolean, default true).

**`updateStaffSchema`** — same as create but all fields optional.

**`createClassSchema`** — required: `name`. Optional: `numeric` (integer).

**`updateClassSchema`** — same as create but all fields optional.

**`createSectionSchema`** — required: `name`. Optional: `classTeacherId` (uuid), `capacity` (integer, default 40).

**`updateSectionSchema`** — same as create but all fields optional.

**`bulkAttendanceSchema`** — required: `sectionId` (uuid), `date` (ISO date), `records` (array, each item: `studentId` (uuid, required), `status` (valid: PRESENT|ABSENT|LATE|HOLIDAY, required), `remarks` (string, optional)).

**`createFeeStructureSchema`** — required: `academicYear`, `feeHead`, `amount` (positive number), `frequency` (valid: MONTHLY|QUARTERLY|ANNUALLY|ONE_TIME). Optional: `classId` (uuid), `dueDay` (integer 1–31), `isActive` (boolean).

**`updateFeeStructureSchema`** — same as create but all fields optional.

**`createFeePaymentSchema`** — required: `studentId` (uuid), `feeHead`, `academicYear`, `amount` (positive number), `paymentDate` (ISO date), `paymentMode` (valid: CASH|UPI|BANK_TRANSFER|CHEQUE), `receiptNo`. Optional: `remarks`.

**`bulkTimetableSchema`** — required: `classId` (uuid), `entries` (array). Each entry: `dayOfWeek` (integer 1–6), `periodNo` (positive integer), `subject` (string), `startTime` (string HH:MM), `endTime` (string HH:MM). Optional per entry: `staffId` (uuid), `room` (string), `sectionId` (uuid, applies to all entries from outer body). Optional at root: `sectionId` (uuid).

**`createNoticeSchema`** — required: `title`, `body`. Optional: `targetRole` (valid: all|teacher|student|parent), `isPinned` (boolean, default false), `publishedAt` (ISO datetime), `expiresAt` (ISO datetime).

**`updateNoticeSchema`** — same as create but all fields optional.

**`updateUserProfileSchema`** — optional: `firstName`, `lastName`, `phone`, `avatarUrl`, `avatar_base64`.

**`updateSchoolProfileSchema`** — optional: `name`, `phone`, `email`, `address`, `city`, `state`, `logoUrl`.

**`changePasswordSchema`** — required: `currentPassword` (min 6), `newPassword` (min 8).

---

### File 2: `school-admin.repository.js`

All functions receive `schoolId` as the first parameter to enforce tenant isolation.

```js
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
```

**Export these functions** (implement fully):

#### Dashboard
```js
export async function getDashboardStats(schoolId)
```
Returns one object:
```js
{
  total_students,   // count students where schoolId AND deletedAt null AND status != TRANSFERRED
  total_staff,      // count staff where schoolId AND deletedAt null AND isActive true
  total_classes,    // count school_classes where schoolId AND isActive true
  total_sections,   // count sections where schoolId AND isActive true
  today_attendance_percent, // (present count / total_students) * 100 for today's date
  fee_collected_this_month, // sum of fee_payments.amount where schoolId AND paymentDate in current month, returned as number
  notices_count,    // count school_notices where schoolId AND deletedAt null
  recent_activity,  // last 5 audit log entries where actorId in school users — use prisma.$queryRaw or AuditSuperAdminLog model
}
```

#### Students
```js
export async function getStudents(schoolId, { page, limit, search, classId, sectionId, status })
// Returns { data: [...], total }
// search matches firstName OR lastName OR admissionNo (case-insensitive)
// include class_.name as class_name, section.name as section_name via Prisma include

export async function getStudentById(schoolId, id)
// Returns student with class_.name and section.name; throws AppError 404 if not found or deletedAt set

export async function createStudent(schoolId, data)
// Check admissionNo uniqueness within school before insert; throw AppError 409 if duplicate
// data fields: all Student columns except id, schoolId, createdAt, updatedAt, deletedAt

export async function updateStudent(schoolId, id, data)
// Verify record exists and belongs to school; throw 404 if not
// If admissionNo changed, re-check uniqueness

export async function softDeleteStudent(schoolId, id)
// Set deletedAt = new Date(); throw 404 if not found
```

#### Staff
```js
export async function getStaff(schoolId, { page, limit, search, designation, isActive })
// search matches firstName OR lastName OR email OR employeeNo
// isActive filter: convert query string 'true'/'false' to boolean

export async function getStaffById(schoolId, id)
// Returns staff with user relation (id, email, firstName, lastName); throw 404 if deletedAt set

export async function createStaff(schoolId, data)
// Check employeeNo uniqueness; throw 409 if duplicate

export async function updateStaff(schoolId, id, data)
// Verify ownership; re-check employeeNo uniqueness if changed

export async function softDeleteStaff(schoolId, id)
```

#### Classes
```js
export async function getClasses(schoolId)
// Return all classes where isActive=true, ordered by numeric ASC NULLS LAST, name ASC
// Include sections with _count: { select: { students: true } }

export async function createClass(schoolId, data)
// data: { name, numeric? }; check name uniqueness; throw 409 if duplicate

export async function updateClass(schoolId, id, data)
// Re-check name uniqueness if name changed

export async function deleteClass(schoolId, id)
// Hard delete (no soft delete for classes) — throw 400 if sections exist for this class
```

#### Sections
```js
export async function getSectionsByClass(schoolId, classId)
// Include classTeacher (id, firstName, lastName) and _count: { students: true }

export async function createSection(schoolId, classId, data)
// data: { name, classTeacherId?, capacity? }; check name uniqueness within class; throw 409 if duplicate

export async function updateSection(schoolId, id, data)
// Verify schoolId ownership; re-check name uniqueness if name changed

export async function deleteSection(schoolId, id)
// Hard delete — throw 400 if students assigned to this section
```

#### Attendance
```js
export async function getAttendance(schoolId, { classId, sectionId, date })
// Return all students in the section/class with their attendance record for the given date (LEFT JOIN)
// If no attendance record exists for a student, return null status

export async function bulkUpsertAttendance(schoolId, { sectionId, date, records, markedBy })
// records = [{ studentId, status, remarks? }]
// Upsert each record: unique constraint is (studentId, date)
// Use prisma.attendance.upsert() for each record
// Return { saved: records.length, date, section_name }

export async function getAttendanceReport(schoolId, { classId, sectionId, month })
// month = "2026-03" — derive start/end date range
// Return calendar: [{ date, present, absent, late }] for each working day
// Return summary: { present_days, absent_days, total_days }
```

#### Fees
```js
export async function getFeeStructures(schoolId, { academicYear, classId })

export async function createFeeStructure(schoolId, data)

export async function updateFeeStructure(schoolId, id, data)

export async function deleteFeeStructure(schoolId, id)
// Hard delete

export async function getFeePayments(schoolId, { page, limit, studentId, month, academicYear })
// month = "2026-03" → filter paymentDate between first and last day of month

export async function createFeePayment(schoolId, data, collectedBy)
// Validate receiptNo uniqueness within school; throw 409 if duplicate
// collectedBy = req.user.userId

export async function getFeePaymentById(schoolId, id)

export async function getFeeSummary(schoolId, month)
// month = "2026-03" → sum amounts grouped by feeHead for that month
// Return: { month, total, breakdown: [{ fee_head, amount }] }
```

#### Timetable
```js
export async function getTimetable(schoolId, { classId, sectionId })
// Return all timetable entries for classId (optionally filtered by sectionId)
// Include staff (id, firstName, lastName) if staffId set

export async function replaceTimetable(schoolId, { classId, sectionId, entries })
// Transaction: delete all existing entries for classId+sectionId, then create all new entries
// entries = [{ dayOfWeek, periodNo, subject, staffId?, startTime, endTime, room? }]
```

#### Notices
```js
export async function getNotices(schoolId, { page, limit, search })
// search matches title; soft-delete filter deletedAt null
// Order: isPinned DESC, createdAt DESC

export async function createNotice(schoolId, data, createdBy)

export async function updateNotice(schoolId, id, data)

export async function softDeleteNotice(schoolId, id)
```

#### Profile
```js
export async function getSchoolProfile(schoolId)
// Return school record + the school admin user record
// Admin user: find User where schoolId = schoolId AND (role includes 'school_admin' OR portalType = 'school_admin')

export async function updateUserProfile(userId, data)
// data: { firstName?, lastName?, phone?, avatarUrl? }

export async function updateSchoolProfile(schoolId, data)
// data: { name?, phone?, email?, address?, city?, state?, logoUrl? }
```

---

### File 3: `school-admin.service.js`

The service layer coordinates business logic and calls repository functions. Keep thin — primarily validates cross-entity business rules and formats responses.

```js
import * as repo from './school-admin.repository.js';
import { AppError } from '../../utils/response.js';
import bcrypt from 'bcrypt';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
```

**Export these functions**:

```js
export async function getDashboardStats(schoolId)
// Calls repo.getDashboardStats; formats today_attendance_percent as integer 0–100

export async function getStudents(schoolId, filters)
// Calls repo.getStudents; builds pagination object { page, limit, total, total_pages }

export async function getStudentById(schoolId, id)

export async function createStudent(schoolId, data)

export async function updateStudent(schoolId, id, data)

export async function deleteStudent(schoolId, id)

export async function getStaff(schoolId, filters)

export async function getStaffById(schoolId, id)

export async function createStaff(schoolId, data)

export async function updateStaff(schoolId, id, data)

export async function deleteStaff(schoolId, id)

export async function getClasses(schoolId)

export async function createClass(schoolId, data)

export async function updateClass(schoolId, id, data)

export async function deleteClass(schoolId, id)

export async function getSectionsByClass(schoolId, classId)

export async function createSection(schoolId, classId, data)

export async function updateSection(schoolId, id, data)

export async function deleteSection(schoolId, id)

export async function getAttendance(schoolId, filters)

export async function bulkMarkAttendance(schoolId, body, markedBy)

export async function getAttendanceReport(schoolId, filters)

export async function getFeeStructures(schoolId, filters)

export async function createFeeStructure(schoolId, data)

export async function updateFeeStructure(schoolId, id, data)

export async function deleteFeeStructure(schoolId, id)

export async function getFeePayments(schoolId, filters)

export async function createFeePayment(schoolId, data, collectedBy)

export async function getFeePaymentById(schoolId, id)

export async function getFeeSummary(schoolId, month)

export async function getTimetable(schoolId, filters)

export async function replaceTimetable(schoolId, body)

export async function getNotices(schoolId, filters)

export async function createNotice(schoolId, data, createdBy)

export async function updateNotice(schoolId, id, data)

export async function deleteNotice(schoolId, id)

export async function getSchoolProfile(schoolId)

export async function updateUserProfile(userId, data)

export async function updateSchoolProfile(schoolId, data)

export async function changePassword(userId, currentPassword, newPassword)
// 1. Find user by userId; throw 404 if not found
// 2. Compare currentPassword with user.passwordHash using bcrypt.compare; throw 401 if mismatch
// 3. Hash newPassword with bcrypt (saltRounds = 10)
// 4. Update user.passwordHash and user.passwordChangedAt = new Date()

export async function getSchoolNotifications(schoolId, { page, limit })
// Placeholder: query AuditSuperAdminLog or a future Notification model filtered by schoolId
// For now, return empty paginated list with structure { data: [], pagination: { page, limit, total: 0, total_pages: 0 } }

export async function getUnreadNotificationCount(schoolId)
// Return { count: 0 } as placeholder

export async function markNotificationRead(schoolId, notificationId)
// No-op placeholder; return { success: true }
```

---

### File 4: `school-admin.controller.js`

Follow exactly the same pattern as `backend/src/modules/super-admin/super-admin.controller.js`.

```js
import { successResponse, AppError } from '../../utils/response.js';
import * as service from './school-admin.service.js';
import * as auditService from '../audit/audit.service.js';

const handle = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res)).catch(next);
};
```

**Export one handler per endpoint** (listed in Task 5 below). Each handler:

1. Reads params from `req.query`, `req.params`, or `req.body`
2. Reads `schoolId = req.user.school_id`
3. Calls the corresponding service function
4. Calls `auditService.logAudit(...)` (fire-and-forget `.catch(() => {})`) for all mutating operations (POST, PUT, DELETE)
5. Returns `successResponse(res, statusCode, message, data)`

**Audit action names** (use these exact strings):
- `CREATE_STUDENT`, `UPDATE_STUDENT`, `DELETE_STUDENT`
- `CREATE_STAFF`, `UPDATE_STAFF`, `DELETE_STAFF`
- `CREATE_CLASS`, `UPDATE_CLASS`, `DELETE_CLASS`
- `CREATE_SECTION`, `UPDATE_SECTION`, `DELETE_SECTION`
- `MARK_ATTENDANCE`
- `CREATE_FEE_STRUCTURE`, `UPDATE_FEE_STRUCTURE`, `DELETE_FEE_STRUCTURE`
- `CREATE_FEE_PAYMENT`
- `REPLACE_TIMETABLE`
- `CREATE_NOTICE`, `UPDATE_NOTICE`, `DELETE_NOTICE`
- `UPDATE_USER_PROFILE`, `UPDATE_SCHOOL_PROFILE`, `CHANGE_PASSWORD`

---

### File 5: `school-admin.routes.js`

```js
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireSchoolAdmin } from '../../middleware/school-admin-guard.middleware.js';
import * as ctrl from './school-admin.controller.js';
import * as v from './school-admin.validation.js';

const router = express.Router();

// Apply auth to all routes
router.use(verifyAccessToken, requireSchoolAdmin);
```

---

## Task 3: Define All Routes

Register routes in the order below (specific paths before parameterized paths to avoid conflicts):

### Dashboard
```
GET  /dashboard/stats          → ctrl.getDashboardStats
```

### Students
```
GET    /students               → ctrl.getStudents
POST   /students               → v.validate(v.createStudentSchema), ctrl.createStudent
GET    /students/:id           → ctrl.getStudentById
PUT    /students/:id           → v.validate(v.updateStudentSchema), ctrl.updateStudent
DELETE /students/:id           → ctrl.deleteStudent
```

### Staff
```
GET    /staff                  → ctrl.getStaff
POST   /staff                  → v.validate(v.createStaffSchema), ctrl.createStaff
GET    /staff/:id              → ctrl.getStaffById
PUT    /staff/:id              → v.validate(v.updateStaffSchema), ctrl.updateStaff
DELETE /staff/:id              → ctrl.deleteStaff
```

### Classes
```
GET    /classes                → ctrl.getClasses
POST   /classes                → v.validate(v.createClassSchema), ctrl.createClass
PUT    /classes/:id            → v.validate(v.updateClassSchema), ctrl.updateClass
DELETE /classes/:id            → ctrl.deleteClass
```

### Sections (nested under class + standalone for updates)
```
GET    /classes/:classId/sections     → ctrl.getSectionsByClass
POST   /classes/:classId/sections     → v.validate(v.createSectionSchema), ctrl.createSection
PUT    /sections/:id                  → v.validate(v.updateSectionSchema), ctrl.updateSection
DELETE /sections/:id                  → ctrl.deleteSection
```

### Attendance (specific paths BEFORE parameterized)
```
GET  /attendance/report        → ctrl.getAttendanceReport
GET  /attendance               → ctrl.getAttendance
POST /attendance/bulk          → v.validate(v.bulkAttendanceSchema), ctrl.bulkMarkAttendance
```

### Fees
```
GET    /fees/summary           → ctrl.getFeeSummary
GET    /fees/structures        → ctrl.getFeeStructures
POST   /fees/structures        → v.validate(v.createFeeStructureSchema), ctrl.createFeeStructure
PUT    /fees/structures/:id    → v.validate(v.updateFeeStructureSchema), ctrl.updateFeeStructure
DELETE /fees/structures/:id    → ctrl.deleteFeeStructure
GET    /fees/payments/:id      → ctrl.getFeePaymentById
GET    /fees/payments          → ctrl.getFeePayments
POST   /fees/payments          → v.validate(v.createFeePaymentSchema), ctrl.createFeePayment
```

### Timetable
```
GET  /timetable                → ctrl.getTimetable
PUT  /timetable/bulk           → v.validate(v.bulkTimetableSchema), ctrl.replaceTimetable
```

### Notices
```
GET    /notices                → ctrl.getNotices
POST   /notices                → v.validate(v.createNoticeSchema), ctrl.createNotice
PUT    /notices/:id            → v.validate(v.updateNoticeSchema), ctrl.updateNotice
DELETE /notices/:id            → ctrl.deleteNotice
```

### Notifications
```
GET  /notifications/unread-count  → ctrl.getUnreadNotificationCount
GET  /notifications               → ctrl.getNotifications
PUT  /notifications/:id/read      → ctrl.markNotificationRead
```

### Profile & Auth
```
GET  /profile                    → ctrl.getSchoolProfile
PUT  /profile/user               → v.validate(v.updateUserProfileSchema), ctrl.updateUserProfile
PUT  /profile/school             → v.validate(v.updateSchoolProfileSchema), ctrl.updateSchoolProfile
POST /auth/change-password       → v.validate(v.changePasswordSchema), ctrl.changePassword
```

---

## Task 4: Register Routes in app.js

**File**: `e:/School_ERP_AI/erp-new-logic/backend/src/app.js`

The file already contains:
```js
import schoolManagementRoutes from './modules/school/school.routes.js';
// ...
app.use('/api/school', schoolManagementRoutes);
```

**Replace** the import and mount with:
```js
import schoolAdminRoutes from './modules/school-admin/school-admin.routes.js';
// ...
app.use('/api/school', schoolAdminRoutes);
```

Remove the old import of `schoolManagementRoutes` from `./modules/school/school.routes.js` entirely. The old placeholder module at `backend/src/modules/school/` can be left in place but is no longer mounted.

---

## Task 5: Complete Endpoint Reference

### GET /api/school/dashboard/stats
- No query params
- Calls `service.getDashboardStats(schoolId)`
- Response 200:
```json
{
  "success": true,
  "data": {
    "total_students": 342,
    "total_staff": 28,
    "total_classes": 12,
    "total_sections": 24,
    "today_attendance_percent": 87,
    "fee_collected_this_month": 125000,
    "notices_count": 5,
    "recent_activity": [
      { "type": "CREATE_STUDENT", "message": "New student enrolled", "created_at": "2026-03-15T10:00:00Z" }
    ]
  }
}
```

### GET /api/school/students
- Query: `page`, `limit`, `search`, `classId`, `sectionId`, `status`
- Response 200:
```json
{
  "success": true,
  "data": [...],
  "pagination": { "page": 1, "limit": 20, "total": 342, "total_pages": 18 }
}
```

### POST /api/school/students
- Body: student fields (see validation schema)
- Response 201: `{ success: true, data: { ...student }, message: "Student created" }`
- Error 409: admissionNo already exists in this school
- Error 400: validation failure

### GET /api/school/students/:id
- Response 200: `{ success: true, data: { ...student, class_name, section_name } }`
- Error 404: not found

### PUT /api/school/students/:id
- Response 200: `{ success: true, data: { ...student }, message: "Student updated" }`

### DELETE /api/school/students/:id
- Soft delete (sets `deletedAt`)
- Response 200: `{ success: true, message: "Student deleted" }`

### GET /api/school/staff
- Query: `page`, `limit`, `search`, `designation`, `isActive`
- Response 200 with pagination

### POST /api/school/staff
- Response 201; error 409 if employeeNo duplicate within school

### GET /api/school/staff/:id
### PUT /api/school/staff/:id
### DELETE /api/school/staff/:id  (soft delete)

### GET /api/school/classes
- No pagination — returns full list
- Response 200:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Class 10",
      "numeric": 10,
      "is_active": true,
      "sections": [
        { "id": "uuid", "name": "A", "student_count": 38 }
      ]
    }
  ]
}
```

### POST /api/school/classes
- Body: `{ name, numeric? }`
- Response 201; error 409 if name duplicate within school

### PUT /api/school/classes/:id
### DELETE /api/school/classes/:id
- Error 400: "Cannot delete class with existing sections"

### GET /api/school/classes/:classId/sections
- Response 200: list of sections with classTeacher and student_count

### POST /api/school/classes/:classId/sections
- classId from URL param, passed to service
- Body: `{ name, classTeacherId?, capacity? }`
- Response 201; error 409 if section name duplicate within class

### PUT /api/school/sections/:id
### DELETE /api/school/sections/:id
- Error 400: "Cannot delete section with assigned students"

### GET /api/school/attendance
- Query: `classId`, `sectionId`, `date` (required, format: YYYY-MM-DD)
- Response 200:
```json
{
  "success": true,
  "data": [
    { "student_id": "uuid", "student_name": "Ravi Kumar", "roll_no": 1, "status": "PRESENT", "remarks": null }
  ]
}
```

### POST /api/school/attendance/bulk
- Body: `{ sectionId, date, records: [{ studentId, status, remarks? }] }`
- Upserts all records
- Response 200: `{ success: true, data: { saved: 40, date: "2026-03-15", section_name: "A" } }`

### GET /api/school/attendance/report
- Query: `classId`, `sectionId`, `month` (format: YYYY-MM)
- Response 200:
```json
{
  "success": true,
  "data": {
    "calendar": [{ "date": "2026-03-01", "present": 38, "absent": 2, "late": 0 }],
    "summary": { "present_days": 18, "absent_days": 4, "total_days": 22 }
  }
}
```

### GET /api/school/fees/structures
- Query: `academicYear`, `classId` (optional)

### POST /api/school/fees/structures
### PUT /api/school/fees/structures/:id
### DELETE /api/school/fees/structures/:id

### GET /api/school/fees/payments
- Query: `page`, `limit`, `studentId` (optional), `month` (YYYY-MM, optional), `academicYear` (optional)

### POST /api/school/fees/payments
- `collectedBy` is set server-side from `req.user.userId`
- Response 201: `{ success: true, data: { ...payment }, message: "Payment recorded" }`
- Error 409: receiptNo duplicate within school

### GET /api/school/fees/payments/:id
### GET /api/school/fees/summary
- Query: `month` (YYYY-MM, required)
- Response 200: `{ success: true, data: { month, total, breakdown: [{ fee_head, amount }] } }`

### GET /api/school/timetable
- Query: `classId` (required), `sectionId` (optional)
- Response 200: list of timetable entries grouped or flat

### PUT /api/school/timetable/bulk
- Body: `{ classId, sectionId?, entries: [...] }`
- Replaces entire timetable for that class+section in a transaction
- Response 200: `{ success: true, data: { saved: 30 }, message: "Timetable updated" }`

### GET /api/school/notices
- Query: `page`, `limit`, `search`

### POST /api/school/notices
- `createdBy` = `req.user.userId`
- Response 201

### PUT /api/school/notices/:id
### DELETE /api/school/notices/:id  (soft delete)

### GET /api/school/notifications/unread-count
- Response 200: `{ success: true, data: { count: 0 } }`

### GET /api/school/notifications
- Query: `page`, `limit`
- Response 200: paginated list (placeholder empty)

### PUT /api/school/notifications/:id/read
- Response 200: `{ success: true, message: "Marked as read" }`

### GET /api/school/profile
- Response 200:
```json
{
  "success": true,
  "data": {
    "school": { "id": "uuid", "name": "...", "email": "...", "phone": "...", "address": "...", "city": "...", "state": "...", "logo_url": "..." },
    "user": { "id": "uuid", "first_name": "...", "last_name": "...", "email": "...", "phone": "...", "avatar_url": "..." }
  }
}
```

### PUT /api/school/profile/user
- Body: `{ firstName?, lastName?, phone?, avatarUrl?, avatar_base64? }`
- If `avatar_base64` provided: save to `uploads/avatars/{userId}.jpg` and set `avatarUrl` to `/uploads/avatars/{userId}.jpg`
- Response 200: updated user object

### PUT /api/school/profile/school
- Body: `{ name?, phone?, email?, address?, city?, state?, logoUrl? }`
- Response 200: updated school object

### POST /api/school/auth/change-password
- Body: `{ currentPassword, newPassword }`
- Response 200: `{ success: true, message: "Password changed successfully" }`
- Error 401: "Current password is incorrect"

---

## Security Requirements

1. Every repository function receives `schoolId` explicitly — never trust client-provided `school_id` in the body; always use `req.user.school_id`.
2. All `findMany` queries include `deletedAt: null` for soft-deleted models (Student, Staff, SchoolNotice).
3. `admissionNo` uniqueness is scoped to school: `@@unique([schoolId, admissionNo])` — check before insert.
4. `employeeNo` uniqueness is scoped to school: `@@unique([schoolId, employeeNo])` — check before insert.
5. `receiptNo` uniqueness is scoped to school: `@@unique([schoolId, receiptNo])` — check before insert.
6. Joi validation runs BEFORE the controller handler for all POST/PUT routes.
7. The `requireSchoolAdmin` guard runs before every route handler.
8. Change password: use bcrypt compare; never log passwords.

---

## Error Cases Reference

| Scenario | Status | Message |
|---|---|---|
| admissionNo duplicate | 409 | "Admission number already exists in this school" |
| employeeNo duplicate | 409 | "Employee number already exists in this school" |
| receiptNo duplicate | 409 | "Receipt number already exists in this school" |
| Student/Staff/Notice not found | 404 | "Not found" |
| Delete class with sections | 400 | "Cannot delete class with existing sections" |
| Delete section with students | 400 | "Cannot delete section with assigned students" |
| Wrong current password | 401 | "Current password is incorrect" |
| Not a school admin | 403 | "Access denied. School admin privileges required." |
| No school on account | 403 | "No school assigned to this account." |
| Joi validation failure | 400 | joined detail messages |

---

## Output Checklist

- [ ] `backend/src/middleware/school-admin-guard.middleware.js`
- [ ] `backend/src/modules/school-admin/school-admin.validation.js`
- [ ] `backend/src/modules/school-admin/school-admin.repository.js`
- [ ] `backend/src/modules/school-admin/school-admin.service.js`
- [ ] `backend/src/modules/school-admin/school-admin.controller.js`
- [ ] `backend/src/modules/school-admin/school-admin.routes.js`
- [ ] `backend/src/app.js` — updated import and mount
