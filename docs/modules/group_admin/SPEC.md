# Group Admin Portal - Technical Specification

## 1. Domain Overview

A **School Group** is a trust, society, or chain of schools operating under one management entity —
for example "DPS Group" running 8 Delhi Public Schools across a state, or "Podar Education Network"
running 100+ schools nationwide. The **Group Admin** is the operations manager or regional director
assigned to oversee all schools within that group.

The Group Admin Portal gives that person a unified read-only operations view across their assigned
schools: combined headcounts, subscription health, school-level status, and platform notifications.
They cannot modify school data (that is the Super Admin's domain) but need live visibility to manage
their group's operations on the ground.

### Real-world operations this covers
- Morning check: "How many of my schools are currently active/suspended?"
- Subscription monitoring: "Which schools are expiring in the next 30 days?"
- School drill-down: "What is the student count and plan tier for Noida branch?"
- Contact management: "Who is the school admin for the Pune school?"
- Profile management: Group admin updates their own password

---

## 2. User Roles and Permissions

| Role | Access Level |
|------|-------------|
| Super Admin | Can create/manage group admins via Super Admin portal — not covered here |
| Group Admin | Read-only access to their own group's data only — this module |

### Group Admin Permissions
- View dashboard stats for their assigned group only
- View list of all schools in their group
- View detail of any school in their group
- View platform notifications addressed to group_admin role
- View and update their own profile
- Change their own password
- No write access to schools, plans, or any school data

### Tenant Isolation
Every backend query uses `groupId` extracted from the JWT by the `requireGroupAdmin` middleware.
The middleware looks up `SchoolGroup.groupAdminUserId = req.user.userId` — so a group admin
can only ever see their own group's data even if they tamper with request parameters.

---

## 3. Features and User Stories

### Core Features

#### Dashboard
- As a group admin, I can see a summary card showing total schools in my group so that I have an instant count
- As a group admin, I can see how many of those schools are currently ACTIVE vs SUSPENDED/INACTIVE
- As a group admin, I can see a combined student headcount across all group schools
- As a group admin, I can see how many subscriptions expire within 30 days so I can proactively alert management
- As a group admin, I can see a breakdown of schools by subscription plan tier (BASIC/STANDARD/PREMIUM)
- As a group admin, I can see my group's name and logo in the portal header

#### Schools List
- As a group admin, I can view a list of all schools in my group with search/sort
- As a group admin, I can search schools by name, code, or city
- As a group admin, I can sort schools by name, city, status, or subscription end date
- As a group admin, I can see each school's status badge (ACTIVE/SUSPENDED/INACTIVE)
- As a group admin, I can see each school's plan tier and subscription expiry date at a glance
- As a group admin, I can see a user count per school

#### School Detail
- As a group admin, I can tap a school to see full detail: name, code, board, city, state, contact email/phone
- As a group admin, I can see the name and email of the assigned school admin
- As a group admin, I can see the school's current plan and exact subscription start/end dates
- As a group admin, I can see the school's status and when it was last updated

#### Notifications
- As a group admin, I can see platform notifications addressed to the group_admin role
- As a group admin, I can mark individual notifications as read
- As a group admin, I can see an unread count badge on the bell icon in the top bar

#### Profile and Account
- As a group admin, I can view my own profile (name, email, phone, last login)
- As a group admin, I can see which group I manage (name, country, contact details)
- As a group admin, I can change my password using current + new password

---

## 4. Data Model

### Existing Entities (no new tables required for Phase 1)

#### SchoolGroup (existing — `school_groups` table)
```
id               UUID PK
name             VARCHAR(255)
slug             VARCHAR(100) UNIQUE
type             VARCHAR(50)          -- e.g. "trust", "society", "franchise"
description      TEXT
contactPerson    VARCHAR(255)
contactEmail     VARCHAR(255)
contactPhone     VARCHAR(20)
logoUrl          TEXT
address          TEXT
city             VARCHAR(100)
state            VARCHAR(100)
country          VARCHAR(100)
status           GroupStatus          -- ACTIVE | INACTIVE
groupAdminUserId UUID UNIQUE FK->users
deletedAt        TIMESTAMPTZ
createdAt        TIMESTAMPTZ
updatedAt        TIMESTAMPTZ
```

#### School (existing — `schools` table)
```
id               UUID PK
name             VARCHAR(255)
code             VARCHAR(50) UNIQUE
subdomain        VARCHAR(50) UNIQUE
board            VARCHAR(100)
email            VARCHAR(255)
phone            VARCHAR(20)
address          TEXT
city             VARCHAR(100)
state            VARCHAR(100)
country          VARCHAR(100)
pinCode          VARCHAR(20)
timezone         VARCHAR(50)
logoUrl          TEXT
status           SchoolStatus         -- ACTIVE | SUSPENDED | INACTIVE
subscriptionPlan SubscriptionPlan     -- BASIC | STANDARD | PREMIUM
subscriptionStart DATE
subscriptionEnd  DATE
groupId          UUID FK->school_groups
createdAt        TIMESTAMPTZ
updatedAt        TIMESTAMPTZ
```

#### User (existing — `users` table)
```
id               UUID PK
email            VARCHAR(255) UNIQUE
firstName        VARCHAR(100)
lastName         VARCHAR(100)
phone            VARCHAR(20)
passwordHash     VARCHAR(255)
roleId           INT FK->roles
schoolId         UUID FK->schools (NULL for group admin)
isActive         BOOLEAN
lastLogin        TIMESTAMPTZ
resetPasswordToken TEXT
resetPasswordExpires TIMESTAMPTZ
deletedAt        TIMESTAMPTZ
```

#### platform_notifications (existing raw table used by super-admin service)
```
id          UUID PK
type        VARCHAR                  -- 'info' | 'warning' | 'success' | 'error'
title       VARCHAR
body        TEXT
is_read     BOOLEAN DEFAULT false
link        TEXT
target_role VARCHAR                  -- 'super_admin' | 'group_admin' | NULL
created_at  TIMESTAMPTZ
```

### Relations
- `SchoolGroup` has one `User` as groupAdmin (via `groupAdminUserId`)
- `School` belongs to one `SchoolGroup` (via `groupId`)
- `SchoolGroup` has many `School`
- `User` (group admin) manages one `SchoolGroup`

### No new DB migrations required for Phase 1
All data needed is in existing tables. The `platform_notifications` table already has
`target_role` column — group admin notifications use `target_role = 'group_admin'`.

---

## 5. API Endpoints

### Base Path
All group admin API routes: `/api/platform/group-admin`
All auth routes for group admin: `/api/platform/auth/group-admin/*`

### Auth Endpoints (in existing auth.routes.js)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/platform/auth/group-admin/login` | None | Login with email+password, returns JWT with portal_type=group_admin |
| POST | `/api/platform/auth/group-admin/forgot-password` | None | Send reset email to group admin email |
| POST | `/api/platform/auth/group-admin/reset-password` | None | Consume reset token, set new password |

#### POST /auth/group-admin/login
Request body:
```json
{
  "identifier": "groupadmin@dpsgroup.in",
  "password": "SecurePass@123",
  "group_id": "uuid-of-group",
  "device_fingerprint": "fp_abc123",
  "device_meta": { "platform": "web", "browser": "Chrome" }
}
```
Success response (200):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": {
      "user_id": "uuid",
      "first_name": "Rajesh",
      "last_name": "Sharma",
      "email": "groupadmin@dpsgroup.in",
      "portal_type": "group_admin"
    },
    "group": {
      "id": "uuid-of-group",
      "name": "DPS Group",
      "slug": "dpsgroup"
    }
  }
}
```
OTP required response (200):
```json
{
  "success": true,
  "data": {
    "requires_otp": true,
    "otp_session_id": "session_abc",
    "expires_in": 120,
    "masked_phone": "98****01",
    "masked_email": "g***@d***.in"
  }
}
```
Error cases: 401 (wrong password), 403 (group inactive, no group assigned), 404 (user not found)

#### POST /auth/group-admin/forgot-password
Request:
```json
{ "email": "groupadmin@dpsgroup.in" }
```
Response (200):
```json
{ "success": true, "message": "Reset link sent to your email." }
```
Note: Always returns 200 even if email not found (security — no user enumeration).

#### POST /auth/group-admin/reset-password
Request:
```json
{ "token": "hex-reset-token", "new_password": "NewPass@456" }
```
Response (200):
```json
{ "success": true, "message": "Password has been reset successfully." }
```

---

### Group Admin Portal Endpoints (group-admin.routes.js — currently not mounted)

All routes require `verifyAccessToken` + `requireGroupAdmin` middleware.
The middleware injects `req.groupId` from the JWT user's managed group.

#### Dashboard

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/platform/group-admin/dashboard/stats` | Aggregated stats for the group |

