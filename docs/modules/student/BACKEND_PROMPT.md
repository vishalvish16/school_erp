# Student Module — Backend Prompt

**Purpose**: Implement the Student Portal backend — new `/api/student/*` module, `requireStudent` middleware, school-admin extensions for create-login and reset-password, and auth flow extension for `user_type=student`.

**Reference patterns**: `backend/src/modules/staff/` (staff portal), `backend/src/modules/teacher/`, `backend/src/modules/school-admin/`

**Root**: `e:/School_ERP_AI/erp-new-logic/`

---

## 1. Module Structure

Create `backend/src/modules/student/` with:

| File | Purpose |
|------|---------|
| `student.controller.js` | HTTP handlers for all /api/student/* endpoints |
| `student.service.js` | Business logic |
| `student.repository.js` | Prisma queries |
| `student.routes.js` | Route definitions |
| `student.validation.js` | Request validation (Zod or Joi) |

---

## 2. Middleware: requireStudent

Create `backend/src/middleware/student-guard.middleware.js`.

**Logic** (follow pattern from `staff-guard.middleware.js`):
1. Require `req.user` (from `verifyAccessToken`)
2. Require `req.user.portal_type === 'student'` (or `portalType === 'student'`)
3. Resolve `userId` from `req.user.userId || req.user.id`
4. Query: `Student` where `userId = userId`, `deletedAt IS NULL`, `status = 'ACTIVE'`
5. If not found → `AppError('Student account not found or inactive. Access denied.', 403)`
6. Attach `req.student` (the Student record)
7. Set `req.user.school_id = req.student.schoolId` for downstream consistency

**Import**: `PrismaClient`, `AppError` from `../utils/response.js`

---

## 3. Student Portal Routes

**Base path**: `/api/student`  
**Mount in** `backend/src/app.js`: `app.use('/api/student', studentRoutes);`

**Middleware chain**: `verifyAccessToken` → `requireStudent` (apply to all routes via `router.use`)

**Route order**: Specific paths (e.g. `/attendance/summary`) MUST come before parameterized paths (e.g. `/notices/:id`).

### 3.1 Endpoints

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| GET | `/profile` | `getProfile` | Own full profile |
| GET | `/dashboard` | `getDashboard` | Dashboard data |
| GET | `/attendance` | `getAttendance` | Own attendance (query: `month` YYYY-MM) |
| GET | `/attendance/summary` | `getAttendanceSummary` | Monthly summary |
| GET | `/fees/dues` | `getFeeDues` | Fee dues for current academic year |
| GET | `/fees/payments` | `getFeePayments` | Payment history (paginated) |
| GET | `/fees/receipt/:receiptNo` | `getReceiptByReceiptNo` | Receipt detail |
| GET | `/timetable` | `getTimetable` | Weekly timetable |
| GET | `/notices` | `getNotices` | Notices list (paginated) |
| GET | `/notices/:id` | `getNoticeById` | Notice detail |
| GET | `/documents` | `getDocuments` | Own documents list |
| POST | `/auth/change-password` | `changePassword` | Change password |

---

## 4. Request/Response Shapes

### 4.1 GET /profile

**Response** `{ success, data }`:
```json
{
  "id": "uuid",
  "admissionNo": "string",
  "firstName": "string",
  "lastName": "string",
  "gender": "MALE|FEMALE|OTHER",
  "dateOfBirth": "YYYY-MM-DD",
  "bloodGroup": "string|null",
  "phone": "string|null",
  "email": "string|null",
  "address": "string|null",
  "photoUrl": "string|null",
  "classId": "uuid|null",
  "sectionId": "uuid|null",
  "rollNo": "int|null",
  "class": { "id", "name", "numeric" },
  "section": { "id", "name" },
  "parentName": "string|null",
  "parentPhone": "string|null",
  "parentEmail": "string|null",
  "parentRelation": "string|null"
}
```

### 4.2 GET /dashboard

**Response** `{ success, data }`:
```json
{
  "todayAttendance": { "status": "PRESENT|ABSENT|LATE|HALF_DAY|null", "date": "YYYY-MM-DD" },
  "presentDaysThisMonth": 15,
  "totalFeePaidThisYear": 0,
  "upcomingDues": [ { "feeHead": "string", "amount": 0, "dueDate": "YYYY-MM-DD" } ],
  "todayTimetable": [ { "periodNo": 1, "subject": "string", "startTime": "string", "endTime": "string", "room": "string|null" } ],
  "recentNotices": [ { "id": "uuid", "title": "string", "publishedAt": "ISO8601", "isPinned": false } ],
  "unreadNoticesCount": 0
}
```

### 4.3 GET /attendance?month=YYYY-MM

**Query**: `month` (required, format YYYY-MM)

**Response** `{ success, data }`:
```json
{
  "records": [ { "date": "YYYY-MM-DD", "status": "PRESENT|ABSENT|LATE|HALF_DAY" } ],
  "month": "YYYY-MM"
}
```

### 4.4 GET /attendance/summary?month=YYYY-MM

**Query**: `month` (optional, default current month)

**Response** `{ success, data }`:
```json
{
  "month": "YYYY-MM",
  "present": 15,
  "absent": 3,
  "late": 1,
  "halfDay": 0
}
```

### 4.5 GET /fees/dues

**Response** `{ success, data }`:
```json
{
  "academicYear": "2025-26",
  "dues": [ { "feeHead": "string", "amount": 0, "dueDate": "YYYY-MM-DD", "paid": 0, "balance": 0 } ],
  "totalDue": 0
}
```

### 4.6 GET /fees/payments?page=1&limit=20

**Query**: `page`, `limit` (pagination)

**Response** `{ success, data, pagination }`:
```json
{
  "data": [ { "id", "feeHead", "amount", "paymentDate", "receiptNo", "paymentMode" } ],
  "pagination": { "page": 1, "limit": 20, "total": 0, "totalPages": 0 }
}
```

### 4.7 GET /fees/receipt/:receiptNo

**Response** `{ success, data }`:
```json
{
  "id": "uuid",
  "receiptNo": "string",
  "feeHead": "string",
  "amount": 0,
  "paymentDate": "YYYY-MM-DD",
  "paymentMode": "string",
  "remarks": "string|null"
}
```

### 4.8 GET /timetable

**Response** `{ success, data }`:
```json
{
  "slots": [ { "dayOfWeek": 1, "periodNo": 1, "subject": "string", "startTime": "string", "endTime": "string", "room": "string|null", "staffName": "string|null" } ]
}
```
`dayOfWeek`: 1=Mon, 6=Sat.

### 4.9 GET /notices?page=1&limit=20

**Query**: `page`, `limit`

**Response** `{ success, data, pagination }`:
- Filter: `targetRole IN ('student', 'all')`, `deletedAt IS NULL`, `publishedAt <= now`, `(expiresAt IS NULL OR expiresAt > now)`
- Order: `isPinned DESC`, `publishedAt DESC`

### 4.10 GET /notices/:id

**Response**: Single notice `{ id, title, body, publishedAt, expiresAt, isPinned }`

### 4.11 GET /documents

**Response** `{ success, data }`:
```json
{
  "data": [ { "id", "documentType", "documentName", "fileUrl", "fileSizeKb", "verified", "verifiedAt" } ]
}
```
Filter: `deletedAt IS NULL`, `studentId = req.student.id`

### 4.12 POST /auth/change-password

**Body** (validate):
```json
{ "currentPassword": "string", "newPassword": "string" }
```
- `newPassword`: min 8 chars
- Verify `currentPassword` against `User.passwordHash`, then update to `newPassword`
- Use `req.user.id` (User linked to Student) for the password update

---

## 5. School Admin Extensions

Add to `backend/src/modules/school-admin/`:

### 5.1 POST /api/school/students/:id/create-login

**Route**: Add to `school-admin.routes.js` (after existing student routes):
```javascript
router.post('/students/:id/create-login', validate(createStudentLoginSchema), ctrl.createStudentLogin);
router.post('/students/:id/reset-password', validate(resetStudentPasswordSchema), ctrl.resetStudentPassword);
```

**Validation** `createStudentLoginSchema`:
```javascript
{ password: Joi.string().min(8).max(128).required() }
```

**Logic** (in `school-admin.service.js`):
1. Find Student by id + schoolId, ensure `deletedAt IS NULL`, `status = 'ACTIVE'`
2. If `student.userId` exists → `AppError('Student already has a portal login', 409)`
3. Phone required: `student.phone || student.parentPhone` — if both null → `AppError('Student must have phone or parent phone to create login', 400)`
4. Find Role `name = 'STUDENT'`, scope SCHOOL — if not found → `AppError('STUDENT role not found. Add it to roles table.', 500)`
5. Email: Use `student_${student.admissionNo.replace(/[^a-zA-Z0-9]/g, '_')}@portal.vidyron.in` — ensure unique (append suffix if collision)
6. Create User: `email`, `passwordHash` (bcrypt 12 rounds), `schoolId`, `firstName`, `lastName`, `phone` (student.phone || parentPhone), `roleId` (STUDENT)
7. Update Student: `userId = newUser.id`
8. Audit: `STAFF_LOGIN_CREATE` → use `STUDENT_LOGIN_CREATE` for entityType `student`
9. Return `{ message: 'Portal login created. Student can log in with their phone and OTP.' }`

### 5.2 POST /api/school/students/:id/reset-password

**Validation** `resetStudentPasswordSchema`:
```javascript
{ newPassword: Joi.string().min(8).max(128).required() }
```

**Logic**:
1. Find Student by id + schoolId
2. If `!student.userId` → `AppError('Student has no portal login. Create one first.', 400)`
3. Update User password: `passwordHash = bcrypt.hash(newPassword, 12)`
4. Audit: `STUDENT_PASSWORD_RESET`
5. Return `{ message: 'Password reset successfully.' }`

---

## 6. Auth: resolve-user-by-phone Extension

**File**: `backend/src/modules/auth/resolve-user-by-phone.repository.js`

**Change**: When `userType === 'student'`, filter `users` to only those with `role.name === 'STUDENT'`.

Current flow: finds users by phone, returns first. Add:
```javascript
// After fetching users, if userType === 'student':
if (userType === 'student') {
    const filtered = validUsers.filter(u => (u.role?.name || '').toUpperCase() === 'STUDENT');
    if (filtered.length === 0) return null;
    // Use filtered instead of validUsers for the rest of the logic
}
```

**File**: `backend/src/modules/auth/auth.validation.js`

**Change**: `resolveUserByPhoneSchema` — extend `user_type` enum to include `'student'`:
```javascript
user_type: z.enum(['parent', 'student']).optional().default('parent')
```
(Already supports 'student' per spec — verify it does.)

---

## 7. Login Flow — JWT and portal_type

When a student logs in via smart-login (phone + OTP):
- JWT must include: `portal_type: 'student'`, `role: 'student'`, `school_id`, `userId` (User id)
- Auth guard: when `portal_type === 'student'` → redirect to `/student/dashboard` (Flutter)

Ensure the smart-login / device-verification flow sets `portal_type` from the User's role when role is STUDENT.

---

## 8. App Registration

In `backend/src/app.js`:
```javascript
import studentRoutes from './modules/student/student.routes.js';
// ...
app.use('/api/student', studentRoutes);
```

---

## 9. Repository Methods (student.repository.js)

| Method | Signature | Purpose |
|--------|-----------|---------|
| `findByUserId` | `(userId)` | Student where userId, deletedAt null, status ACTIVE |
| `findProfileById` | `(studentId, schoolId)` | Student with class, section includes |
| `getTodayAttendance` | `(studentId, date)` | Attendance for student+date |
| `getAttendanceByMonth` | `(studentId, year, month)` | All attendance records in month |
| `getAttendanceSummary` | `(studentId, year, month)` | Aggregated counts by status |
| `getFeeDues` | `(studentId, schoolId, academicYear)` | From FeeStructure vs FeePayment |
| `getFeePayments` | `(studentId, schoolId, page, limit)` | Paginated |
| `getFeePaymentByReceiptNo` | `(studentId, schoolId, receiptNo)` | Single receipt |
| `getTimetable` | `(classId, sectionId)` | Timetable slots |
| `getNotices` | `(schoolId, page, limit)` | Filter targetRole IN student,all |
| `getNoticeById` | `(id, schoolId)` | Single notice |
| `getStudentDocuments` | `(studentId)` | Where deletedAt null |

---

## 10. Service Methods (student.service.js)

Each controller calls a service method. Service uses repository. All methods receive `{ studentId, schoolId }` or equivalent from `req.student`.

**Academic year**: Use current academic year — e.g. if month >= 4 use `YYYY-(YY+1)`, else `(YYYY-1)-YY`. Or read from a config/table if available.

---

## 11. Error Handling

- Use `AppError` from `../../utils/response.js`
- 404: Student not found, notice not found, receipt not found
- 403: requireStudent fails (no/inactive student)
- 400: Validation errors, missing phone for create-login
- 409: Student already has login

---

## 12. Audit Log Events

| Event | entityType | When |
|-------|------------|------|
| `STUDENT_LOGIN_CREATE` | student | create-login |
| `STUDENT_PASSWORD_RESET` | student | reset-password |

Use `auditService.logAudit` (from school-admin module) with `actorId`, `actorRole: 'school_admin'`, `action`, `entityType`, `entityId`, `entityName`.

---

## 13. Validation (student.validation.js)

- `changePasswordSchema`: `currentPassword` (required), `newPassword` (min 8)
- Reuse existing patterns from `staff-portal.validation.js` or `teacher.validation.js`

---

## 14. Summary Checklist

- [ ] Create `student-guard.middleware.js` (requireStudent)
- [ ] Create `student.controller.js`, `student.service.js`, `student.repository.js`, `student.routes.js`, `student.validation.js`
- [ ] Implement all 12 student portal endpoints
- [ ] Add `createStudentLogin`, `resetStudentPassword` to school-admin (controller, service, repository, validation, routes)
- [ ] Extend `resolve-user-by-phone.repository.js` for `user_type=student`
- [ ] Register `/api/student` in `app.js`
- [ ] Ensure STUDENT role exists (seed/migration)
