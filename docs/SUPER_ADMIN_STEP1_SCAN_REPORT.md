# VIDYRON — Super Admin STEP 1 Scan Report

> **Generated:** Before any implementation. All findings below.

---

## 1A. Existing Flutter Files

### lib/screens/super_admin/
**Status:** ❌ **DOES NOT EXIST**
- No `lib/screens/super_admin/` directory found
- No super admin screens exist yet

### lib/features/settings/
**Status:** ✅ **EXISTS — PRESERVE ALL**
| File | Purpose |
|------|---------|
| `settings_screen.dart` | Main settings UI |
| `settings_provider.dart` | Riverpod state |
| `settings_state.dart` | State model |

**CRITICAL — DO NOT REMOVE:**
- ✅ **Biometric Login** — Toggle at lines 56–72 (`Icons.fingerprint_rounded`, `toggleBiometric`)
- ✅ **Auto-Lock Session** — Toggle at lines 76–88 (`Icons.security_rounded`, `toggleAutoLock`, "30 minutes of inactivity")
- ⚠️ **Screen timeout on/off** — Not found as separate toggle; Auto-Lock may serve this purpose. Verify with user.
- ✅ **Theme** — Handled by `ThemeToggleButton` + `ThemeNotifier` in design_system (see below)

### lib/models/ (and lib/features/*/domain/models/)
**Status:** ✅ **PARTIAL**
| Path | Files |
|------|-------|
| `lib/models/` | `school_identity.dart` |
| `lib/features/schools/domain/models/` | `school_model.dart`, `pagination_model.dart`, `subscription_models.dart` |
| `lib/features/subscription/data/models/` | `plan_model.dart` |
| `lib/shared/models/` | `sidebar_menu_model.dart` |

**No super_admin models** — Need: `PlanModel`, `SchoolGroupModel`, `SchoolModel` (extend), `SchoolSubscriptionModel`, `HardwareDeviceModel`, `SuperAdminUserModel`, `PlatformFeatureModel`, `AuditLogModel`, `DashboardStatsModel`, `PlanDistributionModel`

### lib/services/ (and lib/core/services/)
**Status:** ✅ **PARTIAL**
| Path | Files |
|------|-------|
| `lib/core/services/` | `auth_service.dart`, `biometric_service.dart`, `local_storage_service.dart`, `secure_storage_service.dart` |
| `lib/features/subscription/data/services/` | `plan_service.dart` |

**No SuperAdminService** — Need: `lib/core/services/super_admin_service.dart` or `lib/features/super_admin/data/services/super_admin_service.dart`

### lib/widgets/ (and lib/design_system/widgets/, lib/shared/widgets/)
**Status:** ✅ **EXISTS**
| Path | Files |
|------|-------|
| `lib/widgets/` | `school_identity_banner.dart`, `group_identity_banner.dart`, `widgets.dart` |
| `lib/design_system/widgets/` | `app_card_container.dart`, `app_buttons.dart`, `app_inputs.dart`, `app_logo.dart`, `app_loading_overlay.dart`, `theme_toggle_button.dart`, `responsive_wrapper.dart`, `responsive_frame.dart` |
| `lib/shared/widgets/` | `inactivity_wrapper.dart`, `reusable_data_table.dart`, `widgets.dart` |
| `lib/features/subscription/presentation/widgets/` | `plan_dialog.dart` |

**No super_admin widgets** — Need: `stat_card_widget`, `school_list_tile_widget`, `plan_select_card_widget`, `toggle_feature_row_widget`, `audit_log_tile_widget`, `hardware_status_dot_widget`, `section_label_widget`, `plan_distribution_bar_widget`, `adaptive_page_header_widget`, plus dialogs in `lib/widgets/super_admin/dialogs/`

### pubspec.yaml — Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| flutter | sdk | Core |
| flutter_riverpod | ^2.5.1 | State management |
| provider | ^6.1.2 | ThemeNotifier |
| go_router | ^17.1.0 | Routing |
| dio | ^5.9.1 | HTTP |
| shared_preferences | ^2.5.4 | Local storage |
| local_auth | ^3.0.0 | Biometric |
| flutter_secure_storage | ^10.0.0 | Secure storage |
| google_fonts | ^6.2.1 | Typography |
| intl | ^0.20.2 | i18n |
| crypto | ^3.0.3 | Hashing |
| gif_view | ^1.0.3 | GIF display |

**Missing for Super Admin:** `shimmer` (optional, for loading), no other critical gaps.

### State Management Pattern
**Pattern:** **Riverpod** (primary) + **Provider** (ThemeNotifier only)
- `flutter_riverpod` for auth, settings, schools, subscriptions
- `provider` for `ThemeNotifier` in `main.dart`
- Use `ConsumerWidget`, `ConsumerStatefulWidget`, `StateNotifierProvider`, `FutureProvider`

---

## 1B. Existing API Routes

### Base
- **Prefix:** `/api/platform`
- **Auth:** Bearer token (assumed from auth flow)

