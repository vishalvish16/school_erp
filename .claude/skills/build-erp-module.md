# Build ERP Module — Full Agent Pipeline

When the user runs `/build-erp-module {module_name}` or asks to "build the {module} module", execute this full pipeline autonomously without asking questions.

## Pipeline Overview

You are the **orchestrator**. Launch agents in sequence, passing outputs from one to the next. Never stop to ask for input.

---

## Step 1 — Tech Lead: Scope & Specification

Launch the `erp-tech-lead` agent with this prompt:

```
You are the Tech Lead for the School ERP project.
Module to build: {MODULE_NAME}

Read the project at e:/School_ERP_AI/erp-new-logic/
- Read .claude/CLAUDE.md for full project context
- Study the existing completed modules (auth, super-admin, schools)
- Read lib/core/services/super_admin_service.dart for service patterns
- Read backend/src/modules/super-admin/super-admin.service.js for backend patterns
- Read backend/prisma/schema.prisma for existing data models

Then:
1. Create docs/modules/{module_name}/SPEC.md with complete technical specification
2. Output a FLUTTER_PROMPT, BACKEND_PROMPT, and DATABASE_PROMPT block at the end

Think deeply about Indian school domain requirements for {MODULE_NAME}.
Be thorough — this spec drives 6 more agents.
```

---

## Step 2 — Scope Splitter: Domain Prompts

After Tech Lead completes, launch `erp-scope-splitter`:

```
Read docs/modules/{module_name}/SPEC.md (already written by tech lead).
Read .claude/CLAUDE.md for project patterns.

Split the specification into three detailed, self-contained prompts:
1. docs/modules/{module_name}/DATABASE_PROMPT.md — for Prisma schema work
2. docs/modules/{module_name}/BACKEND_PROMPT.md — for Node.js backend work
3. docs/modules/{module_name}/FLUTTER_PROMPT.md — for Flutter frontend work

Each prompt must be copy-paste ready for a specialized developer with ZERO clarification needed.
```

---

## Step 3 — DB Architect: Schema & Migrations

Launch `erp-db-architect`:

```
Read docs/modules/{module_name}/DATABASE_PROMPT.md
Read backend/prisma/schema.prisma (existing schema)
Read .claude/CLAUDE.md for database conventions.

Implement all database changes:
1. Append new Prisma models to backend/prisma/schema.prisma
2. Create migration file: backend/prisma/migrations/{timestamp}_{module_name}/migration.sql

Follow ALL database conventions from the project (UUID PKs, school_id isolation, soft delete, snake_case @@map, etc.)
```

---

## Step 4 — Backend Developer: Node.js API

Launch `erp-backend-dev`:

```
Read docs/modules/{module_name}/BACKEND_PROMPT.md
Read .claude/CLAUDE.md for backend patterns.
Read these existing files for patterns:
- backend/src/modules/super-admin/super-admin.controller.js
- backend/src/modules/super-admin/super-admin.service.js
- backend/src/modules/super-admin/super-admin.repository.js
- backend/src/modules/super-admin/super-admin.routes.js

Create the complete backend module at backend/src/modules/{module_name}/:
- {module_name}.controller.js
- {module_name}.service.js
- {module_name}.repository.js
- {module_name}.routes.js
- {module_name}.validation.js

Also update backend/src/app.js to register the new routes.
Follow ALL patterns exactly — multi-tenant isolation, soft delete, pagination, audit logging.
```

---

## Step 5 — Flutter Developer: Screens & State

Launch `erp-flutter-dev`:

```
Read docs/modules/{module_name}/FLUTTER_PROMPT.md
Read .claude/CLAUDE.md for Flutter patterns.
Read .claude/agents/erp-flutter-dev.md — ALL rules apply, especially RULE 5 (glassmorphism).
Read these existing files for patterns:
- lib/core/services/super_admin_service.dart
- lib/features/super_admin/presentation/screens/super_admin_schools_screen.dart
- lib/features/super_admin/presentation/super_admin_shell.dart  ← glass sidebar/drawer pattern
- lib/widgets/super_admin/super_admin_dialogs.dart               ← showAdaptiveModal (glass bottom sheet)
- lib/widgets/super_admin/notifications_bell_button.dart         ← top-anchored popover glass pattern
- lib/features/auth/auth_guard_provider.dart
- lib/core/config/api_config.dart
- lib/routes/app_router.dart

Create complete Flutter implementation:
1. lib/core/services/{module_name}_service.dart — all API methods
2. lib/models/{module_name}/ — all Dart models with fromJson/toJson
3. lib/features/{module_name}/data/{module_name}_provider.dart — Riverpod state
4. lib/features/{module_name}/presentation/screens/ — all screens
5. lib/features/{module_name}/presentation/widgets/ — dialogs and components

Update:
- lib/core/config/api_config.dart — add endpoint constants
- lib/routes/app_router.dart — add new routes

GLASSMORPHISM MANDATORY RULES (RULE 5 — erp-flutter-dev.md):
- Never set Scaffold(backgroundColor: ...) — always transparent
- All card/panel surfaces use t.cardBg from AppThemeTokens
- Sidebars/topbars: ClipRect > BackdropFilter(blur 24) > Container(white.15 / dark.88)
- Mobile bottom sheets: always showAdaptiveModal — never raw showModalBottomSheet with opaque container
- Mobile drawers: Drawer(backgroundColor: transparent) + BackdropFilter glass
- Dialogs: barrierColor must be Colors.black.withValues(alpha: 0.35) — never a solid color
- Add import 'dart:ui' as ui; when using ui.ImageFilter.blur
- Run RULE 5G glass preflight checklist before declaring done
```

