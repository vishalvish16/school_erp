# Parent Portal — Full Module Specification

**Purpose:** Build parent full models from login → dashboard → profile → all related models.  
**Stack:** Flutter (Riverpod, GoRouter) | Node.js/Express | Prisma/PostgreSQL  
**Date:** 2026-03-16

---

## 1. Problem Statement

The Parent Portal currently has:
- **Login UI** (`parent_login_screen.dart`) — 3-step flow (Phone → School → OTP) but no backend integration
- **Redirect** to `/dashboard/parent` — route not defined (404)
- **No Parent entity** — Student has flat `parentName`, `parentPhone`, `parentEmail`, `parentRelation`
- **No parent auth** — OTP flow does not establish JWT or session
- **No parent shell, dashboard, profile, or related screens**

**Goal:** Create a complete Parent Portal with proper Parent model, auth, shell, dashboard, profile, and related screens (children, attendance, fees, notices).

---

## 2. Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter, Riverpod, GoRouter, design_system |
| Backend | Node.js, Express, Prisma |
| Database | PostgreSQL |
| Auth | JWT (24h for parents), OTP via existing flow |

---

## 3. Database Schema

### 3.1 New Models

#### `Parent` — Full parent/guardian entity
```prisma
model Parent {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  firstName   String    @map("first_name") @db.VarChar(100)
  lastName    String    @map("last_name") @db.VarChar(100)
  phone       String    @db.VarChar(20)      // Primary login identifier
  email       String?   @db.VarChar(255)
  relation    String?   @db.VarChar(50)     // Father, Mother, Guardian
  isActive    Boolean   @default(true) @map("is_active")
  deletedAt   DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @updatedAt @map("updated_at")

  school  School           @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  links   StudentParent[]

  @@unique([schoolId, phone])
  @@index([schoolId])
  @@index([phone])
  @@map("parents")
}
```

#### `StudentParent` — Parent–Student link (many-to-many)
```prisma
model StudentParent {
  id           String   @id @default(uuid()) @db.Uuid
  studentId    String   @map("student_id") @db.Uuid
  parentId     String   @map("parent_id") @db.Uuid
  relation     String   @db.VarChar(50)    // Father, Mother, Guardian
  isPrimary    Boolean  @default(false) @map("is_primary")
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt @map("updated_at")

  student Student @relation(fields: [studentId], references: [id], onDelete: Cascade)
  parent  Parent  @relation(fields: [parentId], references: [id], onDelete: Cascade)

  @@unique([studentId, parentId])
  @@index([parentId])
  @@index([studentId])
  @@map("student_parents")
}
```

#### Updates to existing models
- **School**: Add `parents Parent[]`
- **Student**: Add `parentLinks StudentParent[]`; keep `parentName`, `parentPhone`, etc. for backward compatibility (denormalized from primary parent)

---

## 4. Auth Flow

### 4.1 Resolve by Phone (existing endpoint, extend)
- **POST** `/auth/resolve-user-by-phone`
- Body: `{ "phone": "+919876543210", "user_type": "parent" }`
- Logic: Look up `Parent` by normalized phone + school. If not found, look up `Student` by `parentPhone`, create `Parent` from student's parent fields, create `StudentParent` link.
- Response: `{ school, user: { id, name, school_id }, otp_session_id, masked_phone }`

### 4.2 Verify OTP (new or extend)
- **POST** `/auth/verify-parent-otp` (or extend existing verify-device-otp)
- Body: `{ "otp_session_id", "otp": "123456", "phone", "school_id" }`
- On success: Issue JWT with `{ parent_id, school_id, portal_type: "parent" }`, 24h expiry
- Return: `{ access_token, refresh_token, parent: { id, firstName, lastName, phone, email } }`

### 4.3 Parent Auth Guard
- Middleware: `verifyParentAccess` — requires `req.user.portal_type === 'parent'` and `req.user.parent_id`
- All `/api/parent/*` routes use this guard

---

## 5. API Contract (Backend → Frontend)

**Base path:** `/api/parent/`  
**Auth:** Bearer JWT (parent token)  
**Tenant:** `req.user.school_id`, `req.user.parent_id`

### Endpoints

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| GET | `/api/parent/profile` | — | `ParentProfileResponse` (200) |
| PATCH | `/api/parent/profile` | `{ firstName?, lastName?, email? }` | `ParentProfileResponse` (200) |
| GET | `/api/parent/children` | — | `{ children: ChildSummary[] }` (200) |
| GET | `/api/parent/children/:studentId` | — | `ChildDetailResponse` (200) or 404 |
| GET | `/api/parent/children/:studentId/attendance` | `?month=YYYY-MM&limit=31` | `{ attendances: AttendanceEntry[] }` (200) |
| GET | `/api/parent/children/:studentId/fees` | `?academic_year=2024-25` | `{ feePayments: FeePaymentSummary[], feeStructure: FeeStructureSummary[] }` (200) |
| GET | `/api/parent/notices` | `?page=1&limit=20` | `{ notices: NoticeSummary[], pagination }` (200) |
| GET | `/api/parent/notices/:id` | — | `NoticeDetailResponse` (200) or 404 |

### Response Shapes (exact JSON)

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

