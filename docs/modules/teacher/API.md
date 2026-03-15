# Teacher/Staff Module — API Reference

**Base URL:** `/api/school`
**Authentication:** All endpoints require `Authorization: Bearer {access_token}`
**Role required:** `SCHOOL_ADMIN` unless otherwise noted
**Tenant isolation:** School context is derived exclusively from the JWT (`req.user.school_id`). The `school_id` is never accepted from the request body or query parameters.

---

## Utility Endpoints

### GET /api/school/staff/suggest-employee-no

Generate a suggested employee number based on the staff member's name. Used by the Add Staff form to pre-fill the employee number field.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| firstName | string | No | First name of the prospective staff member |
| lastName | string | No | Last name of the prospective staff member |

**Response 200**
```json
{
  "success": true,
  "data": "EMP043"
}
```

---

### GET /api/school/staff/check-employee-no

Check whether a given employee number is available (not already in use within the school).

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| employeeNo | string | Yes | Employee number to check |
| excludeStaffId | UUID | No | Exclude this staff ID from the check (for edit mode) |

**Response 200**
```json
{
  "success": true,
  "data": {
    "available": true
  }
}
```

---

## Staff CRUD

### GET /api/school/staff

Retrieve a paginated, filterable list of all staff members in the school.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number |
| limit | integer | No | 20 | Records per page (max 100) |
| search | string | No | — | Partial match on name, email, or employee number |
| designation | string | No | — | Filter by designation: `TEACHER`, `PRINCIPAL`, `VICE_PRINCIPAL`, `HOD`, `CLERK`, `ACCOUNTANT`, `LIBRARIAN`, `LAB_ASSISTANT`, `COUNSELOR`, `SPORTS_COACH`, `OTHER` |
| department | string | No | — | Filter by department name |
| isActive | boolean | No | — | `true` for active staff only, `false` for inactive only |
| employeeType | string | No | — | Filter by employment type: `PERMANENT`, `CONTRACTUAL`, `PART_TIME`, `PROBATION` |
| subject | string | No | — | Return only staff who teach this subject |

**Response 200**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "d4e8f012-...",
        "school_id": "a1b2c3d4-...",
        "user_id": "u9f8e7d6-...",
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
        "photo_url": "https://storage.vidyron.in/photos/ravi.jpg",
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

**Note:** Sensitive fields (`salary_grade`, `emergency_contact_name`, `emergency_contact_phone`) are excluded from the list response. They appear only in the full detail endpoint.

**Error Responses**

| Status | Condition |
|--------|-----------|
| 401 | Missing or invalid access token |
| 403 | User does not have SCHOOL_ADMIN role |

---

### POST /api/school/staff

Create a new staff member. Optionally creates a portal login account in the same request.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| firstName | string | Yes | 1–100 characters |
| lastName | string | Yes | 1–100 characters |
| gender | string | Yes | `MALE`, `FEMALE`, or `OTHER` |
| email | string | Yes | Valid email, max 255 characters, unique within school |
| phone | string | Yes | 10–20 characters |
| designation | string | Yes | One of the 11 valid designation values (see above) |
| joinDate | string (ISO date) | Yes | e.g., `"2026-04-01"` |
| employeeNo | string | No | Max 50 characters; auto-suggested if omitted; must be unique within school |
| dateOfBirth | string (ISO date) | No | |
| subjects | string[] | No | Up to 30 subject names, each max 100 characters |
| qualification | string | No | Max 255 characters (short summary; full qualifications go in the qualifications sub-resource) |
| photoUrl | string (HTTPS URL) | No | Must be a valid HTTPS URI |
| department | string | No | Max 100 characters |
| employeeType | string | No | `PERMANENT` (default), `CONTRACTUAL`, `PART_TIME`, `PROBATION` |
| address | string | No | Max 500 characters |
| city | string | No | Max 100 characters |
| state | string | No | Max 100 characters |
| bloodGroup | string | No | Max 5 characters (e.g., `"O+"`) |
| emergencyContactName | string | No | Max 100 characters |
| emergencyContactPhone | string | No | Max 20 characters |
| experienceYears | integer | No | 0–60 |
| salaryGrade | string | No | Max 50 characters |
| createLogin | boolean | No | If `true`, creates a `users` record linked to this staff member |
| password | string | No | Required when `createLogin` is `true`; min 8 characters |
| isActive | boolean | No | Defaults to `true` |

