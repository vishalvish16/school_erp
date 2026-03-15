# Non-Teaching Staff — API Reference

Version: 1.0
Base path: `/api/school/non-teaching`

---

## Authentication

Every endpoint under `/api/school/non-teaching/` requires two middleware layers:

1. `verifyAccessToken` — validates the JWT in the `Authorization` header and populates `req.user`.
2. `requireSchoolAdmin` — asserts the user belongs to the school portal and sets `req.user.school_id` from the JWT. No client-supplied `school_id` is ever trusted.

```
Authorization: Bearer <access_token>
```

Unauthorized requests receive:

```json
{ "success": false, "error": "Unauthorized" }
```

---

## Standard Response Envelope

All responses follow this shape:

```json
{
  "success": true,
  "message": "Human-readable status",
  "data": { ... }
}
```

Error responses:

```json
{
  "success": false,
  "error": "Error description"
}
```

Validation errors (HTTP 422) include a `details` array of individual field messages.

---

## Rate Limits

| Limiter | Applies To | Limit |
|---------|-----------|-------|
| `passwordOpLimiter` | `POST /staff/:id/create-login`, `POST /staff/:id/reset-password` | 10 requests / 15 min / IP |
| `bulkAttendanceLimiter` | `POST /attendance/bulk` | 60 requests / 15 min / IP |

All other endpoints are subject to the global application rate limiter only.

---

## Roles API

### List Roles

`GET /api/school/non-teaching/roles`

