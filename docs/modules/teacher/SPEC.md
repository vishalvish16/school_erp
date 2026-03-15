# Teacher/Staff Module — Technical Specification

**Platform**: Vidyron School ERP
**Version**: 1.0
**Date**: 2026-03-15
**Status**: Ready for Implementation
**API Base**: `/api/school/` (school-scoped, JWT-authenticated)

---

## 1. Module Overview

### Goals
The Teacher/Staff Module manages every person employed at a school — from the
principal to the librarian to classroom teachers. It is the identity and
HR backbone that all other modules (Attendance, Timetable, Exams, Fees) reference
when they need to know "who is responsible for what".

### Scope for This Release (v1)
1. **Staff Directory** — paginated list with search, designation filter, active/inactive filter
2. **Staff Profile** — full personal + contact + employment details; photo upload
3. **Qualifications** — multiple academic/professional qualifications per staff member
4. **Documents** — store document metadata (Aadhaar, PAN, degree certificates, experience letters)
5. **Subject Assignments** — which subject(s) a teacher teaches in which class-section
6. **Timetable View** — read-only weekly schedule derived from the Timetable table (no editing — that belongs to the Timetable module)
7. **Leave Management** — staff applies for leave; school admin approves or rejects

### Out of Scope (future modules)
- Full timetable builder (Timetable module)
- Payroll and salary slip generation (HR/Payroll module)
- Biometric/RFID attendance for staff (Attendance module)
- Teacher portal self-service screens (Teacher portal — separate feature set)

### User Roles
| Role | Portal | Access |
|------|--------|--------|
| SCHOOL_ADMIN | `{school}.vidyron.in` | Full CRUD on all staff, qualifications, documents, subject assignments; approve/reject leaves |
| STAFF (Clerk) | `{school}.vidyron.in` | Read staff directory; own profile read-only; own leave apply/view |
| TEACHER | Teacher portal (future) | Own profile read; own subject assignments read; own leave apply/view; own timetable read |

---

## 2. User Stories

### School Admin
- As a school admin, I can create a new staff member with full personal, contact, and employment details so the person appears in the system and can log in.
- As a school admin, I can upload a photo for a staff member so directories and ID cards look professional.
- As a school admin, I can add multiple qualifications (degree, institution, year, grade) to a staff member's profile.
- As a school admin, I can record and tag HR documents (Aadhaar, PAN, degree, experience letter) for a staff member so we have a digital document store.
- As a school admin, I can assign a teacher to teach specific subjects in specific class-sections (e.g., "Ravi teaches Maths in Class 9-A").
- As a school admin, I can view a teacher's weekly timetable in a read-only grid.
- As a school admin, I can filter the staff list by designation, active status, or subject expertise.
- As a school admin, I can deactivate (soft-delete) a staff member when they leave so historical data is preserved.
- As a school admin, I can view all pending leave requests and approve or reject them with a remark.
- As a school admin, I can see the total approved leave days taken by any staff member in the current academic year.
- As a school admin, I can export the staff directory as a CSV.

### Teacher / Staff (self-service)
- As a teacher, I can view my own complete profile.
- As a teacher, I can view which subjects I am assigned to teach and in which class-sections.
- As a teacher, I can see my personal weekly timetable.
- As a teacher, I can apply for a leave request (casual/medical/other) specifying dates and reason.
- As a teacher, I can view the status (pending/approved/rejected) of my leave requests.

---

## 3. Database Schema

### 3.1 Existing Table: `staff`
Already in `schema.prisma`. Fields currently present:
`id`, `school_id`, `user_id`, `employee_no`, `first_name`, `last_name`, `gender`,
`date_of_birth`, `phone`, `email`, `designation`, `subjects[]`, `qualification`,
`join_date`, `photo_url`, `is_active`, `deleted_at`, `created_at`, `updated_at`

**New columns to add to `staff`** (via migration):
| Column | Type | Notes |
|--------|------|-------|
| `address` | `Text?` | Residential address |
| `city` | `VarChar(100)?` | City |
| `state` | `VarChar(100)?` | State |
| `blood_group` | `VarChar(5)?` | A+, B-, O+, etc. |
| `emergency_contact_name` | `VarChar(100)?` | Next of kin name |
| `emergency_contact_phone` | `VarChar(20)?` | Next of kin phone |
| `employee_type` | `VarChar(30)` | `PERMANENT`, `CONTRACTUAL`, `PART_TIME`, `PROBATION` — default `PERMANENT` |
| `department` | `VarChar(100)?` | e.g., Science, Arts, Administration |
| `experience_years` | `SmallInt?` | Total prior experience before joining |
| `salary_grade` | `VarChar(50)?` | Pay grade reference (for future HR module) |