**Example Request**
```json
{
  "firstName": "Priya",
  "lastName": "Menon",
  "gender": "FEMALE",
  "email": "priya.menon@school.in",
  "phone": "+919876500000",
  "designation": "TEACHER",
  "joinDate": "2026-04-01",
  "dateOfBirth": "1990-03-22",
  "subjects": ["English", "Hindi"],
  "qualification": "B.Ed",
  "department": "Languages",
  "employeeType": "PERMANENT",
  "experienceYears": 3,
  "address": "14, MG Road",
  "city": "Bengaluru",
  "state": "Karnataka",
  "bloodGroup": "B+",
  "emergencyContactName": "Suresh Menon",
  "emergencyContactPhone": "+919876500001",
  "salaryGrade": "PB-2",
  "createLogin": true,
  "password": "Welcome@123"
}
```

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": "d4e8f012-...",
    "employee_no": "EMP042",
    "first_name": "Priya",
    "last_name": "Menon",
    "full_name": "Priya Menon",
    "user_id": "u9f8e7d6-...",
    "is_active": true,
    "created_at": "2026-04-01T09:00:00Z"
  },
  "message": "Staff member created successfully"
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 409 | Employee number or email already in use within the school |
| 422 | Validation failure — response includes field-level details |
| 400 | `createLogin: true` but `password` not provided |

---

### GET /api/school/staff/:id

Retrieve a complete staff profile, including qualifications, documents, subject assignments, and leave summary.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | UUID | Yes | Staff member ID |