Returns all roles visible to the calling school — both the platform's built-in system roles (where `school_id` is null) and any custom roles created by this school.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `includeInactive` | boolean | No | `false` | When `true`, inactive custom roles are included in the response. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "uuid",
      "school_id": null,
      "code": "LIBRARIAN",
      "display_name": "Librarian",
      "category": "LIBRARY",
      "is_system": true,
      "description": "Manages library books and issue/return",
      "is_active": true,
      "staff_count": 2,
      "created_at": "2026-01-01T00:00:00.000Z",
      "updated_at": "2026-01-01T00:00:00.000Z"
    },
    {
      "id": "uuid",
      "school_id": "school-uuid",
      "code": "HEAD_CLERK",
      "display_name": "Head Clerk",
      "category": "ADMIN_SUPPORT",
      "is_system": false,
      "description": null,
      "is_active": true,
      "staff_count": 1,
      "created_at": "2026-03-10T10:00:00.000Z",
      "updated_at": "2026-03-10T10:00:00.000Z"
    }
  ]
}
```

Roles are ordered: custom roles before system roles, then by `category`, then alphabetically by `display_name`.

---

### Create Role

`POST /api/school/non-teaching/roles`

Creates a school-specific custom role. System roles (`is_system: true`) are seeded by the platform and cannot be created through this endpoint.

**Request Body**

```json
{
  "code": "HEAD_CLERK",
  "display_name": "Head Clerk",
  "category": "ADMIN_SUPPORT",
  "description": "Manages office filing and correspondence"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `code` | string | Yes | Uppercase letters and underscores only (`^[A-Z_]+$`), max 50 chars. Must be unique within the school and must not conflict with any system role code. |
| `display_name` | string | Yes | 2–100 chars. |
| `category` | string | Yes | One of: `FINANCE`, `LIBRARY`, `LABORATORY`, `ADMIN_SUPPORT`, `GENERAL`. |
| `description` | string | No | Max 500 chars. Accepts empty string or null. |

**Response 201 Created**

```json
{
  "success": true,
  "message": "Role created",
  "data": {
    "id": "new-uuid",
    "school_id": "school-uuid",
    "code": "HEAD_CLERK",
    "display_name": "Head Clerk",
    "category": "ADMIN_SUPPORT",
    "is_system": false,
    "description": "Manages office filing and correspondence",
    "is_active": true,
    "created_at": "2026-03-15T10:00:00.000Z",
    "updated_at": "2026-03-15T10:00:00.000Z"
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 409 | A role with this `code` already exists in the school, or `code` conflicts with a platform system role. |
| 422 | Validation error — missing required fields, invalid `category`, invalid `code` format. |

---

### Update Role

`PUT /api/school/non-teaching/roles/:roleId`

Updates the `display_name` and/or `description` of a school-created custom role. The `code` and `category` fields are immutable after creation. System roles cannot be updated.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `roleId` | UUID of the role to update. Must belong to the calling school. |

**Request Body** (at least one field required)

```json
{
  "display_name": "Senior Head Clerk",
  "description": "Updated description"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `display_name` | string | No | 2–100 chars. |
| `description` | string | No | Max 500 chars. Accepts empty string or null. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Role updated",
  "data": { ...role object... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 403 | Role is a system role — cannot be modified. |
| 404 | Role not found or does not belong to this school. |
| 422 | Validation error or empty request body. |

---

### Toggle Role Active Status

`PATCH /api/school/non-teaching/roles/:roleId/toggle`

Flips the `is_active` flag of a custom role. Inactive roles are hidden from dropdowns by default but still visible with `includeInactive=true`. System roles cannot be toggled.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `roleId` | UUID of the role to toggle. |

**Request Body** — none required.

**Response 200 OK**

```json
{
  "success": true,
  "message": "Role toggled",
  "data": {
    "id": "uuid",
    "is_active": false,
    ...
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 403 | Role is a system role. |
| 404 | Role not found. |

---

### Delete Role

`DELETE /api/school/non-teaching/roles/:roleId`

Permanently deletes a custom role. The role must have zero staff currently assigned to it. System roles cannot be deleted.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `roleId` | UUID of the role to delete. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Role deleted",
  "data": null
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 403 | Role is a system role. |
| 404 | Role not found. |
| 409 | Role still has active staff assigned. The error message includes the staff count, for example: `Cannot delete role with 3 active staff assigned. Reassign them first.` |

---

## Staff API

### List Staff

`GET /api/school/non-teaching/staff`

Returns a paginated list of non-teaching staff members belonging to the calling school.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Page number (1-based). |
| `limit` | integer | No | `20` | Items per page. Capped at 100 server-side. |
| `search` | string | No | — | Case-insensitive search across `first_name`, `last_name`, `email`, `employee_no`, `phone`. |
| `roleId` | UUID | No | — | Filter by exact role ID. |
| `category` | string | No | — | Filter by role category: `FINANCE`, `LIBRARY`, `LABORATORY`, `ADMIN_SUPPORT`, `GENERAL`. |
| `department` | string | No | — | Case-insensitive partial match on `department`. |
| `employeeType` | string | No | — | Filter by: `PERMANENT`, `CONTRACT`, `PART_TIME`, `DAILY_WAGE`. |
| `isActive` | boolean | No | — | Filter by active status. |
| `sortBy` | string | No | `firstName` | Sort field. Allowed values: `firstName`, `lastName`, `employeeNo`, `joinDate`, `createdAt`, `department`. Any other value falls back to `firstName`. |
| `sortOrder` | string | No | `asc` | `asc` or `desc`. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "data": [
      {
        "id": "uuid",
        "school_id": "school-uuid",
        "user_id": null,
        "has_login": false,
        "employee_no": "NTS-2026-001",
        "first_name": "Rajesh",
        "last_name": "Kumar",
        "full_name": "Rajesh Kumar",
        "gender": "MALE",
        "date_of_birth": "1985-06-15T00:00:00.000Z",
        "phone": "9876543210",
        "email": "rajesh.kumar@schoolname.in",
        "department": "Administration",
        "designation": "Senior Clerk",
        "qualification": "B.Com",
        "join_date": "2020-04-01T00:00:00.000Z",
        "employee_type": "PERMANENT",
        "salary_grade": "Grade-B",
        "address": "123 Main Street",
        "city": "Bengaluru",
        "state": "Karnataka",
        "blood_group": "O+",
        "emergency_contact_name": "Sunita Kumar",
        "emergency_contact_phone": "9876543211",
        "photo_url": null,
        "is_active": true,
        "created_at": "2026-03-01T00:00:00.000Z",
        "updated_at": "2026-03-01T00:00:00.000Z",
        "role": {
          "id": "role-uuid",
          "school_id": null,
          "code": "OFFICE_CLERK",
          "display_name": "Office Clerk",
          "category": "ADMIN_SUPPORT",
          "is_system": true,
          "description": null,
          "is_active": true,
          "created_at": "2026-01-01T00:00:00.000Z",
          "updated_at": "2026-01-01T00:00:00.000Z"
        },
        "user": null
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

The `user` field is non-null only for staff who have a portal login. The `has_login` boolean is a convenience field derived from whether `user_id` is non-null.

---

### Suggest Employee Number

`GET /api/school/non-teaching/staff/suggest-employee-no`

Returns a system-generated employee number suggestion based on the current year and the count of non-teaching staff created in that year. The format is `NTS-{YYYY}-{NNN}` (zero-padded three digits).

This is a suggestion only. The caller may override it when creating a staff member.

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "employee_no": "NTS-2026-007"
  }
}
```

---

### Export Staff

`GET /api/school/non-teaching/staff/export`

CSV export endpoint. Currently returns HTTP 501 (Not Implemented) as a placeholder.

**Response 501 Not Implemented**

```json
{
  "success": true,
  "message": "Export coming soon",
  "data": {}
}
```

---

### Create Staff

`POST /api/school/non-teaching/staff`

Creates a new non-teaching staff record. This creates the HR profile only; it does not create a login account. To enable portal login, use `POST /staff/:id/create-login` afterwards.

**Request Body**

```json
{
  "role_id": "uuid",
  "employee_no": "NTS-2026-007",
  "first_name": "Meena",
  "last_name": "Sharma",
  "gender": "FEMALE",
  "date_of_birth": "1990-03-20",
  "phone": "9876543220",
  "email": "meena.sharma@school.in",
  "department": "Library",
  "designation": "Assistant Librarian",
  "qualification": "B.Lib",
  "join_date": "2026-04-01",
  "employee_type": "PERMANENT",
  "salary_grade": "Grade-C",
  "address": "45 Cross Road",
  "city": "Mumbai",
  "state": "Maharashtra",
  "blood_group": "A+",
  "emergency_contact_name": "Ravi Sharma",
  "emergency_contact_phone": "9876543221"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `role_id` | UUID | Yes | Must be a valid role ID visible to this school. |
| `employee_no` | string | No | Max 50 chars. If omitted, auto-generated as `NTS-{YYYY}-{NNN}`. Must be unique within the school. |
| `first_name` | string | Yes | 1–100 chars. |
| `last_name` | string | Yes | 1–100 chars. |
| `gender` | string | Yes | One of: `MALE`, `FEMALE`, `OTHER`. |
| `date_of_birth` | string | No | ISO 8601 date format `YYYY-MM-DD`. |
| `phone` | string | No | Max 20 chars. |
| `email` | string | Yes | Valid email format, max 255 chars. Must be unique within the school. |
| `department` | string | No | Max 100 chars. |
| `designation` | string | No | Max 100 chars. |
| `qualification` | string | No | Max 255 chars. Brief summary; detailed qualifications use the qualifications sub-resource. |
| `join_date` | string | Yes | ISO 8601 date `YYYY-MM-DD`. |
| `employee_type` | string | No | One of: `PERMANENT`, `CONTRACT`, `PART_TIME`, `DAILY_WAGE`. Default: `PERMANENT`. |
| `salary_grade` | string | No | Max 50 chars. |
| `address` | string | No | Free text. |
| `city` | string | No | Max 100 chars. |
| `state` | string | No | Max 100 chars. |
| `blood_group` | string | No | Max 5 chars (e.g., `O+`, `AB-`). |
| `emergency_contact_name` | string | No | Max 100 chars. |
| `emergency_contact_phone` | string | No | Max 20 chars. |

**Response 201 Created**

```json
{
  "success": true,
  "message": "Staff member created",
  "data": { ...full staff object... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | `role_id` does not exist or does not belong to this school. |
| 409 | `email` or `employee_no` already exists within this school. |
| 422 | Validation error — missing required fields or invalid values. |

---

### Get Staff by ID

`GET /api/school/non-teaching/staff/:id`

Returns the full profile of a single non-teaching staff member, including their role and portal user account (if any).

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "uuid",
    ...full staff fields...,
    "role": { ...role object... },
    "user": {
      "id": "user-uuid",
      "is_active": true,
      "email": "meena.sharma@school.in",
      "last_login": "2026-03-14T09:00:00.000Z"
    }
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 404 | Staff member not found or soft-deleted. |

---

### Update Staff

`PUT /api/school/non-teaching/staff/:id`

Updates any combination of fields on a staff member's profile. All fields are optional in the update schema. Only fields present in the request body are updated (partial update semantics).

If `email` is changed, uniqueness is re-validated within the school.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Request Body** — same fields as Create Staff, all optional.

**Response 200 OK**

```json
{
  "success": true,
  "message": "Staff member updated",
  "data": { ...updated staff object... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 404 | Staff member not found. |
| 409 | New `email` already used by another staff in this school. |
| 422 | Validation error. |

---

### Delete Staff (Soft Delete)

`DELETE /api/school/non-teaching/staff/:id`

Soft-deletes a staff member by setting `deleted_at` to the current timestamp and `is_active` to `false`. The record is not removed from the database. Soft-deleted staff are excluded from all list and lookup queries.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Staff member deleted",
  "data": null
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 404 | Staff member not found or already deleted. |

---

### Update Staff Active Status

`PATCH /api/school/non-teaching/staff/:id/status`

Activates or deactivates a staff member without deleting them.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Request Body**

```json
{ "is_active": false }
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `is_active` | boolean | Yes | |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Staff status updated",
  "data": { ...staff object with updated is_active... }
}
```

---

### Create Staff Portal Login

`POST /api/school/non-teaching/staff/:id/create-login`

Creates a `users` record linked to this staff member, allowing them to log into the staff portal. This endpoint is rate-limited to 10 calls per 15 minutes per IP.

The staff member's `email` is used as the login email. A user account for that email must not already exist in the system.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Request Body**

```json
{ "password": "SecureP@ss1" }
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `password` | string | Yes | Minimum 8 characters after whitespace trimming, max 100 chars. |

**Response 201 Created**

```json
{
  "success": true,
  "message": "Portal login created successfully",
  "data": {
    "message": "Portal login created successfully",
    "user_id": "new-user-uuid"
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | Staff member has no portal login to reset (for reset endpoint) or system role not found. |
| 404 | Staff member not found. |
| 409 | Portal login already exists for this staff member, or a user account with this email already exists. |
| 422 | Password too short. |
| 429 | Rate limit exceeded. |

---

### Reset Staff Password

`POST /api/school/non-teaching/staff/:id/reset-password`

Resets the portal login password for a staff member who already has a login. The password is hashed with bcrypt (12 rounds). This endpoint is rate-limited to 10 calls per 15 minutes per IP.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Request Body**

```json
{ "new_password": "NewSecureP@ss2" }
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `new_password` | string | Yes | Minimum 8 characters after whitespace trimming, max 100 chars. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Password reset successfully",
  "data": { "message": "Password reset successfully" }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | No portal login exists for this staff member. |
| 404 | Staff member not found. |
| 429 | Rate limit exceeded. |

---

## Qualifications API

Qualifications are detailed educational records attached to a staff member. They are separate from the brief `qualification` text field on the main staff profile.

### List Qualifications

`GET /api/school/non-teaching/staff/:id/qualifications`

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "uuid",
      "school_id": "school-uuid",
      "staff_id": "staff-uuid",
      "degree": "B.Com",
      "institution": "Mysore University",
      "board_or_university": "University of Mysore",
      "year_of_passing": 2010,
      "grade_or_percentage": "72%",
      "is_highest": false,
      "created_at": "2026-03-01T00:00:00.000Z",
      "updated_at": "2026-03-01T00:00:00.000Z"
    }
  ]
}
```

---

### Add Qualification

`POST /api/school/non-teaching/staff/:id/qualifications`

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Request Body**

```json
{
  "degree": "M.Com",
  "institution": "Delhi University",
  "board_or_university": "University of Delhi",
  "year_of_passing": 2012,
  "grade_or_percentage": "68%",
  "is_highest": true
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `degree` | string | Yes | Max 100 chars. |
| `institution` | string | Yes | Max 255 chars. |
| `board_or_university` | string | No | Max 255 chars. |
| `year_of_passing` | integer | No | Between 1950 and the current year. |
| `grade_or_percentage` | string | No | Max 20 chars. |
| `is_highest` | boolean | No | Default `false`. When `true`, all previous qualifications for this staff member have their `is_highest` flag unset before the new one is saved. |

**Response 201 Created**

```json
{
  "success": true,
  "message": "Qualification added",
  "data": { ...qualification object... }
}
```

---

### Update Qualification

`PUT /api/school/non-teaching/staff/:id/qualifications/:qualId`

Updates an existing qualification record. All fields are optional.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |
| `qualId` | UUID of the qualification record. |

**Request Body** — same fields as Add Qualification, all optional.

**Response 200 OK**

```json
{
  "success": true,
  "message": "Qualification updated",
  "data": { ...updated qualification object... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 404 | Staff member or qualification not found, or qualification does not belong to this staff/school. |

---

### Delete Qualification

`DELETE /api/school/non-teaching/staff/:id/qualifications/:qualId`

Permanently deletes a qualification record.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |
| `qualId` | UUID of the qualification to delete. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Qualification deleted",
  "data": null
}
```

---

## Documents API

Documents are file attachments (Aadhaar, PAN, degree certificates, etc.) linked to a staff member. File content is stored externally (S3/GCS); only the metadata and URL are stored in the database.

### List Documents

`GET /api/school/non-teaching/staff/:id/documents`

Returns all non-deleted documents for a staff member, ordered newest-first.

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "uuid",
      "school_id": "school-uuid",
      "staff_id": "staff-uuid",
      "uploaded_by": "user-uuid",
      "verified_by": null,
      "document_type": "AADHAAR",
      "document_name": "Aadhaar Card - Meena Sharma",
      "file_url": "https://vidyron-storage.s3.ap-south-1.amazonaws.com/docs/aadhaar-meena.pdf",
      "file_size_kb": 512,
      "mime_type": "application/pdf",
      "verified": false,
      "verified_at": null,
      "created_at": "2026-03-01T00:00:00.000Z"
    }
  ]
}
```

---

### Add Document

`POST /api/school/non-teaching/staff/:id/documents`

Attaches a document record to the staff member. The file must already be uploaded to an approved storage domain before calling this endpoint.

**Request Body**

```json
{
  "document_type": "AADHAAR",
  "document_name": "Aadhaar Card - Meena Sharma",
  "file_url": "https://vidyron-storage.s3.ap-south-1.amazonaws.com/docs/aadhaar-meena.pdf",
  "file_size_kb": 512,
  "mime_type": "application/pdf"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `document_type` | string | Yes | One of: `AADHAAR`, `PAN`, `DEGREE`, `EXPERIENCE`, `ADDRESS_PROOF`, `PHOTO`, `APPOINTMENT_LETTER`, `OTHER`. |
| `document_name` | string | Yes | Max 255 chars. |
| `file_url` | string | Yes | Must be HTTPS. Must point to an approved storage domain: `storage.googleapis.com`, `s3.amazonaws.com`, `vidyron-storage.s3.ap-south-1.amazonaws.com`, or `vidyron.in` (and their subdomains). Max 2048 chars. This restriction prevents SSRF via redirected URLs. |
| `file_size_kb` | integer | No | 1–5120 (max 5 MB). |
| `mime_type` | string | No | Max 100 chars. |

**Response 201 Created**

```json
{
  "success": true,
  "message": "Document added",
  "data": { ...document object... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 422 | `file_url` scheme is not HTTPS, or host is not an approved storage domain. |

---

### Verify Document

`PUT /api/school/non-teaching/staff/:id/documents/:docId/verify`

Marks a document as verified by the current admin. Sets `verified: true`, `verified_by`, and `verified_at`.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |
| `docId` | UUID of the document. |

**Request Body** — none required.

**Response 200 OK**

```json
{
  "success": true,
  "message": "Document verified",
  "data": {
    "id": "uuid",
    "verified": true,
    "verified_by": "admin-user-uuid",
    "verified_at": "2026-03-15T11:00:00.000Z",
    ...
  }
}
```

---

### Delete Document

`DELETE /api/school/non-teaching/staff/:id/documents/:docId`

Soft-deletes a document by setting `deleted_at`. The file in external storage is not removed by this call.

**Response 200 OK**

```json
{
  "success": true,
  "message": "Document deleted",
  "data": null
}
```

---

## Attendance API

Non-teaching staff attendance uses a check-in/check-out model, distinct from the teacher period-wise attendance model. One record per staff member per calendar day.

### Get Attendance for a Date

`GET /api/school/non-teaching/attendance`

Returns the full list of active staff for the date, each paired with their attendance record if it has been marked. Staff without a record on that date have `attendance: null`.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | string | Yes | ISO date `YYYY-MM-DD`. |
| `department` | string | No | Case-insensitive partial filter on staff department. |
| `category` | string | No | Filter staff by role category: `FINANCE`, `LIBRARY`, `LABORATORY`, `ADMIN_SUPPORT`, `GENERAL`. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "staff": { ...staff object... },
      "attendance": {
        "id": "uuid",
        "school_id": "school-uuid",
        "staff_id": "staff-uuid",
        "date": "2026-03-15T00:00:00.000Z",
        "status": "PRESENT",
        "check_in_time": "09:05",
        "check_out_time": "17:00",
        "marked_by": "admin-uuid",
        "remarks": null,
        "created_at": "2026-03-15T09:10:00.000Z",
        "updated_at": "2026-03-15T17:05:00.000Z"
      }
    },
    {
      "staff": { ...staff object... },
      "attendance": null
    }
  ]
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | `date` query parameter is missing. |

---

### Bulk Mark Attendance

`POST /api/school/non-teaching/attendance/bulk`

Creates or updates attendance records for multiple staff on a given date in a single transaction. Uses upsert semantics: if a record already exists for `staff_id + date`, it is updated; otherwise it is created. Rate-limited to 60 calls per 15 minutes per IP.

**Request Body**

```json
{
  "date": "2026-03-15",
  "records": [
    {
      "staff_id": "uuid-1",
      "status": "PRESENT",
      "check_in_time": "09:05",
      "check_out_time": "17:00",
      "remarks": null
    },
    {
      "staff_id": "uuid-2",
      "status": "ABSENT",
      "check_in_time": null,
      "check_out_time": null,
      "remarks": "Informed leave"
    },
    {
      "staff_id": "uuid-3",
      "status": "LATE",
      "check_in_time": "10:30",
      "check_out_time": "17:00",
      "remarks": null
    }
  ]
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `date` | string | Yes | ISO date `YYYY-MM-DD`. |
| `records` | array | Yes | 1–500 items. |
| `records[].staff_id` | UUID | Yes | Must belong to the calling school. All IDs are validated as a batch before any writes. |
| `records[].status` | string | Yes | One of: `PRESENT`, `ABSENT`, `HALF_DAY`, `ON_LEAVE`, `HOLIDAY`, `LATE`. |
| `records[].check_in_time` | string | No | `HH:MM` format (24-hour). |
| `records[].check_out_time` | string | No | `HH:MM` format (24-hour). |
| `records[].remarks` | string | No | Max 255 chars. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Attendance saved",
  "data": { "processed": 25 }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | One or more `staff_id` values do not belong to this school. |
| 422 | Validation error — missing `date`, empty `records`, invalid `status` value, invalid time format. |
| 429 | Rate limit exceeded. |

---

### Correct Attendance Record

`PUT /api/school/non-teaching/attendance/:id`

Corrects an existing attendance record identified by its own UUID (not the staff ID). Updates the `marked_by` field to the current admin performing the correction.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the attendance record to correct. |

**Request Body** (at least one field required)

```json
{
  "status": "HALF_DAY",
  "check_in_time": "09:05",
  "check_out_time": "13:00",
  "remarks": "Left early due to medical appointment"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `status` | string | No | One of: `PRESENT`, `ABSENT`, `HALF_DAY`, `ON_LEAVE`, `HOLIDAY`, `LATE`. |
| `check_in_time` | string | No | `HH:MM` format. |
| `check_out_time` | string | No | `HH:MM` format. |
| `remarks` | string | No | Max 255 chars. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Attendance corrected",
  "data": { ...updated attendance record... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 404 | Attendance record not found for this school. |
| 422 | Empty request body. |

---

### Get Attendance Report

`GET /api/school/non-teaching/attendance/report`

Returns a month-wise attendance summary aggregated across staff. Optionally filtered to a single staff member or department.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `month` | string | Yes | Format `YYYY-MM` (e.g., `2026-03`). |
| `staffId` | UUID | No | Restrict report to a single staff member. |
| `department` | string | No | Case-insensitive partial filter on department. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "month": "2026-03",
    "summary": {
      "present": 412,
      "absent": 38,
      "half_day": 12,
      "on_leave": 25,
      "late": 18,
      "holiday": 50
    },
    "by_staff": [
      {
        "staff_id": "uuid",
        "first_name": "Rajesh",
        "last_name": "Kumar",
        "employee_no": "NTS-2026-001",
        "role": { "id": "uuid", "display_name": "Office Clerk" },
        "present": 20,
        "absent": 2,
        "half_day": 1,
        "on_leave": 1,
        "late": 1,
        "holiday": 5
      }
    ]
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | `month` parameter is missing or not in `YYYY-MM` format. |

---

## Leaves API (School-Wide)

These endpoints manage leave requests across all non-teaching staff from the school admin's perspective.

### List Leaves

`GET /api/school/non-teaching/leaves`

Returns a paginated list of leave applications for the school.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | |
| `limit` | integer | No | `20` | Capped at 100. |
| `status` | string | No | — | One of: `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`. |
| `staffId` | UUID | No | — | Filter to a specific staff member. |
| `leaveType` | string | No | — | One of: `CASUAL`, `SICK`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, `COMPENSATORY`, `OTHER`. |
| `fromDate` | string | No | — | ISO date. Returns leaves where `from_date >= fromDate`. |
| `toDate` | string | No | — | ISO date. Returns leaves where `to_date <= toDate`. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "data": [
      {
        "id": "uuid",
        "school_id": "school-uuid",
        "staff_id": "staff-uuid",
        "applied_by": "admin-uuid",
        "reviewed_by": null,
        "leave_type": "SICK",
        "from_date": "2026-03-18T00:00:00.000Z",
        "to_date": "2026-03-19T00:00:00.000Z",
        "total_days": 2,
        "reason": "Fever and doctor's rest advised",
        "status": "PENDING",
        "reviewed_at": null,
        "admin_remark": null,
        "created_at": "2026-03-15T10:00:00.000Z",
        "updated_at": "2026-03-15T10:00:00.000Z",
        "staff": {
          "id": "staff-uuid",
          "first_name": "Meena",
          "last_name": "Sharma",
          "employee_no": "NTS-2026-007"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 8,
      "total_pages": 1
    }
  }
}
```

---

### Get Leave Summary

`GET /api/school/non-teaching/leaves/summary`

Returns the total number of leave days and leave applications grouped by leave type, optionally scoped to a specific staff member and academic year.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `staffId` | UUID | No | Restrict to one staff member. |
| `academicYear` | string | No | Format `YYYY-YYYY` (e.g., `2025-2026`). The academic year runs April 1 of the first year to March 31 of the second year. |

**Response 200 OK**

```json
{
  "success": true,
  "message": "OK",
  "data": [
    { "leave_type": "CASUAL",  "total_days": 6, "total_count": 3 },
    { "leave_type": "SICK",    "total_days": 4, "total_count": 2 },
    { "leave_type": "EARNED",  "total_days": 10, "total_count": 1 }
  ]
}
```

---

### Review Leave (Approve or Reject)

`PUT /api/school/non-teaching/leaves/:leaveId/review`

Approves or rejects a pending leave application. Only leaves with status `PENDING` can be reviewed. A rejection requires `admin_remark` to be provided.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `leaveId` | UUID of the leave application. |

**Request Body**

```json
{
  "status": "REJECTED",
  "admin_remark": "Insufficient leave balance for the requested period"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `status` | string | Yes | One of: `APPROVED`, `REJECTED`. |
| `admin_remark` | string | No | Max 500 chars. **Required when `status` is `REJECTED`.** |

**Response 200 OK**

```json
{
  "success": true,
  "message": "Leave reviewed",
  "data": {
    "id": "uuid",
    "status": "REJECTED",
    "reviewed_by": "admin-uuid",
    "reviewed_at": "2026-03-15T11:30:00.000Z",
    "admin_remark": "Insufficient leave balance for the requested period",
    ...
  }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | Leave is not in `PENDING` status, or `status` is `REJECTED` but `admin_remark` is empty. |
| 404 | Leave application not found. |
| 422 | `status` is not `APPROVED` or `REJECTED`. |

---

### Cancel Leave

`PUT /api/school/non-teaching/leaves/:leaveId/cancel`

Cancels a pending leave application. Only `PENDING` leaves can be cancelled; approved or rejected leaves cannot be cancelled through this endpoint.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `leaveId` | UUID of the leave application. |

**Request Body** — none required.

**Response 200 OK**

```json
{
  "success": true,
  "message": "Leave cancelled",
  "data": { "id": "uuid", "status": "CANCELLED", ... }
}
```

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | Leave is not in `PENDING` status. |
| 404 | Leave not found. |

---

## Per-Staff Leaves API

These endpoints manage leaves for a specific staff member.

### Get Leaves for Staff Member

`GET /api/school/non-teaching/staff/:id/leaves`

Returns a paginated list of leave applications for a specific staff member.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | |
| `limit` | integer | No | `20` | Capped at 100. |
| `status` | string | No | — | Filter by leave status. |
| `leaveType` | string | No | — | Filter by leave type. |
| `fromDate` | string | No | — | ISO date lower bound. |
| `toDate` | string | No | — | ISO date upper bound. |

**Response 200 OK** — same shape as school-wide list, without the nested `staff` object.

---

### Apply Leave for Staff Member

`POST /api/school/non-teaching/staff/:id/leaves`

Creates a leave application on behalf of a staff member. The `applied_by` field is set to the authenticated admin's user ID.

**Path Parameters**

| Parameter | Description |
|-----------|-------------|
| `id` | UUID of the staff member. |

**Request Body**

```json
{
  "leave_type": "SICK",
  "from_date": "2026-03-18",
  "to_date": "2026-03-19",
  "reason": "Fever and doctor's rest advised"
}
```

**Field Validation**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `leave_type` | string | Yes | One of: `CASUAL`, `SICK`, `EARNED`, `MATERNITY`, `PATERNITY`, `UNPAID`, `COMPENSATORY`, `OTHER`. |
| `from_date` | string | Yes | ISO date. Cannot be more than 7 calendar days in the past (backdating limit enforced at validation time). |
| `to_date` | string | Yes | ISO date. Must be on or after `from_date`. |
| `reason` | string | Yes | 5–1000 chars. |

**Response 201 Created**

```json
{
  "success": true,
  "message": "Leave applied",
  "data": { ...leave object with total_days calculated... }
}
```

The `total_days` field is calculated server-side as the inclusive day count from `from_date` to `to_date`.

**Error Responses**

| Status | Condition |
|--------|-----------|
| 400 | `from_date` is after `to_date`. |
| 404 | Staff member not found. |
| 409 | Staff already has an overlapping `PENDING` or `APPROVED` leave for this date range. |
| 422 | `from_date` is more than 7 days in the past; missing required fields; reason too short. |

---

## Staff Portal Self-Service API

These endpoints are used by non-teaching staff members after they log into the staff portal using their own credentials. They are served under `/api/staff/my/` and authenticated with the staff member's own JWT (not the school admin's token).

Note: The staff portal self-service routes are defined in a separate router registered at `/api/staff/`. The specification lists the following intended endpoints. Implementation status should be confirmed against the staff portal route file.

### Get Own Profile

`GET /api/staff/my/profile`

Returns the authenticated staff member's own profile.

**Auth:** Staff portal JWT

---

### Get Own Attendance

`GET /api/staff/my/attendance`

Returns the authenticated staff member's attendance records for a given month.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `month` | string | Yes | Format `YYYY-MM`. |

---

### List Own Leaves

`GET /api/staff/my/leaves`

Returns the authenticated staff member's leave applications.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | string | No | Filter by leave status. |

---

### Apply for Leave (Self)

`POST /api/staff/my/leaves`

Allows a staff member to apply for leave themselves. Same validation rules as the admin-facing endpoint, including the 7-day backdating limit.

---

### Cancel Own Leave

`PUT /api/staff/my/leaves/:leaveId/cancel`

Allows a staff member to cancel their own pending leave.

---

### Get Own Leave Summary

`GET /api/staff/my/leave-summary`

Returns the authenticated staff member's leave usage grouped by leave type.

---

### Get Own Payslip (Placeholder)

`GET /api/staff/my/payslip`

Placeholder endpoint. Returns a stub response until the Payroll module is implemented.
