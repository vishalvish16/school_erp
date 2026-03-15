# Teacher Portal Module — Technical Specification

**Platform**: Vidyron School ERP
**Version**: 1.0
**Date**: 2026-03-15
**Status**: Ready for Implementation
**API Base**: `/api/teacher/` (teacher-scoped, JWT-authenticated)

---

## 1. Module Overview

### Problem Statement
Currently, teachers are stored in the `staff` table and share the same generic "Staff Portal"
as clerks and other non-teaching staff. Teachers have no pedagogical tools — they cannot
mark student attendance, assign homework, manage class diaries, or view their teaching
dashboard. The system treats teachers identically to other staff members.

### Goals
Build a dedicated **Teacher Portal** with features that only teachers need:
1. **Student Attendance Marking** — class teacher or subject teacher marks daily attendance
   for their assigned class-sections
2. **Homework / Assignment Management** — create, assign, and track homework for classes
3. **Class Diary** — daily notes for each class-section (what was taught, remarks)
4. **Teacher Dashboard** — teaching-focused overview (today's classes, pending attendance,
   recent homework, class strength)

### Scope for This Release (v1)
1. **Teacher Dashboard** — today's timetable, quick stats, pending actions
2. **Student Attendance Marking** — mark attendance for assigned class-sections
3. **Attendance Reports** — view attendance history for their classes
4. **Homework Management** — create, list, view homework/assignments
5. **Class Diary** — daily teaching log per class-section

### Out of Scope (future modules)
- Exam/test creation and marks entry (Exam module)
- Report card / gradebook generation (Exam module)
- Parent messaging / communication (Communication module)
- Lesson plan builder (Curriculum module)
- Online assessments / quizzes (Assessment module)

### User Roles
| Role | Portal | Access |
|------|--------|--------|
| TEACHER | Teacher Portal (`/teacher/*`) | Mark attendance for assigned sections, manage homework, write class diary, view own timetable |
| CLASS_TEACHER | Teacher Portal | All TEACHER access + view full class stats, student details for their class |
| SCHOOL_ADMIN | School Admin Portal | View teacher activities, attendance reports (read-only oversight) |

### How Teachers Are Identified
- Teachers are rows in the `staff` table with `designation IN ('TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD')`
- Teachers MUST have a linked `User` record (`staff.user_id IS NOT NULL`) to access the portal
- Subject assignments (`staff_subject_assignments`) determine which class-sections a teacher can mark attendance for and assign homework to
- Class teacher assignment (`sections.class_teacher_id`) determines the class teacher role

---

## 2. User Stories

### Teacher — Attendance
- As a teacher, I can see which class-sections I teach today so I know where to go.
- As a teacher, I can mark student attendance (PRESENT/ABSENT/LATE/HALF_DAY) for any class-section I am assigned to.
- As a class teacher, I can mark the daily attendance for my entire class even if I don't teach every period.
- As a teacher, I can view attendance history for my assigned sections filtered by date range.
- As a teacher, I can see today's attendance summary (total present, absent, late) for each section.
- As a teacher, I can edit today's attendance until end of day (locked after midnight).

### Teacher — Homework
- As a teacher, I can create a homework assignment specifying subject, class-section, title, description, due date, and optional attachments.
- As a teacher, I can view all homework I've assigned with filters by class, subject, status.
- As a teacher, I can edit or delete homework that hasn't passed its due date.
- As a teacher, I can mark homework as "Reviewed" after checking submissions.

### Teacher — Class Diary
- As a teacher, I can write a class diary entry for each period I teach, noting what was taught, page numbers, and any remarks.
- As a teacher, I can view past diary entries for my sections.
- As a class teacher, I can view diary entries written by all teachers for my class.

### Teacher — Dashboard
- As a teacher, I can see my today's timetable with class details on my dashboard.
- As a teacher, I can see quick stats: total students across my sections, attendance pending count, recent homework.
- As a teacher, I can see notifications for pending actions (unmarked attendance, approaching homework deadlines).

---

## 3. Database Schema

