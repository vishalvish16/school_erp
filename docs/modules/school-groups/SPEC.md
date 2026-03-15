# School Groups — Technical Specification

> Version: 1.0 | Date: 2026-03-14 | Author: Tech Lead Agent
> Drives: erp-db-architect, erp-backend-dev, erp-flutter-dev, erp-code-reviewer, erp-security-reviewer, erp-qa-tester

---

## 1. Domain Overview

School groups represent chains/trusts/franchises that operate multiple schools under a single umbrella. Examples in the Indian context: Delhi Public School (DPS) chain, Ryan International Group, DAV Schools, Diocesan school boards, and state-government aided school clusters.

**Key personas:**
- **Super Admin** (platform operator) manages all groups, assigns group admins, views analytics.
- **Group Admin** (regional director / trust manager) oversees multiple schools within their assigned group. They can view aggregate data, compare school performance, and manage group-level settings. They cannot edit individual school configurations -- that remains with School Admins.

**Business value:**
- Groups unlock bulk pricing, unified billing, cross-school analytics, and centralized compliance.
- Group Admins reduce Super Admin workload by handling day-to-day oversight of their schools.
- Groups create a natural sales unit: sell to a trust, onboard 20 schools at once.

**Current state summary:**
- `SchoolGroup` model exists in Prisma with only `id`, `name`, `createdAt`, `updatedAt`.
- `School.groupId` FK exists (nullable, onDelete SetNull).
- Backend has 5 endpoints: getGroups, createGroup, updateGroup, addSchoolToGroup, removeSchoolFromGroup.
- Flutter has a groups screen with expand/collapse, create dialog (name-only), edit dialog (name-only), add-school-to-group dialog.
- Flutter model `SuperAdminSchoolGroupModel` already has fields for slug, subdomain, type, hqCity, contactPerson, contactEmail, status, schoolCount, studentCount, mrr -- but the backend does NOT populate most of them (they default to null/0).
- Group Admin login route exists (`POST /auth/group-admin/login`) but is a stub. Flutter `GroupAdminLoginScreen` exists but `_handleLogin` is a TODO.
- No Group Admin portal/dashboard exists at all.
- No `deleteGroup` endpoint exists.
- No group-admin user role row exists in the `roles` table.
- studentCount and mrr are hardcoded to 0 in the backend getGroups response.

---

## 2. User Roles & Permissions

| Action | Super Admin | Group Admin | School Admin |
|---|---|---|---|
| Create group | Yes | No | No |
| Edit group details | Yes | No | No |
| Delete group (soft) | Yes | No | No |
| Add/remove schools from group | Yes | No | No |
| View all groups | Yes | No | No |
| Assign Group Admin user | Yes | No | No |
| View own group details | N/A | Yes | No |
| View schools in own group (read-only) | N/A | Yes | No |
| View group aggregate stats | Yes (any) | Yes (own) | No |
| View school detail within group | Yes (edit) | Yes (read-only) | Own only |
| View group-level reports | Yes | Yes (own) | No |
| Receive group notifications | N/A | Yes | No |
| Compare schools within group | N/A | Yes | No |
| Export group reports | Yes | Yes (own) | No |
| Change own password | Yes | Yes | Yes |

**Role definition:**
- A new role `group_admin` must exist in the `roles` table with `scope = GLOBAL` (they are not school-scoped).
- A Group Admin user has `schoolId = NULL` (like super_admin) but `role.name = 'group_admin'`.
- The `SchoolGroup` model links to the Group Admin user via `groupAdminUserId`.

---

## 3. Features & User Stories

### 3A. Super Admin -- Group Management (enhance existing)

| ID | Story | Priority |
|---|---|---|
| SG-01 | As a Super Admin, I can create a group with full details (name, slug, type, contact person, email, phone, logo, address, city, state, country, status) | P0 |
| SG-02 | As a Super Admin, I can edit all group fields | P0 |
| SG-03 | As a Super Admin, I can soft-delete (deactivate) a group | P1 |
| SG-04 | As a Super Admin, I can view a group detail page with all member schools and aggregate stats | P0 |
| SG-05 | As a Super Admin, I can add/remove schools from a group | P0 (exists) |
| SG-06 | As a Super Admin, I can assign a Group Admin user to a group (create user if needed) | P0 |
| SG-07 | As a Super Admin, I can reset a Group Admin's password | P1 |
| SG-08 | As a Super Admin, I can deactivate a Group Admin | P1 |
| SG-09 | As a Super Admin, I can view group-level analytics: total schools, total students, total teachers, aggregate MRR, subscription breakdown | P0 |
| SG-10 | As a Super Admin, I can search/filter groups by name, status, city, state | P1 |
| SG-11 | As a Super Admin, I can paginate the groups list | P1 |

