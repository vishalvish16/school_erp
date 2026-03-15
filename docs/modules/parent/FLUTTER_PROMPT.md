# Parent Portal — Flutter Prompt

**Purpose:** Build the Parent Portal UI — shell, dashboard, profile, children, attendance, fees, notices.  
**Target:** `lib/features/parent/` and related files  
**Date:** 2026-03-16

---

## 1. Reference Patterns

Follow these existing files exactly:

- **Shell:** `lib/features/staff/presentation/staff_shell.dart` — web sidebar + mobile drawer, TopBar, nav items
- **Profile screen:** `lib/features/staff/presentation/screens/staff_profile_screen.dart` — view/edit form, avatar header, Card layout
- **Dashboard:** `lib/features/staff/presentation/screens/staff_dashboard_screen.dart` — RefreshIndicator, stats cards, quick actions
- **Service:** `lib/core/services/staff_service.dart` — Dio-based API client, Provider pattern
- **Provider:** `lib/features/staff/presentation/providers/staff_profile_provider.dart` — StateNotifier, load/update
- **Auth guard:** `lib/features/auth/auth_guard_provider.dart` — establishSession, clearSession, portalType
- **Router:** `lib/routes/app_router.dart` — ShellRoute, redirect logic, portal_type checks
- **API config:** `lib/core/config/api_config.dart` — endpoint constants
- **Design system:** `lib/design_system/` — AppColors, AppTextStyles, AppSpacing, AppButtons, AppInputs, AppRadius, AppDialogs, AppSnackbar