Response:
```json
{
  "success": true,
  "data": {
    "group": {
      "id": "uuid",
      "name": "DPS Group",
      "slug": "dpsgroup",
      "logoUrl": null,
      "status": "ACTIVE"
    },
    "totalSchools": 8,
    "activeSchools": 7,
    "totalStudents": 12400,
    "totalTeachers": 480,
    "subscriptionBreakdown": {
      "PREMIUM": 3,
      "STANDARD": 4,
      "BASIC": 1
    },
    "expiringSoon": 2,
    "recentActivity": []
  }
}
```

#### Schools

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/platform/group-admin/schools` | List all schools in the group |
| GET | `/api/platform/group-admin/schools/:id` | School detail |

GET /schools query params: `?search=noida&sortBy=name&sortOrder=asc`
- `search`: string — filters by name, code, city (case-insensitive)
- `sortBy`: `name` | `code` | `city` | `status` | `createdAt` (default: `name`)
- `sortOrder`: `asc` | `desc` (default: `asc`)

Schools list response:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Delhi Public School Noida",
      "code": "DPS-NOI",
      "city": "Noida",
      "state": "Uttar Pradesh",
      "board": "CBSE",
      "status": "ACTIVE",
      "subscriptionPlan": "PREMIUM",
      "subscriptionEnd": "2026-03-31",
      "userCount": 1240
    }
  ]
}
```

