# Driver Module — Backend Prompt

**Purpose**: Implement the Node.js Express backend for the Driver Portal. This prompt is copy-paste ready for the erp-backend-dev agent or a backend developer.

**Project Root**: `e:/School_ERP_AI/erp-new-logic/`  
**Module Folder**: `backend/src/modules/driver/`  
**Reference**: `docs/modules/driver/SPEC.md`, `.claude/CLAUDE.md`

---

## 1. Architecture Overview

- **API Base**: `/api/driver/`
- **Auth**: All routes require `verifyAccessToken` + `requireDriver` middleware
- **Pattern**: Follow `backend/src/modules/staff/` pattern (controller → service → repository)
- **Response**: `{ success: true, data: {...}, message: "..." }` via `successResponse`

---

## 2. Middleware: requireDriver

**File**: `backend/src/middleware/driver-guard.middleware.js`

Create a new middleware that:

1. Ensures `req.user` exists (from `verifyAccessToken`)
2. Checks `req.user.portal_type === 'driver'` (accept both `portal_type` and `portalType`)
3. Uses `req.user.userId` or `req.user.id` to find Driver by `userId`
4. Loads Driver with `school`, `vehicle`, `vehicle.route` (TransportRoute with `stops`)
5. Filters: `deletedAt: null`, `isActive: true`, `driver.schoolId === req.user.school_id`
6. Attaches `req.driverId` and `req.driver` (full Driver record)
7. On failure: `next(new AppError('Driver account not found or inactive. Access denied.', 403))`

**Reference**: Copy structure from `backend/src/middleware/staff-guard.middleware.js`, but lookup `Driver` instead of `Staff`/`NonTeachingStaff`.

---

## 3. Module Files to Create

| File | Purpose |
|------|---------|
| `backend/src/modules/driver/driver.controller.js` | HTTP handlers |
| `backend/src/modules/driver/driver.service.js` | Business logic |
| `backend/src/modules/driver/driver.repository.js` | Prisma queries |
| `backend/src/modules/driver/driver.routes.js` | Express routes |
| `backend/src/modules/driver/driver.validation.js` | Joi schemas |

---

## 4. Routes

| Method | Path | Middleware | Handler | Description |
|--------|------|------------|---------|-------------|
| GET | `/dashboard/stats` | verifyAccessToken, requireDriver | getDashboardStats | Dashboard stats |
| GET | `/profile` | verifyAccessToken, requireDriver | getProfile | Full driver profile |
| PUT | `/profile` | verifyAccessToken, requireDriver, validate(updateProfileSchema) | updateProfile | Update profile |
| POST | `/auth/change-password` | verifyAccessToken, requireDriver, validate(changePasswordSchema) | changePassword | Change password |

**Router setup**: `router.use(verifyAccessToken, requireDriver)` for all routes below the mount point.

---

## 5. Auth Endpoints (Driver Login)

**Phase 1**: Driver login uses the same platform auth endpoint: `POST /api/platform/auth/login` with body:
- `identifier`: email or phone
- `password`: password
- `portal_type`: `'driver'`
- `school_id`: required (UUID of school)

The smart-login service must support `portal_type: 'driver'` and look up a `Driver` record by `User` (via `Driver.userId`). If no Driver record exists for that user, return 403.

**Update required**: `backend/src/modules/auth/smart-login.service.js` — add handling for `portal_type === 'driver'`:
- Find User by identifier + school_id
- Find Driver where `userId = user.id`, `deletedAt: null`, `isActive: true`
- If no Driver found: throw AppError('Driver account not found', 403)
- Return JWT with `portal_type: 'driver'`, `school_id`, `user_id`

**Phase 2 (QR login)**: `POST /api/driver/auth/qr-login` — decode `qr_token`, verify school, assign vehicle from driver record. Stub for now or document as future.

---

## 6. Endpoint Specifications

### 6.1 GET /api/driver/dashboard/stats