### 3.1 New Table: `homework`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `UUID` | PK, default uuid() |
| `school_id` | `UUID` | FK → schools.id ON DELETE CASCADE |
| `staff_id` | `UUID` | FK → staff.id ON DELETE CASCADE (the teacher who created it) |
| `class_id` | `UUID` | FK → school_classes.id ON DELETE CASCADE |
| `section_id` | `UUID?` | FK → sections.id ON DELETE SET NULL (null = all sections) |
| `subject` | `VarChar(100)` | Subject name |
| `title` | `VarChar(255)` | Homework title |
| `description` | `Text?` | Detailed description / instructions |
| `assigned_date` | `Date` | Date when homework was assigned |
| `due_date` | `Date` | Submission deadline |
| `attachment_urls` | `Text[]` | Array of file/image URLs (optional) |
| `status` | `VarChar(20)` | `ACTIVE`, `REVIEWED`, `CANCELLED` — default `ACTIVE` |
| `created_at` | `Timestamptz` | Default now() |
| `updated_at` | `Timestamptz` | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`, `(class_id, section_id)`, `(school_id, due_date)`
Unique: none (same teacher can assign multiple homework on same day)

### 3.2 New Table: `class_diary`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `UUID` | PK, default uuid() |
| `school_id` | `UUID` | FK → schools.id ON DELETE CASCADE |
| `staff_id` | `UUID` | FK → staff.id ON DELETE CASCADE (teacher who wrote) |
| `class_id` | `UUID` | FK → school_classes.id ON DELETE CASCADE |
| `section_id` | `UUID?` | FK → sections.id ON DELETE SET NULL |
| `subject` | `VarChar(100)` | Subject taught |
| `date` | `Date` | Teaching date |
| `period_no` | `SmallInt?` | Period number (1-8, optional) |
| `topic_covered` | `VarChar(500)` | What was taught |
| `description` | `Text?` | Detailed notes |
| `page_from` | `VarChar(20)?` | Textbook page start |
| `page_to` | `VarChar(20)?` | Textbook page end |
| `homework_given` | `VarChar(500)?` | Brief homework note (cross-reference, not FK) |
| `remarks` | `Text?` | Any remarks (student behavior, class notes) |
| `created_at` | `Timestamptz` | Default now() |
| `updated_at` | `Timestamptz` | @updatedAt |

Indexes: `(school_id)`, `(staff_id)`, `(class_id, section_id, date)`, `(school_id, date)`
Unique: `(school_id, staff_id, class_id, section_id, subject, date, period_no)` — one entry per teacher per period per section per day

### 3.3 Existing Table: `attendances` (No Schema Change)
The existing `attendances` table already supports what we need:
- `student_id`, `section_id`, `date`, `status`, `marked_by` (User UUID), `remarks`
- Unique constraint: `(student_id, date)` — one attendance per student per day
- `marked_by` links to `users.id` — which links back to `staff.user_id`

No schema change needed. The teacher module will use this table as-is.

### 3.4 Entity Relations
```
Staff (teacher)
  ├── StaffSubjectAssignment[] → determines which classes/sections teacher can access
  ├── Section (as classTeacher) → determines class teacher role
  ├── Homework[] (created by)
  ├── ClassDiary[] (written by)
  └── User → Attendance.markedBy (marks student attendance)

Homework
  ├── School (FK)
  ├── Staff (FK — creator)
  ├── SchoolClass (FK)
  └── Section? (FK)

ClassDiary
  ├── School (FK)
  ├── Staff (FK — author)
  ├── SchoolClass (FK)
  └── Section? (FK)