### 3.2 New Table: `staff_qualifications`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `UUID` | PK, default uuid() |
| `school_id` | `UUID` | FK → schools.id ON DELETE CASCADE |
| `staff_id` | `UUID` | FK → staff.id ON DELETE CASCADE |
| `degree` | `VarChar(100)` | e.g., "B.Ed", "M.Sc Mathematics" |
| `institution` | `VarChar(255)` | University/College name |
| `board_or_university` | `VarChar(255)?` | Board name (for school-level certs) |
| `year_of_passing` | `SmallInt?` | Year |
| `grade_or_percentage` | `VarChar(20)?` | "First Class", "78.5%" |
| `is_highest` | `Boolean` | Default false — marks the highest qualification |
| `created_at` | `Timestamptz` | Default now() |
| `updated_at` | `Timestamptz` | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`

### 3.3 New Table: `staff_documents`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `UUID` | PK, default uuid() |
| `school_id` | `UUID` | FK → schools.id ON DELETE CASCADE |
| `staff_id` | `UUID` | FK → staff.id ON DELETE CASCADE |
| `document_type` | `VarChar(50)` | Enum-like: `AADHAAR`, `PAN`, `DEGREE_CERTIFICATE`, `EXPERIENCE_LETTER`, `APPOINTMENT_LETTER`, `OTHER` |
| `document_name` | `VarChar(255)` | Display name |
| `file_url` | `Text` | Cloud storage URL (S3/Supabase) |
| `file_size_kb` | `Integer?` | Size in KB for UI display |
| `mime_type` | `VarChar(100)?` | e.g., `application/pdf`, `image/jpeg` |
| `uploaded_by` | `UUID` | FK → users.id (who uploaded) |
| `verified` | `Boolean` | Default false — admin marks as verified |
| `verified_at` | `Timestamptz?` | When verified |
| `verified_by` | `UUID?` | FK → users.id |
| `deleted_at` | `Timestamptz?` | Soft delete |
| `created_at` | `Timestamptz` | Default now() |
| `updated_at` | `Timestamptz` | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`

### 3.4 New Table: `staff_subject_assignments`
Links a teacher to a subject within a specific class-section. The Timetable
table already has `staff_id` and `subject` — this table is a canonical declaration
("this teacher IS responsible for this subject in this section") separate from
the scheduled period slots.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `UUID` | PK, default uuid() |
| `school_id` | `UUID` | FK → schools.id ON DELETE CASCADE |
| `staff_id` | `UUID` | FK → staff.id ON DELETE CASCADE |
| `class_id` | `UUID` | FK → school_classes.id ON DELETE CASCADE |
| `section_id` | `UUID?` | FK → sections.id ON DELETE SetNull (null = all sections of the class) |
| `subject` | `VarChar(100)` | Subject name (matches subjects used in Timetable) |
| `academic_year` | `VarChar(10)` | e.g., "2025-26" |
| `is_active` | `Boolean` | Default true |
| `created_at` | `Timestamptz` | Default now() |
| `updated_at` | `Timestamptz` | @updatedAt |

Unique: `(school_id, staff_id, class_id, section_id, subject, academic_year)`
Indexes: `(school_id)`, `(staff_id)`, `(class_id)`

