# Parent Portal — Backend Prompt

**Purpose:** Build the Parent Portal API module with auth flow, parent guard, and all endpoints.  
**Target:** `backend/src/modules/parent/`  
**Date:** 2026-03-16

---

## 1. Reference Patterns

Follow these existing files exactly:

- **Module structure:** `backend/src/modules/staff/` — controller → service → repository + routes + validation
- **Staff guard:** `backend/src/middleware/staff-guard.middleware.js` — create analogous `parent-guard.middleware.js`
- **Response format:** `successResponse(res, statusCode, message, data)` from `backend/src/utils/response.js`
- **Errors:** `throw new AppError('message', statusCode)` — caught by errorHandler
- **Validation:** Zod schemas in `validation.js`, `validate(schema)` middleware
- **Auth routes:** `backend/src/modules/auth/auth.routes.js` — auth routes under `/api/platform/auth`

---

## 2. Auth Flow Changes

### 2.1 Extend resolve-user-by-phone (user_type: parent)

**File:** `backend/src/modules/auth/resolve-user-by-phone.repository.js` (or new `resolve-parent-by-phone.repository.js`)

**Logic when `user_type === 'parent'`:**

1. Normalize phone to E.164: `+91` + 10 digits (strip non-digits, take last 10).
2. If school_id provided (from step 2 of login), use it; else resolve school from results.
3. **Look up Parent first:** `Parent` where `schoolId` + normalized `phone`, `deletedAt: null`, `isActive: true`.
4. **If Parent found:** Return `{ school, user: { id: parent.id, name, school_id }, otp_session_id, masked_phone }`. Store OTP session (see 2.3).
5. **If Parent not found:** Look up `Student` where `schoolId` + `parentPhone` matches (normalize both). Take first matching student.
6. **If Student found:** Create `Parent` from `student.parentName`, `parentPhone`, `parentEmail`, `parentRelation`. Create `StudentParent` link with `isPrimary: true`. Return as in step 4.
7. **If neither found:** Return `null` (controller returns 404).

**Response shape (unchanged):**

```json
{
  "success": true,
  "message": "School found",
  "data": {
    "school": { "id", "name", "code", "city", "state", "board", "type", "logo_url", "is_active" },
    "user": { "id": "<parent_id>", "name": "Parent Name", "school_id": "<uuid>" },
    "otp_session_id": "<uuid>",
    "masked_phone": "****543210"
  }
}
```

**Controller:** `resolve-user-by-phone.controller.js` — when `user_type === 'parent'`, call the parent-specific resolve logic instead of User lookup.

### 2.2 New Endpoint: POST /auth/verify-parent-otp

**File:** `backend/src/modules/auth/` — add `verify-parent-otp.controller.js` and service logic.

**Path:** `POST /api/platform/auth/verify-parent-otp` (no auth required)

**Request body:**

```json
{
  "otp_session_id": "uuid",
  "otp": "123456",
  "phone": "+919876543210",
  "school_id": "uuid"
}
```

**Validation schema (auth.validation.js):**

```javascript
export const verifyParentOtpSchema = z.object({
  body: z.object({
    otp_session_id: z.string().uuid('Invalid OTP session'),
    otp: z.string().length(6, 'OTP must be 6 digits'),
    phone: z.string().min(10, 'Phone required'),
    school_id: z.string().uuid('School ID required')
  })
});
```

**Logic:**

