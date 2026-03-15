// =============================================================================
// FILE: lib/routes/app_router.dart
// PURPOSE: Centralized GoRouter configuration with Auth Guard and Shell patterns.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/device_verification_screen.dart';
import '../features/auth/verify_2fa_screen.dart';
import '../features/auth/group_admin_login_screen.dart';
import '../features/auth/school_admin_login_screen.dart';
import '../features/group_admin/presentation/group_admin_shell.dart';
import '../features/group_admin/presentation/screens/group_admin_dashboard_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_schools_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_school_detail_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_notifications_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_profile_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_edit_profile_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_change_password_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_forgot_password_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_reset_password_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_analytics_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_reports_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_students_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_notices_screen.dart';
import '../features/group_admin/presentation/screens/group_admin_alerts_screen.dart';
import '../features/school_admin/presentation/school_admin_shell.dart';
import '../features/school_admin/presentation/screens/school_admin_dashboard_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_students_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_student_detail_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_staff_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_staff_detail_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_staff_form_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_leaves_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_leave_apply_screen.dart';
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
import '../features/school_admin/presentation/screens/school_admin_non_teaching_staff_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_non_teaching_staff_form_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_non_teaching_staff_detail_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_non_teaching_roles_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_non_teaching_attendance_screen.dart';
import '../features/school_admin/presentation/screens/school_admin_non_teaching_leaves_screen.dart';
import '../features/auth/staff_login_screen.dart';
import '../features/auth/driver_login_screen.dart';
import '../features/teacher/presentation/teacher_shell.dart';
import '../features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import '../features/teacher/presentation/screens/teacher_attendance_screen.dart';
import '../features/teacher/presentation/screens/teacher_attendance_report_screen.dart';
import '../features/teacher/presentation/screens/teacher_homework_screen.dart';
import '../features/teacher/presentation/screens/teacher_homework_form_screen.dart';
import '../features/teacher/presentation/screens/teacher_homework_detail_screen.dart';
import '../features/teacher/presentation/screens/teacher_diary_screen.dart';
import '../features/teacher/presentation/screens/teacher_diary_form_screen.dart';
import '../features/teacher/presentation/screens/teacher_profile_screen.dart';
import '../features/staff/presentation/staff_shell.dart';
import '../features/staff/presentation/screens/staff_dashboard_screen.dart';
import '../features/staff/presentation/screens/staff_fees_screen.dart';
import '../features/staff/presentation/screens/staff_students_screen.dart';
import '../features/staff/presentation/screens/staff_student_detail_screen.dart';
import '../features/staff/presentation/screens/staff_notices_screen.dart';
import '../features/staff/presentation/screens/staff_notice_detail_screen.dart';
import '../features/staff/presentation/screens/staff_notifications_screen.dart';
import '../features/staff/presentation/screens/staff_profile_screen.dart';
import '../features/staff/presentation/screens/staff_change_password_screen.dart';
import '../features/staff/presentation/screens/staff_my_attendance_screen.dart';
import '../features/staff/presentation/screens/staff_apply_leave_screen.dart';
import '../features/staff/presentation/screens/staff_my_leaves_screen.dart';
import '../features/staff/presentation/screens/staff_payslip_screen.dart';
import '../features/driver/presentation/driver_shell.dart';
import '../features/driver/presentation/screens/driver_dashboard_screen.dart';
import '../features/driver/presentation/screens/driver_profile_screen.dart';
import '../features/driver/presentation/screens/driver_change_password_screen.dart';
import '../features/auth/parent_login_screen.dart';
import '../features/parent/presentation/parent_shell.dart';
import '../features/parent/presentation/screens/parent_dashboard_screen.dart';
import '../features/parent/presentation/screens/parent_profile_screen.dart';
import '../features/parent/presentation/screens/parent_children_list_screen.dart';
import '../features/parent/presentation/screens/parent_child_detail_screen.dart';
import '../features/parent/presentation/screens/parent_child_attendance_screen.dart';
import '../features/parent/presentation/screens/parent_child_fees_screen.dart';
import '../features/parent/presentation/screens/parent_notices_screen.dart';
import '../features/parent/presentation/screens/parent_notice_detail_screen.dart';
import '../features/student/presentation/student_shell.dart';
import '../features/student/presentation/screens/student_dashboard_screen.dart';
import '../features/student/presentation/screens/student_profile_screen.dart';
import '../features/student/presentation/screens/student_attendance_screen.dart';
import '../features/student/presentation/screens/student_fees_screen.dart';
import '../features/student/presentation/screens/student_timetable_screen.dart';
import '../features/student/presentation/screens/student_notices_screen.dart';
import '../features/student/presentation/screens/student_notice_detail_screen.dart';
import '../features/student/presentation/screens/student_documents_screen.dart';
import '../features/student/presentation/screens/student_change_password_screen.dart';
import '../features/auth/school_setup_screen.dart';
import '../features/auth/auth_guard_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/schools/presentation/views/schools_screen.dart';
import '../features/schools/presentation/views/platform_school_detail_page.dart';
import '../features/subscription/presentation/pages/subscription_page.dart';
import '../features/super_admin/presentation/super_admin_shell.dart';
import '../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_schools_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_plans_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_billing_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_groups_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_features_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_hardware_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_admins_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_audit_logs_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_security_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_change_password_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_profile_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_infra_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_notifications_screen.dart';
import '../shared/layouts/admin_layout.dart';
import '../design_system/tokens/app_spacing.dart';