### 3.5 New Table: `staff_leaves`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `UUID` | PK, default uuid() |
| `school_id` | `UUID` | FK → schools.id ON DELETE CASCADE |
| `staff_id` | `UUID` | FK → staff.id ON DELETE CASCADE |
| `leave_type` | `VarChar(30)` | `CASUAL`, `MEDICAL`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, `OTHER` |
| `from_date` | `Date` | Start date |
| `to_date` | `Date` | End date |
| `total_days` | `SmallInt` | Calculated: working days between from_date and to_date |
| `reason` | `Text` | Staff's stated reason |
| `status` | `VarChar(20)` | `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED` — default `PENDING` |
| `applied_by` | `UUID` | FK → users.id (the staff member's user account) |
| `reviewed_by` | `UUID?` | FK → users.id (admin who acted on it) |
| `reviewed_at` | `Timestamptz?` | When reviewed |
| `admin_remark` | `Text?` | Admin's approval/rejection note |
| `created_at` | `Timestamptz` | Default now() |
| `updated_at` | `Timestamptz` | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`, `(school_id, status)`, `(school_id, from_date)`

### 3.6 Entity Relations Summary
```
School
  └── Staff (many)
        ├── StaffQualification (many)
        ├── StaffDocument (many)
        ├── StaffSubjectAssignment (many)
        │     ├── SchoolClass (FK)
        │     └── Section? (FK)
        └── StaffLeave (many)
              └── User (applied_by FK, reviewed_by FK)
```

---

## 4. API Endpoints

**Base URL**: `/api/school`
**Auth**: All endpoints require `Authorization: Bearer <access_token>`
**Middleware**: `verifyAccessToken` → `requireSchoolAdmin`
**School isolation**: `req.user.school_id` injected automatically — never trusted from body/params

### 4.1 Staff — Core CRUD

#### GET `/staff`
List staff with pagination, search, filters.

Query params:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Page size (max 100) |
| `search` | string | — | Name, email, employee number |
| `designation` | string | — | Filter by designation enum value |
| `department` | string | — | Filter by department |
| `isActive` | boolean | — | true/false |
| `employeeType` | string | — | PERMANENT, CONTRACTUAL, etc. |
| `subject` | string | — | Teachers who teach this subject |

Response `200`:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "uuid",
        "school_id": "uuid",
        "user_id": "uuid|null",
        "employee_no": "EMP001",
        "first_name": "Ravi",
        "last_name": "Sharma",
        "full_name": "Ravi Sharma",
        "gender": "MALE",
        "date_of_birth": "1985-06-15",
        "phone": "+919876543210",
        "email": "ravi.sharma@school.in",
        "designation": "TEACHER",
        "department": "Science",
        "employee_type": "PERMANENT",
        "subjects": ["Physics", "Mathematics"],
        "qualification": "M.Sc Physics",
        "join_date": "2018-04-01",
        "experience_years": 5,
        "photo_url": "https://...",
        "blood_group": "O+",
        "is_active": true,
        "created_at": "2024-04-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 85,
      "total_pages": 5
    }
  }
}
```

#### POST `/staff`
Create a new staff member.

Request body:
```json
{
  "employee_no": "EMP042",
  "first_name": "Priya",
  "last_name": "Menon",
  "gender": "FEMALE",
  "email": "priya.menon@school.in",
  "designation": "TEACHER",
  "join_date": "2026-04-01",
  "date_of_birth": "1990-03-22",
  "phone": "+919876500000",
  "subjects": ["English", "Hindi"],
  "qualification": "B.Ed",
  "department": "Languages",
  "employee_type": "PERMANENT",
  "experience_years": 3,
  "address": "14, MG Road",
  "city": "Bengaluru",
  "state": "Karnataka",
  "blood_group": "B+",
  "emergency_contact_name": "Suresh Menon",
  "emergency_contact_phone": "+919876500001",
  "salary_grade": "PB-2",
  "photo_url": "https://...",
  "create_login": true,
  "initial_password": "Welcome@123"
}
```

`create_login: true` triggers creation of a User record with role TEACHER.
`initial_password` is required if `create_login: true`.

Response `201`: Full staff object (same shape as list item) plus `user_id`.

#### GET `/staff/:id`
Full staff profile with qualifications, documents count, subject assignments, leave summary.

Response `200`:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee_no": "EMP001",
    ...all base fields...,
    "qualifications": [
      {
        "id": "uuid",
        "degree": "M.Sc Physics",
        "institution": "Delhi University",
        "year_of_passing": 2010,
        "grade_or_percentage": "First Class",
        "is_highest": true
      }
    ],
    "documents": [
      {
        "id": "uuid",
        "document_type": "AADHAAR",
        "document_name": "Aadhaar Card",
        "file_url": "https://...",
        "file_size_kb": 340,
        "verified": true
      }
    ],
    "subject_assignments": [
      {
        "id": "uuid",
        "class_id": "uuid",
        "class_name": "Class 9",
        "section_id": "uuid",
        "section_name": "A",
        "subject": "Physics",
        "academic_year": "2025-26"
      }
    ],
    "leave_summary": {
      "total_approved": 12,
      "pending": 1,
      "academic_year": "2025-26"
    }
  }
}
```

#### PUT `/staff/:id`
Update any field of the staff profile. Partial update — only provided fields change.

Request body: Same fields as POST but all optional. `employee_no` uniqueness checked.

Response `200`: Updated staff object.

#### DELETE `/staff/:id`
Soft-delete: sets `deleted_at = now()` and `is_active = false`.
Also sets the linked User's `is_active = false` if a user account exists.

Response `200`: `{ "success": true, "message": "Staff member deactivated" }`

#### PUT `/staff/:id/status`
Toggle active/inactive without full update.

Request: `{ "is_active": false, "reason": "On long leave" }`
Response `200`: `{ "success": true, "data": { "is_active": false } }`

#### GET `/staff/export`
Export staff list as CSV. Accepts same filters as GET /staff (no pagination).

Response `200`: `text/csv` attachment.

---

### 4.2 Staff — Qualifications

#### GET `/staff/:id/qualifications`
Response `200`: `{ "success": true, "data": [ ...qualification objects... ] }`

#### POST `/staff/:id/qualifications`
Request:
```json
{
  "degree": "B.Ed",
  "institution": "Jamia Millia Islamia",
  "board_or_university": null,
  "year_of_passing": 2012,
  "grade_or_percentage": "65%",
  "is_highest": false
}
```
Response `201`: Created qualification object.

#### PUT `/staff/:staffId/qualifications/:qualId`
Partial update. Response `200`: Updated object.

#### DELETE `/staff/:staffId/qualifications/:qualId`
Hard delete (qualifications are not critical for audit trail).
Response `200`: `{ "success": true }`

---

### 4.3 Staff — Documents

#### GET `/staff/:id/documents`
Response `200`: Array of document metadata (no file content — only URLs).

#### POST `/staff/:id/documents`
Upload document metadata (actual file upload handled via separate file-upload endpoint or direct-to-cloud URL).

Request:
```json
{
  "document_type": "PAN",
  "document_name": "PAN Card",
  "file_url": "https://storage.vidyron.in/docs/pan_ravi.pdf",
  "file_size_kb": 180,
  "mime_type": "application/pdf"
}
```
Response `201`: Document metadata object.

#### PUT `/staff/:staffId/documents/:docId/verify`
Mark document as verified. Only school admin can call this.

Request: `{}` (no body needed)
Response `200`: `{ "success": true, "data": { "verified": true, "verified_at": "..." } }`

#### DELETE `/staff/:staffId/documents/:docId`
Soft-delete: sets `deleted_at = now()`.
Response `200`: `{ "success": true }`

---

### 4.4 Staff — Subject Assignments

#### GET `/staff/:id/subject-assignments`
Query params: `academicYear` (default: current year)

Response `200`:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "class_id": "uuid",
      "class_name": "Class 9",
      "section_id": "uuid",
      "section_name": "A",
      "subject": "Physics",
      "academic_year": "2025-26",
      "is_active": true
    }
  ]
}
```