```

---

## 4. API Endpoints

**Base URL**: `/api/teacher`
**Auth**: All endpoints require `Authorization: Bearer <access_token>`
**Middleware**: `verifyAccessToken` → `requireTeacher` (new middleware)
**Teacher identification**: JWT contains `userId` → lookup `staff` where `user_id = userId` → `req.teacher` (staff record)
**Section access**: Teacher can only access class-sections they are assigned to via `staff_subject_assignments` OR where they are `class_teacher_id`

### 4.1 Teacher Dashboard

#### GET `/api/teacher/dashboard`
Returns teacher's dashboard data: today's schedule, stats, pending actions.

Response `200`:
```json
{
  "success": true,
  "data": {
    "teacher": {
      "id": "uuid",
      "name": "Ravi Sharma",
      "designation": "TEACHER",
      "employee_no": "EMP001",
      "photo_url": "https://..."
    },
    "today_schedule": [
      {
        "period_no": 1,
        "subject": "Physics",
        "class_name": "Class 9",
        "section_name": "A",
        "start_time": "08:00",
        "end_time": "08:45",
        "room": "Lab-1"
      }
    ],
    "stats": {
      "total_sections": 4,
      "total_students": 160,
      "attendance_pending_today": 2,
      "homework_active": 5,
      "homework_due_this_week": 2
    },
    "pending_actions": [
      {
        "type": "ATTENDANCE_PENDING",
        "label": "Mark attendance for Class 9-A",
        "class_id": "uuid",
        "section_id": "uuid"
      }
    ],
    "class_teacher_of": {
      "class_id": "uuid",
      "class_name": "Class 9",
      "section_id": "uuid",
      "section_name": "A",
      "student_count": 42
    }
  }
}
```

### 4.2 Student Attendance

#### GET `/api/teacher/sections`
List all sections the teacher is assigned to (via subject assignments + class teacher).

Response `200`:
```json
{
  "success": true,
  "data": [
    {
      "class_id": "uuid",
      "class_name": "Class 9",
      "section_id": "uuid",
      "section_name": "A",
      "student_count": 42,
      "is_class_teacher": true,
      "subjects": ["Physics", "Mathematics"]
    }
  ]
}
```

#### GET `/api/teacher/attendance`
Get attendance for a specific section on a date.

Query params:
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `sectionId` | UUID | Yes | Section to fetch attendance for |
| `date` | YYYY-MM-DD | No | Default: today |

Response `200`:
```json
{
  "success": true,
  "data": {
    "section_id": "uuid",
    "class_name": "Class 9",
    "section_name": "A",
    "date": "2026-03-15",
    "is_locked": false,
    "summary": {
      "total": 42,
      "present": 38,
      "absent": 3,
      "late": 1,
      "half_day": 0,
      "not_marked": 0
    },
    "students": [
      {
        "student_id": "uuid",
        "admission_no": "ADM001",
        "name": "Aarav Patel",
        "roll_no": 1,
        "status": "PRESENT",
        "remarks": null
      }
    ]
  }
}
```

#### POST `/api/teacher/attendance`
Mark or update attendance for a section on a date (bulk upsert).

Request body:
```json
{
  "section_id": "uuid",
  "date": "2026-03-15",
  "records": [
    {
      "student_id": "uuid",
      "status": "PRESENT",
      "remarks": null
    },
    {
      "student_id": "uuid",
      "status": "ABSENT",
      "remarks": "Informed by parent"
    }
  ]
}
```

Validation:
- Teacher must be assigned to this section (via subject assignment or class teacher)
- Date must be today or within last 3 days (configurable)
- Status must be one of: `PRESENT`, `ABSENT`, `LATE`, `HALF_DAY`
- All student_ids must belong to the given section

Response `200`:
```json
{
  "success": true,
  "data": {
    "marked": 42,
    "updated": 0,
    "date": "2026-03-15",
    "section_id": "uuid"
  }
}
```

#### GET `/api/teacher/attendance/report`
Attendance report for a section over a date range.

Query params:
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `sectionId` | UUID | Yes | Section ID |
| `fromDate` | YYYY-MM-DD | No | Start date (default: start of current month) |
| `toDate` | YYYY-MM-DD | No | End date (default: today) |

Response `200`:
```json
{
  "success": true,
  "data": {
    "section_id": "uuid",
    "class_name": "Class 9",
    "section_name": "A",
    "from_date": "2026-03-01",
    "to_date": "2026-03-15",
    "summary": {
      "total_working_days": 12,
      "average_attendance_pct": 91.5
    },
    "students": [
      {
        "student_id": "uuid",
        "name": "Aarav Patel",
        "roll_no": 1,
        "present": 11,
        "absent": 1,
        "late": 0,
        "half_day": 0,
        "attendance_pct": 91.7
      }
    ]
  }
}
```

### 4.3 Homework Management

#### GET `/api/teacher/homework`
List homework assigned by this teacher.

Query params:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Page size (max 50) |
| `classId` | UUID | — | Filter by class |
| `sectionId` | UUID | — | Filter by section |
| `subject` | string | — | Filter by subject |
| `status` | string | — | ACTIVE / REVIEWED / CANCELLED |
| `fromDate` | date | — | Due date from |
| `toDate` | date | — | Due date to |

Response `200`:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "uuid",
        "subject": "Physics",
        "class_name": "Class 9",
        "section_name": "A",
        "title": "Chapter 5 - Light Reflection Problems",
        "description": "Solve exercises 5.1 to 5.10 from NCERT textbook",
        "assigned_date": "2026-03-14",
        "due_date": "2026-03-17",
        "attachment_urls": [],
        "status": "ACTIVE",
        "created_at": "2026-03-14T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 15,
      "total_pages": 1
    }
  }
}
```

#### POST `/api/teacher/homework`
Create a new homework assignment.

Request body:
```json
{
  "class_id": "uuid",
  "section_id": "uuid",
  "subject": "Physics",
  "title": "Chapter 5 - Light Reflection Problems",
  "description": "Solve exercises 5.1 to 5.10 from NCERT textbook",
  "due_date": "2026-03-17",
  "attachment_urls": []
}
```

