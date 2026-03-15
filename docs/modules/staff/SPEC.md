# Non-Teaching Staff Module — Technical Specification

Version: 2.0
Date: 2026-03-15
Author: ERP Tech Lead Agent (Vidyron)

---

## 1. Domain Overview

Schools employ a wide spectrum of non-teaching personnel. Unlike teachers (who are
subject-specialists with class assignments and period-wise attendance), non-teaching staff
perform operational roles: financial clerks collect fees, librarians manage books, lab
assistants manage equipment, security guards man gates, and peons run errands. Each role
has a different daily workflow, yet all share the same HR concerns — attendance, leave,
payslips, and notices.

The critical business insight driving this module's design is that **staff roles in Indian
schools are not a closed enum**. A school in Karnataka might call someone a "Senior Clerk",
while a school in Mumbai calls the same function a "Head Office Assistant". The system must
therefore support:

1. A set of well-known **system-defined role types** (built-in, cannot be deleted) that
   the platform uses internally to determine portal access level.
2. **School-defined custom roles** that extend or alias the system roles with local
   terminology.
3. A **role_category** concept that buckets all roles (predefined and custom) into five
   access tiers: ADMIN_SUPPORT, FINANCE, LIBRARY, LABORATORY, GENERAL.

This module covers:
- Role management (predefined system roles + school custom roles)
- Non-teaching staff CRUD on the School Admin side
- Daily attendance for non-teaching staff (check-in/check-out model, distinct from
  teacher period-wise attendance)
- Leave application and approval for non-teaching staff
- The staff portal experience after login (personalized by role_category)

### Indian School Context
- Academic year: April to March
- Most schools follow a shift-based day (morning/afternoon) for non-teaching staff
- Government schools often have official pay grades mapped to salary bands
- Private schools may use contract or part-time staff for roles like security, peon
- Staff employee IDs typically follow a format like "SCH-2025-001" or "EMP/2025/001"

---

## 2. User Roles and Permissions

### 2.1 Role Categories and Portal Access

| Role Category | Included System Roles | Portal Access Level |
|---|---|---|
| FINANCE | CLERK, ACCOUNTANT, CASHIER, FINANCE_OFFICER | Fee collection screens + base portal |
| LIBRARY | LIBRARIAN, ASST_LIBRARIAN | Library dashboard (placeholder) + base portal |
| LABORATORY | LAB_ASSISTANT, LAB_TECHNICIAN | Lab inventory summary (placeholder) + base portal |
| ADMIN_SUPPORT | RECEPTIONIST, PEON, SECURITY, STORE_KEEPER, IT_ADMIN, TRANSPORT_COORDINATOR | Base portal only |
| GENERAL | Other / custom roles | Base portal only |

**Base portal** = own profile, own attendance, own leaves, school notices, payslip view (placeholder).

### 2.2 Who Creates/Manages Staff

| Actor | Capability |
|---|---|
| School Admin | Full CRUD on staff records, role assignment, attendance entry, leave approval, role management |
| Non-teaching Staff (portal login) | View own profile, own attendance, apply for leave, view notices, view payslip |

### 2.3 System Role Definitions (Predefined — Cannot Be Deleted)

| System Role Code | Display Name | Category |
|---|---|---|
| CLERK | Clerk | FINANCE |
| ACCOUNTANT | Accountant | FINANCE |
| CASHIER | Cashier | FINANCE |
| FINANCE_OFFICER | Finance Officer | FINANCE |
| LIBRARIAN | Librarian | LIBRARY |
| ASST_LIBRARIAN | Assistant Librarian | LIBRARY |
| LAB_ASSISTANT | Lab Assistant | LABORATORY |
| LAB_TECHNICIAN | Lab Technician | LABORATORY |
| RECEPTIONIST | Receptionist | ADMIN_SUPPORT |
| PEON | Peon | ADMIN_SUPPORT |
| SECURITY | Security Guard | ADMIN_SUPPORT |
| STORE_KEEPER | Store Keeper | ADMIN_SUPPORT |
| IT_ADMIN | IT Administrator | ADMIN_SUPPORT |
| TRANSPORT_COORDINATOR | Transport Coordinator | ADMIN_SUPPORT |
| OTHER | Other | GENERAL |

Schools may add custom roles (e.g., "Senior Clerk", "Head Librarian") and map them to a
category. Custom roles inherit access level from their assigned category.

---

## 3. Features and User Stories

### 3.1 Role Management (School Admin)

- As a School Admin, I can view all predefined system roles so that I understand what
  access each role grants.
- As a School Admin, I can create custom roles with a display name and category so that
  I can match our school's internal terminology.
- As a School Admin, I can edit the display name and description of custom roles so that
  I can correct typos or update role titles.
- As a School Admin, I can deactivate a custom role so that it no longer appears when
  creating new staff (existing staff retain their role assignment).
- As a School Admin, I cannot delete a system-predefined role.
- As a School Admin, I cannot delete a custom role that has active staff assigned to it.

### 3.2 Staff Management (School Admin)

- As a School Admin, I can list all non-teaching staff filterable by role, category,
  department, and active status so that I can find staff quickly.
- As a School Admin, I can add a new non-teaching staff member with a role assignment
  (from predefined or custom roles) so that they are on record.
- As a School Admin, I can edit a staff member's profile, role, department, and employment
  details so that records stay accurate.
- As a School Admin, I can activate or deactivate a staff member so that I can handle
  joinings and exits without permanent deletion.
- As a School Admin, I can soft-delete a staff member (with confirmation) so that history
  is preserved.
- As a School Admin, I can generate a portal login for a non-teaching staff member so that
  they can access the staff portal.
- As a School Admin, I can reset a staff member's portal password so that they can regain
  access.
- As a School Admin, I can export the non-teaching staff list as CSV for payroll or
  reporting purposes.
- As a School Admin, I can view a staff member's detailed profile including qualifications,
  documents, attendance summary, and leave history.

### 3.3 Staff Attendance (School Admin Entry)

- As a School Admin, I can mark daily attendance for all non-teaching staff in a bulk
  entry grid so that the HR record is maintained.
- As a School Admin, I can view a monthly attendance report for a specific staff member or
  all non-teaching staff so that I can calculate pay deductions.