#### POST `/staff/:id/subject-assignments`
Assign a subject in a class-section to this teacher.

Request:
```json
{
  "class_id": "uuid",
  "section_id": "uuid",
  "subject": "Physics",
  "academic_year": "2025-26"
}
```
Validation: Enforce uniqueness — same subject cannot be assigned to two active teachers in the same class-section for the same academic year.

Response `201`: Created assignment object.

#### DELETE `/staff/:staffId/subject-assignments/:assignId`
Hard delete (or set `is_active = false`).
Response `200`: `{ "success": true }`

#### GET `/staff/:id/timetable`
Read-only view: pulls from existing `timetables` table filtered by `staff_id`.
Query params: `weekOffset` (0 = current week, supports -1, +1 for navigation) — ignored for now since timetable is static; returns full weekly schedule.

Response `200`:
```json
{
  "success": true,
  "data": {
    "staff_id": "uuid",
    "staff_name": "Ravi Sharma",
    "academic_year": "2025-26",
    "schedule": [
      {
        "day_of_week": 1,
        "day_name": "Monday",
        "periods": [
          {
            "period_no": 1,
            "subject": "Physics",
            "class_name": "Class 9",
            "section_name": "A",
            "start_time": "08:00",
            "end_time": "08:45",
            "room": "Lab-1"
          }
        ]
      }
    ]
  }
}
```

---

### 4.5 Staff — Leave Management

#### GET `/staff/leaves`
School admin: view all leave requests for the school.
Query params: `page`, `limit`, `status` (PENDING/APPROVED/REJECTED/CANCELLED), `staffId`, `leaveType`, `fromDate`, `toDate`, `academicYear`

