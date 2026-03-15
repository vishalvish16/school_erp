# School Admin Portal — Technical Specification

## Overview
Portal for school principals and head admins to manage their school's day-to-day operations.
- **URL**: `{schoolname}.vidyron.in` (login at `/login/school`)
- **Portal Type** (JWT): `school_admin`
- **API Base**: `/api/school/`
- **Accent Color**: `#4CAF50` (green), badge `#1B5E20` dark green

---

## 1. Database Models (Prisma)

All models use `school_id UUID` FK referencing `School.id` with `onDelete: Cascade`.

### 1.1 Student
```prisma
model Student {
  id              String    @id @default(uuid()) @db.Uuid
  schoolId        String    @map("school_id") @db.Uuid
  admissionNo     String    @map("admission_no") @db.VarChar(50)
  firstName       String    @map("first_name") @db.VarChar(100)
  lastName        String    @map("last_name") @db.VarChar(100)
  gender          String    @db.VarChar(10)        // MALE | FEMALE | OTHER
  dateOfBirth     DateTime  @map("date_of_birth") @db.Date
  bloodGroup      String?   @map("blood_group") @db.VarChar(5)
  phone           String?   @db.VarChar(20)
  email           String?   @db.VarChar(255)
  address         String?   @db.Text
  photoUrl        String?   @map("photo_url") @db.Text
  classId         String?   @map("class_id") @db.Uuid
  sectionId       String?   @map("section_id") @db.Uuid
  rollNo          Int?      @map("roll_no")
  status          String    @default("ACTIVE") @db.VarChar(20) // ACTIVE | INACTIVE | TRANSFERRED
  admissionDate   DateTime  @map("admission_date") @db.Date
  // Parent/Guardian
  parentName      String?   @map("parent_name") @db.VarChar(200)
  parentPhone     String?   @map("parent_phone") @db.VarChar(20)
  parentEmail     String?   @map("parent_email") @db.VarChar(255)
  parentRelation  String?   @map("parent_relation") @db.VarChar(50)
  deletedAt       DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt       DateTime  @default(now()) @map("created_at")
  updatedAt       DateTime  @default(now()) @updatedAt @map("updated_at")

  school          School         @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_          SchoolClass?   @relation(fields: [classId], references: [id], onDelete: SetNull)
  section         Section?       @relation(fields: [sectionId], references: [id], onDelete: SetNull)
  attendances     Attendance[]

  @@unique([schoolId, admissionNo])
  @@index([schoolId])
  @@index([classId])
  @@map("students")
}
```

### 1.2 Staff
```prisma
model Staff {
  id           String    @id @default(uuid()) @db.Uuid
  schoolId     String    @map("school_id") @db.Uuid
  userId       String?   @unique @map("user_id") @db.Uuid   // links to User for login
  employeeNo   String    @map("employee_no") @db.VarChar(50)
  firstName    String    @map("first_name") @db.VarChar(100)
  lastName     String    @map("last_name") @db.VarChar(100)
  gender       String    @db.VarChar(10)
  dateOfBirth  DateTime? @map("date_of_birth") @db.Date
  phone        String?   @db.VarChar(20)
  email        String    @db.VarChar(255)
  designation  String    @db.VarChar(100)      // TEACHER | CLERK | LIBRARIAN | ACCOUNTANT | etc
  subjects     String[]  @default([])          // array of subject names
  qualification String?  @db.VarChar(255)
  joinDate     DateTime  @map("join_date") @db.Date
  photoUrl     String?   @map("photo_url") @db.Text
  isActive     Boolean   @default(true) @map("is_active")
  deletedAt    DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt    DateTime  @default(now()) @map("created_at")
  updatedAt    DateTime  @default(now()) @updatedAt @map("updated_at")

  school       School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  user         User?        @relation("StaffUser", fields: [userId], references: [id], onDelete: SetNull)

  @@unique([schoolId, employeeNo])
  @@index([schoolId])
  @@map("staff")
}
```

### 1.3 SchoolClass
```prisma
model SchoolClass {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  name        String    @db.VarChar(50)     // "Class 1", "Grade 10", "LKG"
  numeric     Int?                          // sort order (1–12, null for LKG/UKG)
  isActive    Boolean   @default(true) @map("is_active")
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @default(now()) @updatedAt @map("updated_at")

  school      School     @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  sections    Section[]
  students    Student[]
  timetables  Timetable[]
  feeStructures FeeStructure[]

  @@unique([schoolId, name])
  @@index([schoolId])
  @@map("school_classes")
}
```