- As a School Admin, I can correct an attendance entry for a past date (within current
  month) so that I can fix mistakes.
- As a School Admin, I can filter the bulk attendance screen by department or role category
  so that I can handle large staff rosters efficiently.

### 3.4 Leave Management (School Admin Side)

- As a School Admin, I can view all pending leave requests from non-teaching staff so that
  I can act on them promptly.
- As a School Admin, I can approve or reject a leave request with a remark so that the
  staff member is informed.
- As a School Admin, I can view a leave summary per staff member per academic year showing
  leaves taken by type so that I can enforce leave policies.
- As a School Admin, I can configure leave types and annual quotas per leave type per
  category of staff (optional — via school_leave_policy table).

### 3.5 Staff Portal — Own Experience (After Login)

- As a non-teaching staff member, I can see my personalized dashboard showing today's
  attendance status, pending leaves, and unread notices so that I have a quick overview.
- As a non-teaching staff member, I can view my own profile with employment details so
  that I can verify my records.
- As a non-teaching staff member, I can request a profile update for phone/address via
  the portal so that admin can approve the change.
- As a non-teaching staff member, I can view my attendance record for the current month
  and past months so that I know my standing.
- As a non-teaching staff member, I can apply for leave with date range, leave type, and
  reason so that I formally request time off.
- As a non-teaching staff member, I can view my leave history and status (PENDING /
  APPROVED / REJECTED / CANCELLED) so that I know where my requests stand.
- As a non-teaching staff member, I can cancel a PENDING leave request so that I can
  withdraw applications I no longer need.
- As a non-teaching staff member, I can view school notices targeted at "all" or at the
  "staff" role so that I stay informed.
- As a Finance staff member, I can additionally access the fee collection screen so that
  I can collect student fees and issue receipts.
- As a Library staff member, I can additionally see the library dashboard placeholder so
  that the library module will integrate here when built.
- As a Lab staff member, I can additionally see the lab inventory summary placeholder so
  that the lab module will integrate here when built.
- As a non-teaching staff member, I can view my payslip (placeholder for Payroll module)
  so that the section is reserved for future use.

---

## 4. Data Model

### 4.1 New Tables Required

#### 4.1.1 `non_teaching_staff_roles` — Predefined + custom roles per school

```
id              UUID PK @default(uuid())
school_id       UUID? FK → schools.id   (NULL = system predefined role visible to all schools)
code            VARCHAR(50)              (e.g., "CLERK", "ACCOUNTANT", "SENIOR_CLERK")
display_name    VARCHAR(100)             (e.g., "Senior Clerk", "Head Finance")
category        StaffRoleCategory ENUM   (FINANCE | LIBRARY | LABORATORY | ADMIN_SUPPORT | GENERAL)
is_system       Boolean @default(false)  (true = predefined, cannot be deleted by school)
description     TEXT?
is_active       Boolean @default(true)
created_at      Timestamptz
updated_at      Timestamptz
```

Constraints:
- `@@unique([school_id, code])` — code unique per school (system roles have NULL school_id,
  code unique across NULLs enforced at application layer)
- System roles are seeded in migration and protected at API layer from deletion

#### 4.1.2 `non_teaching_staff` — Non-teaching staff records (separate from teaching Staff)

Design decision: Use the existing `staff` table for teaching staff (teachers already exist
there). Create a parallel `non_teaching_staff` table for non-teaching staff. This avoids
polluting teacher records with role/category concepts that don't apply to teaching staff,
and allows the two populations to evolve independently.

```
id                    UUID PK @default(uuid())
school_id             UUID FK → schools.id
user_id               UUID? UNIQUE FK → users.id   (null = no portal login yet)
role_id               UUID FK → non_teaching_staff_roles.id   (primary role)
employee_no           VARCHAR(50)   unique within school
first_name            VARCHAR(100)
last_name             VARCHAR(100)
gender                VARCHAR(10)   (MALE | FEMALE | OTHER)
date_of_birth         Date?
phone                 VARCHAR(20)?
email                 VARCHAR(255)
department            VARCHAR(100)?   (e.g., "Accounts", "Library", "General")
designation           VARCHAR(100)?   (free-text title if different from role display_name)
qualification         VARCHAR(255)?
join_date             Date
employee_type         VARCHAR(30) @default("PERMANENT")  (PERMANENT | CONTRACT | PART_TIME | DAILY_WAGE)
salary_grade          VARCHAR(50)?
address               TEXT?
city                  VARCHAR(100)?
state                 VARCHAR(100)?
blood_group           VARCHAR(5)?
emergency_contact_name  VARCHAR(100)?
emergency_contact_phone VARCHAR(20)?
photo_url             TEXT?
is_active             Boolean @default(true)
deleted_at            Timestamptz?
created_at            Timestamptz @default(now())
updated_at            Timestamptz @updatedAt

@@unique([school_id, employee_no])
@@index([school_id])
@@index([school_id, role_id])
@@index([school_id, is_active])
```

#### 4.1.3 `non_teaching_staff_attendance` — Daily check-in/check-out attendance

This is separate from `attendances` table (which is for students) and intentionally
separate from teacher attendance (teachers have period-wise attendance in the Timetable
module context). Non-teaching staff attendance is a simple day-level record.

```
id                UUID PK @default(uuid())
school_id         UUID FK → schools.id
staff_id          UUID FK → non_teaching_staff.id
date              Date
status            NonTeachingAttendanceStatus ENUM  (PRESENT | ABSENT | HALF_DAY | ON_LEAVE | HOLIDAY | LATE)
check_in_time     VARCHAR(8)?   (HH:MM format, optional)
check_out_time    VARCHAR(8)?   (HH:MM format, optional)
marked_by         UUID FK → users.id
remarks           VARCHAR(255)?
created_at        Timestamptz @default(now())
updated_at        Timestamptz @updatedAt

@@unique([staff_id, date])
@@index([school_id, date])
@@index([school_id, staff_id])
```

#### 4.1.4 `non_teaching_staff_leaves` — Leave requests for non-teaching staff