### Super Admin Routes
**Status:** ❌ **NO DEDICATED /super-admin/* ROUTES**
- No `/api/v1/super-admin/` or `/api/platform/super-admin/` base

### Schools Routes
**Status:** ✅ **EXISTS**
| Route | Method | Module |
|-------|--------|--------|
| `/api/platform/schools` | GET, POST | schools.routes.js |
| `/api/platform/schools/:id` | GET, PUT, DELETE | schools.routes.js |
| `/api/platform/schools/:id/assign-plan` | PUT | schools.repository / schools |
| `/api/platform/schools/:id/analytics` | GET | schools |
| `/api/public/schools/search` | GET | schools.public.controller (no auth) |

### Billing Routes
**Status:** ⚠️ **PARTIAL — via subscription**
| Route | Method | Module |
|-------|--------|--------|
| `/api/platform/subscriptions` | (check) | subscription.routes.js |
| `/api/platform/plans` | GET, etc. | plans.routes.js |

**Missing:** `/billing`, `/billing/:school_id/renew`, `/billing/:school_id/assign-plan`, `/billing/:school_id/resolve-overdue`

### Plans Routes
**Status:** ✅ **EXISTS**
| Route | Method | Module |
|-------|--------|--------|
| `/api/platform/plans` | (check) | plans.routes.js |

**Missing:** Full CRUD + `/plans/:id/change-log`, `/plans/:id/status`

### Other Missing Routes
- ❌ `/groups` — not found
- ❌ `/features/platform`, `/features/school/:school_id` — not found
- ❌ `/hardware` — not found
- ❌ `/admins` (super admins) — not found
- ❌ `/audit/*` (schools, plans, billing, features, security, hardware, groups, super-admin) — not found
- ❌ `/security/events`, `/security/devices`, `/security/block-ip` — not found
- ❌ `/infra/status` — not found

---

## 1C. Database Schema (Prisma vs Prompt)

**Note:** The project uses **Prisma** with **BIGINT** IDs. The prompt's SQL uses **UUID**. Adjust migrations if DB uses BIGINT.

### Prisma schema (current)
- `PlatformPlan` (platform_plans) — exists
- `School` — has subdomain, planId, subscriptionStart/End; **missing:** group_id, student_limit, overdue_days, status enum, pin_code, school_type, established_year, deleted_at, created_by
- `SchoolSubscription` — exists (school_subscriptions)
- `User` — exists (users)
- `user_sessions` — exists
- **No:** `school_groups`, `school_features`, `billing` (separate), `audit_logs`, `plans` (prompt's plans table), `plan_features`, `platform_features`, `super_admins`, `school_admins`, `plan_change_log`, `hardware_devices`, 7 audit tables

### Smart Login / Addon Tables (migrations)
- `auth_sessions`, `otp_verifications`, `registered_devices`, `login_attempts` — in `add_smart_login_*.sql`
- `school_features`, `billing` — may exist in migrations; check `add_smart_login_public.sql`, `add_smart_login_20260307.sql`

---

## 1D. Theme & Settings Preservation

| Item | Location | Status |
|------|----------|--------|
| Biometric on/off | `lib/features/settings/settings_screen.dart` L56–72 | ✅ PRESERVE |
| Screen timeout (Auto-Lock) | `lib/features/settings/settings_screen.dart` L76–88 | ✅ PRESERVE |
| Light/Dark theme | `lib/design_system/tokens/theme.dart` + `ThemeToggleButton` | ✅ PRESERVE |

---

## 1E. Existing Flutter Routes (app_router.dart)

| Path | Screen |
|------|--------|
| `/splash` | SplashScreen |
| `/login` | LoginScreen |
| `/school-setup` | SchoolSetupScreen |
| `/login/group`, `/login/school`, `/login/staff`, `/login/parent`, `/login/student` | Auth screens |
| `/forgot-password`, `/reset-password`, `/device-verification` | Auth recovery |
| `/dashboard` | DashboardScreen |
| `/schools`, `/schools/:id` | SchoolsScreen, PlatformSchoolDetailPage |
| `/plans` | SubscriptionPage |
| `/branches`, `/users`, `/roles`, `/modules`, `/subscriptions`, `/revenue`, `/audit-logs`, `/system-health` | Placeholder Scaffolds |
| `/settings` | SettingsScreen |

**No `/super-admin/*` routes** — Add as per STEP 9.

---

## Summary Checklist for Implementation

| Area | Status | Action |
|------|--------|--------|
| Super Admin screens | ❌ Missing | Create all 12 screens |
| Settings (biometric, timeout, theme) | ✅ Exists | **DO NOT REMOVE** |
| Models | ⚠️ Partial | Add super_admin models |
| Services | ⚠️ Partial | Add SuperAdminService |
| Widgets | ⚠️ Partial | Add super_admin widgets + dialogs |
| API routes | ⚠️ Partial | Add super-admin routes, groups, billing, features, hardware, admins, audit, security, infra |
| Database | ⚠️ Mismatch | Run migrations; align UUID vs BIGINT |
| State management | ✅ Riverpod | Follow existing pattern |
| Routing | ⚠️ Partial | Add /super-admin/* routes with guard |

---

**Next:** Proceed to STEP 2 (Database Migrations) after confirming this report.
