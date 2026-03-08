# Mobile Addon — Step 1: Existing Code Scan Report

**Scan Date:** Per addon prompt  
**Rule:** Use existing packages — do NOT add new ones unless absolutely required.

---

## Checklist Findings

| Item | Status | Details |
|------|--------|---------|
| **SharedPreferences** | ✅ Yes | Used in: `auth_guard_provider`, `login_screen`, `login_provider`, `subdomain_resolver`, `parent_login_screen`, `settings_provider`, `auto_lock_provider` |
| **Hive** | ❌ No | Not in pubspec.yaml |
| **flutter_secure_storage** | ✅ Yes | In `lib/core/services/secure_storage_service.dart` — used for biometric credentials |
| **School selection / school code entry screen** | ❌ No | No dedicated screen. `schools_screen` has client-side search filter. `parent_login_screen` has phone auto-detect. |
| **Splash screen / app initializer** | ✅ Yes | `lib/features/auth/splash_screen.dart` — redirects to `/login` after GIF or 5s timeout |
| **Navigation/routing** | ✅ go_router | `lib/routes/app_router.dart` |
| **Search widget** | ⚠️ Partial | `schools_screen` has TextField search for filtering. No reusable debounced search widget. |
| **local storage** | shared_preferences, flutter_secure_storage | Both in pubspec |
| **http/api** | dio | In pubspec |
| **state management** | riverpod, provider | flutter_riverpod, provider |

---

## Key Observations

1. **Auth flow:** `AuthGuardNotifier` uses SharedPreferences with keys `access_token`, `is_session_locked_persistently`. No centralized LocalStorageService yet.

2. **School identity:** `SchoolIdentity` model exists in `lib/models/school_identity.dart` — id, name, code, logoUrl, board, type, studentCount, active.

3. **Backend schools API:** `GET /api/platform/schools` requires auth (platform admin). No public search endpoint for unauthenticated mobile users.

4. **Subdomain resolver:** Web-only. Uses `hostname_web.dart` / `hostname_stub.dart` for platform detection.

5. **Splash logic:** Currently always goes to `/login`. No session check or school setup decision tree.

---

## Implementation Plan

- Create `LocalStorageService` using **SharedPreferences** (existing)
- Create `SchoolSetupScreen` (new)
- Add `SearchSchoolWidget`, `PhoneDetectWidget`, `SchoolFoundBottomSheet`
- Update splash to use decision tree
- Add public `GET /schools/search` backend endpoint (no auth)
- Add `POST /auth/resolve-user-by-phone` if not exists
- Create `PortalResolver` utility
- Update login screens with `_loadSavedSchool()` for mobile
- Add "Change School" to SchoolIdentityBanner