Response `200`:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "uuid",
        "staff_id": "uuid",
        "staff_name": "Ravi Sharma",
        "employee_no": "EMP001",
        "leave_type": "CASUAL",
        "from_date": "2026-03-20",
        "to_date": "2026-03-21",
        "total_days": 2,
        "reason": "Personal work",
        "status": "PENDING",
        "applied_by": "uuid",
        "reviewed_by": null,
        "reviewed_at": null,
        "admin_remark": null,
        "created_at": "2026-03-15T09:00:00Z"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 5, "total_pages": 1 }
  }
}
```

#### GET `/staff/:id/leaves`
Leave requests for a specific staff member.
Query params: `page`, `limit`, `status`, `academicYear`

#### POST `/staff/:id/leaves`
Apply for leave (can be called by school admin on behalf, or by teacher via their own portal).

Request:
```json
{
  "leave_type": "CASUAL",
  "from_date": "2026-03-20",
  "to_date": "2026-03-21",
  "reason": "Personal work"
}
```
Validation:
- `from_date` must be today or future
- `to_date` >= `from_date`
- `total_days` is auto-calculated server-side (calendar days; future: working-day calculation)
- Cannot apply if a PENDING leave overlaps the same date range

Response `201`: Created leave object.

#### PUT `/staff/leaves/:leaveId/review`
School admin approves or rejects a leave request.

Request:
```json
{
  "status": "APPROVED",
  "admin_remark": "Approved. Arrange substitute."
}
```
Validation:
- `status` must be `APPROVED` or `REJECTED`
- Leave must currently be in `PENDING` state
- Reviewer must be school admin (enforced by middleware)

Response `200`: Updated leave object.

#### PUT `/staff/leaves/:leaveId/cancel`
Staff member cancels their own PENDING leave.

Request: `{}` (no body)
Response `200`: Updated leave with `status: CANCELLED`

#### GET `/staff/leaves/summary`
Aggregated leave stats for dashboard/reporting.
Query params: `academicYear` (default current), `staffId` (optional — omit for all staff)

Response `200`:
```json
{
  "success": true,
  "data": {
    "academic_year": "2025-26",
    "total_applied": 48,
    "total_approved": 35,
    "total_rejected": 8,
    "total_pending": 5,
    "by_leave_type": {
      "CASUAL": 20,
      "MEDICAL": 10,
      "EARNED": 5
    }
  }
}
```

---

## 5. Flutter Screens — School Admin Portal

### Screen Inventory

All screens live under `lib/features/school_admin/presentation/screens/`.
All providers live under `lib/features/school_admin/presentation/providers/`.
Models live under `lib/models/school_admin/`.
Routes registered in `lib/routes/app_router.dart` under the `school-admin` shell.

---

### 5.1 `school_admin_staff_screen.dart` (EXTEND EXISTING)
**Purpose**: Staff directory list — search, filters, paginated table/cards, add button
**Route**: `/school/staff` (already registered)
**Current state**: Exists but is minimal. Needs full redesign to match the spec.

Key additions over current version:
- Filter chips for: Designation, Department, Employee Type, Active/Inactive, Subject
- Sortable columns: Name, Employee No, Designation, Join Date
- Export CSV button
- Row action: View, Edit, Deactivate, View Timetable
- Summary count bar (total staff, teachers, non-teaching, inactive)

**State**: `schoolAdminStaffProvider` (StateNotifierProvider — already exists, extend)
**New state fields to add**: `departmentFilter`, `employeeTypeFilter`, `subjectFilter`

**API Calls**:
- `GET /api/school/staff` (paginated, filterable)
- `DELETE /api/school/staff/:id` (deactivate)
- `GET /api/school/staff/export` (CSV download)

---

### 5.2 `school_admin_staff_form_screen.dart` (NEW)
**Purpose**: Create and edit staff member — tabbed form
**Route**: `/school/staff/new` and `/school/staff/:id/edit`
**Tabs**:
  1. **Personal** — name, gender, DOB, blood group, address, emergency contact, photo upload
  2. **Employment** — employee no, designation, department, employee type, join date, experience years, salary grade
  3. **Contact** — email, phone (readonly if linked user exists — managed via auth)
  4. **Subjects** — multi-select from school's subject list; syncs to `staff.subjects[]` array
  5. **Login** — toggle "Create Portal Login"; email pre-filled; set initial password; shows linked user status if exists

**State**: `StaffFormNotifier` (StateNotifierProvider, auto-disposed)

```dart
// Provider signature
final staffFormProvider = StateNotifierProvider.autoDispose<StaffFormNotifier, StaffFormState>((ref) {
  return StaffFormNotifier(ref.read(schoolAdminServiceProvider));
});
```

**API Calls**:
- `POST /api/school/staff` (create)
- `PUT /api/school/staff/:id` (edit)
- `GET /api/school/staff/:id` (pre-populate form when editing)

---

### 5.3 `school_admin_staff_detail_screen.dart` (EXTEND EXISTING)
**Purpose**: Full staff profile view — tabbed detail page
**Route**: `/school/staff/:id` (already registered)
**Current state**: Exists but shows only base fields. Needs tabbed redesign.

**Tabs**:
  1. **Overview** — photo, name, designation, department, status badge, quick stats (total leaves taken, subjects count, years of service)
  2. **Qualifications** — list of qualifications with add/edit/delete inline actions
  3. **Documents** — document cards with type icon, name, size, verified badge; upload and delete actions
  4. **Subject Assignments** — table: Class | Section | Subject | Academic Year | Actions (remove)
  5. **Timetable** — read-only weekly grid (Mon–Sat, periods as columns)
  6. **Leaves** — leave request history list with status chips; link to "Apply Leave" for admin

**State**:
- `staffDetailProvider` — `FutureProvider.autoDispose.family<StaffDetailModel, String>` (already partially exists)
- `staffQualificationsProvider` — `FutureProvider.autoDispose.family`
- `staffDocumentsProvider` — `FutureProvider.autoDispose.family`
- `staffSubjectAssignmentsProvider` — `FutureProvider.autoDispose.family`
- `staffTimetableProvider` — `FutureProvider.autoDispose.family`
- `staffLeavesProvider` — `StateNotifierProvider.autoDispose.family`

---

### 5.4 `school_admin_staff_qualifications_screen.dart` (NEW — can be inline tab or separate)
**Purpose**: Manage qualifications for a staff member
**Route**: Can remain embedded in detail screen tab; no separate route needed
**UI**: List of qualification cards with expand/collapse; floating "Add Qualification" button opens a bottom sheet form

**Bottom Sheet Form fields**:
- Degree (text, required)
- Institution (text, required)
- Board/University (text, optional)
- Year of Passing (number picker)
- Grade/Percentage (text)
- Is Highest Qualification (toggle)

**API Calls**:
- `GET /api/school/staff/:id/qualifications`
- `POST /api/school/staff/:id/qualifications`
- `PUT /api/school/staff/:id/qualifications/:qualId`
- `DELETE /api/school/staff/:id/qualifications/:qualId`

---

### 5.5 `school_admin_staff_documents_screen.dart` (NEW — inline tab)
**Purpose**: Document store for a staff member
**UI**: Grid of document cards (icon reflects type — PDF/image), upload button, verify button for admin, delete

**Key UX decisions**:
- File upload is URL-based (school admin pastes URL OR uses a file picker that uploads to cloud and returns URL)
- Verified documents show a green shield badge
- Document type dropdown: Aadhaar, PAN, Degree Certificate, Experience Letter, Appointment Letter, Other

**API Calls**:
- `GET /api/school/staff/:id/documents`
- `POST /api/school/staff/:id/documents`
- `PUT /api/school/staff/:id/documents/:docId/verify`
- `DELETE /api/school/staff/:id/documents/:docId`

---

### 5.6 `school_admin_staff_timetable_screen.dart` (NEW — inline tab)
**Purpose**: Read-only weekly timetable grid for a specific teacher
**Route**: Embedded in staff detail tab; also accessible via `/school/staff/:id/timetable`

**UI**: 7-column grid (days Mon–Sat + labels) × N-row (period slots).
Each cell shows: Subject, Class-Section, Room.
Empty cells show a dash. Color-coded by subject.

**State**: `FutureProvider.autoDispose.family<StaffTimetableModel, String>`

**API Calls**:
- `GET /api/school/staff/:id/timetable`

---

### 5.7 `school_admin_leaves_screen.dart` (NEW)
**Purpose**: Leave management hub for school admin — all pending/recent requests
**Route**: `/school/leaves`

**Tabs**:
  1. **Pending** — requests awaiting action; approve/reject inline
  2. **All Requests** — full history with all filters
  3. **Summary** — aggregated stats card per leave type and per staff member

**Filter bar**: Status, Leave Type, Date Range, Staff member (searchable dropdown)

**State**: `SchoolAdminLeavesNotifier` (StateNotifierProvider)

**API Calls**:
- `GET /api/school/staff/leaves` (with filters)
- `PUT /api/school/staff/leaves/:leaveId/review`
- `GET /api/school/staff/leaves/summary`

---

### 5.8 `school_admin_leave_apply_screen.dart` (NEW)
**Purpose**: Apply for leave (admin applying on behalf of a staff member OR teacher self-service in future)
**Route**: `/school/staff/:id/leave/apply`

**Form fields**:
- Leave Type (dropdown)
- From Date (date picker — future dates only)
- To Date (date picker — >= from date)
- Reason (multiline text, required)
- Calculated days display (auto-updates as dates change)

**State**: Local form state; calls notifier on submit

**API Calls**:
- `POST /api/school/staff/:id/leaves`

---

### 5.9 Models to Create/Extend

**`lib/models/school_admin/staff_model.dart`** — EXTEND with new fields:
- `address`, `city`, `state`, `bloodGroup`, `emergencyContactName`, `emergencyContactPhone`
- `employeeType`, `department`, `experienceYears`, `salaryGrade`

**New model files**:

`lib/models/school_admin/staff_qualification_model.dart`:
```dart
class StaffQualificationModel {
  final String id;
  final String staffId;
  final String degree;
  final String institution;
  final String? boardOrUniversity;
  final int? yearOfPassing;
  final String? gradeOrPercentage;
  final bool isHighest;
  // fromJson / toJson
}
```

`lib/models/school_admin/staff_document_model.dart`:
```dart
class StaffDocumentModel {
  final String id;
  final String staffId;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final int? fileSizeKb;
  final String? mimeType;
  final bool verified;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  // fromJson / toJson
}
```

`lib/models/school_admin/staff_subject_assignment_model.dart`:
```dart
class StaffSubjectAssignmentModel {
  final String id;
  final String staffId;
  final String classId;
  final String className;
  final String? sectionId;
  final String? sectionName;
  final String subject;
  final String academicYear;
  final bool isActive;
  // fromJson / toJson
}
```

`lib/models/school_admin/staff_leave_model.dart`:
```dart
class StaffLeaveModel {
  final String id;
  final String staffId;
  final String? staffName;
  final String? employeeNo;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED | CANCELLED
  final String appliedBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminRemark;
  final DateTime createdAt;
  // fromJson / toJson
}
```

`lib/models/school_admin/staff_timetable_model.dart`:
```dart
class StaffSchedulePeriod {
  final int periodNo;
  final String subject;
  final String className;
  final String sectionName;
  final String startTime;
  final String endTime;
  final String? room;
}