**Response 200**
```json
{
  "success": true,
  "data": {
    "id": "d4e8f012-...",
    "school_id": "a1b2c3d4-...",
    "user_id": "u9f8e7d6-...",
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
    "address": "12, Park Street, New Delhi",
    "city": "New Delhi",
    "state": "Delhi",
    "emergency_contact_name": "Sunita Sharma",
    "emergency_contact_phone": "+919876543299",
    "salary_grade": "PB-3",
    "is_active": true,
    "deleted_at": null,
    "created_at": "2024-04-01T00:00:00Z",
    "updated_at": "2026-03-10T14:30:00Z",
    "qualifications": [
      {
        "id": "q1a2b3c4-...",
        "degree": "M.Sc Physics",
        "institution": "Delhi University",
        "board_or_university": null,
        "year_of_passing": 2010,
        "grade_or_percentage": "First Class",
        "is_highest": true,
        "created_at": "2024-04-02T00:00:00Z"
      }
    ],
    "documents": [
      {
        "id": "doc1a2b3-...",
        "document_type": "AADHAAR",
        "document_name": "Aadhaar Card",
        "file_url": "https://storage.vidyron.in/docs/aadhaar_ravi.pdf",
        "file_size_kb": 340,
        "mime_type": "application/pdf",
        "verified": true,
        "verified_at": "2024-04-05T11:00:00Z",
        "created_at": "2024-04-02T09:00:00Z"
      }
    ],
    "subject_assignments": [
      {
        "id": "sa1b2c3-...",
        "class_id": "cl1a2b3-...",
        "class_name": "Class 9",
        "section_id": "sec1a2b-...",
        "section_name": "A",
        "subject": "Physics",
        "academic_year": "2025-26",
        "is_active": true
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

**Error Responses**

| Status | Condition |
|--------|-----------|
| 403 | Staff belongs to a different school |
| 404 | Staff ID not found or soft-deleted |

---

### PUT /api/school/staff/:id

Update any field on a staff profile. Only fields present in the request body are changed (partial update).

**Request Body**

Same fields as POST but all optional. At least one field must be provided.

| Field | Type | Validation |
|-------|------|------------|
| firstName | string | 1–100 characters |
| lastName | string | 1–100 characters |
| gender | string | `MALE`, `FEMALE`, or `OTHER` |
| email | string | Valid email, uniqueness re-checked within school |
| phone | string | 10–20 characters |
| designation | string | One of the 11 valid designation values |
| joinDate | string (ISO date) | |
| dateOfBirth | string (ISO date) | |
| subjects | string[] | Up to 30 items |
| qualification | string | Max 255 characters |
| photoUrl | string (HTTPS URL) | |
| department | string | Max 100 characters |
| employeeType | string | `PERMANENT`, `CONTRACTUAL`, `PART_TIME`, `PROBATION` |
| address | string | Max 500 characters |
| city | string | Max 100 characters |
| state | string | Max 100 characters |
| bloodGroup | string | Max 5 characters |
| emergencyContactName | string | Max 100 characters |
| emergencyContactPhone | string | Max 20 characters |
| experienceYears | integer | 0–60 |
| salaryGrade | string | Max 50 characters |
| isActive | boolean | |

**Response 200**
```json
{
  "success": true,
  "data": { "...updated staff object..." },
  "message": "Staff updated successfully"
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 409 | Updated employee number or email conflicts with an existing record |
| 422 | Validation failure |
| 404 | Staff not found |

---

### DELETE /api/school/staff/:id

Soft-delete a staff member. Sets `deleted_at = now()` and `is_active = false`. Also deactivates the linked user account if one exists. The record is retained in the database for audit and historical data integrity.

**Constraints:** Cannot delete a staff member who is currently set as a class teacher for any active section. Reassign the class teacher first.

**Response 200**
```json
{
  "success": true,
  "message": "Staff member deactivated"
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 409 | Staff member is assigned as a class teacher for one or more sections |
| 404 | Staff not found |

---

### PUT /api/school/staff/:id/status

Toggle a staff member's active/inactive status without submitting a full update payload. Useful for quickly suspending or reinstating a staff member.

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| isActive | boolean | Yes | `true` to activate, `false` to deactivate |
| reason | string | No | Max 500 characters; reason for the status change |

**Response 200**
```json
{
  "success": true,
  "data": {
    "is_active": false
  }
}
```

---

### GET /api/school/staff/export

Export the staff list as a CSV file. Accepts the same filter parameters as `GET /api/school/staff` but with no pagination — all matching records are exported.

**Query Parameters:** Same as `GET /api/school/staff` (except `page` and `limit` are ignored).

**Response 200**

Content-Type: `text/csv`
Content-Disposition: `attachment; filename="staff_export.csv"`

The CSV includes: Employee No, Full Name, Designation, Department, Email, Phone, Join Date, Status.

---

### POST /api/school/staff/:id/create-login

Create a portal login account for a staff member who was added without one.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| password | string | Yes | 8–128 characters |

**Response 201**
```json
{
  "success": true,
  "message": "Login account created successfully"
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 409 | Staff member already has a linked login account |

---

### POST /api/school/staff/:id/reset-password

Reset a staff member's portal login password.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| newPassword | string | Yes | 8–128 characters |

**Response 200**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

## Qualifications

### GET /api/school/staff/:id/qualifications

Retrieve all academic and professional qualifications for a staff member.

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "id": "q1a2b3c4-...",
      "staff_id": "d4e8f012-...",
      "degree": "M.Sc Physics",
      "institution": "Delhi University",
      "board_or_university": null,
      "year_of_passing": 2010,
      "grade_or_percentage": "First Class",
      "is_highest": true,
      "created_at": "2024-04-02T00:00:00Z",
      "updated_at": "2024-04-02T00:00:00Z"
    },
    {
      "id": "q2b3c4d5-...",
      "staff_id": "d4e8f012-...",
      "degree": "B.Ed",
      "institution": "Jamia Millia Islamia",
      "board_or_university": null,
      "year_of_passing": 2012,
      "grade_or_percentage": "65%",
      "is_highest": false,
      "created_at": "2024-04-02T00:00:00Z",
      "updated_at": "2024-04-02T00:00:00Z"
    }
  ]
}
```

---

### POST /api/school/staff/:id/qualifications

Add a qualification to a staff member's profile.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| degree | string | Yes | Max 100 characters (e.g., `"B.Ed"`, `"M.Sc Physics"`) |
| institution | string | Yes | Max 255 characters |
| boardOrUniversity | string | No | Max 255 characters |
| yearOfPassing | integer | No | 1950–2100 |
| gradeOrPercentage | string | No | Max 20 characters (e.g., `"First Class"`, `"78.5%"`) |
| isHighest | boolean | No | Default `false`. If `true`, any previous qualification marked as highest is automatically unset. |

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": "q3c4d5e6-...",
    "staff_id": "d4e8f012-...",
    "degree": "B.Ed",
    "institution": "Jamia Millia Islamia",
    "board_or_university": null,
    "year_of_passing": 2012,
    "grade_or_percentage": "65%",
    "is_highest": false,
    "created_at": "2026-03-15T10:00:00Z",
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

---

### PUT /api/school/staff/:staffId/qualifications/:qualId

Update a specific qualification. All fields are optional; at least one must be provided.

**Request Body:** Same fields as POST, all optional.

**Response 200**
```json
{
  "success": true,
  "data": { "...updated qualification object..." }
}
```

---

### DELETE /api/school/staff/:staffId/qualifications/:qualId

Permanently delete a qualification. This is a hard delete — qualifications are not soft-deleted.

**Response 200**
```json
{
  "success": true
}
```

---

## Documents

### GET /api/school/staff/:id/documents

List all non-deleted documents for a staff member. Returns document metadata only — file content is accessed via the `file_url`.

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "id": "doc1a2b3-...",
      "staff_id": "d4e8f012-...",
      "document_type": "AADHAAR",
      "document_name": "Aadhaar Card",
      "file_url": "https://storage.vidyron.in/docs/aadhaar_ravi.pdf",
      "file_size_kb": 340,
      "mime_type": "application/pdf",
      "uploaded_by": "u9f8e7d6-...",
      "verified": true,
      "verified_at": "2024-04-05T11:00:00Z",
      "verified_by": "admin-user-uuid",
      "created_at": "2024-04-02T09:00:00Z"
    }
  ]
}
```