/// Global navigation keys for multi-level routing
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Simple provider to expose the authentication status
final authStateProvider = Provider<bool>((ref) {
  return ref.watch(authGuardProvider).isAuthenticated;
});

/// Exposes whether the current user is a super admin (from JWT portal_type)
final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(authGuardProvider).isSuperAdmin;
});

/// Centralized Router Provider that reactively handles authentication redirects
final routerProvider = Provider<GoRouter>((ref) {
  // Creating a listenable value to safely push downstream state to GoRouter
  final currentAuth = ValueNotifier<bool>(false);

  // Updating listenable reactively without forcefully recreating GoRouter Object mapping
  ref.listen<bool>(
    authStateProvider,
    (_, isAuth) => currentAuth.value = isAuth,
    fireImmediately: true,
  );

  final isSuperAdmin = ValueNotifier<bool>(
    ref.read(authGuardProvider).isSuperAdmin,
  );
  final portalType = ValueNotifier<String?>(
    ref.read(authGuardProvider).portalType,
  );
  ref.listen(authGuardProvider, (_, authState) {
    isSuperAdmin.value = authState.isSuperAdmin;
    portalType.value = authState.portalType;
  });

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: Listenable.merge([currentAuth, isSuperAdmin, portalType]),
    redirect: (context, state) {
      final isAuthenticated = currentAuth.value;
      final superAdmin = isSuperAdmin.value;
      final loc = state.matchedLocation;
      final isLogin =
          loc == '/login' ||
          loc.startsWith('/login/group') ||
          loc.startsWith('/login/school') ||
          loc.startsWith('/login/staff') ||
          loc.startsWith('/login/driver') ||
          loc.startsWith('/login/parent') ||
          loc.startsWith('/login/student');
      final isSplashing = loc == '/splash';
      final isRecovering = loc == '/forgot-password';
      final isResetting = loc == '/reset-password';
      final isDeviceVerify = loc.startsWith('/device-verification');
      final isVerify2fa = loc.startsWith('/verify-2fa');
      final isSchoolSetup = loc == '/school-setup';
      final isGroupAdminPublic = loc.startsWith('/group-admin/forgot-password') ||
          loc.startsWith('/group-admin/reset-password');
      final isGroupAdminRoute = loc.startsWith('/group-admin');
      final isSchoolAdminRoute = loc.startsWith('/school-admin');
      final isTeacherRoute = loc.startsWith('/teacher');
      final isStaffRoute = loc.startsWith('/staff');
      final isDriverRoute = loc.startsWith('/driver');
      final isStudentRoute = loc.startsWith('/student');
      final isParentRoute = loc.startsWith('/parent');

      if (!isAuthenticated) {
        if (!isLogin &&
            !isRecovering &&
            !isResetting &&
            !isSplashing &&
            !isDeviceVerify &&
            !isVerify2fa &&
            !isSchoolSetup &&
            !isGroupAdminPublic) {
          // Protect group admin routes
          if (isGroupAdminRoute && !isGroupAdminPublic) {
            return '/login/group';
          }
          // Protect school admin routes
          if (isSchoolAdminRoute) {
            return '/login/school';
          }
          // Protect teacher routes
          if (isTeacherRoute) {
            return '/login/staff';
          }
          // Protect staff routes
          if (isStaffRoute) {
            return '/login/staff';
          }
          // Protect driver routes
          if (isDriverRoute) {
            return '/login/driver';
          }
          // Protect student routes
          if (isStudentRoute) {
            return '/login/student';
          }
          // Protect parent routes
          if (isParentRoute) {
            return '/login/parent';
          }
          return '/splash';
        }
        return null;
      }

      // /login (exact) is Super Admin login — always redirect to super-admin dashboard
      if (loc == '/login') return '/super-admin/dashboard';

      // Teacher redirect logic (portal_type 'teacher' stored by login flow)
      final isTeacher = portalType.value == 'teacher';
      if (isAuthenticated && isTeacher && !isTeacherRoute) {
        return '/teacher/dashboard';
      }

      // Staff redirect logic
      final isStaff = portalType.value == 'staff';
      if (isAuthenticated && isStaff && !isStaffRoute && !isTeacherRoute) {
        return '/staff/dashboard';
      }

      // Student redirect logic
      final isStudent = portalType.value == 'student';
      if (isAuthenticated && isStudent && !isStudentRoute) {
        return '/student/dashboard';
      }

      // Parent redirect logic
      final isParent = portalType.value == 'parent';
      if (isAuthenticated && isParent && !isParentRoute) {
        return '/parent/dashboard';
      }

      // School admin redirect logic
      final isSchoolAdmin = portalType.value == 'school_admin';
      if (isAuthenticated && isSchoolAdmin && !isSchoolAdminRoute) {
        return '/school-admin/dashboard';
      }

      // Group admin redirect logic
      final isGroupAdmin = portalType.value == 'group_admin';
      if (isAuthenticated && isGroupAdmin && !isGroupAdminRoute && !isGroupAdminPublic) {
        return '/group-admin/dashboard';
      }

      // Device-verification and verify-2fa — redirect based on portal type after auth
      if ((isDeviceVerify || isVerify2fa) && isAuthenticated) {
        if (isTeacher) return '/teacher/dashboard';
        if (isStaff) return '/staff/dashboard';
        if (isStudent) return '/student/dashboard';
        if (isParent) return '/parent/dashboard';
        final isDriverPostAuth = portalType.value == 'driver';
        if (isDriverPostAuth) return '/driver/dashboard';
        if (isSchoolAdmin) return '/school-admin/dashboard';
        if (isGroupAdmin) return '/group-admin/dashboard';
        return '/super-admin/dashboard';
      }

      if (isLogin || isRecovering || isResetting) {
        if (isTeacher) return '/teacher/dashboard';
        if (isStaff) return '/staff/dashboard';
        if (isStudent) return '/student/dashboard';
        if (isParent) return '/parent/dashboard';
        if (portalType.value == 'driver') return '/driver/dashboard';
        if (isSchoolAdmin) return '/school-admin/dashboard';
        if (isGroupAdmin) return '/group-admin/dashboard';
        return superAdmin ? '/super-admin/dashboard' : '/dashboard';
      }

      // Super admin on regular admin routes → redirect to super admin
      if (superAdmin &&
          (loc == '/dashboard' ||
              loc.startsWith('/dashboard') ||
              loc == '/schools' ||
              loc == '/plans')) {
        return '/super-admin/dashboard';
      }

      return null;
    },
    routes: [
      // ── Public Access ──────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/school-setup',
        builder: (context, state) => const SchoolSetupScreen(),
      ),
      GoRoute(
        path: '/login/group',
        builder: (context, state) => const GroupAdminLoginScreen(),
      ),
      GoRoute(
        path: '/login/school',
        builder: (context, state) => const SchoolAdminLoginScreen(),
      ),
      GoRoute(
        path: '/login/staff',
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        path: '/login/driver',
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: '/login/parent',
        builder: (context, state) => ParentLoginScreen(key: ValueKey('parent')),
      ),
      GoRoute(
        path: '/login/student',
        builder: (context, state) => ParentLoginScreen(
          key: ValueKey('student'),
          initialUserType: ParentStudentUserType.student,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/group-admin/forgot-password',
        builder: (context, state) => const GroupAdminForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/group-admin/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return GroupAdminResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/device-verification',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return DeviceVerificationScreen(
            otpSessionId: params['otp_session_id'] ?? '',
            maskedPhone: params['masked_phone']?.isNotEmpty == true
                ? params['masked_phone']
                : null,
            maskedEmail: params['masked_email']?.isNotEmpty == true
                ? params['masked_email']
                : null,
            otpSentTo: params['otp_sent_to']?.isNotEmpty == true
                ? params['otp_sent_to']
                : null,
            portalType: params['portal_type']?.isNotEmpty == true
                ? params['portal_type']
                : null,
            devOtp: params['dev_otp']?.isNotEmpty == true
                ? params['dev_otp']
                : null,
          );
        },
      ),
      GoRoute(
        path: '/verify-2fa',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final token = params['temp_token'];
          return Verify2faScreen(
            tempToken: token != null ? Uri.decodeComponent(token) : '',
            portalType: params['portal_type']?.isNotEmpty == true
                ? params['portal_type']
                : null,
          );
        },
      ),

      // ── Super Admin Shell ───────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => SuperAdminShell(child: child),
        routes: [
          GoRoute(
            path: '/super-admin',
            redirect: (context, state) => '/super-admin/dashboard',
          ),
          GoRoute(
            path: '/super-admin/dashboard',
            builder: (context, state) => const SuperAdminDashboardScreen(),
          ),
          GoRoute(
            path: '/super-admin/schools',
            builder: (context, state) => const SuperAdminSchoolsScreen(),
          ),
          GoRoute(
            path: '/super-admin/groups',
            builder: (context, state) => const SuperAdminGroupsScreen(),
          ),
          GoRoute(
            path: '/super-admin/plans',
            builder: (context, state) => const SuperAdminPlansScreen(),
          ),
          GoRoute(
            path: '/super-admin/billing',
            builder: (context, state) => const SuperAdminBillingScreen(),
          ),
          GoRoute(
            path: '/super-admin/features',
            builder: (context, state) => const SuperAdminFeaturesScreen(),
          ),
          GoRoute(
            path: '/super-admin/hardware',
            builder: (context, state) => const SuperAdminHardwareScreen(),
          ),
          GoRoute(
            path: '/super-admin/admins',
            builder: (context, state) => const SuperAdminAdminsScreen(),
          ),
          GoRoute(
            path: '/super-admin/audit-logs',
            builder: (context, state) => const SuperAdminAuditLogsScreen(),
          ),
          GoRoute(
            path: '/super-admin/security',
            builder: (context, state) => const SuperAdminSecurityScreen(),
          ),
          GoRoute(
            path: '/super-admin/infra',
            builder: (context, state) => const SuperAdminInfraScreen(),
          ),
          GoRoute(
            path: '/super-admin/notifications',
            builder: (context, state) => const SuperAdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/super-admin/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/super-admin/change-password',
            builder: (context, state) => const SuperAdminChangePasswordScreen(),
          ),
          GoRoute(
            path: '/super-admin/profile',
            builder: (context, state) => const SuperAdminProfileScreen(),
          ),
        ],
      ),

      // ── Group Admin Shell ───────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => GroupAdminShell(child: child),
        routes: [
          GoRoute(
            path: '/group-admin',
            redirect: (context, state) => '/group-admin/dashboard',
          ),
          GoRoute(
            path: '/group-admin/dashboard',
            builder: (context, state) => const GroupAdminDashboardScreen(),
          ),
          GoRoute(
            path: '/group-admin/schools',
            builder: (context, state) => const GroupAdminSchoolsScreen(),
          ),
          GoRoute(
            path: '/group-admin/schools/:id',
            builder: (context, state) => GroupAdminSchoolDetailScreen(
              schoolId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/group-admin/notifications',
            builder: (context, state) =>
                const GroupAdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/group-admin/profile',
            builder: (context, state) => const GroupAdminProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const GroupAdminEditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/group-admin/change-password',
            builder: (context, state) =>
                const GroupAdminChangePasswordScreen(),
          ),
          GoRoute(
            path: '/group-admin/students',
            builder: (context, state) => const GroupAdminStudentsScreen(),
          ),
          GoRoute(
            path: '/group-admin/analytics',
            builder: (context, state) => const GroupAdminAnalyticsScreen(),
          ),
          GoRoute(
            path: '/group-admin/reports',
            builder: (context, state) => const GroupAdminReportsScreen(),
          ),
          GoRoute(
            path: '/group-admin/notices',
            builder: (context, state) => const GroupAdminNoticesScreen(),
          ),
          GoRoute(
            path: '/group-admin/alerts',
            builder: (context, state) => const GroupAdminAlertsScreen(),
          ),
        ],
      ),

      // ── School Admin Shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => SchoolAdminShell(child: child),
        routes: [
          GoRoute(
            path: '/school-admin',
            redirect: (context, state) => '/school-admin/dashboard',
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
            path: '/school-admin/staff/new',
            builder: (context, state) =>
                const SchoolAdminStaffFormScreen(),
          ),
          GoRoute(
            path: '/school-admin/staff/leaves',
            builder: (context, state) =>
                const SchoolAdminLeavesScreen(),
          ),
          GoRoute(
            path: '/school-admin/staff/:id',
            builder: (context, state) => SchoolAdminStaffDetailScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/school-admin/staff/:id/edit',
            builder: (context, state) => SchoolAdminStaffFormScreen(
              staffId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/school-admin/staff/:id/leave/apply',
            builder: (context, state) => SchoolAdminLeaveApplyScreen(
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
            builder: (context, state) =>
                const SchoolAdminAttendanceReportScreen(),
          ),
          GoRoute(
            path: '/school-admin/fees',
            builder: (context, state) => const SchoolAdminFeesScreen(),
          ),
          GoRoute(
            path: '/school-admin/fees/collection',
            builder: (context, state) =>
                const SchoolAdminFeeCollectionScreen(),
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
            builder: (context, state) =>
                const SchoolAdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/school-admin/profile',
            builder: (context, state) => const SchoolAdminProfileScreen(),
          ),
          GoRoute(
            path: '/school-admin/change-password',
            builder: (context, state) =>
                const SchoolAdminChangePasswordScreen(),
          ),
          GoRoute(
            path: '/school-admin/settings',
            builder: (context, state) =>
                const SchoolAdminSettingsScreen(),
          ),
          // Non-Teaching Staff routes
          GoRoute(
            path: '/school-admin/non-teaching-staff',
            builder: (context, state) =>
                const SchoolAdminNonTeachingStaffScreen(),
          ),
          GoRoute(
            path: '/school-admin/non-teaching-staff/new',
            builder: (context, state) =>
                const SchoolAdminNonTeachingStaffFormScreen(),
          ),
          GoRoute(
            path: '/school-admin/non-teaching-staff/:id',
            builder: (context, state) =>
                SchoolAdminNonTeachingStaffDetailScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/school-admin/non-teaching-staff/:id/edit',
            builder: (context, state) =>
                SchoolAdminNonTeachingStaffFormScreen(
              staffId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/school-admin/non-teaching-roles',
            builder: (context, state) =>
                const SchoolAdminNonTeachingRolesScreen(),
          ),
          GoRoute(
            path: '/school-admin/non-teaching-attendance',
            builder: (context, state) =>
                const SchoolAdminNonTeachingAttendanceScreen(),
          ),
          GoRoute(
            path: '/school-admin/non-teaching-leaves',
            builder: (context, state) =>
                const SchoolAdminNonTeachingLeavesScreen(),
          ),
        ],
      ),

      // ── Teacher Shell ────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
            path: '/teacher',
            redirect: (context, state) => '/teacher/dashboard',
          ),
          GoRoute(
            path: '/teacher/dashboard',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/attendance',
            builder: (context, state) => const TeacherAttendanceScreen(),
          ),
          GoRoute(
            path: '/teacher/attendance/report',
            builder: (context, state) =>
                const TeacherAttendanceReportScreen(),
          ),
          GoRoute(
            path: '/teacher/homework',
            builder: (context, state) => const TeacherHomeworkScreen(),
          ),
          GoRoute(
            path: '/teacher/homework/new',
            builder: (context, state) => const TeacherHomeworkFormScreen(),
          ),
          GoRoute(
            path: '/teacher/homework/:id',
            builder: (context, state) => TeacherHomeworkDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/teacher/homework/:id/edit',
            builder: (context, state) => TeacherHomeworkFormScreen(
              homeworkId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/teacher/diary',
            builder: (context, state) => const TeacherDiaryScreen(),
          ),
          GoRoute(
            path: '/teacher/diary/new',
            builder: (context, state) => const TeacherDiaryFormScreen(),
          ),
          GoRoute(
            path: '/teacher/diary/:id/edit',
            builder: (context, state) => TeacherDiaryFormScreen(
              diaryId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/teacher/profile',
            builder: (context, state) => const TeacherProfileScreen(),
          ),
        ],
      ),

      // ── Student Shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student',
            redirect: (context, state) => '/student/dashboard',
          ),
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const StudentProfileScreen(),
          ),
          GoRoute(
            path: '/student/attendance',
            builder: (context, state) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: '/student/fees',
            builder: (context, state) => const StudentFeesScreen(),
          ),
          GoRoute(
            path: '/student/timetable',
            builder: (context, state) => const StudentTimetableScreen(),
          ),
          GoRoute(
            path: '/student/notices',
            builder: (context, state) => const StudentNoticesScreen(),
          ),
          GoRoute(
            path: '/student/notices/:id',
            builder: (context, state) => StudentNoticeDetailScreen(
              noticeId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/student/documents',
            builder: (context, state) => const StudentDocumentsScreen(),
          ),
          GoRoute(
            path: '/student/change-password',
            builder: (context, state) => const StudentChangePasswordScreen(),
          ),
        ],
      ),

      // ── Staff Shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => StaffShell(child: child),
        routes: [
          GoRoute(
            path: '/staff',
            redirect: (context, state) => '/staff/dashboard',
          ),
          GoRoute(
            path: '/staff/dashboard',
            builder: (context, state) => const StaffDashboardScreen(),
          ),
          GoRoute(
            path: '/staff/fees',
            builder: (context, state) => const StaffFeesScreen(),
          ),
          GoRoute(
            path: '/staff/students',
            builder: (context, state) => const StaffStudentsScreen(),
          ),
          GoRoute(
            path: '/staff/students/:id',
            builder: (context, state) => StaffStudentDetailScreen(
              studentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/staff/notices',
            builder: (context, state) => const StaffNoticesScreen(),
          ),
          GoRoute(
            path: '/staff/notices/:id',
            builder: (context, state) => StaffNoticeDetailScreen(
              noticeId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/staff/notifications',
            builder: (context, state) => const StaffNotificationsScreen(),
          ),
          GoRoute(
            path: '/staff/profile',
            builder: (context, state) => const StaffProfileScreen(),
          ),
          GoRoute(
            path: '/staff/change-password',
            builder: (context, state) => const StaffChangePasswordScreen(),
          ),
          GoRoute(
            path: '/staff/my-attendance',
            builder: (context, state) => const StaffMyAttendanceScreen(),
          ),
          GoRoute(
            path: '/staff/apply-leave',
            builder: (context, state) => const StaffApplyLeaveScreen(),
          ),
          GoRoute(
            path: '/staff/my-leaves',
            builder: (context, state) => const StaffMyLeavesScreen(),
          ),
          GoRoute(
            path: '/staff/payslip',
            builder: (context, state) => const StaffPayslipScreen(),
          ),
        ],
      ),

      // ── Driver Shell (mobile-only) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/driver',
            redirect: (context, state) => '/driver/dashboard',
          ),
          GoRoute(
            path: '/driver/dashboard',
            builder: (context, state) => const DriverDashboardScreen(),
          ),
          GoRoute(
            path: '/driver/profile',
            builder: (context, state) => const DriverProfileScreen(),
          ),
          GoRoute(
            path: '/driver/change-password',
            builder: (context, state) => const DriverChangePasswordScreen(),
          ),
        ],
      ),

      // ── Parent Shell ───────────────────────────────────────────────────
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

      // ── Protected Admin Shell ──────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/schools',
            builder: (context, state) => const SchoolsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlatformSchoolDetailPage(schoolId: id);
                },
              ),
            ],
          ),
          _adminPath('/branches', 'Branch Management'),
          GoRoute(
            path: '/plans',
            builder: (context, state) => const SubscriptionPage(),
          ),
          _adminPath('/users', 'Global Users'),
          _adminPath('/roles', 'RBAC Management'),
          _adminPath('/modules', 'System Modules'),
          _adminPath('/subscriptions', 'Active Subscriptions'),
          _adminPath('/revenue', 'Revenue Analysis'),
          _adminPath('/audit-logs', 'Security Audit'),
          _adminPath('/system-health', 'System Health'),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Helper to create placeholder routes for the admin shell
GoRoute _adminPath(String path, String title) {
  return GoRoute(
    path: path,
    builder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapSm,
            const Text('Platform Level Module — Development in Progress'),
          ],
        ),
      ),
    ),
  );
}