class StaffScheduleDay {
  final int dayOfWeek;
  final String dayName;
  final List<StaffSchedulePeriod> periods;
}

class StaffTimetableModel {
  final String staffId;
  final String staffName;
  final String academicYear;
  final List<StaffScheduleDay> schedule;
}
```

---

### 5.10 Service Extensions

**`lib/core/services/school_admin_service.dart`** — ADD these methods:

```dart
// Staff extended profile
Future<Map<String, dynamic>> getStaffDetail(String id);
Future<void> updateStaffStatus(String id, bool isActive, {String? reason});
Future<List<int>> exportStaff({String? search, String? designation, String? department});

// Qualifications
Future<List<StaffQualificationModel>> getStaffQualifications(String staffId);
Future<StaffQualificationModel> addQualification(String staffId, Map<String, dynamic> body);
Future<StaffQualificationModel> updateQualification(String staffId, String qualId, Map<String, dynamic> body);
Future<void> deleteQualification(String staffId, String qualId);

// Documents
Future<List<StaffDocumentModel>> getStaffDocuments(String staffId);
Future<StaffDocumentModel> addDocument(String staffId, Map<String, dynamic> body);
Future<void> verifyDocument(String staffId, String docId);
Future<void> deleteDocument(String staffId, String docId);

// Subject Assignments
Future<List<StaffSubjectAssignmentModel>> getSubjectAssignments(String staffId, {String? academicYear});
Future<StaffSubjectAssignmentModel> addSubjectAssignment(String staffId, Map<String, dynamic> body);
Future<void> removeSubjectAssignment(String staffId, String assignId);
Future<StaffTimetableModel> getStaffTimetable(String staffId);