School detail response:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Delhi Public School Noida",
    "code": "DPS-NOI",
    "board": "CBSE",
    "email": "info@dpsnoida.in",
    "phone": "0120-1234567",
    "address": "Sector 30, Noida",
    "city": "Noida",
    "state": "Uttar Pradesh",
    "country": "India",
    "pinCode": "201301",
    "timezone": "Asia/Kolkata",
    "logoUrl": null,
    "status": "ACTIVE",
    "subscriptionPlan": "PREMIUM",
    "subscriptionStart": "2025-04-01",
    "subscriptionEnd": "2026-03-31",
    "_count": { "users": 1240 },
    "users": [
      {
        "id": "uuid",
        "firstName": "Priya",
        "lastName": "Mehta",
        "email": "priya.mehta@dpsnoida.in"
      }
    ]
  }
}
```

#### Profile

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/platform/group-admin/profile` | Get own profile + group info |
| PUT | `/api/platform/group-admin/change-password` | Change own password |

Profile response:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "groupadmin@dpsgroup.in",
      "firstName": "Rajesh",
      "lastName": "Sharma",
      "phone": "+91-9876543210",
      "lastLogin": "2026-03-14T08:30:00Z"
    },
    "group": {
      "id": "uuid",
      "name": "DPS Group",
      "slug": "dpsgroup",
      "logoUrl": null,
      "country": "India"
    }
  }
}
```

Change password request:
```json
{ "current_password": "OldPass@123", "new_password": "NewPass@456" }
```

#### Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/platform/group-admin/notifications` | Paginated notification list |
| PUT | `/api/platform/group-admin/notifications/:id/read` | Mark one notification as read |

Notifications query params: `?page=1&limit=20`

Notifications response:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "uuid",
        "type": "warning",
        "title": "Subscription Expiring",
        "body": "DPS Noida subscription expires in 15 days",
        "isRead": false,
        "link": null,
        "createdAt": "2026-03-14T06:00:00Z"
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

#### Reports (Stubs — return placeholder until school modules are built)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/platform/group-admin/reports/attendance` | Stub — attendance module not activated |
| GET | `/api/platform/group-admin/reports/fees` | Stub — fees module not activated |
| GET | `/api/platform/group-admin/reports/performance` | Stub — performance module not activated |
| GET | `/api/platform/group-admin/reports/comparison` | Stub — comparison not activated |