```
id              UUID PK @default(uuid())
school_id       UUID FK → schools.id
staff_id        UUID FK → non_teaching_staff.id
applied_by      UUID FK → users.id    (could be staff themselves or admin on their behalf)
reviewed_by     UUID? FK → users.id
leave_type      VARCHAR(30)           (CASUAL | SICK | EARNED | MATERNITY | PATERNITY | UNPAID | OTHER)
from_date       Date
to_date         Date
total_days      SmallInt
reason          TEXT
status          VARCHAR(20) @default("PENDING")  (PENDING | APPROVED | REJECTED | CANCELLED)
reviewed_at     Timestamptz?
admin_remark    TEXT?
created_at      Timestamptz @default(now())
updated_at      Timestamptz @updatedAt

@@index([school_id])
@@index([staff_id])
@@index([school_id, status])
@@index([school_id, from_date])
```

#### 4.1.5 `non_teaching_staff_documents` — Document attachments

```
id              UUID PK @default(uuid())
school_id       UUID FK → schools.id
staff_id        UUID FK → non_teaching_staff.id
uploaded_by     UUID FK → users.id
verified_by     UUID? FK → users.id
document_type   VARCHAR(50)    (AADHAR | PAN | DEGREE | EXPERIENCE_LETTER | OTHER)
document_name   VARCHAR(255)
file_url        TEXT
file_size_kb    Int?
mime_type       VARCHAR(100)?
verified        Boolean @default(false)
verified_at     Timestamptz?
deleted_at      Timestamptz?
created_at      Timestamptz @default(now())
updated_at      Timestamptz @updatedAt

@@index([school_id])
@@index([staff_id])
```

#### 4.1.6 `non_teaching_staff_qualifications` — Academic qualifications

```
id                  UUID PK @default(uuid())
school_id           UUID FK → schools.id
staff_id            UUID FK → non_teaching_staff.id
degree              VARCHAR(100)
institution         VARCHAR(255)
board_or_university VARCHAR(255)?
year_of_passing     SmallInt?
grade_or_percentage VARCHAR(20)?
is_highest          Boolean @default(false)
created_at          Timestamptz @default(now())
updated_at          Timestamptz @updatedAt

@@index([school_id])
@@index([staff_id])
```

### 4.2 New Enum Types

```
enum StaffRoleCategory {
  FINANCE
  LIBRARY
  LABORATORY
  ADMIN_SUPPORT
  GENERAL
}

enum NonTeachingAttendanceStatus {
  PRESENT
  ABSENT
  HALF_DAY
  ON_LEAVE
  HOLIDAY
  LATE
}
```

### 4.3 Relation Summary (ERD in text)

```
School              has many  NonTeachingStaffRole  (school_id nullable — system roles have NULL)
School              has many  NonTeachingStaff
NonTeachingStaff    belongs to NonTeachingStaffRole (role_id)
NonTeachingStaff    belongs to User (user_id, optional — for portal login)
NonTeachingStaff    has many  NonTeachingStaffAttendance
NonTeachingStaff    has many  NonTeachingStaffLeave
NonTeachingStaff    has many  NonTeachingStaffDocument
NonTeachingStaff    has many  NonTeachingStaffQualification
User (admin)        marks many NonTeachingStaffAttendance (marked_by)
User (admin/staff)  applies   NonTeachingStaffLeave (applied_by)
User (admin)        reviews   NonTeachingStaffLeave (reviewed_by)
```

### 4.4 Existing Tables Used (No Changes)

| Table | How Non-Teaching Staff Module Uses It |
|---|---|
| `users` | Each staff member with portal access has a User record (role_id points to existing 'staff' Role row) |
| `school_notices` | Staff portal reads notices where target_role IS NULL or 'staff' or 'all' |
| `schools` | Tenant root for all queries |

### 4.5 Sequence: Employee Number Generation

Format: `NTS-{YYYY}-{3-digit-seq}` where YYYY is the current calendar year and seq is
school-scoped auto-increment. Example: `NTS-2025-001`, `NTS-2025-002`.

The backend generates this automatically; the frontend shows it as a read-only field after
creation, with an option to suggest before saving.

---

## 5. API Endpoints

All School Admin endpoints: base path `/api/school/`
All Staff Portal endpoints: base path `/api/staff/`
All endpoints require `verifyAccessToken`. School admin endpoints additionally require
`requireSchoolAdmin`. Staff portal endpoints additionally require `requireStaff`.

### 5.1 Role Management (School Admin)

| Method | Path | Description |
|---|---|---|
| GET | /api/school/non-teaching/roles | List all roles available to this school (system + school-custom) |
| POST | /api/school/non-teaching/roles | Create a custom role |
| PUT | /api/school/non-teaching/roles/:roleId | Update display name / description of custom role |
| PATCH | /api/school/non-teaching/roles/:roleId/toggle | Activate / deactivate a custom role |
| DELETE | /api/school/non-teaching/roles/:roleId | Delete custom role (blocked if staff assigned) |

