# FLUTTER PROMPT — School Admin Module

## Agent Role
You are the Flutter Developer for the Vidyron School ERP platform. Your task is to build the complete School Admin portal UI — shell, screens, providers, models, and service. The portal uses green as its accent color and is accessed at `/school-admin/*` routes.

---

## Project Context

- **Root**: `e:/School_ERP_AI/erp-new-logic/`
- **Flutter root**: `e:/School_ERP_AI/erp-new-logic/lib/`
- **State management**: Riverpod (`StateNotifierProvider`, `FutureProvider`, `AsyncNotifier`)
- **Navigation**: GoRouter with ShellRoute
- **HTTP client**: Dio via `ref.read(dioProvider)` from `lib/core/network/dio_client.dart`
- **Auth token**: `ref.read(authGuardProvider).accessToken` — the Dio interceptor attaches it automatically
- **Design system**: `lib/design_system/design_system.dart` — exports AppColors, AppTextStyles, AppSpacing, AppButtons, AppInputs, AppLogoWidget
- **Portal accent color**: `const Color _accentColor = Color(0xFF4CAF50)` (Material green)
- **Portal badge color**: `const Color _badgeColor = Color(0xFF1B5E20)` (dark green)
- **Badge text**: `'SCHOOL ADMIN'`

---

## Reference Patterns

Before writing any code, read these existing files for patterns to follow exactly:

- **Service pattern**: `lib/core/services/super_admin_service.dart`
- **Shell pattern**: `lib/features/group_admin/presentation/group_admin_shell.dart`
- **Router pattern**: `lib/routes/app_router.dart`
- **API config pattern**: `lib/core/config/api_config.dart`
- **Auth guard**: `lib/features/auth/auth_guard_provider.dart`

Key conventions observed in those files:
- Service class takes `Dio _dio` in constructor, created via `Provider<ServiceClass>`
- All API responses unwrap: `final data = res.data is Map ? res.data['data'] ?? res.data : res.data`
- Shell has two layouts: `_WebLayout` (sidebar 214px + content column) and `_MobileLayout` (AppBar + Drawer + BottomNavigationBar)
- `_NavItem` widget with `icon`, `activeIcon`, `label`, `isActive`, `onTap` — uses left-border highlight when active
- Logout: `ref.read(authGuardProvider.notifier).clearSession()` then `context.go('/login/school')`
- Router redirect: check `portalType.value == 'school_admin'` and redirect to `/school-admin/dashboard`

---

## API Backend Reference

All endpoints are prefixed `/api/school/` and require Bearer JWT. The backend is implemented per `BACKEND_PROMPT.md`. Here is the complete endpoint list:

```
GET    /api/school/dashboard/stats
GET    /api/school/students?page&limit&search&classId&sectionId&status
POST   /api/school/students
GET    /api/school/students/:id
PUT    /api/school/students/:id
DELETE /api/school/students/:id
GET    /api/school/staff?page&limit&search&designation&isActive
POST   /api/school/staff
GET    /api/school/staff/:id
PUT    /api/school/staff/:id
DELETE /api/school/staff/:id
GET    /api/school/classes
POST   /api/school/classes
PUT    /api/school/classes/:id
DELETE /api/school/classes/:id
GET    /api/school/classes/:classId/sections
POST   /api/school/classes/:classId/sections
PUT    /api/school/sections/:id
DELETE /api/school/sections/:id
GET    /api/school/attendance?classId&sectionId&date
POST   /api/school/attendance/bulk
GET    /api/school/attendance/report?classId&sectionId&month
GET    /api/school/fees/structures?academicYear&classId
POST   /api/school/fees/structures
PUT    /api/school/fees/structures/:id
DELETE /api/school/fees/structures/:id
GET    /api/school/fees/payments?page&limit&studentId&month&academicYear
POST   /api/school/fees/payments
GET    /api/school/fees/payments/:id
GET    /api/school/fees/summary?month
GET    /api/school/timetable?classId&sectionId
PUT    /api/school/timetable/bulk
GET    /api/school/notices?page&limit&search
POST   /api/school/notices
PUT    /api/school/notices/:id
DELETE /api/school/notices/:id
GET    /api/school/notifications/unread-count
GET    /api/school/notifications?page&limit
PUT    /api/school/notifications/:id/read
GET    /api/school/profile
PUT    /api/school/profile/user
PUT    /api/school/profile/school
POST   /api/school/auth/change-password
```

---

## Task 1: Add API Constants

**File**: `e:/School_ERP_AI/erp-new-logic/lib/core/config/api_config.dart`

Add inside the `ApiConfig` class body (after the existing group admin constants):

```dart
// School Admin Portal
static const String schoolAdminBase         = '/api/school';
static const String schoolDashboardStats    = '/api/school/dashboard/stats';
static const String schoolStudents          = '/api/school/students';
static const String schoolStaff             = '/api/school/staff';
static const String schoolClasses           = '/api/school/classes';
static const String schoolSections          = '/api/school/sections';
static const String schoolAttendance        = '/api/school/attendance';
static const String schoolAttendanceReport  = '/api/school/attendance/report';
static const String schoolAttendanceBulk    = '/api/school/attendance/bulk';
static const String schoolFeeStructures     = '/api/school/fees/structures';
static const String schoolFeePayments       = '/api/school/fees/payments';
static const String schoolFeeSummary        = '/api/school/fees/summary';
static const String schoolTimetable         = '/api/school/timetable';
static const String schoolTimetableBulk     = '/api/school/timetable/bulk';
static const String schoolNotices           = '/api/school/notices';
static const String schoolNotifications     = '/api/school/notifications';
static const String schoolProfile           = '/api/school/profile';
static const String schoolProfileUser       = '/api/school/profile/user';
static const String schoolProfileSchool     = '/api/school/profile/school';
static const String schoolChangePassword    = '/api/school/auth/change-password';
```

