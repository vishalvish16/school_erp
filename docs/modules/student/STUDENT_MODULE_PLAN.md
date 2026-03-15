# Student Portal Module — Build Plan

**Platform**: Vidyron School ERP  
**Version**: 1.0  
**Date**: 2026-03-16  
**Scope**: Full Student portal — login → dashboard → profile → attendance → fees → timetable → notices → documents

---

## 1. Overview

Build the **Student Portal** — a self-service portal for students (Class 9+) to log in and access their own data. The flow spans:

1. **Login** — Extend existing parent/student login (vidyron.in/login) to support student identity
2. **Dashboard** — Personalized overview: today's attendance, fee dues, timetable, notices
3. **Profile** — View and request updates to personal info
4. **Attendance** — View own attendance record (monthly)
5. **Fees** — View fee dues, payment history, receipts
6. **Timetable** — Read-only weekly class schedule
7. **Notices** — School notices targeted at students
8. **Documents** — View uploaded documents (Aadhaar, transfer cert, etc.)

### Tech Stack

| Layer    | Technology                    |
|----------|-------------------------------|
| Frontend | Flutter, Riverpod, GoRouter   |
| Backend  | Node.js, Express, Prisma      |
| Database | PostgreSQL (existing schema)   |

### Existing Assets

- **Student model** in Prisma: `Student` with schoolId, admissionNo, firstName, lastName, gender, dateOfBirth, classId, sectionId, rollNo, status, parentName, parentPhone, parentEmail, etc.
- **Attendance** table: `Attendance` (studentId, sectionId, date, status)
- **FeePayment** table: `FeePayment` (studentId, feeHead, amount, receiptNo, etc.)
- **Timetable** table: `Timetable` (classId, sectionId, dayOfWeek, periodNo, subject, staffId)
- **SchoolNotice** table: `SchoolNotice` (schoolId, targetRole)
- **Parent/Student login** screen: `ParentLoginScreen` with `ParentStudentUserType.parent | student`
- **Auth**: JWT with portal_type, school_id, role

### Gap: Student–User Link

The `Student` model has **no `user_id`** today. Students cannot log in directly. To enable student portal:

- Add `userId String? @map("user_id") @unique @db.Uuid` to `Student` (optional FK → users.id)
- When School Admin creates a "portal login" for a student, create a User with role STUDENT and link via `student.user_id`
- `resolve-user-by-phone` and smart-login must support `user_type: 'student'` and resolve to User linked to Student

---

## 2. User Stories

### Login & Auth

- As a student, I can log in at vidyron.in/login by selecting "Student" and entering my phone number so that I access my portal.
- As a student, I receive an OTP to verify my identity before accessing the portal.
- As a school admin, I can create a portal login for a student (Class 9+) so that they can log in independently.

### Dashboard

- As a student, I see a dashboard with: today's attendance status, upcoming fee dues, today's timetable, and recent notices.
- As a student, I see quick stats: present days this month, total fee paid this year, unread notices count.

### Profile

- As a student, I can view my full profile: name, admission no, class-section, roll no, DOB, blood group, parent contact, address, photo.
- As a student, I can request a profile update (phone, address) so that admin can approve it (v1: request creates a note; admin edits manually).

### Attendance

- As a student, I can view my attendance for the current month and past months.
- As a student, I see a summary: present, absent, late, half-day counts per month.

### Fees

- As a student, I can view my fee dues (by fee head, amount, due date).
- As a student, I can view my payment history and download receipts.

### Timetable

- As a student, I can view my weekly timetable (Mon–Sat, periods) for my class-section.

### Notices

- As a student, I can view school notices targeted at "students" or "all".
- As a student, I can mark a notice as read (optional — v1: just list).

### Documents

- As a student, I can view documents uploaded for me (Aadhaar, transfer certificate, etc.) — read-only, no upload from student.

---

## 3. Data Model Changes

### 3.1 Student Table — Add user_id

```prisma
model Student {
  // ... existing fields ...
  userId    String?  @unique @map("user_id") @db.Uuid  // NEW — for portal login
  // ...
  user      User?    @relation(fields: [userId], references: [id], onDelete: SetNull)  // NEW
}
```

### 3.2 User Model — Add Student Relation

```prisma
model User {
  // ... existing ...
  studentProfile Student? @relation("StudentUser")  // NEW
}
```

### 3.3 Student Documents Table (NEW)

Students need document storage (like staff). Create `student_documents`:

| Column        | Type        | Constraints                          |
|---------------|-------------|--------------------------------------|
| id            | UUID        | PK                                   |
| schoolId      | UUID        | FK → schools.id                      |
| studentId     | UUID        | FK → students.id ON DELETE CASCADE   |
| documentType  | VarChar(50) | AADHAAR, TRANSFER_CERT, BIRTH_CERT, OTHER |
| documentName  | VarChar(255)|                                      |
| fileUrl       | Text        |                                      |
| fileSizeKb    | Int?        |                                      |
| mimeType      | VarChar(100)?|                                     |
| uploadedBy    | UUID        | FK → users.id                        |
| verified      | Boolean     | Default false                        |
| verifiedAt    | Timestamptz?|                                      |
| verifiedBy    | UUID?       | FK → users.id                        |
| deletedAt     | Timestamptz?| Soft delete                          |
| createdAt     | Timestamptz |                                      |
| updatedAt     | Timestamptz |                                      |