### 1.4 Section
```prisma
model Section {
  id             String    @id @default(uuid()) @db.Uuid
  schoolId       String    @map("school_id") @db.Uuid
  classId        String    @map("class_id") @db.Uuid
  name           String    @db.VarChar(10)  // "A", "B", "C"
  classTeacherId String?   @map("class_teacher_id") @db.Uuid  // FK Staff.id
  capacity       Int       @default(40)
  isActive       Boolean   @default(true) @map("is_active")
  createdAt      DateTime  @default(now()) @map("created_at")
  updatedAt      DateTime  @default(now()) @updatedAt @map("updated_at")

  school         School      @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_         SchoolClass @relation(fields: [classId], references: [id], onDelete: Cascade)
  classTeacher   Staff?      @relation("ClassTeacher", fields: [classTeacherId], references: [id], onDelete: SetNull)
  students       Student[]
  attendances    Attendance[]
  timetables     Timetable[]

  @@unique([classId, name])
  @@index([schoolId])
  @@map("sections")
}
```

### 1.5 Attendance
```prisma
model Attendance {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  studentId   String    @map("student_id") @db.Uuid
  sectionId   String    @map("section_id") @db.Uuid
  date        DateTime  @db.Date
  status      String    @db.VarChar(10)  // PRESENT | ABSENT | LATE | HOLIDAY
  markedBy    String    @map("marked_by") @db.Uuid   // Staff.id or User.id
  remarks     String?   @db.VarChar(255)
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @default(now()) @updatedAt @map("updated_at")

  school      School    @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  student     Student   @relation(fields: [studentId], references: [id], onDelete: Cascade)
  section     Section   @relation(fields: [sectionId], references: [id], onDelete: Cascade)

  @@unique([studentId, date])
  @@index([schoolId, date])
  @@index([sectionId, date])
  @@map("attendances")
}
```

### 1.6 FeeStructure
```prisma
model FeeStructure {
  id            String    @id @default(uuid()) @db.Uuid
  schoolId      String    @map("school_id") @db.Uuid
  classId       String?   @map("class_id") @db.Uuid  // null = applies to all
  academicYear  String    @map("academic_year") @db.VarChar(10)  // "2025-26"
  feeHead       String    @map("fee_head") @db.VarChar(100) // "Tuition", "Transport", "Library"
  amount        Decimal   @db.Decimal(10,2)
  frequency     String    @db.VarChar(20)  // MONTHLY | QUARTERLY | ANNUALLY | ONE_TIME
  dueDay        Int?      @map("due_day")  // day of month
  isActive      Boolean   @default(true) @map("is_active")
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @default(now()) @updatedAt @map("updated_at")

  school        School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_        SchoolClass? @relation(fields: [classId], references: [id], onDelete: SetNull)

  @@index([schoolId, academicYear])
  @@map("fee_structures")
}
```

### 1.7 FeePayment
```prisma
model FeePayment {
  id              String    @id @default(uuid()) @db.Uuid
  schoolId        String    @map("school_id") @db.Uuid
  studentId       String    @map("student_id") @db.Uuid
  feeHead         String    @map("fee_head") @db.VarChar(100)
  academicYear    String    @map("academic_year") @db.VarChar(10)
  amount          Decimal   @db.Decimal(10,2)
  paymentDate     DateTime  @map("payment_date") @db.Date
  paymentMode     String    @map("payment_mode") @db.VarChar(30)  // CASH | UPI | BANK_TRANSFER | CHEQUE
  receiptNo       String    @map("receipt_no") @db.VarChar(50)
  collectedBy     String    @map("collected_by") @db.Uuid  // User.id
  remarks         String?   @db.VarChar(255)
  createdAt       DateTime  @default(now()) @map("created_at")
  updatedAt       DateTime  @default(now()) @updatedAt @map("updated_at")

  school          School    @relation(fields: [schoolId], references: [id], onDelete: Cascade)

  @@unique([schoolId, receiptNo])
  @@index([schoolId, studentId])
  @@map("fee_payments")
}
```