---

### POST /api/school/staff/:id/documents

Record a document for a staff member. The actual file is uploaded directly to cloud storage; this endpoint stores only the metadata and URL.

If a non-deleted document of the same `documentType` already exists (except for type `OTHER`), the existing document is automatically soft-deleted before saving the new one.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| documentType | string | Yes | `AADHAAR`, `PAN`, `DEGREE`, `EXPERIENCE`, `ADDRESS_PROOF`, `PHOTO`, or `OTHER` |
| documentName | string | Yes | Max 255 characters (display label, e.g., `"Aadhaar Card"`) |
| fileUrl | string (HTTPS URL) | Yes | Must be a valid URI |
| fileSizeKb | integer | No | File size in kilobytes |
| mimeType | string | No | Max 100 characters (e.g., `"application/pdf"`) |

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": "doc2b3c4-...",
    "document_type": "PAN",
    "document_name": "PAN Card",
    "file_url": "https://storage.vidyron.in/docs/pan_ravi.pdf",
    "file_size_kb": 180,
    "mime_type": "application/pdf",
    "verified": false,
    "created_at": "2026-03-15T10:30:00Z"
  }
}
```

---

### PUT /api/school/staff/:staffId/documents/:docId/verify

Mark a document as verified. Only users with the SCHOOL_ADMIN role can call this endpoint.

**Request Body:** Empty — no body required.

**Response 200**
```json
{
  "success": true,
  "data": {
    "verified": true,
    "verified_at": "2026-03-15T11:00:00Z",
    "verified_by": "admin-user-uuid"
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 403 | Caller does not have SCHOOL_ADMIN role |
| 404 | Document not found or already soft-deleted |

---

### DELETE /api/school/staff/:staffId/documents/:docId

Soft-delete a document by setting `deleted_at`. The file itself remains in cloud storage.

**Response 200**
```json
{
  "success": true
}
```

---

## Subject Assignments

### GET /api/school/staff/:id/subject-assignments

Retrieve all subject assignments for a staff member, optionally filtered by academic year.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| academicYear | string | No | Current year | Format `"YYYY-YY"` (e.g., `"2025-26"`) |

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "id": "sa1b2c3-...",
      "staff_id": "d4e8f012-...",
      "class_id": "cl1a2b3-...",
      "class_name": "Class 9",
      "section_id": "sec1a2b-...",
      "section_name": "A",
      "subject": "Physics",
      "academic_year": "2025-26",
      "is_active": true,
      "created_at": "2025-04-01T00:00:00Z"
    }
  ]
}
```

---

### POST /api/school/staff/:id/subject-assignments

Assign a teacher to teach a subject in a class-section for an academic year.

The system enforces uniqueness: if another active teacher is already assigned to the same subject, class, section, and academic year combination, the request is rejected with HTTP 409.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| classId | UUID | Yes | Must belong to the same school |
| sectionId | UUID | No | Null means "all sections of the class" |
| subject | string | Yes | Max 100 characters |
| academicYear | string | Yes | Pattern `YYYY-YY` (e.g., `"2025-26"`) |

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": "sa2c3d4-...",
    "class_id": "cl1a2b3-...",
    "class_name": "Class 9",
    "section_id": "sec1a2b-...",
    "section_name": "A",
    "subject": "Physics",
    "academic_year": "2025-26",
    "is_active": true
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 409 | Another active teacher is already assigned this subject/class/section/year combination |
| 422 | Invalid academic year format or missing required fields |

---

### DELETE /api/school/staff/:staffId/subject-assignments/:assignId

Remove a subject assignment. This is a hard delete.

**Response 200**
```json
{
  "success": true
}
```

---

## Timetable

### GET /api/school/staff/:id/timetable

Read-only view of a teacher's weekly schedule. Data is pulled from the `timetables` table filtered by `staff_id`. This endpoint does not allow editing — use the Timetable module for that.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| weekOffset | integer | No | Reserved for future use. Ignored currently; the full static schedule is always returned. |

**Response 200**
```json
{
  "success": true,
  "data": {
    "staff_id": "d4e8f012-...",
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
          },
          {
            "period_no": 3,
            "subject": "Physics",
            "class_name": "Class 10",
            "section_name": "B",
            "start_time": "09:30",
            "end_time": "10:15",
            "room": "Room-5"
          }
        ]
      },
      {
        "day_of_week": 2,
        "day_name": "Tuesday",
        "periods": []
      }
    ]
  }
}
```

Days with no scheduled periods are returned with an empty `periods` array.

---

## Leave Management — School-Wide

### GET /api/school/staff/leaves

Retrieve all leave requests for the school. Used by the Leave Management screen. Supports rich filtering.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number |
| limit | integer | No | 20 | Records per page |
| status | string | No | — | `PENDING`, `APPROVED`, `REJECTED`, or `CANCELLED` |
| staffId | UUID | No | — | Filter to a specific staff member |
| leaveType | string | No | — | `CASUAL`, `SICK`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, `OTHER` |
| fromDate | string (ISO date) | No | — | Return leaves starting on or after this date |
| toDate | string (ISO date) | No | — | Return leaves starting on or before this date |
| academicYear | string | No | Current year | Format `"YYYY-YY"` |

**Response 200**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "lv1a2b3c-...",
        "staff_id": "d4e8f012-...",
        "staff_name": "Ravi Sharma",
        "employee_no": "EMP001",
        "leave_type": "CASUAL",
        "from_date": "2026-03-20",
        "to_date": "2026-03-21",
        "total_days": 2,
        "reason": "Personal work",
        "status": "PENDING",
        "applied_by": "u9f8e7d6-...",
        "reviewed_by": null,
        "reviewed_at": null,
        "admin_remark": null,
        "created_at": "2026-03-15T09:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "total_pages": 1
    }
  }
}
```