---

## Task 2: Create Dart Model Classes

Create directory: `e:/School_ERP_AI/erp-new-logic/lib/models/school_admin/`

Each model has `fromJson(Map<String, dynamic> json)` factory and `toJson()` method. Use `null`-safe field access with fallback defaults.

---

### `lib/models/school_admin/dashboard_stats_model.dart`

```dart
class DashboardStatsModel {
  final int totalStudents;
  final int totalStaff;
  final int totalClasses;
  final int totalSections;
  final int todayAttendancePercent;
  final double feeCollectedThisMonth;
  final int noticesCount;
  final List<RecentActivityItem> recentActivity;

  const DashboardStatsModel({
    required this.totalStudents,
    required this.totalStaff,
    required this.totalClasses,
    required this.totalSections,
    required this.todayAttendancePercent,
    required this.feeCollectedThisMonth,
    required this.noticesCount,
    required this.recentActivity,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }

  static DashboardStatsModel empty() => DashboardStatsModel(
    totalStudents: 0, totalStaff: 0, totalClasses: 0, totalSections: 0,
    todayAttendancePercent: 0, feeCollectedThisMonth: 0.0,
    noticesCount: 0, recentActivity: [],
  );
}

class RecentActivityItem {
  final String type;
  final String message;
  final DateTime? createdAt;

  const RecentActivityItem({ required this.type, required this.message, this.createdAt });
  factory RecentActivityItem.fromJson(Map<String, dynamic> json) { ... }
}
```

---

### `lib/models/school_admin/student_model.dart`

```dart
class StudentModel {
  final String id;
  final String schoolId;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String gender;
  final String? dateOfBirth;     // ISO date string
  final String? bloodGroup;
  final String? phone;
  final String? email;
  final String? address;
  final String? photoUrl;
  final String? classId;
  final String? sectionId;
  final int? rollNo;
  final String status;           // ACTIVE | INACTIVE | TRANSFERRED
  final String? admissionDate;   // ISO date string
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? parentRelation;
  // Joined
  final String? className;
  final String? sectionName;

  const StudentModel({ ... });
  factory StudentModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }

  String get fullName => '$firstName $lastName'.trim();
}
```

JSON key mapping: `admission_no`, `first_name`, `last_name`, `date_of_birth`, `blood_group`, `photo_url`, `class_id`, `section_id`, `roll_no`, `admission_date`, `parent_name`, `parent_phone`, `parent_email`, `parent_relation`, `class_name`, `section_name`, `school_id`.

---

### `lib/models/school_admin/staff_model.dart`

```dart
class StaffModel {
  final String id;
  final String schoolId;
  final String? userId;
  final String employeeNo;
  final String firstName;
  final String lastName;
  final String gender;
  final String? dateOfBirth;
  final String? phone;
  final String email;
  final String designation;
  final List<String> subjects;
  final String? qualification;
  final String? joinDate;
  final String? photoUrl;
  final bool isActive;

  String get fullName => '$firstName $lastName'.trim();

  factory StaffModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

JSON key mapping: `school_id`, `user_id`, `employee_no`, `first_name`, `last_name`, `date_of_birth`, `join_date`, `photo_url`, `is_active`.

---

### `lib/models/school_admin/school_class_model.dart`

```dart
class SchoolClassModel {
  final String id;
  final String schoolId;
  final String name;
  final int? numeric;
  final bool isActive;
  final List<SectionSummary> sections;

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

class SectionSummary {
  final String id;
  final String name;
  final int studentCount;

  factory SectionSummary.fromJson(Map<String, dynamic> json) {
    // student_count may come as nested _count.students or direct student_count
  }
}
```

---

### `lib/models/school_admin/section_model.dart`

```dart
class SectionModel {
  final String id;
  final String schoolId;
  final String classId;
  final String name;
  final String? classTeacherId;
  final String? classTeacherName;  // derived from included teacher
  final int capacity;
  final bool isActive;
  final int studentCount;

  factory SectionModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

---

### `lib/models/school_admin/attendance_model.dart`

```dart
class AttendanceRecord {
  final String studentId;
  final String studentName;
  final int? rollNo;
  final String? status;    // null = not marked yet
  final String? remarks;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

class AttendanceReportModel {
  final List<AttendanceCalendarDay> calendar;
  final AttendanceSummary summary;

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) { ... }
}

class AttendanceCalendarDay {
  final String date;
  final int present;
  final int absent;
  final int late;
  factory AttendanceCalendarDay.fromJson(Map<String, dynamic> json) { ... }
}

class AttendanceSummary {
  final int presentDays;
  final int absentDays;
  final int totalDays;
  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    // keys: present_days, absent_days, total_days
  }
}
```

---

### `lib/models/school_admin/fee_structure_model.dart`

```dart
class FeeStructureModel {
  final String id;
  final String schoolId;
  final String? classId;
  final String academicYear;
  final String feeHead;
  final double amount;
  final String frequency;  // MONTHLY | QUARTERLY | ANNUALLY | ONE_TIME
  final int? dueDay;
  final bool isActive;

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

JSON key mapping: `school_id`, `class_id`, `academic_year`, `fee_head`, `due_day`, `is_active`.

---

### `lib/models/school_admin/fee_payment_model.dart`

```dart
class FeePaymentModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String feeHead;
  final String academicYear;
  final double amount;
  final String paymentDate;
  final String paymentMode;  // CASH | UPI | BANK_TRANSFER | CHEQUE
  final String receiptNo;
  final String collectedBy;
  final String? remarks;
  final String? createdAt;

