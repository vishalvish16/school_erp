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
import '../features/auth/staff_login_screen.dart';
import '../features/auth/parent_login_screen.dart';
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
import '../features/super_admin/presentation/screens/super_admin_infra_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_notifications_screen.dart';
import '../shared/layouts/admin_layout.dart';

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

  final isSuperAdmin = ValueNotifier<bool>(ref.read(authGuardProvider).isSuperAdmin);
  ref.listen(authGuardProvider, (_, authState) {
    isSuperAdmin.value = authState.isSuperAdmin;
  });

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: Listenable.merge([currentAuth, isSuperAdmin]),
    redirect: (context, state) {
      final isAuthenticated = currentAuth.value;
      final superAdmin = isSuperAdmin.value;
      final loc = state.matchedLocation;
      final isLogin = loc == '/login' ||
          loc.startsWith('/login/group') ||
          loc.startsWith('/login/school') ||
          loc.startsWith('/login/staff') ||
          loc.startsWith('/login/parent') ||
          loc.startsWith('/login/student');
      final isSplashing = loc == '/splash';
      final isRecovering = loc == '/forgot-password';
      final isResetting = loc == '/reset-password';
      final isDeviceVerify = loc.startsWith('/device-verification');
      final isVerify2fa = loc.startsWith('/verify-2fa');
      final isSchoolSetup = loc == '/school-setup';

      if (!isAuthenticated) {
        if (!isLogin && !isRecovering && !isResetting && !isSplashing && !isDeviceVerify && !isVerify2fa && !isSchoolSetup)
          return '/splash';
        return null;
      }

      // /login (exact) is Super Admin login — always redirect to super-admin dashboard
      if (loc == '/login') return '/super-admin/dashboard';
      // Device-verification and verify-2fa — from /login flow, go to super-admin
      if (isDeviceVerify || isVerify2fa) return '/super-admin/dashboard';
      if (isLogin || isRecovering || isResetting) {
        return superAdmin ? '/super-admin/dashboard' : '/dashboard';
      }

      // Super admin on regular admin routes → redirect to super admin
      if (superAdmin && (loc == '/dashboard' || loc.startsWith('/dashboard') || loc == '/schools' || loc == '/plans')) {
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
        path: '/device-verification',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return DeviceVerificationScreen(
            otpSessionId: params['otp_session_id'] ?? '',
            maskedPhone: params['masked_phone']?.isNotEmpty == true ? params['masked_phone'] : null,
            portalType: params['portal_type']?.isNotEmpty == true ? params['portal_type'] : null,
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
            portalType: params['portal_type']?.isNotEmpty == true ? params['portal_type'] : null,
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
            const SizedBox(height: 8),
            const Text('Platform Level Module — Development in Progress'),
          ],
        ),
      ),
    ),
  );
}