**GET /api/school/non-teaching/roles response**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "code": "CLERK",
      "display_name": "Clerk",
      "category": "FINANCE",
      "is_system": true,
      "is_active": true,
      "staff_count": 3
    }
  ]
}
```

**POST /api/school/non-teaching/roles body**
```json
{
  "code": "SENIOR_CLERK",
  "display_name": "Senior Clerk",
  "category": "FINANCE",
  "description": "Senior clerk handling cross-department records"
}
```

### 5.2 Non-Teaching Staff CRUD (School Admin)

| Method | Path | Description |
|---|---|---|
| GET | /api/school/non-teaching/staff | List staff (paginated, filtered) |
| POST | /api/school/non-teaching/staff | Create staff member |
| GET | /api/school/non-teaching/staff/suggest-employee-no | Auto-generate employee number |
| GET | /api/school/non-teaching/staff/export | Export CSV |
| GET | /api/school/non-teaching/staff/:id | Get staff detail |
| PUT | /api/school/non-teaching/staff/:id | Update staff member |
| DELETE | /api/school/non-teaching/staff/:id | Soft delete |
| PATCH | /api/school/non-teaching/staff/:id/status | Activate / deactivate |
| POST | /api/school/non-teaching/staff/:id/create-login | Create portal User account |
| POST | /api/school/non-teaching/staff/:id/reset-password | Reset portal password |

**GET /api/school/non-teaching/staff query params**
- `page`, `limit` — pagination
- `search` — searches first_name, last_name, employee_no, email
- `roleId` — filter by role UUID
- `category` — filter by StaffRoleCategory
- `department` — filter by department string
- `employeeType` — filter by PERMANENT / CONTRACT / PART_TIME / DAILY_WAGE
- `isActive` — true / false / (omit for all)
- `sortBy` — field name (default: first_name)
- `sortOrder` — asc / desc

**GET /api/school/non-teaching/staff response data shape (each item)**
```json
{
  "id": "uuid",
  "school_id": "uuid",
  "user_id": "uuid or null",
  "employee_no": "NTS-2025-001",
  "first_name": "Ramesh",
  "last_name": "Kumar",
  "gender": "MALE",
  "date_of_birth": "1985-04-12",
  "phone": "9876543210",
  "email": "ramesh@school.edu",
  "department": "Accounts",
  "designation": "Senior Clerk",
  "qualification": "B.Com",
  "join_date": "2019-06-01",
  "employee_type": "PERMANENT",
  "salary_grade": "Grade-3",
  "blood_group": "B+",
  "is_active": true,
  "photo_url": null,
  "has_login": true,
  "role": {
    "id": "uuid",
    "code": "CLERK",
    "display_name": "Clerk",
    "category": "FINANCE",
    "is_system": true
  }
}
```

**POST /api/school/non-teaching/staff body**
```json
{
  "role_id": "uuid",
  "employee_no": "NTS-2025-001",
  "first_name": "Ramesh",
  "last_name": "Kumar",
  "gender": "MALE",
  "date_of_birth": "1985-04-12",
  "phone": "9876543210",
  "email": "ramesh@school.edu",
  "department": "Accounts",
  "designation": "Senior Clerk",
  "qualification": "B.Com",
  "join_date": "2019-06-01",
  "employee_type": "PERMANENT",
  "salary_grade": "Grade-3",
  "address": "123 MG Road",
  "city": "Bengaluru",
  "state": "Karnataka",
  "blood_group": "B+",
  "emergency_contact_name": "Priya Kumar",
  "emergency_contact_phone": "9876500001"
}
```

**POST /api/school/non-teaching/staff/:id/create-login body**
```json
{
  "password": "TempPass@123"
}
```

**PATCH /api/school/non-teaching/staff/:id/status body**
```json
{
  "is_active": false,
  "reason": "Resigned effective 2026-03-01"
}
```

### 5.3 Qualifications Sub-Resource

| Method | Path | Description |
|---|---|---|
| GET | /api/school/non-teaching/staff/:id/qualifications | List qualifications |
| POST | /api/school/non-teaching/staff/:id/qualifications | Add qualification |
| PUT | /api/school/non-teaching/staff/:id/qualifications/:qualId | Update qualification |
| DELETE | /api/school/non-teaching/staff/:id/qualifications/:qualId | Delete qualification |

### 5.4 Documents Sub-Resource

| Method | Path | Description |
|---|---|---|
| GET | /api/school/non-teaching/staff/:id/documents | List documents |
| POST | /api/school/non-teaching/staff/:id/documents | Upload document metadata |
| PUT | /api/school/non-teaching/staff/:id/documents/:docId/verify | Mark document verified |
| DELETE | /api/school/non-teaching/staff/:id/documents/:docId | Soft delete document |

### 5.5 Staff Attendance (School Admin)

| Method | Path | Description |
|---|---|---|
| GET | /api/school/non-teaching/attendance | Get attendance for a date (all staff) |
| POST | /api/school/non-teaching/attendance/bulk | Bulk mark attendance for a date |
| PUT | /api/school/non-teaching/attendance/:id | Correct a single attendance record |
| GET | /api/school/non-teaching/attendance/report | Monthly report for a staff member or all |

**GET /api/school/non-teaching/attendance query params**
- `date` (required, YYYY-MM-DD)
- `department` (optional filter)
- `category` (optional filter)

**GET /api/school/non-teaching/attendance response**
```json
{
  "success": true,
  "data": {
    "date": "2026-03-15",
    "total_staff": 12,
    "present": 10,
    "absent": 1,
    "on_leave": 1,
    "records": [
      {
        "staff_id": "uuid",
        "employee_no": "NTS-2025-001",
        "name": "Ramesh Kumar",
        "role_display": "Clerk",
        "department": "Accounts",
        "status": "PRESENT",
        "check_in_time": "08:30",
        "check_out_time": "17:00",
        "remarks": null
      }
    ]
  }
}
```

**POST /api/school/non-teaching/attendance/bulk body**
```json
{
  "date": "2026-03-15",
  "records": [
    {
      "staff_id": "uuid",
      "status": "PRESENT",
      "check_in_time": "08:30",
      "check_out_time": "17:00",
      "remarks": null
    }
  ]
}
```

**GET /api/school/non-teaching/attendance/report query params**
- `staffId` (optional — if omitted, returns aggregate for all)
- `month` (required, YYYY-MM)
- `department` (optional filter)

### 5.6 Leave Management (School Admin)

| Method | Path | Description |
|---|---|---|
| GET | /api/school/non-teaching/leaves | List all leave requests (filtered) |
| GET | /api/school/non-teaching/leaves/summary | Leave summary per staff per year |
| PUT | /api/school/non-teaching/leaves/:leaveId/review | Approve or reject leave |
| PUT | /api/school/non-teaching/leaves/:leaveId/cancel | Cancel leave (admin side) |
| GET | /api/school/non-teaching/staff/:id/leaves | List leaves for specific staff |
| POST | /api/school/non-teaching/staff/:id/leaves | Apply leave on behalf of staff |

**GET /api/school/non-teaching/leaves query params**
- `page`, `limit`
- `status` — PENDING / APPROVED / REJECTED / CANCELLED
- `staffId` — filter to specific staff
- `leaveType` — filter by leave type
- `fromDate`, `toDate` — date range
- `academicYear` — e.g., 2025-26

**PUT /api/school/non-teaching/leaves/:leaveId/review body**
```json
{
  "status": "APPROVED",
  "admin_remark": "Approved. Ensure handover before leave."
}
```

### 5.7 Staff Portal — Own APIs (/api/staff/ extension)

These endpoints are additions to the existing `/api/staff/` module. They are protected by
the existing `requireStaff` middleware.

| Method | Path | Description |
|---|---|---|
| GET | /api/staff/my/profile | Own non-teaching staff profile (role-enriched) |
| GET | /api/staff/my/attendance | Own attendance (month query param) |
| GET | /api/staff/my/leaves | Own leaves (paginated) |
| POST | /api/staff/my/leaves | Apply for leave |
| PUT | /api/staff/my/leaves/:leaveId/cancel | Cancel own PENDING leave |
| GET | /api/staff/my/leave-summary | Own leave summary by type for current year |
| GET | /api/staff/my/payslip | Payslip placeholder (returns 501 message until Payroll built) |

**GET /api/staff/my/profile response**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee_no": "NTS-2025-001",
    "first_name": "Ramesh",
    "last_name": "Kumar",
    "email": "ramesh@school.edu",
    "phone": "9876543210",
    "photo_url": null,
    "department": "Accounts",
    "designation": "Senior Clerk",
    "join_date": "2019-06-01",
    "employee_type": "PERMANENT",
    "blood_group": "B+",
    "address": "123 MG Road, Bengaluru",
    "emergency_contact_name": "Priya Kumar",
    "emergency_contact_phone": "9876500001",
    "is_active": true,
    "role": {
      "code": "CLERK",
      "display_name": "Clerk",
      "category": "FINANCE"
    },
    "portal_access": {
      "fee_collection": true,
      "library_dashboard": false,
      "lab_inventory": false
    },
    "school": {
      "name": "Vidyron Model School",
      "logo_url": null
    },
    "today_attendance": {
      "status": "PRESENT",
      "check_in_time": "08:30"
    },
    "pending_leaves": 1,
    "unread_notices": 3
  }
}
```