  factory FeePaymentModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

---

### `lib/models/school_admin/school_notice_model.dart`

```dart
class SchoolNoticeModel {
  final String id;
  final String schoolId;
  final String title;
  final String body;
  final String? targetRole;
  final bool isPinned;
  final String? publishedAt;
  final String? expiresAt;
  final String createdBy;
  final String? createdAt;

  factory SchoolNoticeModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

---

### `lib/models/school_admin/timetable_model.dart`

```dart
class TimetableEntry {
  final String id;
  final String schoolId;
  final String classId;
  final String? sectionId;
  final int dayOfWeek;    // 1=Mon … 6=Sat
  final int periodNo;
  final String subject;
  final String? staffId;
  final String? staffName;  // joined
  final String startTime;   // "HH:MM"
  final String endTime;     // "HH:MM"
  final String? room;

  factory TimetableEntry.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

---

### `lib/models/school_admin/school_admin_profile_model.dart`

```dart
class SchoolAdminProfileModel {
  final SchoolInfoModel school;
  final AdminUserModel user;

  factory SchoolAdminProfileModel.fromJson(Map<String, dynamic> json) { ... }
}

class SchoolInfoModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? logoUrl;
  factory SchoolInfoModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

class AdminUserModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  factory AdminUserModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

Also create a thin `PaginationModel<T>` if not already present in the project at `lib/features/schools/domain/models/pagination_model.dart`. If it already exists, import it — do not recreate it.

---

## Task 3: Create Service File

**File**: `e:/School_ERP_AI/erp-new-logic/lib/core/services/school_admin_service.dart`

Follow exactly the same pattern as `lib/core/services/super_admin_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../models/school_admin/...';
import '../../core/config/api_config.dart';

class SchoolAdminService {
  SchoolAdminService(this._dio);
  final Dio _dio;

  // ... methods
}

final schoolAdminServiceProvider = Provider<SchoolAdminService>((ref) {
  return SchoolAdminService(ref.read(dioProvider));
});
```

**Implement all these methods**:

```dart
// Dashboard
Future<DashboardStatsModel> getDashboardStats() async {
  final res = await _dio.get(ApiConfig.schoolDashboardStats);
  final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
  return DashboardStatsModel.fromJson(data is Map<String, dynamic> ? data : {});
}

// Students
Future<PaginationModel<StudentModel>> getStudents({
  int page = 1, int limit = 20, String? search,
  String? classId, String? sectionId, String? status,
}) async { ... }

Future<StudentModel> getStudentById(String id) async { ... }
Future<StudentModel> createStudent(Map<String, dynamic> body) async { ... }
Future<StudentModel> updateStudent(String id, Map<String, dynamic> body) async { ... }
Future<void> deleteStudent(String id) async { ... }

// Staff
Future<PaginationModel<StaffModel>> getStaff({
  int page = 1, int limit = 20, String? search,
  String? designation, String? isActive,
}) async { ... }

Future<StaffModel> getStaffById(String id) async { ... }
Future<StaffModel> createStaff(Map<String, dynamic> body) async { ... }
Future<StaffModel> updateStaff(String id, Map<String, dynamic> body) async { ... }
Future<void> deleteStaff(String id) async { ... }

// Classes
Future<List<SchoolClassModel>> getClasses() async { ... }
Future<SchoolClassModel> createClass(Map<String, dynamic> body) async { ... }
Future<SchoolClassModel> updateClass(String id, Map<String, dynamic> body) async { ... }
Future<void> deleteClass(String id) async { ... }

// Sections
Future<List<SectionModel>> getSections(String classId) async { ... }
// GET /api/school/classes/{classId}/sections
Future<SectionModel> createSection(String classId, Map<String, dynamic> body) async { ... }
Future<SectionModel> updateSection(String id, Map<String, dynamic> body) async { ... }
Future<void> deleteSection(String id) async { ... }

// Attendance
Future<List<AttendanceRecord>> getAttendance({
  required String classId, String? sectionId, required String date,
}) async { ... }
Future<Map<String, dynamic>> bulkMarkAttendance(Map<String, dynamic> body) async { ... }
Future<AttendanceReportModel> getAttendanceReport({
  required String classId, String? sectionId, required String month,
}) async { ... }

// Fee Structures
Future<List<FeeStructureModel>> getFeeStructures({
  String? academicYear, String? classId,
}) async { ... }
Future<FeeStructureModel> createFeeStructure(Map<String, dynamic> body) async { ... }
Future<FeeStructureModel> updateFeeStructure(String id, Map<String, dynamic> body) async { ... }
Future<void> deleteFeeStructure(String id) async { ... }

// Fee Payments
Future<PaginationModel<FeePaymentModel>> getFeePayments({
  int page = 1, int limit = 20, String? studentId,
  String? month, String? academicYear,
}) async { ... }
Future<FeePaymentModel> createFeePayment(Map<String, dynamic> body) async { ... }
Future<FeePaymentModel> getFeePaymentById(String id) async { ... }
Future<Map<String, dynamic>> getFeeSummary(String month) async { ... }

// Timetable
Future<List<TimetableEntry>> getTimetable({
  required String classId, String? sectionId,
}) async { ... }
Future<Map<String, dynamic>> replaceTimetable(Map<String, dynamic> body) async {
  final res = await _dio.put(ApiConfig.schoolTimetableBulk, data: body);
  final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
  return data is Map<String, dynamic> ? data : {};
}

// Notices
Future<PaginationModel<SchoolNoticeModel>> getNotices({
  int page = 1, int limit = 20, String? search,
}) async { ... }
Future<SchoolNoticeModel> createNotice(Map<String, dynamic> body) async { ... }
Future<SchoolNoticeModel> updateNotice(String id, Map<String, dynamic> body) async { ... }
Future<void> deleteNotice(String id) async { ... }

// Notifications
Future<int> getUnreadNotificationCount() async { ... }
Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async { ... }
Future<void> markNotificationRead(String id) async { ... }

// Profile
Future<SchoolAdminProfileModel> getProfile() async { ... }
Future<AdminUserModel> updateUserProfile(Map<String, dynamic> body) async { ... }
Future<SchoolInfoModel> updateSchoolProfile(Map<String, dynamic> body) async { ... }
Future<void> changePassword({
  required String currentPassword, required String newPassword,
}) async {
  await _dio.post(ApiConfig.schoolChangePassword, data: {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  });
}
```

---

## Task 4: Create Riverpod Providers

Create directory: `e:/School_ERP_AI/erp-new-logic/lib/features/school_admin/presentation/providers/`

---

### `school_admin_dashboard_provider.dart`

```dart
final schoolAdminDashboardProvider = FutureProvider<DashboardStatsModel>((ref) async {
  return ref.read(schoolAdminServiceProvider).getDashboardStats();
});
```

---

### `school_admin_students_provider.dart`

Define state:
```dart
class SchoolAdminStudentsState {
  final List<StudentModel> students;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String search;
  final String? classId;
  final String? sectionId;
  final String? status;