Validation:
- Teacher must be assigned to this class-section for this subject
- `due_date` must be today or future
- `title` is required, max 255 chars
- `assigned_date` is auto-set to today

Response `201`: Created homework object.

#### GET `/api/teacher/homework/:id`
Get homework detail.

Response `200`: Full homework object (same shape as list item).

#### PUT `/api/teacher/homework/:id`
Update homework. Only the creating teacher can update. Cannot update if status is `CANCELLED`.

Request body: Same fields as POST (all optional for partial update).

Response `200`: Updated homework object.

#### PUT `/api/teacher/homework/:id/status`
Change homework status (mark as REVIEWED or CANCELLED).

Request body:
```json
{
  "status": "REVIEWED"
}
```

Response `200`: Updated homework with new status.

#### DELETE `/api/teacher/homework/:id`
Hard delete homework. Only allowed if due_date hasn't passed. Otherwise, use status change to CANCELLED.

Response `200`: `{ "success": true, "message": "Homework deleted" }`

### 4.4 Class Diary

#### GET `/api/teacher/diary`
List class diary entries for the teacher.

Query params:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Page size |
| `classId` | UUID | — | Filter by class |
| `sectionId` | UUID | — | Filter by section |
| `subject` | string | — | Filter by subject |
| `fromDate` | date | — | From date |
| `toDate` | date | — | To date |

Response `200`:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "uuid",
        "subject": "Physics",
        "class_name": "Class 9",
        "section_name": "A",
        "date": "2026-03-15",
        "period_no": 3,
        "topic_covered": "Reflection of Light - Laws and Mirror Formula",
        "description": "Covered laws of reflection, plane mirror image formation, and introduced concave/convex mirrors",
        "page_from": "78",
        "page_to": "85",
        "homework_given": "Exercise 5.1 to 5.5",
        "remarks": "Students need extra practice on mirror formula",
        "created_at": "2026-03-15T10:45:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "total_pages": 3
    }
  }
}
```

#### POST `/api/teacher/diary`
Create a class diary entry.

Request body:
```json
{
  "class_id": "uuid",
  "section_id": "uuid",
  "subject": "Physics",
  "date": "2026-03-15",
  "period_no": 3,
  "topic_covered": "Reflection of Light - Laws and Mirror Formula",
  "description": "Covered laws of reflection, plane mirror image formation",
  "page_from": "78",
  "page_to": "85",
  "homework_given": "Exercise 5.1 to 5.5",
  "remarks": "Students need extra practice on mirror formula"
}
```

Validation:
- Teacher must be assigned to this class-section for this subject
- `date` must be today or within last 7 days
- `topic_covered` is required
- Unique per (teacher, class, section, subject, date, period_no)

Response `201`: Created diary entry.

#### PUT `/api/teacher/diary/:id`
Update diary entry. Only the author can update. Only entries within last 7 days editable.

Response `200`: Updated diary entry.

#### DELETE `/api/teacher/diary/:id`
Delete diary entry. Only the author can delete. Only entries within last 7 days deletable.

Response `200`: `{ "success": true, "message": "Diary entry deleted" }`

### 4.5 Teacher Profile (Extended from Staff Portal)

#### GET `/api/teacher/profile`
Teacher's own profile with teaching-specific data.

Response `200`:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee_no": "EMP001",
    "first_name": "Ravi",
    "last_name": "Sharma",
    "designation": "TEACHER",
    "department": "Science",
    "email": "ravi@school.in",
    "phone": "+919876543210",
    "photo_url": "https://...",
    "subjects": ["Physics", "Mathematics"],
    "join_date": "2018-04-01",
    "class_teacher_of": {
      "class_name": "Class 9",
      "section_name": "A",
      "student_count": 42
    },
    "subject_assignments": [
      {
        "class_name": "Class 9",
        "section_name": "A",
        "subject": "Physics"
      },
      {
        "class_name": "Class 10",
        "section_name": "B",
        "subject": "Physics"
      }
    ],
    "school": {
      "name": "Vidyron Model School"
    }
  }
}
```

---

## 5. Middleware: `requireTeacher`

New middleware at `backend/src/middleware/teacher-guard.middleware.js`.