### 3.4 Existing Tables Used (No Schema Change)

| Table          | Usage                                      |
|----------------|--------------------------------------------|
| Student        | Core profile; add user_id                  |
| Attendance     | Student's attendance by studentId + date    |
| FeePayment     | Student's payments by studentId            |
| FeeStructure   | Fee heads for class/academic year          |
| Timetable      | By classId + sectionId                     |
| SchoolNotice   | targetRole IN ('student', 'all')           |

---

## 4. API Contract — Student Portal

**Base path**: `/api/student/`  
**Auth**: `verifyAccessToken` + `requireStudent` (new middleware)  
**School isolation**: `req.student.schoolId` from JWT/session

### 4.1 Middleware: requireStudent

- Resolve `req.user` from JWT
- Look up `Student` where `userId = req.user.id` and `deletedAt IS NULL` and `status = 'ACTIVE'`
- If not found → 403
- Attach `req.student` for controllers

### 4.2 Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/student/profile | Own profile (full) |
| GET | /api/student/dashboard | Dashboard data (attendance today, fee summary, timetable today, notices) |
| GET | /api/student/attendance | Own attendance (query: month YYYY-MM) |
| GET | /api/student/attendance/summary | Monthly summary (present, absent, late, half_day) |
| GET | /api/student/fees/dues | Fee dues for current academic year |
| GET | /api/student/fees/payments | Payment history (paginated) |
| GET | /api/student/fees/receipt/:receiptNo | Receipt detail (for download) |
| GET | /api/student/timetable | Weekly timetable for own class-section |
| GET | /api/student/notices | Notices (targetRole student/all), paginated |
| GET | /api/student/notices/:id | Notice detail |
| GET | /api/student/documents | Own documents list |

### 4.3 Response Shapes