1. Verify OTP session exists, not expired, not used, attempts < 3.
2. If OTP code matches, mark session used.
3. Fetch Parent by school_id + phone.
4. Issue JWT with `{ parent_id, school_id, portal_type: 'parent', email: parent.email || `parent_${parent.id}@vidyron.local` }` — **24h expiry** (use `expiresIn: '24h'` in jwt.sign).
5. Return:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "jwt...",
    "refresh_token": null,
    "portal_type": "parent",
    "parent": {
      "id": "uuid",
      "firstName": "string",
      "lastName": "string",
      "phone": "string",
      "email": "string|null"
    }
  }
}
```

### 2.3 Parent OTP Storage

**Option A (recommended for dev):** In-memory Map: `Map<otp_session_id, { parentId, schoolId, phone, otpCode, expiresAt, attempts }>`. Generate `otp_session_id` as UUID. Expire entries after 2 minutes. Max 3 attempts.

**Option B (production):** Add `parent_otp_sessions` table (see DATABASE_PROMPT for optional migration) or use existing `otp_verifications` with `parent_id` column if available.

**OTP creation:** When resolve-user-by-phone finds/creates Parent, generate 6-digit OTP, store session, send via `console.log` in dev (like smart-login). Return `otp_session_id` to client.

---

## 3. Parent Guard Middleware

**File:** `backend/src/middleware/parent-guard.middleware.js`

**Pattern:** Copy `staff-guard.middleware.js`, adapt for parent:

- Require `req.user.portal_type === 'parent'` (or `portalType === 'parent'`).
- Require `req.user.parent_id` (or `parentId`).
- Fetch `Parent` by id, ensure `schoolId` matches `req.user.school_id`, `isActive: true`, `deletedAt: null`.
- Attach `req.parent = parentRecord`.
- Set `req.user.school_id = parentRecord.schoolId` for consistency.
- On failure: `AppError('Parent portal access required', 403)` or `AppError('Parent account not found or inactive', 403)`.

---

## 4. Parent Module Structure

**Folder:** `backend/src/modules/parent/`

| File | Purpose |
|------|---------|
| `parent.controller.js` | HTTP handlers for all /api/parent/* routes |
| `parent.service.js` | Business logic |
| `parent.repository.js` | Prisma queries |
| `parent.routes.js` | Express router, mount at /api/parent |
| `parent.validation.js` | Zod schemas for PATCH profile |

---

## 5. Endpoints (All require verifyAccessToken + requireParent)

**Base path:** `/api/parent`  
**Auth:** Bearer JWT with `portal_type: 'parent'`, `parent_id`, `school_id`

### 5.0 Dashboard

| Method | Path | Handler | Request | Response |
|--------|------|---------|---------|----------|
| GET | `/dashboard` | getDashboard | — | Dashboard stats |

**Response shape:** `{ childrenCount: number, todaysAttendance: { present: number, absent: number, late: number }, recentNotices: NoticeSummary[], feeDues: number }`. Aggregate from children, today's attendance, notices, fees. Reduces frontend round-trips.

### 5.1 Profile

| Method | Path | Handler | Request | Response |
|--------|------|---------|---------|----------|
| GET | `/profile` | getProfile | — | ParentProfileResponse |
| PATCH | `/profile` | updateProfile | `{ firstName?, lastName?, email? }` | ParentProfileResponse |

**ParentProfileResponse:**

```json
{
  "id": "uuid",
  "firstName": "string",
  "lastName": "string",
  "phone": "string",
  "email": "string|null",
  "relation": "string|null",
  "schoolId": "uuid",
  "schoolName": "string"
}
```

### 5.2 Children

| Method | Path | Handler | Request | Response |
|--------|------|---------|---------|----------|
| GET | `/children` | getChildren | — | `{ children: ChildSummary[] }` |
| GET | `/children/:studentId` | getChildById | — | ChildDetailResponse or 404 |

**ChildSummary:**

```json
{
  "id": "uuid",
  "admissionNo": "string",
  "firstName": "string",
  "lastName": "string",
  "class": "string",
  "section": "string",
  "rollNo": 12,
  "photoUrl": "string|null"
}
```

**ChildDetailResponse:** ChildSummary + `{ dateOfBirth, bloodGroup, address, parentRelation }`

**Business rule:** Only return students linked via `StudentParent` where `parentId === req.parent.id`. 404 if studentId not in linked children.

### 5.3 Attendance

| Method | Path | Handler | Request | Response |
|--------|------|---------|---------|----------|
| GET | `/children/:studentId/attendance` | getChildAttendance | `?month=YYYY-MM&limit=31` | `{ attendances: AttendanceEntry[] }` |

**AttendanceEntry:**

```json
{
  "date": "YYYY-MM-DD",
  "status": "PRESENT|ABSENT|LATE|HOLIDAY",
  "remarks": "string|null"
}
```

**Business rule:** Verify child is linked to parent. Query `Attendance` for studentId + month. Default limit 31.

### 5.4 Fees

| Method | Path | Handler | Request | Response |
|--------|------|---------|---------|----------|
| GET | `/children/:studentId/fees` | getChildFees | `?academic_year=2024-25` | `{ feePayments, feeStructure }` |

**FeePaymentSummary:**

```json
{
  "id": "uuid",
  "feeHead": "string",
  "amount": "1000.00",
  "paymentDate": "YYYY-MM-DD",
  "receiptNo": "string",
  "paymentMode": "string"
}
```

**FeeStructureSummary:** `{ feeHead, amount, frequency }` from FeeStructure for student's class + academicYear.

**Business rule:** Verify child linked. Return feePayments for student + academicYear. Return feeStructure for student's class.

### 5.5 Notices

| Method | Path | Handler | Request | Response |
|--------|------|---------|---------|----------|
| GET | `/notices` | getNotices | `?page=1&limit=20` | `{ notices, pagination }` |
| GET | `/notices/:id` | getNoticeById | — | NoticeDetailResponse or 404 |

**NoticeSummary:**

```json
{
  "id": "uuid",
  "title": "string",
  "body": "string",
  "isPinned": false,
  "publishedAt": "ISO8601",
  "expiresAt": "ISO8601|null"
}
```

**Pagination:** `{ page, limit, total, total_pages }`

**Business rule:** Query `SchoolNotice` where `schoolId === req.parent.schoolId`, `deletedAt: null`, `targetRole` in `['parent', 'all', null]` or similar. Order by isPinned DESC, publishedAt DESC. Paginate.

---

## 6. Route Registration

**File:** `backend/src/app.js`

Add:

```javascript
import parentRoutes from './modules/parent/parent.routes.js';
// ...
app.use('/api/parent', parentRoutes);
```

**File:** `backend/src/modules/parent/parent.routes.js`

Structure (follow staff-portal.routes.js pattern):

```javascript
router.use(verifyAccessToken, requireParent);