  const SchoolAdminStudentsState({ ... });
  SchoolAdminStudentsState copyWith({ ... });
}
```

Notifier:
```dart
class SchoolAdminStudentsNotifier extends StateNotifier<SchoolAdminStudentsState> {
  SchoolAdminStudentsNotifier(this._service) : super(SchoolAdminStudentsState.initial());

  final SchoolAdminService _service;

  Future<void> load({ int page = 1 }) async { ... }
  Future<void> search(String query) async { ... }
  Future<void> filterByClass(String? classId) async { ... }
  Future<void> filterBySection(String? sectionId) async { ... }
  Future<void> filterByStatus(String? status) async { ... }
  Future<StudentModel> createStudent(Map<String, dynamic> body) async { ... }
  Future<StudentModel> updateStudent(String id, Map<String, dynamic> body) async { ... }
  Future<void> deleteStudent(String id) async { ... }
}

final schoolAdminStudentsProvider = StateNotifierProvider<
    SchoolAdminStudentsNotifier, SchoolAdminStudentsState>((ref) {
  return SchoolAdminStudentsNotifier(ref.read(schoolAdminServiceProvider));
});
```

---

### `school_admin_staff_provider.dart`

Same pattern as students provider. State fields: `staff`, `page`, `limit`, `total`, `totalPages`, `isLoading`, `error`, `search`, `designation`, `isActive`. Notifier methods: `load`, `search`, `filterByDesignation`, `filterByActive`, `createStaff`, `updateStaff`, `deleteStaff`.

---

### `school_admin_classes_provider.dart`

```dart
final schoolAdminClassesProvider = FutureProvider<List<SchoolClassModel>>((ref) async {
  return ref.read(schoolAdminServiceProvider).getClasses();
});

// Mutable notifier for CRUD operations
class SchoolAdminClassesNotifier extends StateNotifier<AsyncValue<List<SchoolClassModel>>> {
  SchoolAdminClassesNotifier(this._service) : super(const AsyncValue.loading());

  final SchoolAdminService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getClasses());
  }

  Future<void> createClass(Map<String, dynamic> body) async { ... }
  Future<void> updateClass(String id, Map<String, dynamic> body) async { ... }
  Future<void> deleteClass(String id) async { ... }
  Future<List<SectionModel>> getSections(String classId) async { ... }
  Future<void> createSection(String classId, Map<String, dynamic> body) async { ... }
  Future<void> updateSection(String id, Map<String, dynamic> body) async { ... }
  Future<void> deleteSection(String id) async { ... }
}

final schoolAdminClassesCrudProvider = StateNotifierProvider<
    SchoolAdminClassesNotifier, AsyncValue<List<SchoolClassModel>>>((ref) {
  return SchoolAdminClassesNotifier(ref.read(schoolAdminServiceProvider));
});
```

---

### `school_admin_attendance_provider.dart`

```dart
class SchoolAdminAttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;
  final String? selectedClassId;
  final String? selectedSectionId;
  final String selectedDate;   // "YYYY-MM-DD"
  // Mutable attendance map for bulk marking: studentId -> status
  final Map<String, String> pendingStatuses;
  final Map<String, String> pendingRemarks;

  const SchoolAdminAttendanceState({ ... });
  SchoolAdminAttendanceState copyWith({ ... });
}

class SchoolAdminAttendanceNotifier extends StateNotifier<SchoolAdminAttendanceState> {
  ...
  Future<void> loadAttendance({ required String classId, String? sectionId, required String date }) async { ... }
  void updatePendingStatus(String studentId, String status) { ... }
  void updatePendingRemarks(String studentId, String remarks) { ... }
  Future<void> submitBulkAttendance({ required String sectionId, required String date }) async { ... }
  Future<AttendanceReportModel> loadReport({ required String classId, String? sectionId, required String month }) async { ... }
}