```
Flow:
1. Read req.user.userId from JWT (set by verifyAccessToken)
2. Query staff table: WHERE user_id = userId AND deleted_at IS NULL AND is_active = true
3. If no record found → 403 "Teacher access required"
4. Check designation IN ('TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD')
   — If not a teaching designation → 403 "Teacher access required"
5. Attach req.teacher = staff record
6. Fetch subject assignments → attach req.teacherSections = [{classId, sectionId, subject}]
7. Fetch class teacher section if any → attach req.classTeacherSection = {classId, sectionId} | null
8. next()
```

### Section Access Check Helper
```
canAccessSection(req, sectionId):
  return req.teacherSections.some(s => s.sectionId === sectionId)
    || req.classTeacherSection?.sectionId === sectionId
```

This helper is used in every attendance, homework, and diary endpoint to ensure the teacher can only access their assigned sections.

---

## 6. Flutter Screens — Teacher Portal

### Screen Inventory

All screens under `lib/features/teacher/presentation/screens/`.
All providers under `lib/features/teacher/presentation/providers/`.
Models under `lib/models/teacher/`.
Routes registered under `teacher` shell in `app_router.dart`.

### 6.1 Teacher Shell (`teacher_shell.dart`)
**Purpose**: Shell layout for teacher portal with sidebar/bottom navigation.
**Route**: `/teacher`

Navigation items:
| Label | Icon | Route |
|-------|------|-------|
| Dashboard | `Icons.dashboard_outlined` | `/teacher/dashboard` |
| Attendance | `Icons.fact_check_outlined` | `/teacher/attendance` |
| Homework | `Icons.assignment_outlined` | `/teacher/homework` |
| Class Diary | `Icons.menu_book_outlined` | `/teacher/diary` |
| Profile | `Icons.person_outlined` | `/teacher/profile` |

### 6.2 Teacher Dashboard Screen (`teacher_dashboard_screen.dart`)
**Route**: `/teacher/dashboard`

**UI Layout**:
- Welcome header with teacher name, photo, designation
- **Today's Schedule** card — list of periods with subject, class, time, room
- **Quick Stats** row — 4 stat cards: My Sections, Total Students, Pending Attendance, Active Homework
- **Pending Actions** section — list of cards with action buttons (e.g., "Mark Attendance for 9-A")
- **Class Teacher** card (if applicable) — class name, student count, quick link to attendance

**State**: `teacherDashboardProvider` (FutureProvider.autoDispose)
**API**: GET `/api/teacher/dashboard`

### 6.3 Attendance Screen (`teacher_attendance_screen.dart`)
**Route**: `/teacher/attendance`

**UI Layout**:
- **Section Picker** dropdown — shows assigned sections (class name + section)
- **Date Picker** — defaults to today
- **Summary Bar** — Present / Absent / Late / Half Day counts
- **Student List** — scrollable list of students, each row has:
  - Roll No, Student Name, Admission No
  - Attendance status selector (segmented buttons: P / A / L / H)
  - Optional remarks text field (expandable)
- **Mark All Present** quick button at top
- **Save Attendance** sticky bottom button
- **Lock indicator** — shows "Locked" badge if editing past date beyond allowed window

**State**: `teacherAttendanceProvider` (StateNotifierProvider.autoDispose)
**API**: GET `/api/teacher/sections`, GET `/api/teacher/attendance`, POST `/api/teacher/attendance`

### 6.4 Attendance Report Screen (`teacher_attendance_report_screen.dart`)
**Route**: `/teacher/attendance/report`

**UI Layout**:
- Section picker + date range picker
- Summary card: Working days, Avg attendance %
- Student-wise table: Name, Present, Absent, Late, Half Day, Attendance %
- Option to switch between table view and calendar heatmap view
- Export (future enhancement)

**State**: `teacherAttendanceReportProvider` (FutureProvider.autoDispose.family)
**API**: GET `/api/teacher/attendance/report`

### 6.5 Homework Screen (`teacher_homework_screen.dart`)
**Route**: `/teacher/homework`

**UI Layout**:
- Filter bar: Class, Section, Subject, Status (chips)
- Homework list — cards showing:
  - Title, Subject, Class-Section
  - Assigned date, Due date, Days remaining badge
  - Status chip (ACTIVE / REVIEWED / CANCELLED)
  - Tap to view detail
- FAB → Create Homework

**State**: `teacherHomeworkListProvider` (StateNotifierProvider.autoDispose)
**API**: GET `/api/teacher/homework`

### 6.6 Homework Form Screen (`teacher_homework_form_screen.dart`)
**Route**: `/teacher/homework/new`, `/teacher/homework/:id/edit`