**GET /api/staff/my/attendance query params**
- `month` (YYYY-MM, default: current month)

**GET /api/staff/my/attendance response**
```json
{
  "success": true,
  "data": {
    "month": "2026-03",
    "summary": {
      "total_working_days": 26,
      "present": 22,
      "absent": 1,
      "half_day": 1,
      "on_leave": 2,
      "late": 0
    },
    "records": [
      {
        "date": "2026-03-01",
        "status": "PRESENT",
        "check_in_time": "08:35",
        "check_out_time": "17:05",
        "remarks": null
      }
    ]
  }
}
```

**POST /api/staff/my/leaves body**
```json
{
  "leave_type": "CASUAL",
  "from_date": "2026-03-20",
  "to_date": "2026-03-21",
  "reason": "Personal work"
}
```

---

## 6. Screen Inventory (Flutter)

### School Admin Side — New Screens

#### 6.1 Non-Teaching Staff List Screen
- **Purpose**: View, search, filter all non-teaching staff. Entry point to add new staff.
- **Route**: `/school-admin/non-teaching-staff`
- **Key UI Elements**:
  - Header with "Non-Teaching Staff" title and count badge
  - Search field (name / employee no)
  - Filter chips: by category (FINANCE, LIBRARY, LABORATORY, ADMIN_SUPPORT, GENERAL) + status toggle
  - DataTable/ListView of staff cards: name, role, department, employee type, active badge
  - FAB / Add button → Staff Form
  - Each row tappable → Staff Detail
  - Export CSV button (toolbar)
- **State**: `NonTeachingStaffNotifier` (StateNotifierProvider)
- **API Calls**: GET /api/school/non-teaching/staff

#### 6.2 Non-Teaching Staff Add/Edit Form Screen
- **Purpose**: Create or edit a non-teaching staff record.
- **Route**: `/school-admin/non-teaching-staff/new` and `/school-admin/non-teaching-staff/:id/edit`
- **Key UI Elements**:
  - Section 1 — Role: Dropdown of available roles (from roles API), shows category chip below selection
  - Section 2 — Personal Info: first name, last name, gender, DOB, blood group
  - Section 3 — Contact: phone, email, address, city, state
  - Section 4 — Employment: employee_no (auto-generate button), department, designation, join date, employee type, salary grade
  - Section 5 — Emergency: emergency contact name and phone
  - "Suggest Employee No" button auto-fills from API
  - Save / Cancel buttons
- **State**: `NonTeachingStaffFormNotifier` (StateNotifierProvider)
- **API Calls**: GET /api/school/non-teaching/roles, GET /api/school/non-teaching/staff/suggest-employee-no, POST/PUT /api/school/non-teaching/staff

#### 6.3 Non-Teaching Staff Detail Screen
- **Purpose**: View full profile with tabbed sections.
- **Route**: `/school-admin/non-teaching-staff/:id`
- **Key UI Elements**:
  - Profile header card: photo, name, employee no, role badge (with category color), active status
  - Tab bar: Overview | Qualifications | Documents | Attendance | Leaves
  - Overview tab: employment details, contact, emergency contact, login status with "Create Login" / "Reset Password" buttons
  - Qualifications tab: list with Add/Edit/Delete
  - Documents tab: list with Upload/Verify/Delete
  - Attendance tab: monthly summary + day grid (current month default, month picker)
  - Leaves tab: paginated leave history + summary by type
  - Edit button (top-right) → Edit Form
  - Activate/Deactivate toggle button
- **State**: family FutureProviders per tab (autoDispose)
- **API Calls**: GET /api/school/non-teaching/staff/:id, qualifications, documents, attendance/report, leaves

#### 6.4 Role Management Screen
- **Purpose**: View predefined roles and manage custom school roles.
- **Route**: `/school-admin/non-teaching-roles`
- **Key UI Elements**:
  - Two sections: "System Roles" (read-only cards) and "Custom Roles" (editable list)
  - System roles grouped by category with count of assigned staff
  - Custom roles with edit / toggle-active / delete buttons
  - "Add Custom Role" FAB
  - Add/Edit dialog: code, display_name, category dropdown, description
- **State**: `NonTeachingRolesNotifier` (StateNotifierProvider)
- **API Calls**: GET/POST/PUT/PATCH/DELETE /api/school/non-teaching/roles