---

## Step 5.5 — UI/UX Reviewer: Visual Quality & Design System

Launch `erp-ui-ux-reviewer`:

```
Read .claude/agents/erp-ui-ux-reviewer.md — ALL rules apply.

Review and FIX all Flutter UI/UX for the {module_name} module.

Target files:
- lib/features/{module_name}/presentation/screens/ (all screens)
- lib/features/{module_name}/presentation/widgets/ (all dialogs, components)
- lib/features/{module_name}/presentation/*_shell.dart (if shell was created)

Reference implementations to read FIRST:
- lib/features/super_admin/presentation/super_admin_shell.dart
- lib/features/super_admin/presentation/screens/super_admin_schools_screen.dart
- lib/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart
- lib/features/super_admin/presentation/screens/super_admin_billing_screen.dart
- lib/shared/widgets/metric_stat_card.dart
- lib/shared/widgets/list_table_view.dart
- lib/shared/widgets/list_screen_mobile_toolbar.dart
- lib/shared/widgets/mobile_infinite_scroll.dart

For EVERY screen:
1. Audit header section (wide Wrap + narrow ListScreenMobileHeader)
2. Audit stats row (MetricStatCard — wide Row/Expanded, narrow horizontal ListView 148px tiles)
3. Audit filter section (wide Card+Wrap, narrow ListScreenMobileFilterStrip)
4. Audit table/list (ListTableView in ConstrainedBox wide, MobileInfiniteScrollList narrow)
5. Audit mobile cards (InkWell card tap + HoverPopupMenu ⋮, no bottom buttons, AppColors status chips)
6. Audit empty/error/loading states
7. Audit all token usage (no raw hex colors, no raw SizedBox, no kIsWeb, AppStrings for all text)
8. Audit glassmorphism (no opaque backgrounds, showAdaptiveModal for modals)
9. Audit touch targets (≥44px interactive elements)
10. Audit toast notifications (AppToast only, no showSnackBar)

Fix EVERY issue found. Output a UI/UX review report.
```

---

## Step 6 — Code Reviewer: Quality & Consistency

Launch `erp-code-reviewer`:

```
Review ALL new code created for the {module_name} module.

Check these files:
- backend/src/modules/{module_name}/ (all files)
- lib/core/services/{module_name}_service.dart
- lib/models/{module_name}/ (all files)
- lib/features/{module_name}/ (all files)
- Verify updates to backend/src/app.js, lib/routes/app_router.dart, lib/core/config/api_config.dart

Compare patterns against:
- backend/src/modules/super-admin/super-admin.service.js
- lib/core/services/super_admin_service.dart

Fix every inconsistency you find. Output a review report.
```

---

## Step 7 — Security Reviewer: Vulnerability Audit

Launch `erp-security-reviewer`:

```
Perform security audit on all new {module_name} module code.

Priority checks:
1. CRITICAL: Multi-tenant isolation — every DB query uses req.user.school_id
2. HIGH: Ownership verification on single-record endpoints
3. HIGH: Role-based access control on mutation endpoints
4. HIGH: No sensitive data (password hashes) in API responses
5. MEDIUM: Input validation completeness
6. MEDIUM: Soft delete consistency
7. LOW: Audit logging on all mutations

Fix every vulnerability found. Output security report.
```

---

## Step 8 — QA Tester: Test Suite

Launch `erp-qa-tester`:

```
Create comprehensive tests for the {module_name} module:

1. backend/tests/{module_name}/{module_name}.test.mjs — API integration tests
2. backend/tests/{module_name}/{module_name}.service.test.mjs — Unit tests
3. test/features/{module_name}/{module_name}_screen_test.dart — Flutter widget tests

Cover: CRUD, authentication, authorization, tenant isolation, validation, pagination, soft delete.

After creating tests, attempt to run:
- cd e:/School_ERP_AI/erp-new-logic/backend && node tests/{module_name}/{module_name}.smoke.mjs (if server is running)

Report results.
```

---

## Step 9 — Doc Writer: Documentation

Launch `erp-doc-writer`:

```
Write complete documentation for the {module_name} module.

Read all implemented files:
- backend/src/modules/{module_name}/ (all files)
- lib/features/{module_name}/ (all files)
- docs/modules/{module_name}/SPEC.md

Create:
1. docs/modules/{module_name}/README.md
2. docs/modules/{module_name}/API_DOCS.md
3. docs/modules/{module_name}/DEVELOPER_GUIDE.md
4. docs/modules/{module_name}/DATA_MODEL.md
```

---

## Final Report

After all 9 agents complete, output:

```
## ✅ {Module Name} Module — Build Complete

### Deliverables
| Layer | Files Created | Status |
|-------|--------------|--------|
| Database | schema.prisma (updated), migration.sql | ✅ |
| Backend | controller, service, repository, routes, validation | ✅ |
| Flutter | service, models, providers, screens, widgets | ✅ |
| Tests | API tests, unit tests, widget tests | ✅ |
| Docs | README, API docs, Dev guide, Data model | ✅ |

### Code Review: {Good/Excellent}
### Security: {N critical, N high, N medium issues — all fixed}
### Tests: {N passed / N total}

### Next Steps
- [ ] Run `npx prisma migrate dev` to apply database changes
- [ ] Restart backend server
- [ ] Run `flutter pub get` if new packages added
- [ ] Add module link to school admin sidebar navigation
- [ ] Set up feature flags for this module (optional)
```