**AttendanceEntry:**
```json
{
  "date": "YYYY-MM-DD",
  "status": "PRESENT|ABSENT|LATE|HOLIDAY",
  "remarks": "string|null"
}
```

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

**Pagination:**
```json
{
  "page": 1,
  "limit": 20,
  "total": 50,
  "total_pages": 3
}
```

### Error Responses
- 401: `{ "success": false, "error": "You are not logged in..." }`
- 403: `{ "success": false, "error": "Access denied" }`
- 404: `{ "success": false, "error": "Child not found" }`
- 422: `{ "success": false, "error": "Validation failed", "details": [...] }`

---

## 6. Flutter Structure

### 6.1 Routes (add to app_router.dart)
- Shell: `ParentShell` at `/parent`
- Nested routes:
  - `/parent` → redirect to `/parent/dashboard`
  - `/parent/dashboard`
  - `/parent/profile`
  - `/parent/profile/edit`
  - `/parent/children`
  - `/parent/children/:id`
  - `/parent/children/:id/attendance`
  - `/parent/children/:id/fees`
  - `/parent/notices`
  - `/parent/notices/:id`

### 6.2 Auth Redirect
- When `portal_type == 'parent'` and authenticated → redirect to `/parent/dashboard`
- Protect `/parent/*` — redirect to `/login/parent` if not authenticated as parent

### 6.3 Parent Shell
- Sidebar (web) / drawer (mobile): Dashboard, My Children, Notices, Profile
- TopBar: school name, parent name, notifications icon, account menu (Profile, Logout)
- Accent: green (distinct from staff blue, teacher purple)

### 6.4 Screens
| Screen | Purpose |
|--------|---------|
| ParentDashboardScreen | Summary: children count, today's attendance, recent notices, fee dues |
| ParentProfileScreen | View/edit name, email; display phone (read-only) |
| ParentChildrenListScreen | List of linked children (cards or table) |
| ParentChildDetailScreen | Child profile, quick links to attendance/fees |
| ParentChildAttendanceScreen | Monthly attendance for one child |
| ParentChildFeesScreen | Fee structure + payment history for one child |
| ParentNoticesScreen | Paginated notices (targetRole: parent or all) |
| ParentNoticeDetailScreen | Full notice body |

### 6.5 Providers & Services
- `parent_profile_provider.dart` — load/update profile
- `parent_children_provider.dart` — list children
- `parent_service.dart` — API client for `/api/parent/*`
- `parent_auth_guard_provider.dart` — extend auth guard for parent portal_type

---

## 7. Cross-Cutting Concerns

| Concern | Owner | Detail |
|---------|-------|--------|
| Parent creation from Student | Backend | When resolve-user-by-phone finds Student by parentPhone but no Parent, create Parent + StudentParent |
| JWT payload for parent | Backend | Must include `parent_id`, `school_id`, `portal_type: 'parent'` |
| Phone normalization | Backend | E.164: +91 + 10 digits. Both sides use same format |
| Trailing slashes | Backend | Use `/api/parent/profile` (no trailing) for consistency with existing school APIs |
| Pagination | Both | Backend: `page`, `limit`, `total`, `total_pages`. Frontend: match exactly |
| Empty states | Frontend | "No children linked", "No notices", "No attendance this month" |
| aria-labels | Frontend | All interactive elements for accessibility |

---

## 8. Parent Login Integration

### 8.1 parent_login_screen.dart changes
1. Call `POST /auth/resolve-user-by-phone` in step 1 (replace mock)
2. Call `POST /auth/verify-parent-otp` in step 3 (replace mock)
3. On success: store tokens via `authGuardProvider`, set `portal_type` to parent
4. Redirect to `/parent/dashboard` (not `/dashboard/parent`)

### 8.2 Router updates
- Add `isParentRoute` for `/parent/*`
- Redirect: if `portal_type == 'parent'` and on login → `/parent/dashboard`
- Protect parent routes: require auth + portal_type parent

---

## 9. Acceptance Criteria

1. **Login**: Parent enters phone → school detected → OTP → JWT issued → redirect to parent dashboard
2. **Dashboard**: Shows children count, today's attendance summary, recent notices, fee dues
3. **Profile**: View and edit name, email; phone read-only
4. **Children**: List all linked children; tap to see detail
5. **Attendance**: View monthly attendance for each child
6. **Fees**: View fee structure and payment history per child
7. **Notices**: Paginated list of school notices for parents
8. **Auth guard**: Parent routes protected; unauthenticated → login
9. **Responsive**: Works on web (sidebar) and mobile (drawer)

---

## 10. Validation

### Database
- Run Prisma migrate
- Seed one Parent + StudentParent, verify relations

### Backend
```bash
curl -H "Authorization: Bearer <parent_jwt>" http://localhost:3000/api/parent/profile
curl -H "Authorization: Bearer <parent_jwt>" http://localhost:3000/api/parent/children
```

### Frontend
```bash
flutter analyze
flutter test
```

### End-to-End
1. Resolve by phone (use seeded parent phone)
2. Verify OTP (dev bypass or real OTP)
3. Land on dashboard
4. Open profile, edit, save
5. Open children list, tap child, view attendance and fees
6. Open notices, paginate