---

## 6. Screen Inventory (Flutter)

### 6.1 Group Admin Login Screen (fix existing)
- **File**: `lib/features/auth/group_admin_login_screen.dart` (exists — needs `_handleLogin` wired)
- **Purpose**: Password-based login for group admin (OTP tab is deferred to Phase 2)
- **Route**: `/login/group`
- **Key UI Elements**:
  - Group identity banner (existing, shows group logo + name from subdomain resolution)
  - Password tab only (OTP tab shown but disabled with "Coming soon" message)
  - Email + Password fields with validation
  - Forgot password link — navigates to `/group-admin/forgot-password`
  - Error message display
  - Loading overlay
- **State**: `groupAdminLoginProvider` (new `StateNotifierProvider<GroupAdminLoginNotifier, GroupAdminLoginState>`)
- **API Calls**: `POST /api/platform/auth/group-admin/login`
- **On success**: `context.go('/group-admin/dashboard')`
- **Auth guard**: After login, `authGuardProvider.establishSession(token, portalTypeOverride: 'group_admin')`

### 6.2 Group Admin Forgot Password Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_forgot_password_screen.dart`
- **Purpose**: Email entry to trigger reset link
- **Route**: `/group-admin/forgot-password` (public, no auth guard)
- **Key UI Elements**:
  - Same glass card styling as super admin forgot password screen
  - Email field with validation
  - Submit button
  - Success state showing "Check your email"
  - Back to login link
- **State**: Local `StatefulWidget` with loading/success/error states
- **API Calls**: `POST /api/platform/auth/group-admin/forgot-password`

### 6.3 Group Admin Shell
- **File**: `lib/features/group_admin/presentation/group_admin_shell.dart`
- **Purpose**: Responsive shell with sidebar (web) + bottom nav + drawer (mobile)
- **Pattern**: Mirror `super_admin_shell.dart` exactly — same structure, different tabs, different badge label
- **Navigation tabs** (web sidebar):
  - PRIMARY section: Dashboard, Schools, Notifications
  - ACCOUNT section: Profile, Change Password
- **Top bar**: Group name badge (e.g. "DPS GROUP") instead of "SUPER ADMIN"
- **Mobile bottom nav**: Dashboard (index 0), Schools (index 1), More (index 2 — opens drawer)
- **Top bar actions**: NotificationsBellButton (group admin variant), logout button
- **Auth guard**: Wraps all routes with `groupAdminGuardProvider` check

### 6.4 Group Admin Dashboard Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_dashboard_screen.dart`
- **Purpose**: Overview of the group's school portfolio
- **Route**: `/group-admin/dashboard`
- **Key UI Elements**:
  - Page header: Group name + logo (or initials avatar)
  - Stats grid (4 cards):
    - Total Schools (with active count subtitle)
    - Total Students (across all schools)
    - Subscriptions Expiring (within 30 days — shown in amber/red if > 0)
    - Active Schools percentage chip
  - Subscription plan breakdown: Horizontal bar or chips showing BASIC/STANDARD/PREMIUM counts
  - Schools list preview: Top 5 schools by name with status badges and quick expiry warning
  - "View all schools" button at bottom
- **State**: `groupAdminDashboardProvider` as `FutureProvider<GroupAdminDashboardStats>`
- **API Calls**: `GET /api/platform/group-admin/dashboard/stats`
- **Refresh**: Pull-to-refresh using `ref.invalidate(groupAdminDashboardProvider)`

### 6.5 Group Admin Schools Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_schools_screen.dart`
- **Purpose**: Full list of schools in the group with search and sort
- **Route**: `/group-admin/schools`
- **Key UI Elements**:
  - Search bar (debounced 300ms)
  - Sort control: dropdown for sortBy field + asc/desc toggle icon button
  - School list tiles showing: name, code, city, status badge, plan chip, subscription end date, user count
  - Tap to navigate to school detail
  - Empty state when no results
  - Loading skeleton (shimmer effect)
