# Driver Module — Flutter Prompt

**Purpose**: Implement the Flutter frontend for the Driver Portal (mobile-only). This prompt is copy-paste ready for the erp-flutter-dev agent or a Flutter developer.

**Project Root**: `e:/School_ERP_AI/erp-new-logic/`  
**Reference**: `docs/modules/driver/SPEC.md`, `.claude/CLAUDE.md`, `lib/features/staff/` (pattern reference)

---

## 1. Design System

- **Accent Color**: `#FF9800` (orange) — use `AppColors.warning400` or equivalent
- **Badge Color**: `#E65100` (dark orange) — use `AppColors.warning700` or `AppColors.warning800`
- **Layout**: Mobile-only — always use mobile layout (BottomNavigationBar + Drawer), no web sidebar
- **Components**: Use `lib/design_system/` — AppColors, AppTextStyles, AppSpacing, AppButtons, AppInputs

---

## 2. Files to Create

### 2.1 Service

| Path | Purpose |
|------|---------|
| `lib/core/services/driver_service.dart` | All Driver API calls |

### 2.2 Models

| Path | Purpose |
|------|---------|
| `lib/models/driver/driver_dashboard_model.dart` | Dashboard stats response |
| `lib/models/driver/driver_profile_model.dart` | Profile response |

### 2.3 Providers

| Path | Purpose |
|------|---------|
| `lib/features/driver/presentation/providers/driver_dashboard_provider.dart` | Dashboard FutureProvider |
| `lib/features/driver/presentation/providers/driver_profile_provider.dart` | Profile FutureProvider + update |

### 2.4 Shell & Screens

| Path | Purpose |
|------|---------|
| `lib/features/driver/presentation/driver_shell.dart` | Mobile shell (BottomNav + Drawer) |
| `lib/features/driver/presentation/screens/driver_dashboard_screen.dart` | Dashboard |
| `lib/features/driver/presentation/screens/driver_profile_screen.dart` | Profile view/edit |
| `lib/features/driver/presentation/screens/driver_change_password_screen.dart` | Change password |

### 2.5 Auth

| Path | Purpose |
|------|---------|
| `lib/features/auth/driver_login_screen.dart` | Driver login (email/password + school selection) |

---

## 3. API Config

**File**: `lib/core/config/api_config.dart`

Add:

```dart
// Driver Portal endpoints
static const String driverBase = '/api/driver';
static const String driverDashboard = '$driverBase/dashboard/stats';
static const String driverProfile = '$driverBase/profile';
static const String driverChangePassword = '$driverBase/auth/change-password';
```

**Login**: Use existing `ApiConfig.loginEndpoint` (`/api/platform/auth/login`) with `portal_type: 'driver'` and `school_id`.

---

## 4. Driver Service

**File**: `lib/core/services/driver_service.dart`

**Reference**: `lib/core/services/group_admin_service.dart`

```dart
class DriverService {
  DriverService(this._dio);
  final Dio _dio;

  Future<DriverDashboardModel> getDashboardStats() async { ... }
  Future<DriverProfileModel> getProfile() async { ... }
  Future<DriverProfileModel> updateProfile({ String? phone, String? emergencyContactName, String? emergencyContactPhone, String? address }) async { ... }
  Future<void> changePassword({ required String currentPassword, required String newPassword }) async { ... }
}
```

- Use `ref.watch(dioProvider)` for Dio (same as other services)
- Parse `res.data['data']` for response payload
- Throw on non-2xx or `success: false`

---

## 5. Models

### 5.1 DriverDashboardModel

**File**: `lib/models/driver/driver_dashboard_model.dart`

```dart
class DriverDashboardModel {
  final DriverSummary driver;
  final SchoolSummary school;
  final VehicleSummary? vehicle;
  final RouteSummary? route;
  final int studentCount;
  final String tripStatus; // NOT_STARTED | IN_PROGRESS | COMPLETED
}

class DriverSummary { final String id; final String firstName; final String lastName; final String? photoUrl; }
class SchoolSummary { final String id; final String name; final String? logoUrl; }
class VehicleSummary { final String id; final String vehicleNo; final int capacity; }
class RouteSummary { final String id; final String name; final int stopCount; }
```

All with `fromJson(Map<String, dynamic>)` — handle snake_case and null safety.

### 5.2 DriverProfileModel

**File**: `lib/models/driver/driver_profile_model.dart`

```dart
class DriverProfileModel {
  final DriverDetail driver;
  final VehicleSummary? vehicle;
  final RouteSummary? route;
  final DriverUserInfo? user;
}

class DriverDetail {
  final String id;
  final String employeeNo;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String email;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? photoUrl;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isActive;
}

class DriverUserInfo {
  final String userId;
  final String email;
  final DateTime? lastLogin;
}
```

Reuse `VehicleSummary` and `RouteSummary` from dashboard model (or define in shared file).

---

## 6. Driver Shell

**File**: `lib/features/driver/presentation/driver_shell.dart`

**Reference**: `lib/features/staff/presentation/staff_shell.dart` — but **mobile-only** (no `_StaffWebLayout`).

- **BottomNavigationBar**: 2 items — Dashboard, Profile
- **AppBar**: School name, logo (if available), logout icon
- **Drawer**: Dashboard, Profile, Change Password, Logout
- **Accent**: Orange `#FF9800`, badge "DRIVER" with dark orange `#E65100`
- **Child**: `child` passed to shell (nested route content)

**Structure**:
```dart
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _DriverMobileLayout(child: child); // Always mobile
  }
}
```

---

## 7. Screens

### 7.1 Driver Dashboard Screen

**File**: `lib/features/driver/presentation/screens/driver_dashboard_screen.dart`