---

### GET /api/school/staff/leaves/summary

Aggregated leave statistics for the school or for a specific staff member within an academic year. Used by the Summary tab on the Leave Management screen.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| academicYear | string | No | Current year | Format `"YYYY-YY"` |
| staffId | UUID | No | — | Scope summary to a single staff member; omit for all staff |

**Response 200**
```json
{
  "success": true,
  "data": {
    "academic_year": "2025-26",
    "total": 48,
    "pending": 5,
    "approved": 35,
    "rejected": 8,
    "cancelled": 0,
    "byType": {
      "CASUAL": 20,
      "SICK": 10,
      "EARNED": 5,
      "MATERNITY": 0,
      "PATERNITY": 0,
      "UNPAID": 3,
      "OTHER": 10
    }
  }
}
```

---

### PUT /api/school/staff/leaves/:leaveId/review

Approve or reject a leave request. Only callable by SCHOOL_ADMIN.

The leave must currently be in `PENDING` status. Approved or rejected leaves cannot be revised; create a new leave record if a correction is required.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| leaveId | UUID | Yes | Leave request ID |

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| status | string | Yes | `APPROVED` or `REJECTED` |
| adminRemark | string | Conditional | Required when `status` is `REJECTED`; optional for `APPROVED`; max — no explicit limit |