### 1.8 SchoolNotice
```prisma
model SchoolNotice {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  title       String    @db.VarChar(255)
  body        String    @db.Text
  targetRole  String?   @map("target_role") @db.VarChar(50)  // all | teacher | student | parent
  isPinned    Boolean   @default(false) @map("is_pinned")
  publishedAt DateTime? @map("published_at") @db.Timestamptz(6)
  expiresAt   DateTime? @map("expires_at") @db.Timestamptz(6)
  createdBy   String    @map("created_by") @db.Uuid
  deletedAt   DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt   DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt   DateTime  @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

  school      School    @relation(fields: [schoolId], references: [id], onDelete: Cascade)

  @@index([schoolId])
  @@map("school_notices")
}
```

### 1.9 Timetable
```prisma
model Timetable {
  id         String    @id @default(uuid()) @db.Uuid
  schoolId   String    @map("school_id") @db.Uuid
  classId    String    @map("class_id") @db.Uuid
  sectionId  String?   @map("section_id") @db.Uuid
  dayOfWeek  Int       @map("day_of_week")  // 1=Mon … 6=Sat
  periodNo   Int       @map("period_no")
  subject    String    @db.VarChar(100)
  staffId    String?   @map("staff_id") @db.Uuid
  startTime  String    @map("start_time") @db.VarChar(8)  // "08:00"
  endTime    String    @map("end_time") @db.VarChar(8)    // "08:45"
  room       String?   @db.VarChar(50)
  createdAt  DateTime  @default(now()) @map("created_at")
  updatedAt  DateTime  @default(now()) @updatedAt @map("updated_at")

  school     School      @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_     SchoolClass @relation(fields: [classId], references: [id], onDelete: Cascade)
  section    Section?    @relation(fields: [sectionId], references: [id], onDelete: SetNull)

  @@unique([classId, sectionId, dayOfWeek, periodNo])
  @@index([schoolId])
  @@map("timetables")
}
```

---

## 2. Backend API

**Auth**: All routes protected by `verifyAccessToken` + `requireSchoolAdmin` middleware.
`req.user` provides: `{ id, school_id, role, portal_type }`

### 2.1 Dashboard
```
GET /api/school/dashboard/stats
Response: {
  success: true,
  data: {
    total_students: number,
    total_staff: number,
    total_classes: number,
    total_sections: number,
    today_attendance_percent: number,   // students present today / total
    fee_collected_this_month: number,   // sum of fee_payments.amount this month
    notices_count: number,
    recent_activity: [{ type, message, created_at }]
  }
}
```

### 2.2 Students
```
GET    /api/school/students?page=1&limit=20&search=&classId=&sectionId=&status=
POST   /api/school/students
GET    /api/school/students/:id
PUT    /api/school/students/:id
DELETE /api/school/students/:id        (soft delete)

POST body / PUT body:
{
  firstName, lastName, gender, dateOfBirth, admissionNo, admissionDate,
  classId?, sectionId?, rollNo?, bloodGroup?, phone?, email?, address?,
  photoUrl?, parentName?, parentPhone?, parentEmail?, parentRelation?, status?
}

List response: { success, data: [...], pagination: { page, limit, total, total_pages } }
Single: { success, data: { ...all fields, class_name, section_name } }
```

### 2.3 Staff
```
GET    /api/school/staff?page=1&limit=20&search=&designation=&isActive=
POST   /api/school/staff
GET    /api/school/staff/:id
PUT    /api/school/staff/:id
DELETE /api/school/staff/:id           (soft delete)

POST/PUT body:
{
  firstName, lastName, gender, dateOfBirth?, phone?, email, designation,
  subjects?, qualification?, joinDate, photoUrl?, isActive?, employeeNo
}
```

### 2.4 Classes
```
GET    /api/school/classes               (no pagination — short list)
POST   /api/school/classes
PUT    /api/school/classes/:id
DELETE /api/school/classes/:id

POST/PUT body: { name, numeric? }
Response includes sections with student_count
```

### 2.5 Sections
```
GET    /api/school/classes/:classId/sections
POST   /api/school/classes/:classId/sections
PUT    /api/school/sections/:id
DELETE /api/school/sections/:id

POST/PUT body: { name, classTeacherId?, capacity? }
```

### 2.6 Attendance
```
GET  /api/school/attendance?classId=&sectionId=&date=2026-03-15
POST /api/school/attendance/bulk          bulk mark for a section+date
GET  /api/school/attendance/report?classId=&sectionId=&month=2026-03

Bulk POST body: {
  sectionId,
  date,
  records: [{ studentId, status, remarks? }]
}
Bulk response: { success, data: { saved: number, date, section_name } }

Report response: { success, data: { calendar: [{ date, present, absent, late }], summary: { present_days, absent_days, total_days } } }
```