### 3B. Group Admin Portal (NEW)

| ID | Story | Priority |
|---|---|---|
| GA-01 | As a Group Admin, I can log in via the group subdomain ({groupslug}.vidyron.in) with email + password | P0 |
| GA-02 | As a Group Admin, I see a dashboard with aggregate stats: total schools, total students, total teachers, attendance rate, fee collection rate | P0 |
| GA-03 | As a Group Admin, I can view a list of all schools in my group with key metrics per school | P0 |
| GA-04 | As a Group Admin, I can view a school's detail page (read-only): student count, staff count, subscription, contact info | P0 |
| GA-05 | As a Group Admin, I can compare schools side-by-side on key metrics | P1 |
| GA-06 | As a Group Admin, I can view group-level reports: attendance trends, fee collection, exam performance | P1 |
| GA-07 | As a Group Admin, I receive notifications relevant to my group (new school added, subscription expiring, etc.) | P2 |
| GA-08 | As a Group Admin, I can change my own password | P0 |
| GA-09 | As a Group Admin, I can export reports as CSV/PDF | P2 |
| GA-10 | As a Group Admin, I can view my profile and group info | P1 |

---

## 4. Data Model

### 4A. SchoolGroup (expand existing)

```
model SchoolGroup {
  id                String        @id @default(uuid()) @db.Uuid
  name              String        @db.VarChar(255)
  slug              String?       @unique @db.VarChar(100)       // NEW: URL-safe identifier
  type              String?       @db.VarChar(50)                // NEW: trust, franchise, diocesan, government, chain
  description       String?       @db.Text                       // NEW
  contactPerson     String?       @map("contact_person") @db.VarChar(255)  // NEW
  contactEmail      String?       @map("contact_email") @db.VarChar(255)   // NEW
  contactPhone      String?       @map("contact_phone") @db.VarChar(20)    // NEW
  logoUrl           String?       @map("logo_url") @db.Text                // NEW
  address           String?       @db.Text                       // NEW
  city              String?       @db.VarChar(100)               // NEW
  state             String?       @db.VarChar(100)               // NEW
  country           String?       @db.VarChar(100)               // NEW
  status            GroupStatus   @default(ACTIVE)               // NEW
  groupAdminUserId  String?       @unique @map("group_admin_user_id") @db.Uuid  // NEW: FK to users
  createdAt         DateTime      @default(now()) @map("created_at")
  updatedAt         DateTime      @default(now()) @updatedAt @map("updated_at")
  deletedAt         DateTime?     @map("deleted_at") @db.Timestamptz(6)   // NEW: soft delete

  schools           School[]
  groupAdmin        User?         @relation("GroupAdmin", fields: [groupAdminUserId], references: [id], onDelete: SetNull)

  @@map("school_groups")
}

enum GroupStatus {
  ACTIVE
  INACTIVE

  @@map("group_status_enum")
}
```

### 4B. User model addition

Add a reverse relation on User:
```
managedGroup  SchoolGroup?  @relation("GroupAdmin")
```

### 4C. Roles table seed

Insert a row:
```sql
INSERT INTO roles (name, description, scope)
VALUES ('group_admin', 'Group administrator overseeing multiple schools', 'GLOBAL')
ON CONFLICT DO NOTHING;
```

### 4D. Entity Relationship Summary

```
User (group_admin role) <--1:1-- SchoolGroup --1:N--> School
                                      |
                               groupAdminUserId (FK)
```

- One SchoolGroup has exactly 0 or 1 Group Admin user.
- One SchoolGroup has 0..N schools.
- One School belongs to 0 or 1 SchoolGroup.
- Group Admin User has schoolId = NULL, role = group_admin.

---

## 5. API Endpoints

### 5A. Super Admin Group Endpoints (under /api/platform/super-admin)

All require `verifyAccessToken` + `requireSuperAdmin`.