final schoolAdminAttendanceProvider = StateNotifierProvider<
    SchoolAdminAttendanceNotifier, SchoolAdminAttendanceState>((ref) {
  return SchoolAdminAttendanceNotifier(ref.read(schoolAdminServiceProvider));
});
```

---

### `school_admin_fees_provider.dart`

```dart
class SchoolAdminFeesState {
  final List<FeeStructureModel> structures;
  final List<FeePaymentModel> payments;
  final int paymentsPage;
  final int paymentsTotal;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? feeSummary;

  const SchoolAdminFeesState({ ... });
  SchoolAdminFeesState copyWith({ ... });
}

class SchoolAdminFeesNotifier extends StateNotifier<SchoolAdminFeesState> {
  ...
  Future<void> loadStructures({ String? academicYear, String? classId }) async { ... }
  Future<void> createFeeStructure(Map<String, dynamic> body) async { ... }
  Future<void> updateFeeStructure(String id, Map<String, dynamic> body) async { ... }
  Future<void> deleteFeeStructure(String id) async { ... }
  Future<void> loadPayments({ int page = 1, String? studentId, String? month, String? academicYear }) async { ... }
  Future<FeePaymentModel> createFeePayment(Map<String, dynamic> body) async { ... }
  Future<void> loadFeeSummary(String month) async { ... }
}

final schoolAdminFeesProvider = StateNotifierProvider<
    SchoolAdminFeesNotifier, SchoolAdminFeesState>((ref) {
  return SchoolAdminFeesNotifier(ref.read(schoolAdminServiceProvider));
});
```

---

### `school_admin_timetable_provider.dart`

```dart
class SchoolAdminTimetableState {
  final List<TimetableEntry> entries;
  final bool isLoading;
  final String? error;
  final String? selectedClassId;
  final String? selectedSectionId;

  const SchoolAdminTimetableState({ ... });
  SchoolAdminTimetableState copyWith({ ... });
}

class SchoolAdminTimetableNotifier extends StateNotifier<SchoolAdminTimetableState> {
  ...
  Future<void> loadTimetable({ required String classId, String? sectionId }) async { ... }
  Future<void> saveTimetable({ required String classId, String? sectionId, required List<Map<String, dynamic>> entries }) async { ... }
}

final schoolAdminTimetableProvider = StateNotifierProvider<
    SchoolAdminTimetableNotifier, SchoolAdminTimetableState>((ref) {
  return SchoolAdminTimetableNotifier(ref.read(schoolAdminServiceProvider));
});
```

---

### `school_admin_notices_provider.dart`

Same paginated list pattern as students provider. State fields: `notices`, `page`, `limit`, `total`, `totalPages`, `isLoading`, `error`, `search`. Notifier methods: `load`, `search`, `createNotice`, `updateNotice`, `deleteNotice`.

---

### `school_admin_notifications_provider.dart`

```dart
final schoolAdminUnreadCountProvider = FutureProvider<int>((ref) async {
  return ref.read(schoolAdminServiceProvider).getUnreadNotificationCount();
});

final schoolAdminNotificationsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, page) async {
  return ref.read(schoolAdminServiceProvider).getNotifications(page: page);
});
```

---

### `school_admin_profile_provider.dart`

```dart
final schoolAdminProfileProvider = FutureProvider<SchoolAdminProfileModel>((ref) async {
  return ref.read(schoolAdminServiceProvider).getProfile();
});

class SchoolAdminProfileNotifier extends StateNotifier<AsyncValue<SchoolAdminProfileModel>> {
  ...
  Future<void> load() async { ... }
  Future<void> updateUserProfile(Map<String, dynamic> body) async { ... }
  Future<void> updateSchoolProfile(Map<String, dynamic> body) async { ... }
  Future<void> changePassword({ required String currentPassword, required String newPassword }) async { ... }
}

final schoolAdminProfileCrudProvider = StateNotifierProvider<
    SchoolAdminProfileNotifier, AsyncValue<SchoolAdminProfileModel>>((ref) {
  return SchoolAdminProfileNotifier(ref.read(schoolAdminServiceProvider));
});
```

---

## Task 5: Create Shell Layout

**File**: `e:/School_ERP_AI/erp-new-logic/lib/features/school_admin/presentation/school_admin_shell.dart`

Follow `lib/features/group_admin/presentation/group_admin_shell.dart` **exactly**. Adapt the following:

- Replace all color constants: `const Color _accentColor = Color(0xFF4CAF50)` and `const Color _badgeColor = Color(0xFF1B5E20)`
- Replace badge text: `'SCHOOL ADMIN'`
- Replace logout redirect: `context.go('/login/school')`
- Replace all route paths: `/group-admin/...` → `/school-admin/...`
- Replace profile provider: `groupAdminProfileProvider` → `schoolAdminProfileProvider` (returns `AsyncValue<SchoolAdminProfileModel>`)
- Replace initials fallback: `'SA'`
- Replace portal label in dialogs: `'School Admin portal'`

**Top bar tabs** (web layout horizontal tab bar):

```dart
const List<_TopBarTab> _topBarTabs = [
  _TopBarTab('Dashboard', '/school-admin/dashboard'),
  _TopBarTab('Students', '/school-admin/students'),
  _TopBarTab('Teachers', '/school-admin/staff'),
  _TopBarTab('Classes', '/school-admin/classes'),
  _TopBarTab('Attendance', '/school-admin/attendance'),
  _TopBarTab('Fees', '/school-admin/fees'),
  _TopBarTab('Timetable', '/school-admin/timetable'),
  _TopBarTab('Notices', '/school-admin/notices'),
  _TopBarTab('Notifications', '/school-admin/notifications'),
  _TopBarTab('Profile', '/school-admin/profile'),
];
```

**Sidebar nav items** (web layout left panel):

```dart
// Main section
_NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', route: '/school-admin/dashboard')
_NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Students', route: '/school-admin/students')
_NavItem(icon: Icons.person_search_outlined, activeIcon: Icons.person_search, label: 'Teachers', route: '/school-admin/staff')
_NavItem(icon: Icons.class_outlined, activeIcon: Icons.class_, label: 'Classes', route: '/school-admin/classes')
_NavItem(icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check, label: 'Attendance', route: '/school-admin/attendance')
_NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Fees', route: '/school-admin/fees')
_NavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Timetable', route: '/school-admin/timetable')
_NavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign, label: 'Notices', route: '/school-admin/notices')