router.get('/dashboard', ctrl.getDashboard);
router.get('/profile', ctrl.getProfile);
router.patch('/profile', validate(updateParentProfileSchema), ctrl.updateProfile);
router.get('/children', ctrl.getChildren);
router.get('/children/:studentId', ctrl.getChildById);
router.get('/children/:studentId/attendance', ctrl.getChildAttendance);
router.get('/children/:studentId/fees', ctrl.getChildFees);
router.get('/notices', ctrl.getNotices);
router.get('/notices/:id', ctrl.getNoticeById);
```

**File:** `backend/src/modules/auth/auth.routes.js`

Add:

```javascript
import { verifyParentOtpController } from './verify-parent-otp.controller.js';
import { verifyParentOtpSchema } from './auth.validation.js';
// ...
router.post('/verify-parent-otp', validate(verifyParentOtpSchema), verifyParentOtpController);
```

---

## 7. Error Responses

| Status | When | Message |
|--------|------|---------|
| 401 | No/invalid token | "You are not logged in. Please log in to get access." |
| 403 | Wrong portal / parent not found | "Access denied" or "Parent portal access required" |
| 404 | Child not found / Notice not found | "Child not found" or "Notice not found" |
| 422 | Validation failed | `{ success: false, error: "Validation failed", details: [...] }` |

Use `errorHandler` middleware — ensure AppError statusCode is respected.

---

## 8. Phone Normalization

Both resolve-user-by-phone and verify-parent-otp must use the same format:

- Input: `9876543210`, `919876543210`, `+919876543210` → normalize to `+919876543210`
- Store in DB: `+919876543210` (VarChar(20))
- Match: strip non-digits, compare last 10 digits when needed

---

## 9. Audit Log (Optional)

If `audit.service.js` exists, log:

- `PARENT_LOGIN` — on verify-parent-otp success
- `PARENT_PROFILE_UPDATE` — on PATCH profile

---

## 10. Validation Schemas

**parent.validation.js:**

```javascript
import { z } from 'zod';

export const updateParentProfileSchema = z.object({
  body: z.object({
    firstName: z.string().min(1).max(100).optional(),
    lastName: z.string().min(1).max(100).optional(),
    email: z.string().email().nullable().optional(),
  })
});

export const validate = (schema) => (req, res, next) => {
  try {
    const parsed = schema.parse({ body: req.body, query: req.query, params: req.params });
    req.body = parsed.body;
    req.query = parsed.query;
    req.params = parsed.params;
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(422).json({
        success: false,
        error: 'Validation failed',
        details: error.errors.map(e => ({ field: e.path.join('.'), message: e.message }))
      });
    }
    next(error);
  }
};
```

---

## 11. JWT Payload for Parent

When issuing token in verify-parent-otp:

```javascript
const payload = {
  parent_id: parent.id,
  school_id: parent.schoolId,
  portal_type: 'parent',
  email: parent.email || `parent_${parent.id}@vidyron.local`
};
const accessToken = jwt.sign(payload, JWT_ACCESS_SECRET, { expiresIn: '24h' });
```

Ensure `parent_id` and `school_id` use snake_case for consistency with existing tokens.