| Method | Path | Description | Status |
|---|---|---|---|
| GET | /groups | List all groups with pagination, search, filter | ENHANCE (add pagination, search, stats) |
| GET | /groups/:id | Get single group with schools and stats | NEW |
| POST | /groups | Create group with full details | ENHANCE (add all new fields) |
| PUT | /groups/:id | Update group | ENHANCE (add all new fields) |
| DELETE | /groups/:id | Soft-delete group (set deletedAt, status=INACTIVE) | NEW |
| POST | /groups/:id/add-school | Add school to group | EXISTS |
| DELETE | /groups/:id/remove-school/:school_id | Remove school from group | EXISTS |
| POST | /groups/:id/admin/assign | Assign or create Group Admin user for this group | NEW |
| PUT | /groups/:id/admin/reset-password | Reset Group Admin password | NEW |
| PUT | /groups/:id/admin/deactivate | Deactivate Group Admin | NEW |
| GET | /groups/:id/stats | Get group aggregate stats | NEW |

#### Request/Response Shapes

**GET /groups** (enhanced)
```
Query: ?page=1&limit=20&search=dps&status=ACTIVE&state=Delhi
Response: {
  success: true,
  data: {
    data: [
      {
        id: "uuid",
        name: "DPS Group",
        slug: "dps-group",
        type: "franchise",
        contact_person: "Mr. Sharma",
        contact_email: "admin@dps.edu.in",
        contact_phone: "+919876543210",
        logo_url: "https://...",
        city: "New Delhi",
        state: "Delhi",
        country: "India",
        status: "active",
        school_count: 15,
        student_count: 12500,
        teacher_count: 890,
        mrr: 245000,
        group_admin: { user_id: "uuid", name: "Mr. Sharma", email: "admin@dps.edu.in" } | null,
        schools: [
          { id: "uuid", name: "DPS Mathura Road", code: "DPSMR", city: "New Delhi", status: "active" }
        ]
      }
    ],
    pagination: { page: 1, limit: 20, total: 5, totalPages: 1 }
  }
}
```

**GET /groups/:id** (new)
```
Response: {
  success: true,
  data: {
    id: "uuid",
    name: "DPS Group",
    slug: "dps-group",
    type: "franchise",
    description: "Delhi Public School network",
    contact_person: "Mr. Sharma",
    contact_email: "admin@dps.edu.in",
    contact_phone: "+919876543210",
    logo_url: null,
    address: "Mathura Road",
    city: "New Delhi",
    state: "Delhi",
    country: "India",
    status: "active",
    group_admin: { user_id: "uuid", name: "Mr. Sharma", email: "admin@dps.edu.in" } | null,
    schools: [
      { id, name, code, city, state, status, student_count, subscription_plan, subscription_end }
    ],
    stats: {
      total_schools: 15,
      active_schools: 14,
      total_students: 12500,
      total_teachers: 890,
      mrr: 245000,
      subscription_breakdown: { BASIC: 3, STANDARD: 8, PREMIUM: 4 },
      expiring_soon: 2
    },
    created_at: "2026-01-15T...",
    updated_at: "2026-03-14T..."
  }
}
```

**POST /groups** (enhanced)
```
Body: {
  name: "DPS Group",               // required
  slug: "dps-group",               // optional, auto-generated from name if missing
  type: "franchise",               // optional
  description: "...",              // optional
  contact_person: "Mr. Sharma",   // optional
  contact_email: "admin@dps.edu", // optional
  contact_phone: "+919876543210", // optional
  logo_url: "https://...",        // optional
  address: "...",                  // optional
  city: "New Delhi",              // optional
  state: "Delhi",                 // optional
  country: "India"                // optional, default "India"
}
```

**POST /groups/:id/admin/assign** (new)
```
Body: {
  admin_email: "groupadmin@dps.edu",   // required
  first_name: "Rajesh",                // required if new user
  last_name: "Sharma",                 // optional
  phone: "+919876543210",              // optional
  password: "TempPass@123"             // optional, auto-generated if missing
}
Response: { success: true, data: { user_id, email, first_name, must_change_password: true } }
```

**DELETE /groups/:id** (new - soft delete)
```
Response: { success: true, message: "Group deactivated" }
```
Business rule: Removes groupId from all member schools. Does NOT delete schools.

### 5B. Group Admin Portal Endpoints (NEW module: /api/platform/group-admin)

All require `verifyAccessToken` + `requireGroupAdmin` middleware.