### 2.7 Fees
```
GET    /api/school/fees/structures?academicYear=&classId=
POST   /api/school/fees/structures
PUT    /api/school/fees/structures/:id
DELETE /api/school/fees/structures/:id

GET    /api/school/fees/payments?page=1&limit=20&studentId=&month=&academicYear=
POST   /api/school/fees/payments
GET    /api/school/fees/payments/:id
GET    /api/school/fees/summary?month=2026-03     monthly collection totals

POST /api/school/fees/payments body:
{
  studentId, feeHead, academicYear, amount, paymentDate,
  paymentMode, receiptNo, remarks?
}
```

### 2.8 Timetable
```
GET /api/school/timetable?classId=&sectionId=
PUT /api/school/timetable/bulk            (replace entire class timetable)

Bulk PUT body: { classId, sectionId?, entries: [{ dayOfWeek, periodNo, subject, staffId?, startTime, endTime, room? }] }
```

### 2.9 Notices
```
GET    /api/school/notices?page=1&limit=20&search=
POST   /api/school/notices
PUT    /api/school/notices/:id
DELETE /api/school/notices/:id            (soft delete)

POST/PUT body: { title, body, targetRole?, isPinned?, publishedAt?, expiresAt? }
```

### 2.10 Notifications
```
GET  /api/school/notifications?page=1&limit=20
GET  /api/school/notifications/unread-count
PUT  /api/school/notifications/:id/read
```

### 2.11 Profile
```
GET  /api/school/profile                  school info + admin user info
PUT  /api/school/profile/user             update personal info { firstName, lastName, phone, avatarUrl?, avatar_base64? }
PUT  /api/school/profile/school           update school info { name, phone, email, address, city, state, logoUrl? }
POST /api/school/auth/change-password     { currentPassword, newPassword }
```

---

## 3. Backend File Structure

```
backend/src/modules/school-admin/
  school-admin.routes.js
  school-admin.controller.js
  school-admin.service.js
  school-admin.repository.js
  school-admin.validation.js

backend/src/middleware/
  school-admin-guard.middleware.js   (requireSchoolAdmin — checks portal_type === 'school_admin')
```

Route registration in `app.js`:
```js
import schoolAdminRoutes from './modules/school-admin/school-admin.routes.js';
app.use('/api/school', schoolAdminRoutes);  // replaces existing placeholder
```

---

## 4. Flutter File Structure

```
lib/
  core/
    services/school_admin_service.dart        API calls
    config/api_config.dart                    add SchoolAdmin endpoints
  models/school_admin/
    student_model.dart
    staff_model.dart
    school_class_model.dart
    section_model.dart
    attendance_model.dart
    fee_structure_model.dart
    fee_payment_model.dart
    school_notice_model.dart
    dashboard_stats_model.dart
  features/school_admin/
    presentation/
      school_admin_shell.dart                 shell layout (sidebar + mobile)
      providers/
        school_admin_dashboard_provider.dart
        school_admin_students_provider.dart
        school_admin_staff_provider.dart
        school_admin_classes_provider.dart
        school_admin_attendance_provider.dart
        school_admin_fees_provider.dart
        school_admin_timetable_provider.dart
        school_admin_notices_provider.dart
        school_admin_notifications_provider.dart
        school_admin_profile_provider.dart
      screens/
        school_admin_dashboard_screen.dart
        school_admin_students_screen.dart
        school_admin_student_detail_screen.dart
        school_admin_staff_screen.dart
        school_admin_staff_detail_screen.dart
        school_admin_classes_screen.dart
        school_admin_attendance_screen.dart
        school_admin_attendance_report_screen.dart
        school_admin_fees_screen.dart
        school_admin_fee_collection_screen.dart
        school_admin_timetable_screen.dart
        school_admin_notices_screen.dart
        school_admin_notifications_screen.dart
        school_admin_profile_screen.dart
        school_admin_change_password_screen.dart
        school_admin_settings_screen.dart
```

---

## 5. Shell Navigation

**Routes prefix**: `/school-admin/`

| Label | Route | Icon |
|-------|-------|------|
| Dashboard | `/school-admin/dashboard` | `dashboard` |
| Students | `/school-admin/students` | `people` |
| Teachers | `/school-admin/staff` | `person_search` |
| Classes | `/school-admin/classes` | `class_` |
| Attendance | `/school-admin/attendance` | `fact_check` |
| Fees | `/school-admin/fees` | `payments` |
| Timetable | `/school-admin/timetable` | `schedule` |
| Notices | `/school-admin/notices` | `campaign` |
| — ACCOUNT — | | |
| Notifications | `/school-admin/notifications` | `notifications` |
| Profile | `/school-admin/profile` | `person` |
| Change Password | `/school-admin/change-password` | `lock_reset` |
| Settings | `/school-admin/settings` | `settings` |