**Response 200**
```json
{
  "success": true,
  "data": {
    "id": "lv1a2b3c-...",
    "status": "APPROVED",
    "reviewed_by": "admin-user-uuid",
    "reviewed_at": "2026-03-15T12:00:00Z",
    "admin_remark": "Approved. Arrange substitute."
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | Leave is not in PENDING status |
| 403 | Caller does not have SCHOOL_ADMIN role |
| 422 | `adminRemark` missing when status is `REJECTED` |
| 404 | Leave not found or belongs to different school |

---

### PUT /api/school/staff/leaves/:leaveId/cancel

Cancel a leave request. Only PENDING leaves can be cancelled. The cancellation can be performed by the staff member (via their user account) or by a school admin.

**Request Body:** Empty — no body required.

**Response 200**
```json
{
  "success": true,
  "data": {
    "id": "lv1a2b3c-...",
    "status": "CANCELLED"
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | Leave is not in PENDING status |
| 403 | Caller is neither the applying staff member nor a school admin |

---

## Leave Management — Per Staff Member

### GET /api/school/staff/:id/leaves

Retrieve leave requests for a specific staff member.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | |
| limit | integer | No | 20 | |
| status | string | No | — | Filter by status |
| academicYear | string | No | Current year | |

**Response 200**
```json
{
  "success": true,
  "data": {
    "data": [ "...leave objects..." ],
    "pagination": { "page": 1, "limit": 20, "total": 8, "total_pages": 1 }
  }
}
```

---

### POST /api/school/staff/:id/leaves

Submit a leave request for a staff member. When called by a school admin, the `from_date` restriction (no backdating) does not apply. For teacher self-service (future portal), `from_date` must be today or a future date.

**Request Body**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| leaveType | string | Yes | `CASUAL`, `SICK`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, or `OTHER` |
| fromDate | string (ISO date) | Yes | Must be today or future (at application time) |
| toDate | string (ISO date) | Yes | Must be equal to or after `fromDate` |
| reason | string | Yes | 10–1000 characters |

`total_days` is calculated server-side as the inclusive calendar day count between `fromDate` and `toDate`.

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": "lv2b3c4d-...",
    "staff_id": "d4e8f012-...",
    "leave_type": "CASUAL",
    "from_date": "2026-03-20",
    "to_date": "2026-03-21",
    "total_days": 2,
    "reason": "Personal work",
    "status": "PENDING",
    "created_at": "2026-03-15T09:00:00Z"
  },
  "message": "Leave request submitted"
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | `fromDate` is in the past (for non-admin callers) |
| 409 | An overlapping PENDING or APPROVED leave already exists for this staff member |
| 422 | Validation failure |