**UI Layout**:
- Class-Section dropdown (filtered to teacher's assignments)
- Subject dropdown (filtered by selected class-section)
- Title text field
- Description multiline text field
- Due Date picker
- Attachment URLs (add URL fields, optional)
- Save / Cancel buttons

**State**: `teacherHomeworkFormProvider` (StateNotifierProvider.autoDispose)
**API**: POST/PUT `/api/teacher/homework`

### 6.7 Homework Detail Screen (`teacher_homework_detail_screen.dart`)
**Route**: `/teacher/homework/:id`

**UI Layout**:
- Header with title, subject, class-section
- Body with description, dates, attachments
- Status chip with action button: "Mark as Reviewed" or "Cancel"
- Edit button (if due date not passed)
- Delete button (if due date not passed)

**State**: `teacherHomeworkDetailProvider` (FutureProvider.autoDispose.family)
**API**: GET/PUT/DELETE `/api/teacher/homework/:id`

### 6.8 Class Diary Screen (`teacher_diary_screen.dart`)
**Route**: `/teacher/diary`

**UI Layout**:
- Filter bar: Class, Section, Subject, Date range
- Diary entries list — cards showing:
  - Date, Period, Subject, Class-Section
  - Topic covered (truncated)
  - Page range if present
  - Homework given if present
- FAB → Add Diary Entry

**State**: `teacherDiaryListProvider` (StateNotifierProvider.autoDispose)
**API**: GET `/api/teacher/diary`

### 6.9 Class Diary Form Screen (`teacher_diary_form_screen.dart`)
**Route**: `/teacher/diary/new`, `/teacher/diary/:id/edit`

**UI Layout**:
- Class-Section dropdown
- Subject dropdown
- Date picker (default today)
- Period number dropdown (1-8, optional)
- Topic Covered text field (required)
- Description multiline
- Page From / Page To text fields
- Homework Given text field
- Remarks multiline
- Save / Cancel

**State**: `teacherDiaryFormProvider` (StateNotifierProvider.autoDispose)
**API**: POST/PUT `/api/teacher/diary`

### 6.10 Teacher Profile Screen (`teacher_profile_screen.dart`)
**Route**: `/teacher/profile`

**UI Layout**:
- Profile header: photo, name, designation, department
- Employment details section
- Subject Assignments list
- Class Teacher badge (if applicable)
- Change Password link
- School info

**State**: `teacherProfileProvider` (FutureProvider.autoDispose)
**API**: GET `/api/teacher/profile`

---

## 7. Models

### `lib/models/teacher/teacher_dashboard_model.dart`
```dart
class TeacherDashboardModel {
  final TeacherInfo teacher;
  final List<SchedulePeriod> todaySchedule;
  final TeacherStats stats;
  final List<PendingAction> pendingActions;
  final ClassTeacherInfo? classTeacherOf;
}
```

### `lib/models/teacher/attendance_model.dart`
```dart
class SectionAttendanceModel {
  final String sectionId;
  final String className;
  final String sectionName;
  final String date;
  final bool isLocked;
  final AttendanceSummary summary;
  final List<StudentAttendanceRecord> students;
}

class StudentAttendanceRecord {
  final String studentId;
  final String admissionNo;
  final String name;
  final int? rollNo;
  final String status; // PRESENT, ABSENT, LATE, HALF_DAY
  final String? remarks;
}
```

### `lib/models/teacher/homework_model.dart`
```dart
class HomeworkModel {
  final String id;
  final String subject;
  final String className;
  final String sectionName;
  final String title;
  final String? description;
  final String assignedDate;
  final String dueDate;
  final List<String> attachmentUrls;
  final String status; // ACTIVE, REVIEWED, CANCELLED
  final String createdAt;
}
```

### `lib/models/teacher/class_diary_model.dart`
```dart
class ClassDiaryModel {
  final String id;
  final String subject;
  final String className;
  final String sectionName;
  final String date;
  final int? periodNo;
  final String topicCovered;
  final String? description;
  final String? pageFrom;
  final String? pageTo;
  final String? homeworkGiven;
  final String? remarks;
  final String createdAt;
}
```

---

## 8. Service

### `lib/core/services/teacher_service.dart`

```dart
class TeacherService {
  // Dashboard
  Future<TeacherDashboardModel> getDashboard();

  // Sections
  Future<List<TeacherSectionModel>> getSections();

  // Attendance
  Future<SectionAttendanceModel> getAttendance(String sectionId, {String? date});
  Future<Map<String, dynamic>> markAttendance(Map<String, dynamic> body);
  Future<AttendanceReportModel> getAttendanceReport(String sectionId, {String? fromDate, String? toDate});

  // Homework
  Future<PaginatedResponse<HomeworkModel>> getHomework({int page, int limit, String? classId, String? sectionId, String? subject, String? status});
  Future<HomeworkModel> createHomework(Map<String, dynamic> body);
  Future<HomeworkModel> getHomeworkDetail(String id);
  Future<HomeworkModel> updateHomework(String id, Map<String, dynamic> body);
  Future<void> updateHomeworkStatus(String id, String status);
  Future<void> deleteHomework(String id);

  // Class Diary
  Future<PaginatedResponse<ClassDiaryModel>> getDiaryEntries({int page, int limit, String? classId, String? sectionId, String? subject, String? fromDate, String? toDate});
  Future<ClassDiaryModel> createDiaryEntry(Map<String, dynamic> body);
  Future<ClassDiaryModel> updateDiaryEntry(String id, Map<String, dynamic> body);
  Future<void> deleteDiaryEntry(String id);

  // Profile
  Future<TeacherProfileModel> getProfile();
}
```

---

## 9. API Config

In `lib/core/config/api_config.dart`:
```dart
static const String teacherDashboard = '/api/teacher/dashboard';
static const String teacherSections = '/api/teacher/sections';
static const String teacherAttendance = '/api/teacher/attendance';
static const String teacherAttendanceReport = '/api/teacher/attendance/report';
static const String teacherHomework = '/api/teacher/homework';
static const String teacherDiary = '/api/teacher/diary';
static const String teacherProfile = '/api/teacher/profile';
```

---

## 10. Routes in `app_router.dart`

```dart
ShellRoute(
  builder: (_, state, child) => const TeacherShell(child: child),
  routes: [
    GoRoute(path: '/teacher/dashboard', builder: (_, __) => const TeacherDashboardScreen()),
    GoRoute(path: '/teacher/attendance', builder: (_, __) => const TeacherAttendanceScreen()),
    GoRoute(path: '/teacher/attendance/report', builder: (_, __) => const TeacherAttendanceReportScreen()),
    GoRoute(path: '/teacher/homework', builder: (_, __) => const TeacherHomeworkScreen()),
    GoRoute(path: '/teacher/homework/new', builder: (_, __) => const TeacherHomeworkFormScreen()),
    GoRoute(path: '/teacher/homework/:id', builder: (_, state) => TeacherHomeworkDetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/teacher/homework/:id/edit', builder: (_, state) => TeacherHomeworkFormScreen(homeworkId: state.pathParameters['id'])),
    GoRoute(path: '/teacher/diary', builder: (_, __) => const TeacherDiaryScreen()),
    GoRoute(path: '/teacher/diary/new', builder: (_, __) => const TeacherDiaryFormScreen()),
    GoRoute(path: '/teacher/diary/:id/edit', builder: (_, state) => TeacherDiaryFormScreen(diaryId: state.pathParameters['id'])),
    GoRoute(path: '/teacher/profile', builder: (_, __) => const TeacherProfileScreen()),
  ],
)
```

---

## 11. Auth Integration

### Login Flow for Teachers
- Teachers log in via the existing Staff Login screen
- The login response already includes `portal_type` and `role`
- After login, if `staff.designation IN ('TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD')`, route to `/teacher/dashboard` instead of `/staff/dashboard`
- The auth guard must be updated to recognize the teacher portal

### JWT Claims (No Change)
```json
{
  "userId": "uuid",
  "school_id": "uuid",
  "role": "staff",
  "portal_type": "staff"
}
```
The `requireTeacher` middleware differentiates by checking the `staff.designation` field.

---

## 12. Business Rules

### Attendance
1. A teacher can mark attendance only for sections they are assigned to (subject assignment or class teacher).
2. Attendance can be modified for today and up to 3 previous days. After that, it's locked (admin can override via school admin portal).
3. Bulk upsert — if attendance already exists for a student-date, it is updated. Otherwise, created.
4. `marked_by` is set to the teacher's `user_id`.
5. All student attendance statuses must be one of: PRESENT, ABSENT, LATE, HALF_DAY.

### Homework
6. Only the creating teacher can edit/delete their homework.
7. Homework can only be hard-deleted if the due date hasn't passed.
8. After due date, homework can be marked as REVIEWED or CANCELLED (soft status change).
9. `assigned_date` is always auto-set to the creation date.
10. A teacher can only assign homework for class-sections they teach.

### Class Diary
11. Only the author teacher can edit/delete their diary entries.
12. Diary entries are editable within 7 days of the entry date.
13. Unique constraint: one entry per teacher+class+section+subject+date+period.
14. A class teacher can view all diary entries for their class section (all subjects, all teachers).

### Section Access
15. `staff_subject_assignments.is_active = true` determines current access.
16. If a teacher's subject assignment is deactivated, they lose access to that section's data going forward, but historical data (attendance they marked, homework they assigned) remains.

### Security
17. All queries must include `schoolId` from the teacher's staff record (tenant isolation).
18. Teachers cannot access other schools' data.
19. Teachers cannot access sections they are not assigned to.

---

## 13. Migration Plan

### Migration: `20260316100000_create_homework_table`
```sql
CREATE TABLE homework (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES school_classes(id) ON DELETE CASCADE,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  subject VARCHAR(100) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  attachment_urls TEXT[] DEFAULT '{}',
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_homework_school ON homework(school_id);
CREATE INDEX idx_homework_staff ON homework(staff_id);
CREATE INDEX idx_homework_class_section ON homework(class_id, section_id);
CREATE INDEX idx_homework_due_date ON homework(school_id, due_date);
```

### Migration: `20260316100001_create_class_diary_table`
```sql
CREATE TABLE class_diary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES school_classes(id) ON DELETE CASCADE,
  section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
  subject VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  period_no SMALLINT,
  topic_covered VARCHAR(500) NOT NULL,
  description TEXT,
  page_from VARCHAR(20),
  page_to VARCHAR(20),
  homework_given VARCHAR(500),
  remarks TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_class_diary_unique
  ON class_diary(school_id, staff_id, class_id, COALESCE(section_id, '00000000-0000-0000-0000-000000000000'), subject, date, COALESCE(period_no, -1));

CREATE INDEX idx_class_diary_school ON class_diary(school_id);
CREATE INDEX idx_class_diary_staff ON class_diary(staff_id);
CREATE INDEX idx_class_diary_class_section_date ON class_diary(class_id, section_id, date);
CREATE INDEX idx_class_diary_school_date ON class_diary(school_id, date);
```

---

## 14. Backend File Structure

```
backend/src/modules/teacher/
  teacher.controller.js      — route handlers
  teacher.service.js         — business logic
  teacher.repository.js      — Prisma queries
  teacher.routes.js          — Express router
  teacher.validation.js      — Joi schemas

backend/src/middleware/
  teacher-guard.middleware.js — requireTeacher middleware
```

---

## 15. Acceptance Criteria

### Dashboard
- [ ] Dashboard loads teacher's today schedule from timetable
- [ ] Quick stats show correct section count, student count, pending attendance, active homework
- [ ] Pending actions list shows sections where attendance hasn't been marked today
- [ ] Class teacher card shows correctly for class teachers

### Attendance
- [ ] Section picker shows only assigned sections (not all school sections)
- [ ] Mark All Present button sets all students to PRESENT
- [ ] Save attendance creates/updates records and shows success toast
- [ ] Editing today's attendance works (upsert behavior)
- [ ] Attempting to mark attendance for a date >3 days ago returns 400
- [ ] Attendance report shows correct per-student stats with percentages
- [ ] Teacher cannot mark attendance for a section they're not assigned to (403)

### Homework
- [ ] Create homework with all fields, shows in homework list
- [ ] Filter by class, subject, status works
- [ ] Edit homework updates correctly
- [ ] Delete homework before due date works
- [ ] Delete homework after due date returns 400
- [ ] Mark homework as REVIEWED updates status
- [ ] Teacher can only see/manage their own homework

### Class Diary
- [ ] Create diary entry for today shows in diary list
- [ ] Unique constraint prevents duplicate entries for same period/subject/date
- [ ] Edit diary entry within 7 days works
- [ ] Edit diary entry older than 7 days returns 400
- [ ] Class teacher can view all subjects' diary entries for their class
- [ ] Regular teacher can only see their own diary entries

### Security
- [ ] Teacher without subject assignments sees empty section list
- [ ] Non-teacher staff (CLERK, etc.) accessing `/api/teacher/*` gets 403
- [ ] Cross-school data access returns 403
- [ ] All attendance records have correct `marked_by` (teacher's user ID)

---

## 16. Future Enhancements (Not in v1)

1. **Student homework submission tracking** — students submit homework, teacher marks as done/pending
2. **Attendance SMS/push notifications** — auto-send absence notifications to parents
3. **Subject-wise period attendance** — instead of daily, mark per-period attendance
4. **Substitution management** — when a teacher is absent, assign substitute and grant temporary access
5. **Parent view of diary** — parents can see class diary entries for their child's section
6. **Analytics** — attendance trends, homework completion rates, teaching coverage reports
