# Student Module — Flutter Prompt

**Purpose**: Implement the Student Portal Flutter UI — shell, dashboard, profile, attendance, fees, timetable, notices, documents, change-password screens, plus StudentService, models, providers, and routes.

**Reference patterns**: `lib/features/teacher/`, `lib/features/staff/`

**Root**: `e:/School_ERP_AI/erp-new-logic/`

---

## 1. API Config

**File**: `lib/core/config/api_config.dart`

Add constants:

```dart
  // Student Portal endpoints
  static const String studentBase           = '/api/student';
  static const String studentProfile        = '$studentBase/profile';
  static const String studentDashboard     = '$studentBase/dashboard';
  static const String studentAttendance    = '$studentBase/attendance';
  static const String studentAttendanceSummary = '$studentBase/attendance/summary';
  static const String studentFeeDues        = '$studentBase/fees/dues';
  static const String studentFeePayments   = '$studentBase/fees/payments';
  static const String studentFeeReceipt    = '$studentBase/fees/receipt';
  static const String studentTimetable     = '$studentBase/timetable';
  static const String studentNotices       = '$studentBase/notices';
  static const String studentDocuments     = '$studentBase/documents';
  static const String studentChangePassword = '$studentBase/auth/change-password';
```

---

## 2. Models

**Directory**: `lib/models/student/`

### 2.1 StudentProfileModel

```dart
class StudentProfileModel {
  final String id;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String gender; // MALE, FEMALE, OTHER
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? phone;
  final String? email;
  final String? address;
  final String? photoUrl;
  final String? classId;
  final String? sectionId;
  final int? rollNo;
  final StudentClassInfo? class_;
  final StudentSectionInfo? section;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? parentRelation;

  StudentProfileModel({...});
  factory StudentProfileModel.fromJson(Map<String, dynamic> json);
}
```

### 2.2 StudentDashboardModel

```dart
class StudentDashboardModel {
  final TodayAttendance? todayAttendance;
  final int presentDaysThisMonth;
  final double totalFeePaidThisYear;
  final List<FeeDueItem> upcomingDues;
  final List<TimetableSlot> todayTimetable;
  final List<NoticeSummary> recentNotices;
  final int unreadNoticesCount;

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json);
}
```

### 2.3 StudentAttendanceModel

```dart
class StudentAttendanceModel {
  final List<AttendanceRecord> records;
  final String month;

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json);
}

class AttendanceSummaryModel {
  final String month;
  final int present;
  final int absent;
  final int late;
  final int halfDay;

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json);
}
```

### 2.4 StudentFeeModels

```dart
class StudentFeeDuesModel {
  final String academicYear;
  final List<FeeDueItem> dues;
  final double totalDue;

  factory StudentFeeDuesModel.fromJson(Map<String, dynamic> json);
}

class StudentPaymentModel {
  final String id;
  final String feeHead;
  final double amount;
  final String paymentDate;
  final String receiptNo;
  final String paymentMode;

  factory StudentPaymentModel.fromJson(Map<String, dynamic> json);
}

class StudentReceiptModel {
  final String id;
  final String receiptNo;
  final String feeHead;
  final double amount;
  final String paymentDate;
  final String paymentMode;
  final String? remarks;

  factory StudentReceiptModel.fromJson(Map<String, dynamic> json);
}
```

### 2.5 StudentTimetableModel

```dart
class StudentTimetableModel {
  final List<TimetableSlot> slots;

  factory StudentTimetableModel.fromJson(Map<String, dynamic> json);
}

class TimetableSlot {
  final int dayOfWeek;
  final int periodNo;
  final String subject;
  final String startTime;
  final String endTime;
  final String? room;
  final String? staffName;
}
```

### 2.6 StudentNoticeModel

```dart
class StudentNoticeModel {
  final String id;
  final String title;
  final String body;
  final String? publishedAt;
  final String? expiresAt;
  final bool isPinned;

  factory StudentNoticeModel.fromJson(Map<String, dynamic> json);
}
```

### 2.7 StudentDocumentModel

```dart
class StudentDocumentModel {
  final String id;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final int? fileSizeKb;
  final bool verified;
  final String? verifiedAt;

  factory StudentDocumentModel.fromJson(Map<String, dynamic> json);
}
```

---

## 3. StudentService

**File**: `lib/core/services/student_service.dart`