- **State**: `groupAdminSchoolsProvider` as `StateNotifierProvider<GroupAdminSchoolsNotifier, GroupAdminSchoolsState>`
  - State holds: `List<GroupAdminSchoolModel> schools`, `bool isLoading`, `String? error`, `String search`, `String sortBy`, `String sortOrder`
- **API Calls**: `GET /api/platform/group-admin/schools?search=&sortBy=&sortOrder=`

### 6.6 Group Admin School Detail Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_school_detail_screen.dart`
- **Purpose**: Full read-only profile of a school
- **Route**: `/group-admin/schools/:id`
- **Key UI Elements**:
  - Back button to schools list
  - School name as page title
  - Status badge (color-coded: green=ACTIVE, amber=SUSPENDED, red=INACTIVE)
  - Info sections:
    - Contact: email, phone, address, city, state, pinCode
    - Academics: board, timezone
    - Subscription: plan, start date, end date, days remaining chip (red if < 30 days)
    - Users: total user count
    - School Admin: name and email of assigned school_admin user
  - All fields read-only (label + value layout)
- **State**: `groupAdminSchoolDetailProvider(schoolId)` as `FutureProvider.family`
- **API Calls**: `GET /api/platform/group-admin/schools/:id`

### 6.7 Group Admin Notifications Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_notifications_screen.dart`
- **Purpose**: Platform notifications for group admin role
- **Route**: `/group-admin/notifications`
- **Key UI Elements**:
  - Notification list tiles with type icon (info/warning/success/error), title, body, timestamp
  - Unread notifications shown with highlight background
  - Tap to mark as read (calls API, updates local state)
  - Empty state: "No notifications yet"
  - Pagination (load more on scroll)
- **State**: `groupAdminNotificationsProvider` as `StateNotifierProvider<GroupAdminNotificationsNotifier, GroupAdminNotificationsState>`
  - State: `List<GroupAdminNotificationModel> notifications`, `bool isLoading`, `int page`, `bool hasMore`
- **API Calls**: `GET /api/platform/group-admin/notifications`, `PUT /api/platform/group-admin/notifications/:id/read`

### 6.8 Group Admin Profile Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_profile_screen.dart`
- **Purpose**: View personal profile and group info; navigate to change password
- **Route**: `/group-admin/profile`
- **Key UI Elements**:
  - Avatar with initials (first + last name)
  - Profile card: full name, email, phone, last login timestamp
  - Group card: group name, slug, country, logo (if set)
  - "Change Password" button — navigates to `/group-admin/change-password`
  - "Sign out" button
- **State**: `groupAdminProfileProvider` as `FutureProvider<GroupAdminProfileModel>`
- **API Calls**: `GET /api/platform/group-admin/profile`

### 6.9 Group Admin Change Password Screen
- **File**: `lib/features/group_admin/presentation/screens/group_admin_change_password_screen.dart`
- **Purpose**: Secure password change form
- **Route**: `/group-admin/change-password`
- **Key UI Elements**:
  - Current password field (obscured with visibility toggle)
  - New password field
  - Confirm new password field
  - Client-side validation: new != current, confirm matches, min 8 chars
  - Submit button with loading state
  - Success snackbar on completion
- **State**: Local `ConsumerStatefulWidget` with form key
- **API Calls**: `PUT /api/platform/group-admin/change-password`

---

## 7. Business Rules

### Login
1. Only users whose `portal_type` claim resolves to `group_admin` OR whose `role.name = 'group_admin'` can pass the `requireGroupAdmin` middleware
2. The user must have a corresponding `SchoolGroup` where `groupAdminUserId = userId` and `status = ACTIVE`
3. If no group is assigned, return 403 "No group assigned to this account"
4. If group is INACTIVE, return 403 "Your group account is inactive"
5. The `group_id` field in login request is currently for client-side routing (subdomain resolved); the actual group is always resolved server-side from JWT userId — never trust the client-supplied group_id for data access

### Forgot Password
1. Reuse the same `forgotPassword` function from `auth.service.js` — it is portal-agnostic
2. Rate limit: max 3 requests per email per 60 minutes (enforced by existing smart-login.repository countRecentForgotPasswordByEmail)
3. Reset token expires in 1 hour
4. The reset link should point to `/group-admin/reset-password?token=...` (not the generic `/reset-password`)
5. Always return success message regardless of whether email exists (no user enumeration)

