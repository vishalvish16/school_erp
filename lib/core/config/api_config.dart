// =============================================================================
// FILE: lib/core/config/api_config.dart
// PURPOSE: Centralized API configurations and environment-specific variables
// =============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /// Backend port — must match backend .env PORT (default 3000)
  static const int backendPort = 3000;

  /// Override: flutter run --dart-define=API_HOST=192.168.1.100
  /// Emulator: 10.0.2.2 = host localhost. If connection timeout:
  ///   1. Ensure backend runs on 0.0.0.0 (not just 127.0.0.1)
  ///   2. Try: adb reverse tcp:3000 tcp:3000 then run with --dart-define=API_HOST=127.0.0.1
  static String get _host {
    const fromEnv = String.fromEnvironment(
      'API_HOST',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2'; // Emulator; use --dart-define for physical device
    return 'localhost';
  }

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_HOST', defaultValue: '');
    if (fromEnv.isNotEmpty) return 'https://$fromEnv'; // tunnel URL (no port needed)
    return 'http://$_host:$backendPort'; // local dev
  }

  // Specific endpoints
  static const String loginEndpoint = '/api/platform/auth/login';
  static const String forgotPasswordEndpoint =
      '/api/platform/auth/forgot-password';
  static const String resetPasswordEndpoint =
      '/api/platform/auth/reset-password';

  // Group Admin Portal endpoints
  static const String groupAdminBase = '/api/platform/group-admin';
  static const String groupAdminAuth = '/api/platform/auth/group-admin';
  static const String groupAdminLogin = '$groupAdminAuth/login';
  static const String groupAdminForgotPassword = '$groupAdminAuth/forgot-password';
  static const String groupAdminResetPassword = '$groupAdminAuth/reset-password';
  static const String groupAdminDashboard = '$groupAdminBase/dashboard/stats';
  static const String groupAdminSchools = '$groupAdminBase/schools';
  static const String groupAdminProfile = '$groupAdminBase/profile';
  static const String groupAdminChangePassword = '$groupAdminBase/change-password';
  static const String groupAdminNotifications = '$groupAdminBase/notifications';

  // School Admin Portal endpoints
  static const String schoolDashboardStats = '/api/school/dashboard/stats';
  static const String schoolStudents       = '/api/school/students';
  static const String schoolStaff          = '/api/school/staff';
  static const String schoolStaffBase      = '/api/school/staff';
  static const String schoolLeavesBase     = '/api/school/staff/leaves';
  static const String schoolClasses        = '/api/school/classes';
  static const String schoolSections       = '/api/school/sections';
  static const String schoolAttendance     = '/api/school/attendance';
  static const String schoolFeeStructures  = '/api/school/fees/structures';
  static const String schoolFeePayments    = '/api/school/fees/payments';
  static const String schoolFeeSummary     = '/api/school/fees/summary';
  static const String schoolTimetable      = '/api/school/timetable';
  static const String schoolNotices        = '/api/school/notices';
  static const String schoolNotifications  = '/api/school/notifications';
  static const String schoolProfile        = '/api/school/profile';
  static const String schoolChangePassword = '/api/school/auth/change-password';
  static const String schoolParents        = '/api/school/parents';

  // Staff Portal endpoints
  static const String staffDashboard       = '/api/staff/dashboard/stats';
  static const String staffFeePayments     = '/api/staff/fees/payments';
  static const String staffFeeStructures   = '/api/staff/fees/structures';
  static const String staffFeeSummary      = '/api/staff/fees/summary';
  static const String staffStudents        = '/api/staff/students';
  static const String staffClasses         = '/api/staff/classes';
  static const String staffNotices         = '/api/staff/notices';
  static const String staffNotifications   = '/api/staff/notifications';
  static const String staffProfile         = '/api/staff/profile';
  static const String staffChangePassword  = '/api/staff/auth/change-password';

  // Student Report (school admin + staff)
  // Append /{id}/report, /{id}/attendance, /{id}/fees, /{id}/notices
  static const String schoolStudentReport = '/api/school/students';
  static const String staffStudentReport  = '/api/staff/students';

  // Non-Teaching Staff Module endpoints (School Admin)
  static const String nonTeachingRoles       = '/api/school/non-teaching/roles';
  static const String nonTeachingStaff       = '/api/school/non-teaching/staff';
  static const String nonTeachingAttendance  = '/api/school/non-teaching/attendance';
  static const String nonTeachingLeaves      = '/api/school/non-teaching/leaves';

  // Staff Portal — self-service endpoints
  static const String staffMyProfile         = '/api/staff/my/profile';
  static const String staffMyAttendance      = '/api/staff/my/attendance';
  static const String staffMyLeaves          = '/api/staff/my/leaves';
  static const String staffMyLeaveSummary    = '/api/staff/my/leave-summary';
  static const String staffPayslip           = '/api/staff/my/payslip';

  // Driver Portal endpoints
  static const String driverBase = '/api/driver';
  static const String driverDashboard = '$driverBase/dashboard/stats';
  static const String driverProfile = '$driverBase/profile';
  static const String driverChangePassword = '$driverBase/auth/change-password';
  static const String driverTripStart = '$driverBase/trip/start';
  static const String driverTripEnd = '$driverBase/trip/end';
  static const String driverLocation = '$driverBase/location';

  // School Transport — vehicles
  static const String schoolTransportBase = '/api/school/transport';
  static const String schoolTransportVehicles = '$schoolTransportBase/vehicles';
  static const String schoolTransportVehiclesLive = '$schoolTransportBase/vehicles/live';
  static const String schoolTransportLive = schoolTransportVehiclesLive; // alias
  static const String schoolTransportDrivers = '$schoolTransportBase/drivers';
  static const String schoolTransportStudentsUnassigned = '$schoolTransportBase/students/unassigned';
  // student/parent endpoints on same base (auth guards differ)
  static const String schoolTransportMyVehicle = '$schoolTransportBase/my-vehicle';
  static const String schoolTransportMyTrips = '$schoolTransportBase/my-trips';

  // Socket.IO real-time server URL
  static String get socketUrl => baseUrl;

  // Student Portal endpoints
  static const String studentBase = '/api/student';
  static const String studentLiveDrivers = '$studentBase/transport/live';
  static const String studentProfile = '$studentBase/profile';
  static const String studentDashboard = '$studentBase/dashboard';
  static const String studentAttendance = '$studentBase/attendance';
  static const String studentAttendanceSummary = '$studentBase/attendance/summary';
  static const String studentFeeDues = '$studentBase/fees/dues';
  static const String studentFeePayments = '$studentBase/fees/payments';
  static const String studentFeeReceipt = '$studentBase/fees/receipt';
  static const String studentTimetable = '$studentBase/timetable';
  static const String studentNotices = '$studentBase/notices';
  static const String studentDocuments = '$studentBase/documents';
  static const String studentChangePassword = '$studentBase/auth/change-password';

  // Student Profile Requests (school admin / staff)
  static const String schoolProfileRequests = '/api/school/student-profile-requests';
  static const String schoolProfileRequestsPendingCount = '/api/school/student-profile-requests/pending-count';

  // Student Profile Requests (parent)
  static const String parentProfileRequests = '/api/parent/student-profile-requests';

  // Parent Portal endpoints
  static const String parentBase = '/api/parent';
  static const String parentDashboard = '$parentBase/dashboard';
  static const String parentProfile = '$parentBase/profile';
  static const String parentChildren = '$parentBase/children';
  static const String parentNotices = '$parentBase/notices';
  static const String parentNotifications = '$parentBase/notifications';
  static const String parentNotificationsUnreadCount = '$parentBase/notifications/unread-count';
  static const String parentChangePassword = '$parentBase/auth/change-password';

  // FCM token registration (requires parent/student auth)
  static const String parentFcmRegister = '$parentBase/fcm/register';
  static const String studentFcmRegister = '$studentBase/fcm/register';

  // Auth (parent login)
  static const String resolveUserByPhone = '/api/platform/auth/resolve-user-by-phone';
  static const String verifyParentOtp = '/api/platform/auth/verify-parent-otp';
  static const String verifyStudentOtp = '/api/platform/auth/verify-student-otp';

  // Teacher Portal endpoints
  static const String teacherDashboard       = '/api/teacher/dashboard';
  static const String teacherSections        = '/api/teacher/sections';
  static const String teacherAttendance      = '/api/teacher/attendance';
  static const String teacherAttendanceReport = '/api/teacher/attendance/report';
  static const String teacherHomework        = '/api/teacher/homework';
  static const String teacherDiary           = '/api/teacher/diary';
  static const String teacherProfile         = '/api/teacher/profile';

  // Enhanced Super Admin group endpoints
  static const String superAdminGroupDetail = '/api/platform/super-admin/groups'; // + /{id}

  // Theme configuration endpoints
  static const String superAdminTheme      = '/api/platform/theme';
  static const String superAdminThemeApply = '/api/platform/theme/apply';
  static const String schoolTheme          = '/api/school/theme';
  static const String parentTheme          = '/api/parent/theme';

  // Request settings (30s for emulator/slow networks; 10.0.2.2 can be slow)
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