| Method | Path | Description |
|---|---|---|
| GET | /dashboard/stats | Group dashboard: aggregate stats for all schools in admin's group |
| GET | /schools | List all schools in the group with key metrics |
| GET | /schools/:id | View a single school detail (read-only) |
| GET | /reports/attendance | Group-level attendance summary |
| GET | /reports/fees | Group-level fee collection summary |
| GET | /reports/performance | Group-level exam performance summary |
| GET | /reports/comparison | Compare N schools on selected metrics |
| GET | /notifications | Group-level notifications |
| PUT | /notifications/:id/read | Mark notification read |
| GET | /profile | Get group admin profile + group info |
| PUT | /change-password | Change own password |
| GET | /export/:report_type | Export report as CSV (attendance, fees, performance) |

#### Request/Response Shapes

**GET /dashboard/stats**
```
Response: {
  success: true,
  data: {
    group: { id, name, slug, logo_url },
    total_schools: 15,
    active_schools: 14,
    total_students: 12500,
    total_teachers: 890,
    avg_attendance_rate: 87.5,
    fee_collection_rate: 92.3,
    monthly_revenue: 245000,
    schools_by_board: { CBSE: 10, ICSE: 3, "State Board": 2 },
    subscription_breakdown: { BASIC: 3, STANDARD: 8, PREMIUM: 4 },
    expiring_soon: [ { school_id, school_name, days_remaining } ],
    recent_activity: [ { type, message, timestamp } ]
  }
}
```

**GET /schools**
```
Query: ?search=&sort_by=name&sort_order=asc
Response: {
  success: true,
  data: [
    {
      id, name, code, city, state, board,
      student_count, teacher_count, status,
      subscription_plan, subscription_end,
      avg_attendance: 88.2,
      fee_collection_rate: 91.5
    }
  ]
}
```

**GET /schools/:id** (read-only)
```
Response: {
  success: true,
  data: {
    id, name, code, subdomain, board,
    email, phone, address, city, state, country, pin_code,
    logo_url, status,
    student_count, teacher_count, staff_count,
    subscription_plan, subscription_start, subscription_end,
    primary_admin: { name, email, phone },
    recent_attendance: [ { date, present, absent, total } ],
    fee_summary: { collected, pending, total }
  }
}
```

### 5C. Auth Endpoints (enhance existing)

| Method | Path | Description | Status |
|---|---|---|---|
| POST | /auth/group-admin/login | Group Admin login with email+password | ENHANCE (currently stub) |

**POST /auth/group-admin/login** (fix stub)
```
Body: {
  identifier: "admin@dps.edu",
  password: "...",
  device_fingerprint: "...",
  device_meta: { device_name, device_type, browser, os, ip_address }
}
Response (success): {
  success: true,
  data: {
    access_token: "jwt...",
    refresh_token: "jwt...",
    portal_type: "group_admin",
    user: { user_id, first_name, last_name, email, role: "group_admin" },
    group: { id, name, slug, logo_url }
  }
}
Response (requires_otp): same as smart-login OTP flow
```

**Login flow:**
1. Find user by email where role = group_admin.
2. Verify password.
3. Look up which SchoolGroup has groupAdminUserId = this user.
4. If no group found, reject: "No group assigned to this account."
5. Device fingerprint check / OTP flow (reuse smart-login).
6. Issue JWT with `portal_type: 'group_admin'`, `group_id` in claims.

---

## 6. Screen Inventory -- Super Admin Side

### 6A. Groups List Screen (EXISTS: enhance)

**File:** `lib/features/super_admin/presentation/screens/super_admin_groups_screen.dart`

**Current state:**
- Loads all groups + all schools (limit 500 -- not scalable).
- Expand/collapse per group to show member schools.
- Create Group dialog: name only.
- Edit Group dialog: name only.
- Add School to Group dialog: works.
- "Group Report" button navigates to /super-admin/schools (wrong -- should open group detail).
- No delete group.
- No pagination, no search, no filter.
- Stats (studentCount, mrr) always show 0 because backend hardcodes them.

**Changes needed:**
1. Add search bar and status filter (ACTIVE/INACTIVE/All).
2. Add pagination (load 20 groups per page).
3. Fix stats display -- backend must compute real studentCount and mrr.
4. Create Group dialog: add all new fields (type, contact person, email, phone, city, state, country, description).
5. Edit Group dialog: same fields as create.
6. Add "Delete Group" action (with confirmation dialog).
7. Add "Assign Group Admin" action per group.
8. "Group Report" button should navigate to `/super-admin/groups/:id` (new detail page).
9. Show Group Admin badge/avatar if assigned.
10. Show group status chip (ACTIVE/INACTIVE).