### Password Change
1. Verify current password via bcrypt.compare before accepting new one
2. New password must not be identical to current password
3. Minimum 8 characters, at least one uppercase, one lowercase, one digit (enforced client-side; backend enforces min 6 via existing validation)
4. Update `passwordChangedAt` and set `mustChangePassword = false`

### School Data Access
1. When fetching school detail, always verify `school.groupId = req.groupId` before returning data — if school does not belong to this group, return 404 (do not leak existence)
2. Schools with `deletedAt != null` are excluded from all lists
3. `status: 'INACTIVE'` schools are excluded from the dashboard's school list (per existing repository logic) but ARE shown in the full school list for audit awareness

### Notifications
1. Group admin notifications use `target_role = 'group_admin'` in `platform_notifications` table
2. Query: `WHERE target_role = 'group_admin' OR target_role IS NULL` — `NULL` means broadcast to all
3. Mark-as-read is per-notification, not per-user (platform-level, same as super admin pattern)

### Subscription Expiry Warning
1. "Expiring soon" = subscription ends within 30 calendar days from today
2. Already-expired schools (subscriptionEnd < today) should be shown separately as "Overdue"
3. Dashboard `expiringSoon` count excludes INACTIVE schools

---

## 8. Integration Points

### Current integrations (Phase 1)
- **Auth module**: Shares `verifyAccessToken` middleware, `forgotPassword`/`resetPassword` from `auth.service.js`, `smartLogin` from `smart-login.service.js`
- **platform_notifications table**: Shared with super-admin notifications — filtered by `target_role`
- **SchoolGroup model**: Read from existing `school_groups` table
- **School model**: Read from existing `schools` table
- **User model**: Read from existing `users` table

### Future integrations (Phase 2+)
- **Student module**: `totalStudents` will be a real count from `students` table (not user count)
- **Attendance module**: `getAttendanceReport` stub will be fulfilled
- **Fees module**: `getFeesReport` stub will be fulfilled
- **Timetable/Exam modules**: Cross-school comparison reports

---

## 9. Security Requirements

### Authentication
- JWT must contain `portal_type: 'group_admin'` OR `role: 'group_admin'` — enforced by `requireGroupAdmin` middleware
- Token TTL follows platform standard (access: 15min, refresh: 7 days) — same as super admin
- On password change, existing sessions are NOT invalidated in Phase 1 (Phase 2 enhancement: revoke all JWTs)

### Authorization
- Every `group-admin.routes.js` route is gated by both `verifyAccessToken` AND `requireGroupAdmin`
- `req.groupId` is always set by middleware from DB lookup — never from request body/query
- All Prisma queries include `groupId: req.groupId` as a filter — no group admin can access another group's data

### Data isolation
- School detail endpoint verifies `school.groupId === req.groupId` before returning data
- No group admin endpoint exposes other groups' schools, users, or stats

### Input validation
- Login request validated by existing `groupAdminLoginSchema` (Zod) — already in `auth.validation.js`
- Forgot/reset password use existing `forgotPasswordSchema` / new `groupAdminResetPasswordSchema`
- Change password: both `current_password` and `new_password` required, new password min 6 chars (Zod)

### Rate limiting (inherited from platform)
- Forgot password: 3 requests per email per 60 minutes
- Login: existing IP-based rate limiting from smart-login.service.js (5 attempts per 15 min per IP)

### Audit trail
- Password changes logged (passwordChangedAt timestamp update)
- Phase 2: Add dedicated group admin audit log table for login events

---

## 10. Migration Plan

### Phase 1 — No new DB migrations required
All required tables (`school_groups`, `schools`, `users`, `platform_notifications`) already exist.
No schema changes needed.

### Phase 2 — Group Admin Audit Logs (future)
When audit trail is needed, add:
```sql
CREATE TABLE group_admin_audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID NOT NULL REFERENCES school_groups(id),
  actor_id    UUID NOT NULL REFERENCES users(id),
  action      VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100),
  entity_id   VARCHAR(255),
  entity_name VARCHAR(255),
  request_data JSONB,
  ip_address  INET,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_ga_audit_group ON group_admin_audit_logs(group_id);
CREATE INDEX idx_ga_audit_actor ON group_admin_audit_logs(actor_id);
CREATE INDEX idx_ga_audit_created ON group_admin_audit_logs(created_at DESC);
```