// Leaves
Future<Map<String, dynamic>> getLeaves({int page, int limit, String? status, String? staffId,
    String? leaveType, String? fromDate, String? toDate, String? academicYear});
Future<List<StaffLeaveModel>> getStaffLeaves(String staffId, {int page, int limit, String? status});
Future<StaffLeaveModel> applyLeave(String staffId, Map<String, dynamic> body);
Future<StaffLeaveModel> reviewLeave(String leaveId, String status, {String? adminRemark});
Future<StaffLeaveModel> cancelLeave(String leaveId);
Future<Map<String, dynamic>> getLeaveSummary({String? academicYear, String? staffId});
```

---

### 5.11 API Config Constants to Add

In `lib/core/config/api_config.dart`:
```dart
static const String schoolStaff                = '/api/school/staff';
static const String schoolStaffLeaves          = '/api/school/staff/leaves';
static const String schoolStaffLeaveSummary    = '/api/school/staff/leaves/summary';
```
(Per-staff sub-resource URLs are constructed dynamically: `'$schoolStaff/$id/qualifications'` etc.)

---

### 5.12 Routes to Add in `app_router.dart`

```dart
GoRoute(
  path: 'staff/new',
  builder: (_, __) => const SchoolAdminStaffFormScreen(),
),
GoRoute(
  path: 'staff/:id/edit',
  builder: (ctx, state) => SchoolAdminStaffFormScreen(staffId: state.pathParameters['id']),
),
GoRoute(
  path: 'staff/:id/timetable',
  builder: (ctx, state) => SchoolAdminStaffTimetableScreen(staffId: state.pathParameters['id']!),
),
GoRoute(
  path: 'staff/:id/leave/apply',
  builder: (ctx, state) => SchoolAdminLeaveApplyScreen(staffId: state.pathParameters['id']!),
),
GoRoute(
  path: 'leaves',
  builder: (_, __) => const SchoolAdminLeavesScreen(),
),
```

---

## 6. Business Rules

### Staff Core
1. `employee_no` must be unique within a school. Case-insensitive check.
2. `email` must be unique within a school's staff table (enforced at application layer — the DB does not have a unique constraint on `staff.email` at the school level today; a partial unique index should be added).
3. `designation` must be one of: `TEACHER`, `PRINCIPAL`, `VICE_PRINCIPAL`, `HOD`, `CLERK`, `ACCOUNTANT`, `LIBRARIAN`, `LAB_ASSISTANT`, `COUNSELOR`, `SPORTS_COACH`, `OTHER`.
4. Soft delete does NOT remove from DB. `deleted_at` is set; `is_active` is set to false. All list queries must filter `deletedAt: null`.
5. Deactivating a staff member must also deactivate their linked User account (`is_active = false`).
6. A staff member cannot be deleted if they are currently a Class Teacher for any active section (`sections.class_teacher_id`). Admin must first reassign the class teacher.
7. Photo URL must be a valid HTTPS URL. Max file size 2 MB (enforced in Flutter before upload).

### Qualifications
8. There can be at most one qualification with `is_highest = true` per staff member. If a new one is added with `is_highest: true`, the previous one is automatically unset.
9. `year_of_passing` must be between 1950 and current year.

### Documents
10. Only one document of each `document_type` can be non-deleted at a time per staff (except `OTHER`). Uploading a new Aadhaar automatically soft-deletes the old one.
11. Accepted MIME types: `application/pdf`, `image/jpeg`, `image/png`. Enforced by Flutter before upload.
12. Only SCHOOL_ADMIN role can mark documents as verified.

### Subject Assignments
13. The same subject cannot be assigned to two active teachers in the same class-section for the same academic year. Check at creation time and return HTTP 409 if conflict.
14. Subject names must match values in the school's Timetable records (soft constraint — no FK, free text — validated against a suggested list from existing timetable data).
15. `section_id: null` means "all sections of the class" — useful for single-section schools. The uniqueness check must handle null section_id correctly.

### Leave Management
16. Leave `from_date` must be today or in the future at time of application. Exception: school admin can apply retroactively (no date restriction when `applied_by` is an admin).
17. `total_days` = number of calendar days inclusive from `from_date` to `to_date`. Future enhancement: working-day-only count respecting school holidays.
18. A staff member cannot have two PENDING or APPROVED leaves that overlap in dates. Overlap check runs at application time.
19. Only PENDING leaves can be APPROVED or REJECTED. Approved/rejected leaves cannot be changed (create a new record if correction is needed).
20. Only the applying staff member (via their User account) or a school admin can cancel a PENDING leave.
21. CANCELLED or REJECTED leaves do not count toward "days taken" in summary.
22. Academic year for leave defaults to current academic year: April 1 of current calendar year to March 31 of next year (Indian academic year).

### Security / Tenant Isolation
23. All queries MUST include `schoolId: req.user.school_id`. No endpoint accepts `school_id` from request body.
24. Staff detail, document, qualification, leave endpoints must verify the requested `staff.school_id === req.user.school_id` before returning data.
25. Leave review endpoint must be restricted to SCHOOL_ADMIN role only (not accessible to TEACHER or CLERK).

---

## 7. Integration Points

| Module | How Teacher/Staff Links |
|--------|------------------------|
| **Auth** | `staff.user_id` → `users.id` — creating a staff login creates a User with role TEACHER or STAFF |
| **Classes/Sections** | `sections.class_teacher_id` → `staff.id` — class teacher assignment |
| **Timetable** | `timetables.staff_id` → `staff.id` — period allocation uses staff records |
| **Attendance** | Future: `staff_attendance` table will reference `staff.id` |
| **Exams** | Future: `exam_invigilators`, `marks_entry` will reference `staff.id` |
| **HR/Payroll** | Future: payroll will use `staff.id`, `salary_grade`, `employee_type` |
| **Communications** | Future: messaging will send notifications to `staff.user_id` |

---

## 8. Security Requirements

- All routes under `/api/school/` are protected by `verifyAccessToken` + `requireSchoolAdmin` middleware.
- Future teacher self-service will use a `requireTeacher` guard that allows access only to the logged-in teacher's own data.
- Documents are stored as URLs; the cloud storage bucket must use signed URLs or access control to prevent direct access without authentication.
- Sensitive fields (`salary_grade`, `emergency_contact_phone`, `blood_group`) should be excluded from the list endpoint and only returned in the full detail endpoint.
- Audit logging is required for: CREATE_STAFF, UPDATE_STAFF, DELETE_STAFF, STAFF_LEAVE_APPLIED, STAFF_LEAVE_REVIEWED.

---

## 9. Migration Plan

### Migration: `20260315000001_extend_staff_table`
Add new columns to existing `staff` table:
```sql
ALTER TABLE staff
  ADD COLUMN address TEXT,
  ADD COLUMN city VARCHAR(100),
  ADD COLUMN state VARCHAR(100),
  ADD COLUMN blood_group VARCHAR(5),
  ADD COLUMN emergency_contact_name VARCHAR(100),
  ADD COLUMN emergency_contact_phone VARCHAR(20),
  ADD COLUMN employee_type VARCHAR(30) NOT NULL DEFAULT 'PERMANENT',
  ADD COLUMN department VARCHAR(100),
  ADD COLUMN experience_years SMALLINT,
  ADD COLUMN salary_grade VARCHAR(50);