- **RefreshIndicator** with `ref.invalidate(driverDashboardProvider)`
- **AsyncValue** handling: loading, error (retry), data
- **Cards** for:
  - School name + logo
  - Driver name + photo
  - Vehicle (vehicleNo, capacity) — or "No vehicle assigned"
  - Route (name, stopCount) — or "No route assigned"
  - Student count (Phase 1: show 0)
  - Trip status (Phase 1: NOT_STARTED)
- **Reference**: `lib/features/staff/presentation/screens/staff_dashboard_screen.dart` — stat cards pattern

### 7.2 Driver Profile Screen

**File**: `lib/features/driver/presentation/screens/driver_profile_screen.dart`

- **RefreshIndicator** to reload profile
- **Read-only display**: employeeNo, name, gender, DOB, phone, email, license, address, emergency contact
- **Edit button** → navigate to same screen with edit mode, or use inline edit for phone/emergency contact/address
- **Change Password** button → navigate to `/driver/change-password`
- **Logout** in AppBar or Drawer

**Editable fields** (PUT /profile): phone, emergencyContactName, emergencyContactPhone, address

### 7.3 Driver Change Password Screen

**File**: `lib/features/driver/presentation/screens/driver_change_password_screen.dart`

- **Form**: currentPassword, newPassword, confirmPassword
- **Validation**: min 8 chars, new === confirm
- **Submit** → call `driverService.changePassword` → show success → optionally go back
- **Reference**: `lib/features/staff/presentation/screens/staff_change_password_screen.dart`

---

## 8. Driver Login Screen

**File**: `lib/features/auth/driver_login_screen.dart`

**Reference**: `lib/features/auth/staff_login_screen.dart`

- **School selection**: Same as staff — saved school (mobile) or subdomain (web). For mobile, use `SchoolSetupSearchWidget` or saved school from `LocalStorageService`.
- **Form**: identifier (email/phone), password
- **Login**: Use `schoolStaffLoginProvider` (or equivalent) with `portalType: 'driver'`, `schoolId: identity.id` — same pattern as staff login; the provider calls `AuthService.login` with these params
- **Redirect**: On success, auth guard stores session; redirect to `/driver/dashboard` when `portalType == 'driver'`
- **OTP flow**: If `requires_otp`, redirect to device verification with `portal_type=driver`

---

## 9. Routes (app_router.dart)

### 9.1 Add Imports

```dart
import '../features/auth/driver_login_screen.dart';
import '../features/driver/presentation/driver_shell.dart';
import '../features/driver/presentation/screens/driver_dashboard_screen.dart';
import '../features/driver/presentation/screens/driver_profile_screen.dart';
import '../features/driver/presentation/screens/driver_change_password_screen.dart';
```

### 9.2 Auth Redirect Logic

In the redirect logic (where `isStaff`, `isTeacher`, etc. are checked), add:

```dart
final isDriver = portalType.value == 'driver';
// When authenticated and driver, redirect /login or / to /driver/dashboard
if (isDriver && (loc == '/' || loc.startsWith('/login'))) {
  return '/driver/dashboard';
}
// Protect driver routes
if (loc.startsWith('/driver') && !isDriver && isAuthenticated) {
  return '/'; // or appropriate fallback
}
if (loc.startsWith('/driver') && !isAuthenticated) {
  return '/login/driver';
}
```

### 9.3 Route Definitions

```dart
// Login
GoRoute(
  path: '/login/driver',
  builder: (context, state) => const DriverLoginScreen(),
),

// Driver shell (mobile-only)
ShellRoute(
  builder: (context, state, child) => DriverShell(child: child),
  routes: [
    GoRoute(path: '/driver', redirect: (_, __) => '/driver/dashboard'),
    GoRoute(path: '/driver/dashboard', builder: (_, __) => const DriverDashboardScreen()),
    GoRoute(path: '/driver/profile', builder: (_, __) => const DriverProfileScreen()),
    GoRoute(path: '/driver/change-password', builder: (_, __) => const DriverChangePasswordScreen()),
  ],
),
```

---

## 10. Dio Client & Auth Guard

- **Dio**: Driver API calls use the same `dioProvider` (Dio with JWT interceptor). Ensure `authGuardProvider` supplies the access token for driver sessions.
- **Auth Guard**: When `portalType == 'driver'`, token is valid for driver routes. No changes needed if auth guard already passes token for any portal.

---

## 11. State Shapes

### driver_dashboard_provider.dart

```dart
final driverDashboardProvider = FutureProvider<DriverDashboardModel>((ref) {
  final service = ref.watch(driverServiceProvider);
  return service.getDashboardStats();
});
```

### driver_profile_provider.dart

```dart
final driverProfileProvider = FutureProvider<DriverProfileModel>((ref) {
  final service = ref.watch(driverServiceProvider);
  return service.getProfile();
});

// For update: call service.updateProfile(), then ref.invalidate(driverProfileProvider)
```

---

## 12. Navigation Flows

| From | To |
|------|-----|
| `/login/driver` | `/driver/dashboard` (on success) |
| `/driver/dashboard` | `/driver/profile` (via nav) |
| `/driver/profile` | `/driver/change-password` |
| Any driver screen | `/login/driver` (on logout) |

---

## 13. Validation Checklist

- [ ] `flutter analyze` passes
- [ ] Driver login with email/password → redirect to dashboard
- [ ] Dashboard loads vehicle, route, student count, trip status
- [ ] Profile loads and displays all fields
- [ ] Profile update (phone, emergency contact, address) works
- [ ] Change password works
- [ ] Logout clears session and redirects to login
- [ ] Mobile layout only (no web sidebar for driver)