#### 6.5 Non-Teaching Staff Attendance Screen
- **Purpose**: Daily bulk attendance entry for all non-teaching staff.
- **Route**: `/school-admin/non-teaching-attendance`
- **Key UI Elements**:
  - Date picker (defaults today)
  - Filter row: category chip, department dropdown
  - Summary row: Present / Absent / Half-Day / On-Leave counts
  - Scrollable staff rows: name + role + attendance status dropdown (PRESENT/ABSENT/HALF_DAY/ON_LEAVE/LATE/HOLIDAY) + optional time fields
  - "Save All" button (bulk POST)
  - "View Report" button → Attendance Report
- **State**: `NonTeachingAttendanceNotifier` (StateNotifierProvider)
- **API Calls**: GET + POST /api/school/non-teaching/attendance/bulk

#### 6.6 Non-Teaching Staff Leave Management Screen
- **Purpose**: School Admin approves/rejects leave requests.
- **Route**: `/school-admin/non-teaching-leaves`
- **Key UI Elements**:
  - Filter tabs: All | Pending | Approved | Rejected
  - Each leave card: staff name + role + date range + type + days + reason + status chip
  - Pending cards have Approve / Reject action buttons
  - Approve/Reject → bottom sheet with remark field
  - Date range filter, academic year filter
  - Leave summary button → summary sheet per staff
- **State**: `NonTeachingLeaveNotifier` (StateNotifierProvider)
- **API Calls**: GET /api/school/non-teaching/leaves, PUT /api/school/non-teaching/leaves/:id/review

### Staff Portal Side — New Screens (within existing /staff/ shell)

#### 6.7 Staff Dashboard Enhancement
- **Purpose**: Personalize existing staff dashboard with role-category-specific widgets.
- **Route**: `/staff/dashboard` (existing screen — extend, not replace)
- **New Widgets by Category**:
  - All: Today Attendance Status card (PRESENT/ABSENT/NOT MARKED), Pending Leaves count, Unread Notices
  - FINANCE: Quick link "Collect Fee" → existing /staff/fees
  - LIBRARY: "Library Dashboard" placeholder card with "Coming Soon" tag
  - LABORATORY: "Lab Inventory" placeholder card with "Coming Soon" tag
- **Changes to existing**: Add role-category awareness via `portal_access` flags in profile API

#### 6.8 My Attendance Screen
- **Purpose**: View own attendance history month by month.
- **Route**: `/staff/my-attendance`
- **Key UI Elements**:
  - Month selector (defaults current month)
  - Summary bar: Working Days | Present | Absent | Half Day | On Leave | Late
  - Calendar grid or list view of daily records with color-coded status chips
  - No edit capability — read only
- **State**: `MyAttendanceNotifier` (StateNotifierProvider)
- **API Calls**: GET /api/staff/my/attendance

#### 6.9 Leave Application Screen
- **Purpose**: Apply for leave.
- **Route**: `/staff/apply-leave`
- **Key UI Elements**:
  - Leave type dropdown (CASUAL / SICK / EARNED / MATERNITY / PATERNITY / UNPAID / OTHER)
  - Date range picker (from_date, to_date)
  - Auto-computed "Total days" (excludes Sundays)
  - Reason text area
  - Leave balance summary (from leave-summary API)
  - Submit button
- **State**: `LeaveApplicationNotifier` (StateNotifierProvider)
- **API Calls**: GET /api/staff/my/leave-summary, POST /api/staff/my/leaves

#### 6.10 My Leaves Screen
- **Purpose**: View own leave history and cancel pending leaves.
- **Route**: `/staff/my-leaves`
- **Key UI Elements**:
  - Filter tabs: All | Pending | Approved | Rejected
  - Each leave card: date range, type, days, reason, status chip, admin remark (if reviewed)
  - Cancel button on PENDING leaves
  - "Apply Leave" FAB → /staff/apply-leave
  - Annual summary row at top: Casual: 5/12, Sick: 2/10, etc.
- **State**: `MyLeavesNotifier` (StateNotifierProvider)
- **API Calls**: GET /api/staff/my/leaves, GET /api/staff/my/leave-summary, PUT /api/staff/my/leaves/:id/cancel

#### 6.11 My Profile Screen Enhancement
- **Purpose**: Extend existing staff profile to show role and category details.
- **Route**: `/staff/profile` (existing screen — extend)
- **New Fields to Show**: role display_name, category, department, join date, employee type, blood group, emergency contact
- **No new screen needed** — extend StaffProfileScreen with additional sections

#### 6.12 Payslip Screen (Placeholder)
- **Purpose**: Reserve the payslip screen location for future Payroll module integration.
- **Route**: `/staff/payslip`
- **Key UI Elements**:
  - "Payslip" heading
  - Illustration with "Payroll module coming soon" message
  - Month selector (disabled / greyed out)
- **State**: None needed
- **API Calls**: None (static placeholder screen)

### Navigation Changes

#### School Admin Shell — Add to sidebar
Add to `_navItems` in `school_admin_shell.dart`:
```
Non-Teaching Staff  icon: Icons.badge_outlined  route: /school-admin/non-teaching-staff
Leave Approval      icon: Icons.event_busy_outlined  route: /school-admin/non-teaching-leaves
Attendance (NT)     icon: Icons.how_to_reg_outlined  route: /school-admin/non-teaching-attendance
Role Management     icon: Icons.manage_accounts_outlined  route: /school-admin/non-teaching-roles
```

#### Staff Shell — Add to sidebar and nav
Add to `_navItems` in `staff_shell.dart`:
```
My Attendance       icon: Icons.calendar_month_outlined  route: /staff/my-attendance
My Leaves           icon: Icons.event_note_outlined      route: /staff/my-leaves
Payslip             icon: Icons.receipt_long_outlined    route: /staff/payslip
```

---

## 7. Business Rules

### 7.1 Employee Number
- Auto-generated as `NTS-{YEAR}-{seq}` if not provided on creation.
- seq is zero-padded to 3 digits, school-scoped, year-scoped (resets each calendar year).
- Must be unique within a school. API validates uniqueness before save.
- Once set, employee_no can be changed by admin (with uniqueness check).

### 7.2 Role Assignment Rules
- Every non-teaching staff must have exactly one primary role (`role_id` required).
- A role can only be assigned if it belongs to the same school or is a system role (school_id IS NULL).
- A custom role cannot be deactivated while it has active staff assigned (API returns 409).
- System roles cannot be deleted; custom roles can be deleted only if no staff ever used them (hard delete) or soft-flagged (we prefer soft: set is_active=false).