---

## 11. Backend Fix Checklist

These are the exact gaps that need to be closed before the portal works end-to-end:

### app.js — Mount group-admin routes
```js
import groupAdminRoutes from './modules/group-admin/group-admin.routes.js';
// Add after superAdminRoutes:
app.use(`${API_PREFIX}/group-admin`, groupAdminRoutes);
```

### portal-auth.controller.js — Fix groupAdminLoginController
The current implementation calls `smartLoginService.smartLogin` but does not:
1. Verify the user has `portal_type = 'group_admin'`
2. Include group info in the response
3. Handle the case where `device_fingerprint` is not provided
Replace the stub with a proper implementation that:
- Calls `smartLogin` with `portal_type: 'group_admin'`
- On direct token (no OTP required), fetches the group info and includes it in the response
- Sets `portal_type: 'group_admin'` in the JWT via the jwtUtils call

### auth.routes.js — Add forgot/reset password for group admin
Add two routes that reuse existing `auth.service.js` functions:
```js
router.post('/group-admin/forgot-password', validate(forgotPasswordSchema), groupAdminForgotPasswordController);
router.post('/group-admin/reset-password', validate(groupAdminResetPasswordSchema), groupAdminResetPasswordController);
```
The controllers call the same `forgotPassword(email, origin)` and `resetPassword(token, newPassword)` functions.

### group-admin.service.js — Fix notifications getNotifications
Replace the placeholder return with a real query against `platform_notifications`
matching `target_role = 'group_admin' OR target_role IS NULL`, with proper pagination.
Follow the exact pattern in `super-admin.service.js` lines 2037-2068.

### group-admin.repository.js — Add markNotificationRead
Replace the stub with the actual raw SQL update:
```js
await prisma.$executeRawUnsafe(
  `UPDATE platform_notifications SET is_read = TRUE WHERE id = $1::uuid`,
  String(notificationId)
);
```

---

## 12. Flutter Implementation Checklist

### New files to create
```
lib/features/group_admin/
  group_admin_guard_provider.dart
  presentation/
    group_admin_shell.dart
    screens/
      group_admin_dashboard_screen.dart
      group_admin_schools_screen.dart
      group_admin_school_detail_screen.dart
      group_admin_notifications_screen.dart
      group_admin_profile_screen.dart
      group_admin_change_password_screen.dart
      group_admin_forgot_password_screen.dart

lib/core/services/
  group_admin_service.dart

lib/models/group_admin/
  group_admin_models.dart

lib/features/auth/
  group_admin_login_provider.dart   (new — separate from loginProvider)
  group_admin_login_state.dart      (new — simpler than LoginState, no biometrics)
```

### Existing files to modify
```
lib/routes/app_router.dart
  - Add groupAdminGuardProvider check in redirect logic
  - Add ShellRoute for /group-admin/* with GroupAdminShell
  - Add all /group-admin/* GoRoute entries
  - Add /group-admin/forgot-password and /group-admin/reset-password public routes

lib/features/auth/group_admin_login_screen.dart
  - Replace _handleLogin stub with real groupAdminLoginProvider call
  - Handle OTP flow (show device-verification screen)
  - Handle success: context.go('/group-admin/dashboard')
  - Disable OTP tab with "Coming Soon" tooltip
  - Add forgot password link pointing to /group-admin/forgot-password

lib/core/config/api_config.dart
  - Add group admin auth endpoint constants
```

### Router redirect logic additions
The `redirect` function in `app_router.dart` needs to handle `portal_type = 'group_admin'`:
- If authenticated as group_admin and on `/login/*` → redirect to `/group-admin/dashboard`
- If authenticated as group_admin and on `/super-admin/*` → redirect to `/group-admin/dashboard`
- If NOT authenticated and on `/group-admin/*` (except forgot/reset password) → redirect to `/splash`
- The group admin guard provider watches `authGuardProvider` for `portalType == 'group_admin'`