Follow pattern from `lib/core/services/teacher_service.dart`.

```dart
class StudentService {
  StudentService(this._dio);
  final Dio _dio;

  Future<StudentProfileModel> getProfile() async { ... }
  Future<StudentDashboardModel> getDashboard() async { ... }
  Future<StudentAttendanceModel> getAttendance({required String month}) async { ... }
  Future<AttendanceSummaryModel> getAttendanceSummary({String? month}) async { ... }
  Future<StudentFeeDuesModel> getFeeDues() async { ... }
  Future<Map<String, dynamic>> getFeePayments({int page = 1, int limit = 20}) async { ... }
  Future<StudentReceiptModel> getReceiptByReceiptNo(String receiptNo) async { ... }
  Future<StudentTimetableModel> getTimetable() async { ... }
  Future<Map<String, dynamic>> getNotices({int page = 1, int limit = 20}) async { ... }
  Future<StudentNoticeModel> getNoticeById(String id) async { ... }
  Future<List<StudentDocumentModel>> getDocuments() async { ... }
  Future<void> changePassword({required String currentPassword, required String newPassword}) async { ... }
}

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(ref.read(dioProvider));
});
```

All methods use `ApiConfig` constants. Extract `data` from `res.data['data']` when backend returns `{ success, data }`.

---

## 4. Providers

**Directory**: `lib/features/student/data/`

| Provider | Type | Purpose |
|----------|------|---------|
| `studentProfileProvider` | `FutureProvider<StudentProfileModel>` | GET /profile |
| `studentDashboardProvider` | `FutureProvider<StudentDashboardModel>` | GET /dashboard |
| `studentAttendanceProvider` | `FutureProvider.family<StudentAttendanceModel, String>` | GET /attendance?month= |
| `studentAttendanceSummaryProvider` | `FutureProvider.family<AttendanceSummaryModel, String?>` | GET /attendance/summary |
| `studentFeeDuesProvider` | `FutureProvider<StudentFeeDuesModel>` | GET /fees/dues |
| `studentFeePaymentsProvider` | `FutureProvider.family<...>` | GET /fees/payments (page) |
| `studentTimetableProvider` | `FutureProvider<StudentTimetableModel>` | GET /timetable |
| `studentNoticesProvider` | `FutureProvider.family<...>` | GET /notices |
| `studentDocumentsProvider` | `FutureProvider<List<StudentDocumentModel>>` | GET /documents |

Use `ref.watch(studentServiceProvider)` and `ref.invalidate(...)` for refresh.

---

## 5. Student Shell

**File**: `lib/features/student/presentation/student_shell.dart`

Follow pattern from `lib/features/teacher/presentation/teacher_shell.dart` and `lib/features/staff/presentation/staff_shell.dart`.

**Accent color**: Use `AppColors.primary500` or a distinct color (e.g. `AppColors.info500`)  
**Badge**: `STUDENT` on dark background

**Nav items** (main):
- Dashboard → `/student/dashboard`
- Attendance → `/student/attendance`
- Fees → `/student/fees`
- Timetable → `/student/timetable`
- Notices → `/student/notices`

**Account section**:
- Profile → `/student/profile`
- Documents → `/student/documents`
- Change Password → `/student/change-password`

**Layout**: Web = sidebar + top bar; Mobile = drawer + bottom nav (4–5 items) + "More" for account.

---

## 6. Screens

**Directory**: `lib/features/student/presentation/screens/`

| Screen | File | Route | Description |
|--------|------|-------|-------------|
| StudentDashboardScreen | `student_dashboard_screen.dart` | `/student/dashboard` | Stats: today attendance, present days this month, fee paid, upcoming dues; today timetable; recent notices |
| StudentProfileScreen | `student_profile_screen.dart` | `/student/profile` | Full profile: name, admission no, class-section, roll no, DOB, blood group, parent contact, address, photo |
| StudentAttendanceScreen | `student_attendance_screen.dart` | `/student/attendance` | Month selector; list/grid of attendance records; summary (present/absent/late/half-day) |
| StudentFeesScreen | `student_fees_screen.dart` | `/student/fees` | Tabs or sections: Fee Dues, Payment History; receipt download/link |
| StudentTimetableScreen | `student_timetable_screen.dart` | `/student/timetable` | Weekly grid (Mon–Sat, periods) |
| StudentNoticesScreen | `student_notices_screen.dart` | `/student/notices` | Paginated list; tap → detail |
| StudentNoticeDetailScreen | `student_notice_detail_screen.dart` | `/student/notices/:id` | Full notice body |
| StudentDocumentsScreen | `student_documents_screen.dart` | `/student/documents` | List of documents; open fileUrl in browser/app |
| StudentChangePasswordScreen | `student_change_password_screen.dart` | `/student/change-password` | Form: current password, new password, confirm; call StudentService.changePassword |