// ACCOUNT section header
_NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifications', route: '/school-admin/notifications')
_NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', route: '/school-admin/profile')
_NavItem(icon: Icons.lock_reset_outlined, activeIcon: Icons.lock_reset, label: 'Change Password', route: '/school-admin/change-password')
_NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', route: '/school-admin/settings')
```

**Mobile bottom nav** (3 items):
- Dashboard (index 0)
- Students (index 1)
- More / menu (index 2 → opens drawer)

**Mobile drawer** includes all nav items in order matching sidebar above.

**`isActive` detection**: Use `loc.contains('/school-admin/dashboard')` etc., except for profile use exact match `loc == '/school-admin/profile'`.

---

## Task 6: Create Screens

Create directory: `e:/School_ERP_AI/erp-new-logic/lib/features/school_admin/presentation/screens/`

Each screen is a `ConsumerWidget` or `ConsumerStatefulWidget` that reads from providers. Use Material 3 widgets. Apply `_accentColor` (green) for primary buttons, active states, and highlights throughout.

---

### `school_admin_dashboard_screen.dart`

State: watch `schoolAdminDashboardProvider` (FutureProvider).

UI layout (web: grid of stat cards + activity feed; mobile: scrollable column):

**6 stat cards**:
- "Total Students" — value: `totalStudents`, icon: `Icons.people`, color: green
- "Total Staff" — value: `totalStaff`, icon: `Icons.badge`, color: blue
- "Classes" — value: `totalClasses`, icon: `Icons.class_`, color: orange
- "Sections" — value: `totalSections`, icon: `Icons.splitscreen`, color: purple
- "Attendance Today" — value: `"${todayAttendancePercent}%"`, icon: `Icons.fact_check`, color: teal
- "Fee Collected (Month)" — value: `"₹${feeCollectedThisMonth}"`, icon: `Icons.payments`, color: red

**Recent Activity** section: list of `RecentActivityItem` rows with icon, type label, message, and formatted date.

Handle loading state with `CircularProgressIndicator` centered, error state with error text and retry button.

---

### `school_admin_students_screen.dart`

State: watch `schoolAdminStudentsProvider`.

UI:
- Search bar at top
- Filter chips row: status filter (All / Active / Inactive / Transferred), class dropdown
- Paginated list of student cards showing: photo avatar (or initials), full name, admission no, class+section, status badge
- FAB with `Icons.person_add` to open add student dialog/bottom sheet
- Pull-to-refresh triggers `ref.read(schoolAdminStudentsProvider.notifier).load()`
- Tapping a student card navigates to `/school-admin/students/:id`

---

### `school_admin_student_detail_screen.dart`

Receives `studentId` from route params (`:id`).

UI tabs:
1. **Profile** — photo, full personal info, parent info
2. **Attendance** — quick summary (present%, absent days)
3. **Fees** — list of fee payments

Actions (top-right): Edit button → opens edit dialog, Delete button → confirmation dialog → soft delete → go back.

---

### `school_admin_staff_screen.dart`

Same structure as students screen. State: `schoolAdminStaffProvider`.

Filter: designation dropdown (All / Teacher / Clerk / Librarian / Accountant / Principal), active status toggle.

Staff cards show: avatar/initials, full name, employee no, designation, subjects (as chips, truncated to 3), active/inactive badge.

FAB: `Icons.person_add` → add staff dialog.

---

### `school_admin_staff_detail_screen.dart`

Tabs: Profile (all personal and professional info, subjects list), Schedule (placeholder — links to timetable for this staff).

---

### `school_admin_classes_screen.dart`

State: watch `schoolAdminClassesCrudProvider`.

UI: Accordion/expansion tile list. Each class card expands to show its sections (with student count and class teacher name).

Inline actions per class: Edit (pencil icon) → edit dialog, Delete (trash icon) → confirmation.

Per section: Edit, Delete buttons. "Add Section" button inside each class card.

FAB: Add Class.

**Add/Edit Class dialog**:
- TextField: Class Name (required)
- TextField: Numeric order (optional integer)
- Save / Cancel buttons

**Add/Edit Section dialog**:
- TextField: Section Name (required, e.g. "A")
- Dropdown: Class Teacher (optional, list from staff)
- TextField: Capacity (integer, default 40)

---

### `school_admin_attendance_screen.dart`

State: `schoolAdminAttendanceProvider`.

UI:
- Top controls: Class dropdown, Section dropdown (populated based on class), Date picker (defaults to today)
- Load Attendance button → calls `loadAttendance`
- List of student rows:
  - Student name + roll no
  - Toggle buttons for status: P (Present) / A (Absent) / L (Late) — colored chips
  - Remarks text field (expandable on tap)
- Submit Attendance button (bottom, green) → calls `submitBulkAttendance`
- Link to Report → navigates to `/school-admin/attendance/report`

---

### `school_admin_attendance_report_screen.dart`

State: watches `schoolAdminAttendanceProvider` report result.

UI:
- Class + Section + Month picker controls
- Calendar grid (6 columns for days of week × rows for weeks) with color coding: green = high attendance, yellow = moderate, red = low
- Summary row: Present Days, Absent Days, Total Days

---

### `school_admin_fees_screen.dart`

State: `schoolAdminFeesProvider`.

UI tabs:
1. **Fee Structures** — list of fee structures with feeHead, amount, frequency, class, academic year. FAB to add structure. Edit/delete per item.
2. **Payments** — paginated list of fee payment records with filter by student, month, academic year. FAB to record new payment.
3. **Summary** — month picker → shows total collected and breakdown by fee head as a simple bar chart or list.

**Add/Edit Fee Structure dialog**:
- Academic Year input (e.g. "2025-26")
- Fee Head input
- Amount input (decimal)
- Frequency dropdown: Monthly / Quarterly / Annually / One Time
- Class dropdown (optional — "All Classes" as default)
- Due Day input (integer 1–31, optional)

**Record Fee Payment dialog**:
- Student search/dropdown
- Fee Head input
- Academic Year input
- Amount input
- Payment Date picker
- Payment Mode dropdown: Cash / UPI / Bank Transfer / Cheque
- Receipt No input
- Remarks (optional)

---

### `school_admin_fee_collection_screen.dart`

Dedicated screen for recording a fee payment (opened from `/school-admin/fees/collection`). Full-page form version of the fee payment dialog above. On submit, navigate back to `/school-admin/fees`.

---

### `school_admin_timetable_screen.dart`

State: `schoolAdminTimetableProvider`.

UI:
- Class and Section dropdown controls at top
- Weekly grid table: rows = periods (1–8), columns = days (Mon–Sat)
- Each cell shows: subject, staff name, time range, room
- Edit mode toggle: in edit mode, each cell becomes tappable to open a period edit dialog
- Save button (only visible in edit mode) → calls `saveTimetable`

**Period Edit dialog**:
- Subject input
- Staff dropdown (from staff list)
- Start Time / End Time pickers
- Room input (optional)
- Clear button to remove the period

---

### `school_admin_notices_screen.dart`

State: `schoolAdminNoticesProvider`.

UI:
- Search bar
- List of notice cards: title, target role badge, pinned indicator (pin icon if `isPinned`), published date, body preview (max 2 lines)
- FAB: Add Notice
- Swipe-to-delete or context menu (Edit, Delete)

**Add/Edit Notice dialog**:
- Title input
- Body textarea
- Target Role dropdown: All / Teachers / Students / Parents
- Pin toggle switch
- Published At date-time picker (optional)
- Expires At date-time picker (optional)

---

### `school_admin_notifications_screen.dart`

State: `schoolAdminNotificationsProvider`.

UI: Paginated list of notification items. Each item shows type icon, message, date. Tap to mark as read. All unread items have a subtle highlight. Empty state: "No notifications yet."

---

### `school_admin_profile_screen.dart`

State: `schoolAdminProfileCrudProvider`.

UI sections:
1. **School Information** — logo, name, email, phone, address, city, state. Edit button → opens edit school info dialog.
2. **Your Account** — avatar, first/last name, email, phone. Edit button → opens edit user info dialog.

**Edit User Info dialog**: first name, last name, phone, avatar upload (optional base64 picker).

**Edit School Info dialog**: school name, email, phone, address, city, state.

---

### `school_admin_change_password_screen.dart`

Full-page screen (not dialog).

UI: three password fields — Current Password, New Password, Confirm New Password. Validation: new password min 8 chars, passwords must match. Submit button. On success: show SnackBar "Password changed" and navigate back.

Error handling: if API returns 401, show "Current password is incorrect" inline.

---

### `school_admin_settings_screen.dart`

Placeholder screen with title "Settings" and message "Settings coming soon." — consistent with the pattern in `lib/features/super_admin/presentation/screens/super_admin_placeholder_screen.dart`.

---

## Task 7: Update GoRouter

**File**: `e:/School_ERP_AI/erp-new-logic/lib/routes/app_router.dart`

### Step 1: Add all imports at the top of the file

```dart
import '../features/school_admin/presentation/school_admin_shell.dart';
import '../features/school_admin/presentation/screens/school_admin_dashboard_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_students_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_student_detail_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_staff_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_staff_detail_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_classes_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_attendance_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_attendance_report_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_fees_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_fee_collection_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_timetable_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_notices_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_notifications_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_profile_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_change_password_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_settings_screen.dart';
```

### Step 2: Add redirect logic

In the `redirect` callback, find the block that handles group admin and add this block **after** it:

```dart
// School Admin redirect
final isSchoolAdmin = portalType.value == 'school_admin';
if (isAuthenticated && isSchoolAdmin && !loc.startsWith('/school-admin')) {
  return '/school-admin/dashboard';
}
if (!isAuthenticated && loc.startsWith('/school-admin')) {
  return '/login/school';
}
```

### Step 3: Add ShellRoute

In the `routes:` list of the GoRouter, add this ShellRoute **after** the Group Admin ShellRoute:

```dart
ShellRoute(
  builder: (context, state, child) => SchoolAdminShell(child: child),
  routes: [
    GoRoute(
      path: '/school-admin',
      redirect: (_, __) => '/school-admin/dashboard',
    ),
    GoRoute(
      path: '/school-admin/dashboard',
      builder: (context, state) => const SchoolAdminDashboardScreen(),
    ),
    GoRoute(
      path: '/school-admin/students',
      builder: (context, state) => const SchoolAdminStudentsScreen(),
    ),
    GoRoute(
      path: '/school-admin/students/:id',
      builder: (context, state) => SchoolAdminStudentDetailScreen(
        studentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/school-admin/staff',
      builder: (context, state) => const SchoolAdminStaffScreen(),
    ),
    GoRoute(
      path: '/school-admin/staff/:id',
      builder: (context, state) => SchoolAdminStaffDetailScreen(
        staffId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/school-admin/classes',
      builder: (context, state) => const SchoolAdminClassesScreen(),
    ),
    GoRoute(
      path: '/school-admin/attendance',
      builder: (context, state) => const SchoolAdminAttendanceScreen(),
    ),
    GoRoute(
      path: '/school-admin/attendance/report',
      builder: (context, state) => const SchoolAdminAttendanceReportScreen(),
    ),
    GoRoute(
      path: '/school-admin/fees',
      builder: (context, state) => const SchoolAdminFeesScreen(),
    ),
    GoRoute(
      path: '/school-admin/fees/collection',
      builder: (context, state) => const SchoolAdminFeeCollectionScreen(),
    ),
    GoRoute(
      path: '/school-admin/timetable',
      builder: (context, state) => const SchoolAdminTimetableScreen(),
    ),
    GoRoute(
      path: '/school-admin/notices',
      builder: (context, state) => const SchoolAdminNoticesScreen(),
    ),
    GoRoute(
      path: '/school-admin/notifications',
      builder: (context, state) => const SchoolAdminNotificationsScreen(),
    ),
    GoRoute(
      path: '/school-admin/profile',
      builder: (context, state) => const SchoolAdminProfileScreen(),
    ),
    GoRoute(
      path: '/school-admin/change-password',
      builder: (context, state) => const SchoolAdminChangePasswordScreen(),
    ),
    GoRoute(
      path: '/school-admin/settings',
      builder: (context, state) => const SchoolAdminSettingsScreen(),
    ),
  ],
),
```

---

## Task 8: Navigation Flows

| From | Action | Navigate to |
|---|---|---|
| Any `/school-admin/*` | Logout | `/login/school` |
| `/school-admin/students` | Tap student card | `/school-admin/students/:id` |
| `/school-admin/students/:id` | Back button | `/school-admin/students` |
| `/school-admin/staff` | Tap staff card | `/school-admin/staff/:id` |
| `/school-admin/attendance` | "View Report" link | `/school-admin/attendance/report` |
| `/school-admin/fees` tab Payments | FAB | `/school-admin/fees/collection` |
| `/school-admin/fees/collection` | Submit or Cancel | `/school-admin/fees` |
| Any screen | Sidebar/tab nav | Corresponding `/school-admin/*` route |
| Login success with portalType=school_admin | Auto-redirect | `/school-admin/dashboard` |

---

## Design System Usage

Use these consistently:

- **Primary color** for buttons, active nav states, FABs, stat card icons: `Color(0xFF4CAF50)`
- **Badge/dark accent**: `Color(0xFF1B5E20)` for the portal badge background and active nav indicator border
- **AppLogoWidget**: `AppLogoWidget(size: 32, showText: true)` in sidebar header
- **Status badges**: use small `Container` with `BorderRadius.circular(6)` and matching color
  - ACTIVE: green `Color(0xFFE8F5E9)` bg, `Color(0xFF1B5E20)` text
  - INACTIVE: grey bg, grey text
  - TRANSFERRED: orange bg, orange text
  - PRESENT: green
  - ABSENT: red
  - LATE: amber
- **Loading states**: `CircularProgressIndicator(color: Color(0xFF4CAF50))`
- **Error states**: `Text(error, style: TextStyle(color: Colors.red))` with a retry `TextButton`
- **Empty states**: centered column with `Icons.inbox_outlined` (grey, size 64) and descriptive text

---

## File Output Checklist

- [ ] `lib/core/config/api_config.dart` — school admin endpoint constants added
- [ ] `lib/models/school_admin/dashboard_stats_model.dart`
- [ ] `lib/models/school_admin/student_model.dart`
- [ ] `lib/models/school_admin/staff_model.dart`
- [ ] `lib/models/school_admin/school_class_model.dart`
- [ ] `lib/models/school_admin/section_model.dart`
- [ ] `lib/models/school_admin/attendance_model.dart`
- [ ] `lib/models/school_admin/fee_structure_model.dart`
- [ ] `lib/models/school_admin/fee_payment_model.dart`
- [ ] `lib/models/school_admin/school_notice_model.dart`
- [ ] `lib/models/school_admin/timetable_model.dart`
- [ ] `lib/models/school_admin/school_admin_profile_model.dart`
- [ ] `lib/core/services/school_admin_service.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_dashboard_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_students_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_staff_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_classes_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_attendance_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_fees_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_timetable_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_notices_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_notifications_provider.dart`
- [ ] `lib/features/school_admin/presentation/providers/school_admin_profile_provider.dart`
- [ ] `lib/features/school_admin/presentation/school_admin_shell.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_dashboard_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_students_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_student_detail_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_staff_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_staff_detail_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_classes_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_attendance_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_attendance_report_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_fees_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_fee_collection_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_timetable_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_notices_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_notifications_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_profile_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_change_password_screen.dart`
- [ ] `lib/features/school_admin/presentation/screens/school_admin_settings_screen.dart`
- [ ] `lib/routes/app_router.dart` — imports, redirect logic, and ShellRoute added