**GET /api/student/profile**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "admission_no": "ADM-2025-001",
    "first_name": "Rahul",
    "last_name": "Kumar",
    "gender": "MALE",
    "date_of_birth": "2010-05-15",
    "blood_group": "B+",
    "phone": "9876543210",
    "email": "rahul@example.com",
    "address": "123 MG Road",
    "city": "Bengaluru",
    "photo_url": null,
    "class_id": "uuid",
    "class_name": "Class 9",
    "section_id": "uuid",
    "section_name": "A",
    "roll_no": 12,
    "status": "ACTIVE",
    "admission_date": "2025-04-01",
    "parent_name": "Suresh Kumar",
    "parent_phone": "9876500001",
    "parent_email": "suresh@example.com",
    "parent_relation": "Father",
    "school": { "name": "Vidyron Model School", "logo_url": null }
  }
}
```

**GET /api/student/dashboard**
```json
{
  "success": true,
  "data": {
    "student": { "id": "uuid", "first_name": "Rahul", "last_name": "Kumar", "class_name": "9", "section_name": "A" },
    "today_attendance": { "status": "PRESENT", "remarks": null },
    "attendance_summary": { "month": "2026-03", "present": 18, "absent": 1, "late": 0, "half_day": 0 },
    "fee_dues": [ { "fee_head": "Tuition", "amount": 5000, "due_date": "2026-03-31" } ],
    "fee_paid_this_year": 15000,
    "today_timetable": [ { "period_no": 1, "subject": "Maths", "start_time": "08:00", "end_time": "08:45", "teacher": "Ravi Sharma" } ],
    "unread_notices": 3,
    "recent_notices": [ { "id": "uuid", "title": "Holiday Notice", "published_at": "2026-03-10" } ]
  }
}
```

**GET /api/student/attendance?month=2026-03**
```json
{
  "success": true,
  "data": {
    "month": "2026-03",
    "summary": { "present": 18, "absent": 1, "late": 0, "half_day": 0 },
    "records": [
      { "date": "2026-03-01", "status": "PRESENT", "remarks": null },
      { "date": "2026-03-02", "status": "ABSENT", "remarks": "Sick" }
    ]
  }
}
```

**GET /api/student/fees/dues**
```json
{
  "success": true,
  "data": [
    { "fee_head": "Tuition", "amount": 5000, "due_day": 31, "academic_year": "2025-26" }
  ]
}
```

**GET /api/student/fees/payments?page=1&limit=10**
```json
{
  "success": true,
  "data": {
    "data": [
      { "id": "uuid", "fee_head": "Tuition", "amount": 5000, "payment_date": "2026-03-01", "receipt_no": "RCP-001", "payment_mode": "CASH" }
    ],
    "pagination": { "page": 1, "limit": 10, "total": 5, "total_pages": 1 }
  }
}
```

**GET /api/student/timetable**
```json
{
  "success": true,
  "data": {
    "class_name": "Class 9",
    "section_name": "A",
    "academic_year": "2025-26",
    "schedule": [
      {
        "day_of_week": 1,
        "day_name": "Monday",
        "periods": [
          { "period_no": 1, "subject": "Maths", "start_time": "08:00", "end_time": "08:45", "teacher": "Ravi Sharma", "room": null }
        ]
      }
    ]
  }
}
```

**GET /api/student/notices?page=1&limit=20**
```json
{
  "success": true,
  "data": {
    "data": [
      { "id": "uuid", "title": "Holiday Notice", "body": "...", "published_at": "2026-03-10", "is_pinned": false }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 10, "total_pages": 1 }
  }
}
```

---

## 5. School Admin: Create Student Login

Add to School Admin student detail screen:

- **Create Portal Login** button (when student has no user_id)
- Opens dialog: set password (or send OTP for first login)
- Backend: create User with role STUDENT, link student.userId = user.id
- **Reset Password** for existing login

**API (School Admin)**:
- POST /api/school/students/:id/create-login — body: `{ "password": "..." }`
- POST /api/school/students/:id/reset-password — body: `{ "password": "..." }`

---

## 6. Auth Flow for Student Login

### resolve-user-by-phone (extend)

When `user_type: 'student'`:
- Look up User where phone matches AND role.name = 'STUDENT'
- Include school, return schools + user
- OTP flow same as parent

### Roles

- Ensure Role with name `STUDENT` exists (scope: SCHOOL)
- JWT: `portal_type: 'student'`, `role: 'student'`, `school_id`, `userId`

---

## 7. Flutter Screens — Student Portal

### 7.1 Student Shell

- Route prefix: `/student`
- Nav items: Dashboard, Attendance, Fees, Timetable, Notices
- Account: Profile, Change Password

### 7.2 Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| StudentDashboardScreen | /student/dashboard | Dashboard with stats, today attendance, fee dues, timetable, notices |
| StudentProfileScreen | /student/profile | Full profile view |
| StudentAttendanceScreen | /student/attendance | Monthly attendance with summary |
| StudentFeesScreen | /student/fees | Fee dues + payment history tabs |
| StudentTimetableScreen | /student/timetable | Weekly timetable grid |
| StudentNoticesScreen | /student/notices | List of notices |
| StudentNoticeDetailScreen | /student/notices/:id | Notice detail |
| StudentDocumentsScreen | /student/documents | Documents list (read-only) |
| StudentChangePasswordScreen | /student/change-password | Change password |

### 7.3 Models

- `StudentProfileModel` — extend existing StudentModel
- `StudentDashboardModel` — dashboard response
- `StudentAttendanceModel` — attendance record + summary
- `StudentFeeDueModel`, `StudentPaymentModel`
- `StudentTimetableModel` — schedule
- `StudentNoticeModel` — notice (reuse SchoolNoticeModel if exists)
- `StudentDocumentModel` — document metadata

### 7.4 Services

- `StudentService` — all /api/student/* calls
- `ApiConfig` — add student endpoints

### 7.5 Auth Guard

- Extend auth flow: when `portal_type == 'student'` → redirect to `/student/dashboard`
- Add student shell route with `requireAuth` + student portal check

---

## 8. Cross-Cutting Concerns

| Concern | Owner | Detail |
|---------|-------|--------|
| Student–User link | DB + Backend | Add user_id to Student; create-login creates User + link |
| requireStudent middleware | Backend | Resolve Student from req.user.id |
| resolve-user-by-phone student filter | Backend | When user_type=student, filter role=STUDENT |
| URL trailing slashes | Backend | Use `/api/student/` for list endpoints |
| Response envelope | Backend | `{ success, data }` consistent |
| Student shell route | Flutter | Guard: portal_type must be student |

---

## 9. Validation

### Database
- Migration adds user_id to students, creates student_documents
- Seed STUDENT role if missing

### Backend
- requireStudent middleware blocks non-student users
- All /api/student/* return 403 if no linked Student

### Frontend
- Student shell only accessible when portal_type=student
- All screens call StudentService with JWT

### E2E
- Login as student → dashboard loads → profile shows correct data → attendance/fees/timetable/notices render

---

## 10. Acceptance Criteria

1. **Login**: Student can log in via vidyron.in/login (student mode) with phone + OTP
2. **Dashboard**: Shows today attendance, fee dues, today timetable, recent notices
3. **Profile**: Full profile view with class-section, parent contact
4. **Attendance**: Monthly view with summary
5. **Fees**: Dues list + payment history with receipt numbers
6. **Timetable**: Weekly grid for own class-section
7. **Notices**: List + detail
8. **Documents**: Read-only list of uploaded documents
9. **School Admin**: Can create portal login for student, reset password
10. **Security**: Student can only access own data; 403 for other students