### 6B. Group Detail Screen (NEW)

**Route:** `/super-admin/groups/:id`

**Layout:**
- Header: group name, logo, status chip, Edit/Delete buttons.
- Stats cards row: total schools, total students, total teachers, MRR, avg attendance.
- Group Admin section: assigned admin info or "Assign Admin" button.
- Schools table: name, code, city, board, student count, status, subscription, actions (view detail).
- Add School / Remove School actions.
- Subscription breakdown chart (pie: BASIC/STANDARD/PREMIUM).

### 6C. Assign Group Admin Dialog (NEW)

**Fields:** email, first_name, last_name, phone, password (optional, auto-gen).
**Behavior:** If email already exists as a user, assign them. If not, create new user with role=group_admin.

### 6D. Enhanced Create/Edit Group Dialog

**Fields:** name (required), slug (auto-from-name, editable), type (dropdown: trust, franchise, diocesan, government, chain, other), description (textarea), contact person, contact email, contact phone, address, city, state, country (default India), logo upload URL field.

---

## 7. Screen Inventory -- Group Admin Portal (NEW)

### 7A. Group Admin Shell/Layout

**File:** `lib/features/group_admin/presentation/group_admin_shell.dart`

**Layout pattern:** Same sidebar + top-bar pattern as `SuperAdminShell`, but with different nav items:
- Dashboard
- Schools
- Reports (sub-items: Attendance, Fees, Performance, Comparison)
- Notifications
- Settings (Change Password, Profile)

**Sidebar:** Group logo + name at top. Nav items below.

### 7B. Group Admin Dashboard Screen

**Route:** `/group-admin/dashboard`
**File:** `lib/features/group_admin/presentation/screens/group_admin_dashboard_screen.dart`

**Content:**
- Welcome banner with group name and admin name.
- Stats row: Total Schools, Total Students, Total Teachers, Avg Attendance, Fee Collection Rate.
- Schools summary cards (top 5 by student count) with quick-view stats.
- Subscription status overview (expiring-soon alerts).
- Recent activity feed.

### 7C. Group Admin Schools List Screen

**Route:** `/group-admin/schools`
**File:** `lib/features/group_admin/presentation/screens/group_admin_schools_screen.dart`

**Content:**
- Data table / card list of all schools in the group.
- Columns: Name, Code, City, Board, Students, Teachers, Status, Subscription, Actions (View).
- Search by name/code.
- Sort by any column.
- Click row to open school detail (read-only).

### 7D. Group Admin School Detail Screen

**Route:** `/group-admin/schools/:id`
**File:** `lib/features/group_admin/presentation/screens/group_admin_school_detail_screen.dart`

**Content (read-only):**
- School info card: name, code, board, address, contact.
- Stats: student count, teacher count, staff count.
- Subscription info: plan, start, end, status.
- Primary admin contact info.
- Recent attendance chart (last 30 days).
- Fee collection summary.

### 7E. Group Admin Reports Screens

**Routes:**
- `/group-admin/reports/attendance`
- `/group-admin/reports/fees`
- `/group-admin/reports/performance`
- `/group-admin/reports/comparison`

**Attendance report:** Date range picker. Bar chart showing attendance % per school. Table with daily/weekly/monthly breakdown.

**Fees report:** Total collected vs pending per school. Trend chart over months.

**Performance report:** Average exam scores per school, per board. Comparison across schools.

**Comparison report:** Select 2-5 schools. Side-by-side comparison on: student count, attendance, fee collection, exam scores.

### 7F. Group Admin Login Screen (EXISTS: fix)

**File:** `lib/features/auth/group_admin_login_screen.dart`

**Current state:**
- Subdomain resolution works (routes to school login if subdomain is a school).
- Login form UI exists with Password and OTP tabs.
- `_handleLogin()` is a TODO -- does not call the API.
- OTP tab has no logic.

**Changes needed:**
1. Wire `_handleLogin()` to call `POST /auth/group-admin/login`.
2. Handle device OTP flow (same as super admin login).
3. On success, store tokens in AuthGuardProvider with `portal_type = 'group_admin'`.
4. Navigate to `/group-admin/dashboard`.
5. Handle error states (invalid credentials, no group assigned, account locked).