### 7.3 Portal Login Creation
- A staff member can only have one User account (enforced by `user_id UNIQUE` on non_teaching_staff table).
- When creating a login, the backend creates a User record with `role_id` pointing to the 'staff' Role row and `portal_type='staff'` embedded in JWT during login.
- The `requireStaff` middleware must be extended to also look up `non_teaching_staff` by user_id (in addition to the existing `staff` table lookup). The middleware returns whichever record matches, and attaches `req.staffType = 'non_teaching'` or `'teaching'`.

Actually, for clean separation: the existing `requireStaff` middleware looks up the existing `staff` (teaching) table. We need it to also check `non_teaching_staff`. The simplest approach: the middleware tries `staff` table first; if no record found there, tries `non_teaching_staff`. If found in non_teaching_staff, attaches `req.ntStaff` and `req.isNonTeaching = true`.

For non-teaching staff portal APIs (`/api/staff/my/*`), the controller reads `req.ntStaff` (or `req.staff` for teaching). The `requireStaff` middleware is extended to handle both populations transparently.

### 7.4 Attendance Rules
- Attendance for a staff-date combination is unique (`@@unique([staff_id, date])`).
- Bulk mark uses upsert — if a record already exists for that date, it is updated.
- School Admin can correct attendance for any past date within the current academic year.
- Attendance on public holidays should default to HOLIDAY status if the school marks holidays in a future Holidays table (currently no holiday table — leave as open status, admin can manually set HOLIDAY).
- ON_LEAVE status should be set automatically when an APPROVED leave covers that date (a background task or at-mark-time check — marked as a desired behavior, implementation deferred to optimization phase).

### 7.5 Leave Rules
- `total_days` is auto-calculated server-side from `from_date` to `to_date` inclusive (counting all calendar days; not business-day-aware in v1).
- A staff member cannot apply a new leave if an APPROVED or PENDING leave overlaps with the requested date range.
- Only PENDING leaves can be cancelled by the staff member themselves.
- APPROVED leaves can be cancelled by admin (cancellation creates an audit entry).
- Leave types and quotas enforcement: deferred to Payroll module. In v1, system does not block applying leave when balance is exhausted — it is admin's responsibility.

### 7.6 Tenant Isolation
- Every DB query for non-teaching staff must include `WHERE school_id = req.staff.schoolId` (for portal) or `req.user.school_id` (for admin routes).
- The `non_teaching_staff_roles` table: queries must return roles WHERE `school_id = schoolId OR school_id IS NULL` (to include system roles).

### 7.7 Soft Delete
- Staff records use `deleted_at` for soft delete.
- Soft-deleted staff are excluded from all list queries by default (`WHERE deleted_at IS NULL`).
- Attendance and leave records for soft-deleted staff are preserved for historical accuracy.
- Document records use `deleted_at` for soft delete.

---

## 8. Integration Points

### 8.1 Auth System (Built)
- Staff portal login already handles `portal_type: 'staff'`.
- The `requireStaff` middleware in `backend/src/middleware/staff-guard.middleware.js` must be extended to also look up `non_teaching_staff` by `user_id` when the existing `staff` table returns no match.
- JWT claims remain unchanged: `{ userId, school_id, role: 'staff', portal_type: 'staff' }`.

### 8.2 Fees Module (Future)
- Finance-category non-teaching staff already have access to `/staff/fees` via the existing `StaffFeesScreen`.
- The `portal_access.fee_collection` flag in the profile response drives UI visibility.
- No schema changes needed — fee payments already record `collected_by` as a User UUID.

### 8.3 Library Module (Future)
- Library-category staff will see a "Library Dashboard" card in their portal.
- The integration point is `/staff/library` route (to be created by Library module).
- This SPEC reserves the placeholder screen at `/staff/library-placeholder`.

### 8.4 Payroll Module (Future)
- All non-teaching staff attendance and leave data will feed into the Payroll module.
- The `non_teaching_staff_attendance` and `non_teaching_staff_leaves` tables are the canonical data sources.
- Payroll module will add a `payslips` table referencing `non_teaching_staff.id`.
- This SPEC reserves `/staff/payslip` route as a placeholder.

### 8.5 Teaching Staff Module (Existing)
- Teaching staff (teachers) live in the existing `staff` table. This module does NOT modify that table or its related tables (`staff_qualifications`, `staff_documents`, `staff_leaves`, `staff_subject_assignments`).
- The School Admin sidebar already has "Teachers" pointing to `/school-admin/staff`. This module adds a separate "Non-Teaching Staff" section alongside it.
- Over time the two modules can converge via a Staff HR module in Payroll phase.

### 8.6 School Notices (Existing)
- Non-teaching staff portal reads from `school_notices` where `target_role IS NULL OR target_role IN ('all', 'staff')`.
- No schema change needed.

---

## 9. Security Requirements

### 9.1 Tenant Isolation
- ALL queries MUST filter by `school_id`.
- System roles have `school_id IS NULL` and are accessible to all schools (read-only).
- School-custom roles have `school_id = theSchool` and must not be visible to other schools.

### 9.2 Role-Based Access at API Layer
- Creating a staff member: School Admin only.
- Viewing any staff: School Admin only (for `/api/school/non-teaching/*`).
- Viewing own data: Staff portal user via `/api/staff/my/*`.
- A non-teaching staff member cannot read another staff member's attendance or leaves via the portal.
- Leave review: School Admin only.

### 9.3 Data Validation
- `role_id` must belong to the school (or be a system role) — checked at service layer before DB write.
- `from_date` must not be in the past by more than 7 days for self-applied leaves (configurable, default 7).
- `to_date` must be >= `from_date`.
- Employee email must be unique within the school (soft-deleted records excluded from uniqueness check).
- Passwords for created logins must meet the platform's password policy (min 8 chars, at least 1 uppercase, 1 number, 1 special char).

### 9.4 Audit Trail
All write operations must call `auditService.logAudit()` with:
- `actorId` — the logged-in user's ID
- `actorRole` — 'school_admin' or 'staff'
- `action` — e.g., 'NON_TEACHING_STAFF_CREATE', 'LEAVE_APPROVE', 'ATTENDANCE_BULK_MARK'
- `entityType` — 'non_teaching_staff', 'non_teaching_staff_leave', 'non_teaching_staff_attendance'
- `entityId` — the created/modified record UUID