**Parent accent:** Green — use `AppColors.success500` (or `success600`) for accent. Badge: "PARENT" on `AppColors.success700` background. Distinct from staff blue (#2196F3) and teacher purple.

---

## 2. Files to Create

### 2.1 Service

**File:** `lib/core/services/parent_service.dart`

**Pattern:** Follow `lib/core/services/staff_service.dart`

**Provider:**

```dart
final parentServiceProvider = Provider<ParentService>((ref) {
  final dio = ref.watch(dioProvider);
  return ParentService(dio);
});
```

**Methods:**

| Method | Endpoint | Returns |
|--------|----------|---------|
| `getDashboard()` | GET /api/parent/dashboard | `ParentDashboardModel` |
| `getProfile()` | GET /api/parent/profile | `ParentProfileModel` |
| `updateProfile(Map<String, dynamic>)` | PATCH /api/parent/profile | `ParentProfileModel` |
| `getChildren()` | GET /api/parent/children | `List<ChildSummaryModel>` |
| `getChildById(String studentId)` | GET /api/parent/children/:studentId | `ChildDetailModel` |
| `getChildAttendance(String studentId, {String? month, int? limit})` | GET /api/parent/children/:studentId/attendance | `List<AttendanceEntryModel>` |
| `getChildFees(String studentId, {String? academicYear})` | GET /api/parent/children/:studentId/fees | `Map` with `feePayments`, `feeStructure` |
| `getNotices({int page, int limit})` | GET /api/parent/notices | `Map` with `notices`, `pagination` |
| `getNoticeById(String id)` | GET /api/parent/notices/:id | `NoticeDetailModel` |

**Auth:** Use `dioProvider` which already attaches JWT from `authGuardProvider`. Ensure parent token is sent.

---

### 2.2 Models

**Folder:** `lib/models/parent/`

| File | Class | Fields |
|------|-------|--------|
| `parent_profile_model.dart` | ParentProfileModel | id, firstName, lastName, phone, email, relation, schoolId, schoolName; `fromJson`, `toJson`; getter `fullName`, `initials` |
| `child_summary_model.dart` | ChildSummaryModel | id, admissionNo, firstName, lastName, class, section, rollNo, photoUrl |
| `child_detail_model.dart` | ChildDetailModel | extends ChildSummaryModel + dateOfBirth, bloodGroup, address, parentRelation |
| `attendance_entry_model.dart` | AttendanceEntryModel | date, status, remarks |
| `fee_payment_summary_model.dart` | FeePaymentSummaryModel | id, feeHead, amount, paymentDate, receiptNo, paymentMode |
| `fee_structure_summary_model.dart` | FeeStructureSummaryModel | feeHead, amount, frequency |
| `notice_summary_model.dart` | NoticeSummaryModel | id, title, body, isPinned, publishedAt, expiresAt |
| `notice_detail_model.dart` | NoticeDetailModel | full notice (same + any extra) |
| `parent_dashboard_model.dart` | ParentDashboardModel | childrenCount, todaysAttendanceSummary, recentNotices, feeDues (or similar) |

**JSON keys:** Use snake_case in `fromJson`/`toJson` to match API (e.g. `first_name`, `school_id`).

---

### 2.3 Providers

**Folder:** `lib/features/parent/data/` or `lib/features/parent/presentation/providers/`

| File | Provider | State | Methods |
|------|----------|-------|---------|
| `parent_profile_provider.dart` | parentProfileProvider | profile, isLoading, isSaving, errorMessage | loadProfile(), updateProfile() |
| `parent_children_provider.dart` | parentChildrenProvider | FutureProvider<List<ChildSummaryModel>> | — |
| `parent_child_detail_provider.dart` | parentChildDetailProvider(studentId) | FutureProvider<ChildDetailModel?> | — |
| `parent_child_attendance_provider.dart` | parentChildAttendanceProvider(studentId, month) | FutureProvider<List<AttendanceEntryModel>> | — |
| `parent_child_fees_provider.dart` | parentChildFeesProvider(studentId, academicYear) | FutureProvider<Map> | — |
| `parent_notices_provider.dart` | parentNoticesProvider(page, limit) | FutureProvider with pagination | — |
| `parent_dashboard_provider.dart` | parentDashboardProvider | FutureProvider<ParentDashboardModel> | — |

**Pattern:** Follow `staff_profile_provider.dart` for profile; use `FutureProvider.family` for param-based (childId, month).

---

### 2.4 Shell

**File:** `lib/features/parent/presentation/parent_shell.dart`

**Pattern:** Copy `staff_shell.dart`, adapt:

- **Accent:** `AppColors.success500` (green)
- **Badge:** "PARENT" on `AppColors.success700`
- **Nav items:**
  - Dashboard → `/parent/dashboard`
  - My Children → `/parent/children`
  - Notices → `/parent/notices`
  - Profile → `/parent/profile`
- **Account:** Profile, Logout (no Change Password for parent unless specified)
- **TopBar:** School name (from profile or context), parent name, ThemeToggleButton, avatar with logout
- **Mobile:** Drawer + bottom nav (Dashboard, Children, Notices, More)
- **Logout:** `clearSession()`, redirect to `/login/parent`

---

### 2.5 Screens

**Folder:** `lib/features/parent/presentation/screens/`

| Screen | File | Purpose |
|--------|------|---------|
| ParentDashboardScreen | `parent_dashboard_screen.dart` | Summary: children count, today's attendance, recent notices, fee dues. Cards + quick links. Empty states. |
| ParentProfileScreen | `parent_profile_screen.dart` | View/edit name, email; phone read-only. Same layout as staff_profile_screen (inline edit mode). |
| ParentChildrenListScreen | `parent_children_list_screen.dart` | List of linked children (cards on mobile, table on web). Tap → child detail. Empty: "No children linked" |
| ParentChildDetailScreen | `parent_child_detail_screen.dart` | Child profile, quick links to Attendance, Fees. |
| ParentChildAttendanceScreen | `parent_child_attendance_screen.dart` | Monthly attendance for one child. Month picker. List/grid of dates with status. |
| ParentChildFeesScreen | `parent_child_fees_screen.dart` | Fee structure + payment history. Academic year filter. |
| ParentNoticesScreen | `parent_notices_screen.dart` | Paginated notices. Cards/list. Pull-to-refresh. Empty: "No notices" |
| ParentNoticeDetailScreen | `parent_notice_detail_screen.dart` | Full notice body, title, dates. |

**UI guidelines:**

- Use `RefreshIndicator` for list screens
- Use `AppSpacing`, `AppRadius`, `AppColors`
- Empty states: Icon + message + optional action
- Error states: Retry button
- Loading: `CircularProgressIndicator` or `ShimmerListLoadingWidget` for lists
- Add `aria-label` / `semanticLabel` for accessibility where applicable

---

## 3. Routes (app_router.dart)

Add Parent Shell and routes. Insert after Staff Shell block.

```dart
// Parent Shell
ShellRoute(
  builder: (context, state, child) => ParentShell(child: child),
  routes: [
    GoRoute(
      path: '/parent',
      redirect: (context, state) => '/parent/dashboard',
    ),
    GoRoute(
      path: '/parent/dashboard',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/parent/profile',
      builder: (context, state) => const ParentProfileScreen(),
    ),
    GoRoute(
      path: '/parent/children',
      builder: (context, state) => const ParentChildrenListScreen(),
    ),
    GoRoute(
      path: '/parent/children/:id',
      builder: (context, state) => ParentChildDetailScreen(
        studentId: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'attendance',
          builder: (context, state) => ParentChildAttendanceScreen(
            studentId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'fees',
          builder: (context, state) => ParentChildFeesScreen(
            studentId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/parent/notices',
      builder: (context, state) => const ParentNoticesScreen(),
    ),
    GoRoute(
      path: '/parent/notices/:id',
      builder: (context, state) => ParentNoticeDetailScreen(
        noticeId: state.pathParameters['id']!,
      ),
    ),
  ],
),
```

---

## 4. Auth Redirect Logic (app_router.dart)

In the `redirect` callback:

1. Add `isParentRoute = loc.startsWith('/parent')`
2. When `!isAuthenticated` and `isParentRoute`: return `'/login/parent'`
3. When authenticated and `portalType == 'parent'`:
   - If on `/login` or `/login/parent`: return `'/parent/dashboard'`
   - If on `/login/student` (student flow): keep existing logic
4. Add `final isParent = portalType.value == 'parent';`
5. When `isParent` and not on parent route (e.g. on `/staff/dashboard`): return `'/parent/dashboard'`

---

## 5. Parent Login Integration (parent_login_screen.dart)

**Current:** Mock flow with `Future.delayed`. Replace with real API calls.

**Step 1 (Phone):** Call `POST /api/platform/auth/resolve-user-by-phone` with `{ "phone": "...", "user_type": "parent" }`. Use `ApiConfig` or add:

```dart
static const String resolveUserByPhone = '/api/platform/auth/resolve-user-by-phone';
static const String verifyParentOtp = '/api/platform/auth/verify-parent-otp';
```

**Step 2 (School detected):** Use response `school`, `user`, `otp_session_id`, `masked_phone`. Show school name, confirm to send OTP.

**Step 3 (OTP):** Call `POST /api/platform/auth/verify-parent-otp` with `{ otp_session_id, otp, phone, school_id }`. On success: `ref.read(authGuardProvider.notifier).establishSession(data['access_token'], portalTypeOverride: 'parent')`. Redirect: `context.go('/parent/dashboard')`.

**Store:** Save `school_id`, `otp_session_id`, `phone` in state or pass via route params between steps.

---

## 6. API Config Additions

**File:** `lib/core/config/api_config.dart`

Add:

```dart
// Parent Portal
static const String parentBase = '/api/parent';
static const String parentDashboard = '$parentBase/dashboard';
static const String parentProfile = '$parentBase/profile';
static const String parentChildren = '$parentBase/children';
static const String parentNotices = '$parentBase/notices';

// Auth (parent login)
static const String resolveUserByPhone = '/api/platform/auth/resolve-user-by-phone';
static const String verifyParentOtp = '/api/platform/auth/verify-parent-otp';
```

---

## 7. Auth Guard Extension

**File:** `lib/features/auth/auth_guard_provider.dart`

- Ensure `_extractPortalType` reads `portal_type` from JWT (already does).
- For parent, `userEmail` may be null — use `parent.email` or `parent_${id}@vidyron.local` from token. Consider adding `parentName` or `parentId` to state if needed for display.
- `establishSession` already accepts `portalTypeOverride` — use `'parent'` after verify-parent-otp.

---

## 8. Dio Client / JWT

The `dioProvider` in `lib/core/network/dio_client.dart` attaches the token from `authGuardProvider`. Ensure parent token (with `parent_id`, `school_id`, `portal_type: 'parent'`) is stored the same way. No changes needed if `establishSession` stores `access_token` in SharedPreferences and Dio reads it.

---

## 9. Dashboard Content

**ParentDashboardScreen** should show:

- **Children count** — card with count, link to `/parent/children`
- **Today's attendance** — summary (e.g. "2 present, 0 absent") for linked children
- **Recent notices** — last 3–5, link to `/parent/notices`
- **Fee dues** — if backend provides (or placeholder "View fees per child")

Backend may need a `GET /api/parent/dashboard` endpoint. If not in spec, aggregate from `getChildren` + `getChildAttendance` (today) + `getNotices(limit: 5)` on the frontend.

---

## 10. Navigation Flows

| From | To |
|------|-----|
| Login success (parent) | /parent/dashboard |
| Dashboard | /parent/children, /parent/notices, /parent/profile |
| Children list | /parent/children/:id |
| Child detail | /parent/children/:id/attendance, /parent/children/:id/fees |
| Notices list | /parent/notices/:id |
| Profile | Edit inline or /parent/profile/edit |
| Logout | /login/parent |

---

## 11. Error Handling

- **401/403:** Clear session, redirect to `/login/parent`
- **404:** Show "Child not found" or "Notice not found" with back button
- **Network error:** Snackbar + Retry
- Use `try/catch` in providers, set `errorMessage` in state

---

## 12. Responsive Behavior

- **Web (≥768px):** Sidebar nav, TopBar with tabs
- **Mobile (<768px):** Drawer, bottom nav (Dashboard, Children, Notices, More)
- Breakpoint: `MediaQuery.of(context).size.width >= 768` (same as staff_shell)

---

## 13. Accessibility

- Add `semanticLabel` to IconButtons (e.g. "Open menu", "Sign out")
- Ensure focus order and screen reader support for forms