-- Partial unique index: email must be unique within a school among non-deleted staff
CREATE UNIQUE INDEX staff_school_email_unique
  ON staff (school_id, email)
  WHERE deleted_at IS NULL;
```

### Migration: `20260315000002_create_staff_qualifications`
Create `staff_qualifications` table per schema in Section 3.2.

### Migration: `20260315000003_create_staff_documents`
Create `staff_documents` table per schema in Section 3.3.

### Migration: `20260315000004_create_staff_subject_assignments`
Create `staff_subject_assignments` table per schema in Section 3.4.

### Migration: `20260315000005_create_staff_leaves`
Create `staff_leaves` table per schema in Section 3.5.

---

## 10. Acceptance Criteria

### Staff Directory
- [ ] Staff list loads with pagination (20 per page)
- [ ] Search by name, email, employee number works
- [ ] Filter by designation, department, active status works independently and in combination
- [ ] Export CSV downloads all matching staff (same filters, no pagination limit)
- [ ] Deactivating a staff member soft-deletes them and their User account

### Staff Profile
- [ ] Full profile loads in <1 second for a single staff member
- [ ] Editing any field updates correctly and shows a success toast
- [ ] Duplicate employee_no within school returns HTTP 409 with clear message
- [ ] Photo URL field accepts valid HTTPS URLs only

### Qualifications
- [ ] Can add up to 10 qualifications per staff member
- [ ] Setting `is_highest: true` on a new qualification automatically removes it from the previous one
- [ ] Deleting a qualification removes it immediately from the list

### Documents
- [ ] Document list shows type icon and verified badge
- [ ] Uploading a second Aadhaar soft-deletes the first
- [ ] Only school admin can click "Verify" — button is hidden for other roles
- [ ] Soft-deleted documents do not appear in the list

### Subject Assignments
- [ ] Assigning the same subject to two teachers in the same class-section returns HTTP 409
- [ ] Teacher timetable grid renders correctly for a teacher with 5 days × 8 periods
- [ ] Removing a subject assignment removes it from both the assignment list and timetable view immediately

### Leave Management
- [ ] Applying leave with overlapping dates (when a PENDING/APPROVED leave exists) returns HTTP 409
- [ ] Applying leave with `from_date` in the past returns HTTP 400 (for teacher role)
- [ ] Approving a leave sets status to APPROVED and records reviewer + reviewed_at
- [ ] Leave summary correctly shows total approved days for current academic year
- [ ] Pending leaves tab shows badge count on tab header

### Security
- [ ] Requesting another school's staff detail returns HTTP 403
- [ ] TEACHER role cannot access `PUT /staff/leaves/:leaveId/review` — returns HTTP 403
- [ ] All audit events (CREATE_STAFF, STAFF_LEAVE_REVIEWED) appear in audit logs