**Response 200**:
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "uuid",
      "firstName": "Ramesh",
      "lastName": "Kumar",
      "photoUrl": null
    },
    "school": {
      "id": "uuid",
      "name": "DPS Noida",
      "logoUrl": null
    },
    "vehicle": {
      "id": "uuid",
      "vehicleNo": "DL-01-AB-1234",
      "capacity": 30
    },
    "route": {
      "id": "uuid",
      "name": "Route A - Sector 50",
      "stopCount": 8
    },
    "studentCount": 24,
    "tripStatus": "NOT_STARTED"
  }
}
```

**Business logic**:
- `driver`: from `req.driver` (id, firstName, lastName, photoUrl)
- `school`: from `req.driver.school` (id, name, logoUrl)
- `vehicle`: from `req.driver.vehicle` — if null, return `vehicle: null`
- `route`: from `req.driver.vehicle?.route` — if null, return `route: null`; `stopCount` = `route.stops.length`
- `studentCount`: Phase 1 — return `0` (no student-route linkage yet). Phase 2: count students on route.
- `tripStatus`: Phase 1 — return `"NOT_STARTED"` (no trip tracking yet). Phase 2: from TripStatus entity.

---

### 6.2 GET /api/driver/profile

**Response 200**:
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "uuid",
      "employeeNo": "DRV-001",
      "firstName": "Ramesh",
      "lastName": "Kumar",
      "gender": "MALE",
      "dateOfBirth": "1985-03-15",
      "phone": "9876543210",
      "email": "ramesh@school.in",
      "licenseNumber": "DL-123456789",
      "licenseExpiry": "2027-01-31",
      "photoUrl": null,
      "address": "Sector 30, Noida",
      "emergencyContactName": "Sita Kumar",
      "emergencyContactPhone": "9876543211",
      "isActive": true
    },
    "vehicle": {
      "id": "uuid",
      "vehicleNo": "DL-01-AB-1234",
      "capacity": 30
    },
    "route": {
      "id": "uuid",
      "name": "Route A - Sector 50",
      "stopCount": 8
    },
    "user": {
      "userId": "uuid",
      "email": "ramesh@school.in",
      "lastLogin": "2026-03-16T08:30:00Z"
    }
  }
}
```

**Business logic**:
- Load driver with `school`, `vehicle`, `vehicle.route` (include `stops` for count), `user`
- Format dates: `dateOfBirth`, `licenseExpiry` as `YYYY-MM-DD`; `lastLogin` as ISO string

---

### 6.3 PUT /api/driver/profile

**Request body** (all optional, partial update):
```json
{
  "phone": "9876543210",
  "emergencyContactName": "Sita Kumar",
  "emergencyContactPhone": "9876543211",
  "address": "Sector 30, Noida"
}
```

**Validation** (Joi): `updateProfileSchema` — all fields optional, max lengths per DB schema.

**Response 200**: Same shape as GET /api/driver/profile (return updated profile).

**Business logic**:
- Update only provided fields on `Driver` record
- Tenant isolation: `req.driver.id` must match

---

### 6.4 POST /api/driver/auth/change-password

**Request body**:
```json
{
  "currentPassword": "oldpass123",
  "newPassword": "newpass456"
}
```

**Validation** (Joi): `changePasswordSchema` — same as staff:
- `currentPassword`: string, min 8
- `newPassword`: string, min 8

**Response 200**: `{ success: true, message: "Password changed successfully" }`

**Business logic**:
- Get User by `req.driver.userId`
- Verify `currentPassword` against `User.passwordHash` (bcrypt)
- Throw `AppError('Current password is incorrect', 401)` if mismatch
- Hash and update `newPassword`, set `passwordChangedAt`, clear `mustChangePassword`
- Reference: `backend/src/modules/staff/staff-portal.service.js` — `changePassword`

---

## 7. Validation Schemas

**File**: `backend/src/modules/driver/driver.validation.js`

```javascript
// updateProfileSchema
{
  phone: Joi.string().max(20).optional().allow(null, ''),
  emergencyContactName: Joi.string().max(100).optional().allow(null, ''),
  emergencyContactPhone: Joi.string().max(20).optional().allow(null, ''),
  address: Joi.string().max(500).optional().allow(null, ''),
}.min(1)

// changePasswordSchema
{
  currentPassword: Joi.string().min(8).required(),
  newPassword: Joi.string().min(8).required(),
}
```

**validate middleware**: Same pattern as staff — `validate(schema)` returns middleware that validates `req.body` and calls `next(AppError)` on failure.

---

## 8. App Registration

**File**: `backend/src/app.js`

Add:
```javascript
import driverRoutes from './modules/driver/driver.routes.js';
// ...
app.use('/api/driver', driverRoutes);
```

---

## 9. Error Handling

| Case | Status | Message |
|------|--------|---------|
| No token / invalid token | 401 | "You are not logged in. Please log in to get access." |
| portal_type !== 'driver' | 403 | "Driver portal access required" |
| No Driver record for user | 403 | "Driver account not found or inactive. Access denied." |
| Wrong current password | 401 | "Current password is incorrect" |
| Validation error | 422 | "Validation error: ..." |

Use `throw new AppError(message, statusCode)` — caught by `errorHandler` middleware.

---

## 10. Audit Log (Optional)

If audit logging exists, record:
- `driver.profile.updated` on PUT /profile
- `driver.password.changed` on change-password

---

## 11. Reference Files

- `backend/src/modules/staff/staff-portal.routes.js` — route structure
- `backend/src/modules/staff/staff-portal.controller.js` — handle() wrapper, successResponse
- `backend/src/modules/staff/staff-portal.service.js` — changePassword logic
- `backend/src/middleware/staff-guard.middleware.js` — requireDriver pattern
