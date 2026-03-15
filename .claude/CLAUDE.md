# School ERP AI - Project Context for Claude Code

## Project Overview
Multi-tenant SaaS School Management Platform — **Vidyron** (vidyron.in)
- **Frontend**: Flutter (Dart) — web, iOS, Android — using Riverpod + GoRouter
- **Backend**: Node.js/Express + Prisma ORM
- **Database**: PostgreSQL
- **Architecture**: 8 portals — Super Admin, Group Admin, School Admin, Staff/Clerk, Teacher, Parent, Student, Driver

## Working Directory
- Root: `e:/School_ERP_AI/erp-new-logic/`
- Backend: `backend/` (Node.js)
- Frontend: `lib/` (Flutter/Dart)
- Database: `backend/prisma/schema.prisma`
- Docs: `docs/`
- Module docs: `docs/modules/{module_name}/`
- Master Plan: `E:\School_ERP_Documents\School_ERP_Master_Plan_v7_Final`

## 8 Portals
| Portal | URL | Users |
|--------|-----|-------|
| Super Admin | admin.vidyron.in | Platform owners |
| Group Admin | {groupname}.vidyron.in | Chain school owners (read-only cross-school) |
| School Admin | {schoolname}.vidyron.in | Principal, Head Admin |
| Staff/Clerk | {schoolname}.vidyron.in | Office staff |
| Teacher/Faculty | {schoolname}.vidyron.in | Teachers |
| Parent | vidyron.in/login | Parents/guardians |
| Student | vidyron.in/login | Students (Class 9+) |
| Driver | Mobile app | Bus drivers (Transport module) |

## Completed Modules
- **Auth**: Login (all 8 portals), device OTP, 2FA TOTP, biometric, trusted devices, password reset, auto-lock
- **Super Admin Portal**: Dashboard, Schools CRUD, Groups, Plans, Billing, Features, Hardware, Admins, Audit Logs, Security, Infra, Notifications, Change Password
- **Group Admin Portal**: Dashboard, Schools list, Analytics (school comparison), Reports (multi-tab), Notifications, Profile, Change Password

## Remaining Modules to Build (School Portal — Priority Order)
1. School Admin Dashboard
2. Student Module (enrollment, profile, documents, transfers)
3. Teacher/Staff Module (profile, subjects, schedule)
4. Classes & Sections Module
5. Attendance Module (students + staff, RFID-ready)
6. Fees & Finance Module (fee structure, collection, receipts, Razorpay)
7. Examinations Module (schedules, marks entry, result cards)
8. Timetable Module (weekly schedule builder)
9. Library Module (books, issue/return)
10. Transport Module (buses, routes, GPS — Phase 2)
11. Hostel Module (rooms, boarding students)
12. HR/Payroll Module (salary, leaves)
13. Reports & Analytics Module
14. Communications/Messaging Module
15. Parent Portal
16. Staff/Teacher Portal
17. Driver App (Phase 2 — RFID + GPS)

## Key Architecture Patterns

### Flutter Patterns
- **State**: Riverpod (`StateNotifierProvider`, `FutureProvider`, `Provider`)
- **Navigation**: GoRouter with shell routes and auth guards
- **HTTP**: Dio client with JWT interceptor (see `lib/core/network/dio_client.dart`)
- **Auth token**: Read from `ref.read(authGuardProvider).accessToken`
- **Folder**: `lib/features/{feature}/presentation/screens/`, `/data/`, `/domain/`
- **Services**: All API calls in `lib/core/services/{module}_service.dart`
- **Design System**: Use widgets from `lib/design_system/` — AppColors, AppTextStyles, AppSpacing, AppButtons, AppInputs

### Backend Patterns
- **Module structure**: `controller.js` → `service.js` → `repository.js` + `routes.js` + `validation.js`
- **Auth guard**: `verifyAccessToken` middleware on all protected routes
- **School-scoped**: `req.user.school_id` for tenant isolation
- **Response**: `{ success: true, data: {...}, message: "..." }` or `{ success: false, error: "..." }`
- **Error**: `throw new AppError('message', statusCode)` — caught by errorHandler middleware
- **Pagination**: `?page=1&limit=20&search=...&sortBy=field&sortOrder=asc`
- **API Base**: `/api/platform/` for super admin, `/api/group/` for group admin, `/api/school/` for school portal

### Database Patterns
- **ORM**: Prisma with PostgreSQL
- **IDs**: UUID via `@default(uuid())` for main entities, BigInt for plans
- **Soft delete**: `deletedAt DateTime?` on user-facing entities
- **Audit**: `createdAt @default(now())`, `updatedAt @updatedAt`
- **Tenant isolation**: `school_id` FK on all school-scoped models
- **Migrations**: Named `YYYYMMDDHHMMSS_description`

### Token / Auth Rules
- Staff/Admin/Teacher: 4-hour access token, 7-day refresh
- Parents: 24-hour access token
- Trusted devices: 30-day refresh (after device OTP verification)
- OTP: 6-digit, 2-minute expiry, single-use, max 3 attempts

## Agent Pipeline

When building a new module, invoke agents in this order:
1. `/erp-tech-lead` — Scope & spec creation
2. `/erp-scope-splitter` — Split spec into frontend/backend/database tasks
3. `/erp-db-architect` — Schema + migrations
4. `/erp-backend-dev` — Node.js API module
5. `/erp-flutter-dev` — Flutter screens + state
6. `/erp-code-reviewer` — Code quality review
7. `/erp-security-reviewer` — Security audit
8. `/erp-qa-tester` — Testing
9. `/erp-doc-writer` — Documentation

Or use the all-in-one: `/build-erp-module {module_name}`

## Critical Files Reference
- `lib/core/services/auth_service.dart` — Auth API calls
- `lib/core/services/super_admin_service.dart` — Pattern for all API service files
- `lib/core/services/group_admin_service.dart` — Group Admin API pattern
- `lib/features/auth/auth_guard_provider.dart` — Token lifecycle (copy this pattern)
- `lib/features/super_admin/presentation/super_admin_shell.dart` — Shell layout pattern
- `lib/features/group_admin/presentation/group_admin_shell.dart` — Group Admin shell pattern
- `lib/routes/app_router.dart` — Add new routes here
- `lib/core/config/api_config.dart` — Add new endpoint constants here
- `backend/src/app.js` — Register new route modules here
- `backend/src/middleware/auth.middleware.js` — Auth middleware
- `backend/src/middleware/group-admin-guard.middleware.js` — Group Admin guard
- `backend/prisma/schema.prisma` — Database schema