### 7G. Group Admin Profile/Settings Screen

**Route:** `/group-admin/settings`
**Content:** Display group info (read-only), admin profile info, change password form.

### 7H. Group Admin Notifications Screen

**Route:** `/group-admin/notifications`
**Content:** List of notifications (new school added, subscription expiring, system alerts).

---

## 8. Business Rules

### 8A. Group Creation & Management

1. Group name must be unique (case-insensitive).
2. Slug is auto-generated from name (lowercase, hyphenated, max 100 chars) but can be manually overridden. Slug must be unique.
3. Slug must not conflict with reserved subdomains: `admin`, `api`, `www`, `app`, `docs`, `help`, `support`, `billing`, `status`.
4. A school can belong to at most ONE group.
5. Adding a school to a group that already belongs to another group should fail with error "School already belongs to group X".
6. Deleting (deactivating) a group sets all member schools' groupId to NULL and sets group status to INACTIVE.
7. Group slug is used for subdomain routing: `{slug}.vidyron.in`.

### 8B. Group Admin Management

1. Only ONE Group Admin can be assigned per group (enforced by `groupAdminUserId` unique FK).
2. Assigning a new Group Admin replaces the previous one (set previous user's isActive=false, or just unlink).
3. A Group Admin user has `schoolId = NULL` and `role = group_admin`.
4. A Group Admin user MUST have `mustChangePassword = true` on initial creation.
5. Group Admin cannot access Super Admin routes. Middleware must check `portal_type`.
6. Group Admin can only see schools within their own group (enforce via group lookup on every request).

### 8C. Statistics Computation

1. `school_count`: COUNT of schools where groupId = this group AND school.status != 'INACTIVE'.
2. `student_count`: SUM of student counts across group schools. Initially use a reasonable default (e.g., school users with role=student). When student module is built, use actual enrollment counts.
3. `teacher_count`: Same approach -- count users with teacher/staff role in group schools.
4. `mrr` (Monthly Recurring Revenue): SUM of subscription plan prices for all active schools in the group. Use the plan's price field from PlatformPlan.
5. `avg_attendance_rate`: Placeholder (return 0 until attendance module is built). Design the API so it can be populated later.
6. `fee_collection_rate`: Placeholder (return 0 until fees module is built).

### 8D. Auth / Login

1. Group Admin login must verify that the user has role = `group_admin` and is linked to an active group.
2. JWT for group admin must include: `userId`, `email`, `role: 'group_admin'`, `portal_type: 'group_admin'`, `group_id`.
3. Group Admin portal routes require `requireGroupAdmin` middleware that checks JWT `portal_type === 'group_admin'`.
4. Device OTP / trusted device flow is shared with the existing smart-login system.
5. Session check must return `portal_type: 'group_admin'` for group admin sessions.

### 8E. Edge Cases

1. Creating a group with a duplicate name: return 409 Conflict.
2. Assigning a group admin who is already a super_admin: reject with 400 "User is already a super admin."
3. Assigning a group admin who is already a group_admin for another group: reject with 400 "User is already assigned to group X."
4. Deleting a group that has an active Group Admin: deactivate the admin user too.
5. School is deleted/suspended: stats should exclude it from counts.
6. Group Admin tries to access a school not in their group: return 403.
7. Empty group (0 schools): allowed, dashboard shows zeros.

---

## 9. Integration Points

### 9A. Auth Module

- `smart-login.service.js` already handles `portal_type` but does not specifically handle `group_admin`. The `findUserByIdentifier` query must be updated to support `portal_type = 'group_admin'` (users with role.name = 'group_admin', schoolId = null).
- JWT generation must include `group_id` claim for group admin tokens.
- `portal-auth.controller.js` `groupAdminLoginController` must be completed: look up user, verify password, find linked group, issue JWT.
- Flutter `AuthGuardProvider` must handle `portal_type = 'group_admin'` and store `groupId`.
- Flutter `app_router.dart` must add redirect logic: when authenticated as group_admin, redirect to `/group-admin/dashboard`.

### 9B. Super Admin Module

- `super-admin.service.js` group functions must be expanded with new fields and real stats.
- `super-admin.controller.js` must add `getGroupById`, `deleteGroup`, `assignGroupAdmin`, `resetGroupAdminPassword`, `deactivateGroupAdmin`.
- `super-admin.routes.js` must register new routes.
- Dashboard stats should include group count.

### 9C. Schools Module

- When creating a school, optionally assign to a group (already supported via groupId).
- When viewing a school, show which group it belongs to (already in model via group_id).
- School detail page should show group name if grouped.

### 9D. Billing/Subscriptions

- Group-level billing summary: aggregate subscription data across group schools.
- Future: group-level bulk subscription renewal.

### 9E. Notifications

- When a school's subscription is about to expire and it belongs to a group, notify the Group Admin.
- When a school is added/removed from a group, notify the Group Admin.

### 9F. Future Modules

- Attendance, Fees, Exams modules (not yet built) should expose aggregation queries that the Group Admin portal can call.
- Design Group Admin report endpoints to return placeholder data now, with clear interfaces for future population.

---

## 10. Migration Plan

### 10A. Database Migration: Expand SchoolGroup

**Migration name:** `20260314100000_expand_school_groups`

```sql
-- Add new columns to school_groups
DO $$
BEGIN
    -- slug
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'slug') THEN
        ALTER TABLE "school_groups" ADD COLUMN "slug" VARCHAR(100);
    END IF;

    -- type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'type') THEN
        ALTER TABLE "school_groups" ADD COLUMN "type" VARCHAR(50);
    END IF;

    -- description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'description') THEN
        ALTER TABLE "school_groups" ADD COLUMN "description" TEXT;
    END IF;

    -- contact_person
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'contact_person') THEN
        ALTER TABLE "school_groups" ADD COLUMN "contact_person" VARCHAR(255);
    END IF;

    -- contact_email
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'contact_email') THEN
        ALTER TABLE "school_groups" ADD COLUMN "contact_email" VARCHAR(255);
    END IF;

    -- contact_phone
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'contact_phone') THEN
        ALTER TABLE "school_groups" ADD COLUMN "contact_phone" VARCHAR(20);
    END IF;

    -- logo_url
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'logo_url') THEN
        ALTER TABLE "school_groups" ADD COLUMN "logo_url" TEXT;
    END IF;

    -- address
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'address') THEN
        ALTER TABLE "school_groups" ADD COLUMN "address" TEXT;
    END IF;

    -- city
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'city') THEN
        ALTER TABLE "school_groups" ADD COLUMN "city" VARCHAR(100);
    END IF;

    -- state
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'state') THEN
        ALTER TABLE "school_groups" ADD COLUMN "state" VARCHAR(100);
    END IF;

    -- country
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'country') THEN
        ALTER TABLE "school_groups" ADD COLUMN "country" VARCHAR(100) DEFAULT 'India';
    END IF;

    -- status (enum)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'group_status_enum') THEN
        CREATE TYPE "group_status_enum" AS ENUM ('ACTIVE', 'INACTIVE');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'status') THEN
        ALTER TABLE "school_groups" ADD COLUMN "status" "group_status_enum" NOT NULL DEFAULT 'ACTIVE';
    END IF;

    -- group_admin_user_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'group_admin_user_id') THEN
        ALTER TABLE "school_groups" ADD COLUMN "group_admin_user_id" UUID;
    END IF;

    -- deleted_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_groups' AND column_name = 'deleted_at') THEN
        ALTER TABLE "school_groups" ADD COLUMN "deleted_at" TIMESTAMPTZ(6);
    END IF;
END $$;

-- Unique index on slug
CREATE UNIQUE INDEX IF NOT EXISTS "school_groups_slug_key" ON "school_groups" ("slug") WHERE "slug" IS NOT NULL;

-- Unique constraint on group_admin_user_id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'school_groups_group_admin_user_id_key' AND table_name = 'school_groups'
    ) THEN
        ALTER TABLE "school_groups" ADD CONSTRAINT "school_groups_group_admin_user_id_key" UNIQUE ("group_admin_user_id");
    END IF;
END $$;

-- Foreign key: group_admin_user_id -> users.id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'school_groups_group_admin_user_id_fkey' AND table_name = 'school_groups'
    ) THEN
        ALTER TABLE "school_groups" ADD CONSTRAINT "school_groups_group_admin_user_id_fkey"
            FOREIGN KEY ("group_admin_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

-- Seed group_admin role
INSERT INTO roles (name, description, scope)
VALUES ('group_admin', 'Group administrator overseeing multiple schools', 'GLOBAL')
ON CONFLICT (name) DO NOTHING;
```

### 10B. Prisma Schema Update

Update `schema.prisma` to match the expanded SchoolGroup model. See Section 4A.

### 10C. Migration order

1. Run SQL migration to add columns.
2. Update `schema.prisma` to match.
3. Run `npx prisma generate` to regenerate client.
4. Deploy backend code changes.
5. Deploy Flutter code changes.

---

## Appendix A: File Inventory

### Files to CREATE

| File | Purpose |
|---|---|
| `backend/prisma/migrations/20260314100000_expand_school_groups/migration.sql` | DB migration |
| `backend/src/modules/group-admin/group-admin.controller.js` | Group Admin API handlers |
| `backend/src/modules/group-admin/group-admin.service.js` | Group Admin business logic |
| `backend/src/modules/group-admin/group-admin.repository.js` | Group Admin data access |
| `backend/src/modules/group-admin/group-admin.routes.js` | Group Admin route definitions |
| `backend/src/modules/group-admin/group-admin.validation.js` | Request validation schemas |
| `backend/src/middleware/group-admin-guard.middleware.js` | requireGroupAdmin middleware |
| `lib/features/group_admin/presentation/group_admin_shell.dart` | Shell layout |
| `lib/features/group_admin/presentation/screens/group_admin_dashboard_screen.dart` | Dashboard |
| `lib/features/group_admin/presentation/screens/group_admin_schools_screen.dart` | Schools list |
| `lib/features/group_admin/presentation/screens/group_admin_school_detail_screen.dart` | School detail |
| `lib/features/group_admin/presentation/screens/group_admin_reports_screen.dart` | Reports hub |
| `lib/features/group_admin/presentation/screens/group_admin_attendance_report_screen.dart` | Attendance |
| `lib/features/group_admin/presentation/screens/group_admin_fees_report_screen.dart` | Fees |
| `lib/features/group_admin/presentation/screens/group_admin_performance_report_screen.dart` | Performance |
| `lib/features/group_admin/presentation/screens/group_admin_comparison_screen.dart` | Comparison |
| `lib/features/group_admin/presentation/screens/group_admin_notifications_screen.dart` | Notifications |
| `lib/features/group_admin/presentation/screens/group_admin_settings_screen.dart` | Settings |
| `lib/core/services/group_admin_service.dart` | Group Admin API service |
| `lib/models/group_admin/group_admin_models.dart` | Models barrel |
| `lib/models/group_admin/group_dashboard_model.dart` | Dashboard stats model |
| `lib/models/group_admin/group_school_model.dart` | School model for group admin |
| `lib/widgets/super_admin/dialogs/assign_group_admin_dialog.dart` | Assign admin dialog |

### Files to MODIFY

| File | What to change |
|---|---|
| `backend/prisma/schema.prisma` | Expand SchoolGroup, add GroupStatus enum, add User relation |
| `backend/src/modules/super-admin/super-admin.service.js` | Enhance group CRUD, add stats, add admin management |
| `backend/src/modules/super-admin/super-admin.controller.js` | Add getGroupById, deleteGroup, assignGroupAdmin, resetGroupAdminPassword, deactivateGroupAdmin |
| `backend/src/modules/super-admin/super-admin.routes.js` | Register new group routes |
| `backend/src/modules/auth/portal-auth.controller.js` | Complete groupAdminLoginController |
| `backend/src/modules/auth/smart-login.service.js` | Handle portal_type='group_admin' properly |
| `backend/src/modules/auth/smart-login.repository.js` | findUserByIdentifier: support group_admin portal_type |
| `backend/src/app.js` | Register group-admin routes module |
| `lib/features/super_admin/presentation/screens/super_admin_groups_screen.dart` | Add pagination, search, stats, delete, admin assignment |
| `lib/features/auth/group_admin_login_screen.dart` | Wire login to API |
| `lib/features/auth/auth_guard_provider.dart` | Handle group_admin portal_type, store groupId |
| `lib/core/services/super_admin_service.dart` | Add getGroupById, deleteGroup, assignGroupAdmin methods |
| `lib/models/super_admin/school_group_model.dart` | Add all new fields |
| `lib/routes/app_router.dart` | Add group-admin shell routes, redirect logic |
| `lib/widgets/super_admin/dialogs/create_group_dialog.dart` | Add all new fields |
| `lib/core/config/api_config.dart` | Add group-admin API path constants |