### 9.5 Input Sanitization
- All text fields sanitized via existing Joi validation schemas.
- `file_url` for documents: validate as URL format; do not execute or serve directly.
- Phone fields: strip non-digit characters, validate length 10-15.

---

## 10. Migration Plan

### New Migration Files Required

**Migration 1: `20260316000001_add_non_teaching_staff_roles`**
- Create enum `staff_role_category_enum` (FINANCE, LIBRARY, LABORATORY, ADMIN_SUPPORT, GENERAL)
- Create `non_teaching_staff_roles` table
- Seed all 15 system roles (INSERT statements in migration)

**Migration 2: `20260316000002_add_non_teaching_staff`**
- Create `non_teaching_staff` table with FK to `non_teaching_staff_roles` and `users`
- Add indexes

**Migration 3: `20260316000003_add_non_teaching_staff_attendance`**
- Create enum `non_teaching_attendance_status_enum` (PRESENT, ABSENT, HALF_DAY, ON_LEAVE, HOLIDAY, LATE)
- Create `non_teaching_staff_attendance` table

**Migration 4: `20260316000004_add_non_teaching_staff_leaves`**
- Create `non_teaching_staff_leaves` table

**Migration 5: `20260316000005_add_non_teaching_staff_documents_and_qualifications`**
- Create `non_teaching_staff_documents` table
- Create `non_teaching_staff_qualifications` table

### No Changes to Existing Tables
- `staff` table: unchanged (teachers continue to use it)
- `users` table: unchanged (non-teaching staff with logins get User rows the same way teachers do)
- `school_notices`, `attendances`, `staff_leaves`, `fee_payments`: all unchanged

### Seed Data in Migration 1
System roles seeded with `is_system = true`, `school_id = NULL`:

| code | display_name | category |
|---|---|---|
| CLERK | Clerk | FINANCE |
| ACCOUNTANT | Accountant | FINANCE |
| CASHIER | Cashier | FINANCE |
| FINANCE_OFFICER | Finance Officer | FINANCE |
| LIBRARIAN | Librarian | LIBRARY |
| ASST_LIBRARIAN | Assistant Librarian | LIBRARY |
| LAB_ASSISTANT | Lab Assistant | LABORATORY |
| LAB_TECHNICIAN | Lab Technician | LABORATORY |
| RECEPTIONIST | Receptionist | ADMIN_SUPPORT |
| PEON | Peon | ADMIN_SUPPORT |
| SECURITY | Security Guard | ADMIN_SUPPORT |
| STORE_KEEPER | Store Keeper | ADMIN_SUPPORT |
| IT_ADMIN | IT Administrator | ADMIN_SUPPORT |
| TRANSPORT_COORDINATOR | Transport Coordinator | ADMIN_SUPPORT |
| OTHER | Other | GENERAL |

---

## 11. File Paths to Create

### Backend
```
backend/src/modules/non-teaching-staff/
  non-teaching-staff.controller.js
  non-teaching-staff.service.js
  non-teaching-staff.repository.js
  non-teaching-staff.routes.js
  non-teaching-staff.validation.js
backend/src/middleware/staff-guard.middleware.js   (MODIFY — extend to handle non_teaching_staff)
backend/src/app.js                                 (MODIFY — register new route module)
backend/prisma/schema.prisma                       (MODIFY — add new models and enums)
backend/prisma/migrations/20260316000001_add_non_teaching_staff_roles/migration.sql
backend/prisma/migrations/20260316000002_add_non_teaching_staff/migration.sql
backend/prisma/migrations/20260316000003_add_non_teaching_staff_attendance/migration.sql
backend/prisma/migrations/20260316000004_add_non_teaching_staff_leaves/migration.sql
backend/prisma/migrations/20260316000005_add_non_teaching_staff_documents_and_qualifications/migration.sql
```

Also extend `/api/staff/` to include `/api/staff/my/*` routes:
```
backend/src/modules/staff/staff-portal.routes.js    (MODIFY — add /my/* routes)
backend/src/modules/staff/staff-portal.controller.js (MODIFY — add my/* handlers)
backend/src/modules/staff/staff-portal.service.js   (MODIFY — add my/* business logic)
backend/src/modules/staff/staff-portal.repository.js (MODIFY — add my/* queries)
```

### Flutter
```
lib/features/school_admin/presentation/screens/
  school_admin_non_teaching_staff_screen.dart       (new)
  school_admin_non_teaching_staff_form_screen.dart  (new)
  school_admin_non_teaching_staff_detail_screen.dart (new)
  school_admin_non_teaching_roles_screen.dart       (new)
  school_admin_non_teaching_attendance_screen.dart  (new)
  school_admin_non_teaching_leaves_screen.dart      (new)

lib/features/school_admin/presentation/providers/
  school_admin_non_teaching_staff_provider.dart     (new)
  school_admin_non_teaching_roles_provider.dart     (new)
  school_admin_non_teaching_attendance_provider.dart (new)
  school_admin_non_teaching_leaves_provider.dart    (new)

lib/features/staff/presentation/screens/
  staff_my_attendance_screen.dart                   (new)
  staff_apply_leave_screen.dart                     (new)
  staff_my_leaves_screen.dart                       (new)
  staff_payslip_screen.dart                         (new — placeholder)

lib/features/staff/presentation/providers/
  staff_my_attendance_provider.dart                 (new)
  staff_my_leaves_provider.dart                     (new)

lib/models/school_admin/
  non_teaching_staff_model.dart                     (new)
  non_teaching_staff_role_model.dart                (new)
  non_teaching_attendance_model.dart                (new)
  non_teaching_leave_model.dart                     (new)

lib/core/services/
  non_teaching_staff_service.dart                   (new — school admin side API calls)
  school_admin_service.dart                         (MODIFY — add non-teaching endpoints)

lib/features/staff/presentation/staff_shell.dart    (MODIFY — add new nav items)
lib/features/school_admin/presentation/school_admin_shell.dart (MODIFY — add new nav items)
lib/routes/app_router.dart                          (MODIFY — add new routes)
lib/core/config/api_config.dart                     (MODIFY — add new endpoint constants)
```