**Accent**: `const Color _accentColor = Color(0xFF4CAF50)` (green)
**Badge text**: `'SCHOOL ADMIN'`
**Badge bg**: `Color(0xFF1B5E20)` dark green on white bg

**Auth redirect**: `portalType == 'school_admin'` → `/school-admin/dashboard`
**Login redirect after auth**: `/login/school` → success → `/school-admin/dashboard`

---

## 6. Router Changes (`app_router.dart`)

Add to `redirect()`:
```dart
final isSchoolAdmin = portalType.value == 'school_admin';
if (isAuthenticated && isSchoolAdmin && !loc.startsWith('/school-admin')) {
  return '/school-admin/dashboard';
}
```

Add ShellRoute under Group Admin shell:
```dart
ShellRoute(
  builder: (context, state, child) => SchoolAdminShell(child: child),
  routes: [
    GoRoute(path: '/school-admin', redirect: (_, __) => '/school-admin/dashboard'),
    GoRoute(path: '/school-admin/dashboard', builder: ...),
    GoRoute(path: '/school-admin/students', builder: ...),
    GoRoute(path: '/school-admin/students/:id', builder: ...),
    GoRoute(path: '/school-admin/staff', builder: ...),
    GoRoute(path: '/school-admin/staff/:id', builder: ...),
    GoRoute(path: '/school-admin/classes', builder: ...),
    GoRoute(path: '/school-admin/attendance', builder: ...),
    GoRoute(path: '/school-admin/attendance/report', builder: ...),
    GoRoute(path: '/school-admin/fees', builder: ...),
    GoRoute(path: '/school-admin/fees/collection', builder: ...),
    GoRoute(path: '/school-admin/timetable', builder: ...),
    GoRoute(path: '/school-admin/notices', builder: ...),
    GoRoute(path: '/school-admin/notifications', builder: ...),
    GoRoute(path: '/school-admin/profile', builder: ...),
    GoRoute(path: '/school-admin/change-password', builder: ...),
    GoRoute(path: '/school-admin/settings', builder: ...),
  ],
),
```

---

## 7. API Config Constants (`api_config.dart`)

```dart
// School Admin
static const String schoolDashboardStats = '/api/school/dashboard/stats';
static const String schoolStudents       = '/api/school/students';
static const String schoolStaff          = '/api/school/staff';
static const String schoolClasses        = '/api/school/classes';
static const String schoolSections       = '/api/school/sections';
static const String schoolAttendance     = '/api/school/attendance';
static const String schoolFeeStructures  = '/api/school/fees/structures';
static const String schoolFeePayments    = '/api/school/fees/payments';
static const String schoolFeeSummary     = '/api/school/fees/summary';
static const String schoolTimetable      = '/api/school/timetable';
static const String schoolNotices        = '/api/school/notices';
static const String schoolNotifications  = '/api/school/notifications';
static const String schoolProfile        = '/api/school/profile';
static const String schoolChangePassword = '/api/school/auth/change-password';
```

---

## 8. Security Requirements

- `verifyAccessToken` on every route (checks JWT, loads user)
- `requireSchoolAdmin` middleware: `req.user.portal_type === 'school_admin'` else 403
- All DB queries MUST include `schoolId: req.user.school_id` — no cross-school data leakage
- Soft delete: `deletedAt: null` filter on all findMany
- Input validation via Joi on all POST/PUT bodies
- `admissionNo` and `employeeNo` unique within a school (not globally)

---

## 9. Migration

File: `backend/prisma/migrations/20260315130000_add_school_admin_models/migration.sql`

Creates tables: `students`, `staff`, `school_classes`, `sections`, `attendances`, `fee_structures`, `fee_payments`, `school_notices`, `timetables`

Add to User model in schema.prisma:
```prisma
staffProfile    Staff?    @relation("StaffUser")
```

Add to School model:
```prisma
students        Student[]
staff           Staff[]
classes         SchoolClass[]
sections        Section[]
attendances     Attendance[]
feeStructures   FeeStructure[]
feePayments     FeePayment[]
notices         SchoolNotice[]
timetables      Timetable[]
```