**Design system**: Use `AppColors`, `AppTextStyles`, `AppSpacing`, `AppButtons`, `AppInputs` from `lib/design_system/`.

**Loading**: Use `AsyncValue.when` (loading, error, data). Use `RefreshIndicator` + `ref.invalidate(provider)` for pull-to-refresh.

---

## 7. Routes

**File**: `lib/routes/app_router.dart`

### 7.1 Add Student Shell Route

Add a `ShellRoute` for Student portal (after Staff Shell, before Protected Admin Shell):

```dart
ShellRoute(
  builder: (context, state, child) => StudentShell(child: child),
  routes: [
    GoRoute(path: '/student', redirect: (context, state) => '/student/dashboard'),
    GoRoute(path: '/student/dashboard', builder: (context, state) => const StudentDashboardScreen()),
    GoRoute(path: '/student/profile', builder: (context, state) => const StudentProfileScreen()),
    GoRoute(path: '/student/attendance', builder: (context, state) => const StudentAttendanceScreen()),
    GoRoute(path: '/student/fees', builder: (context, state) => const StudentFeesScreen()),
    GoRoute(path: '/student/timetable', builder: (context, state) => const StudentTimetableScreen()),
    GoRoute(path: '/student/notices', builder: (context, state) => const StudentNoticesScreen()),
    GoRoute(
      path: '/student/notices/:id',
      builder: (context, state) => StudentNoticeDetailScreen(noticeId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/student/documents', builder: (context, state) => const StudentDocumentsScreen()),
    GoRoute(path: '/student/change-password', builder: (context, state) => const StudentChangePasswordScreen()),
  ],
),
```

### 7.2 Auth Redirect for Student

In `redirect` callback, add:

```dart
final isStudent = portalType.value == 'student';
if (isAuthenticated && isStudent && !loc.startsWith('/student')) {
  return '/student/dashboard';
}
```

Add `isStudentRoute` check: `loc.startsWith('/student')`.

In unauthenticated block, add:
```dart
if (isStudentRoute) {
  return '/login/student';
}
```

### 7.3 Post-Login Redirect

Update `lib/features/auth/parent_login_screen.dart`:
- When `_userType == ParentStudentUserType.student`, redirect to `/student/dashboard` (not `/dashboard/student`):
```dart
context.go(_userType == ParentStudentUserType.parent ? '/dashboard/parent' : '/student/dashboard');
```

### 7.4 PortalResolver

Update `lib/utils/portal_resolver.dart`:
- In `getDashboardRoute`, for `case 'student':` return `'/student/dashboard'`.

---

## 8. Auth Guard

Ensure `authGuardProvider` treats `portal_type == 'student'` as a valid portal. The existing `isSchoolPortal` or similar should include `student` if it gates school-scoped features.

---

## 9. Navigation Flow

- Login (student) → `/student/dashboard`
- Dashboard → Profile, Attendance, Fees, Timetable, Notices, Documents, Change Password via shell nav
- Notices list → Notice detail (`/student/notices/:id`)
- Fees → Receipt detail (if applicable, via receiptNo param or modal)

---

## 10. Summary Checklist

- [ ] Add student API constants to `api_config.dart`
- [ ] Create models in `lib/models/student/`
- [ ] Create `StudentService` and `studentServiceProvider`
- [ ] Create providers in `lib/features/student/data/`
- [ ] Create `StudentShell`
- [ ] Create all 9 screens
- [ ] Add Student ShellRoute and child routes in `app_router.dart`
- [ ] Add student auth redirect in `app_router.dart`
- [ ] Update `parent_login_screen.dart` redirect to `/student/dashboard`
- [ ] Update `PortalResolver.getDashboardRoute` for student
- [ ] Add `isStudentRoute` protection for unauthenticated access
