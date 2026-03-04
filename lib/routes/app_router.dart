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
import '../features/auth/auth_guard_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/schools/presentation/views/schools_screen.dart';
import '../features/schools/presentation/views/platform_school_detail_page.dart';
import '../features/subscription/presentation/pages/subscription_page.dart';
import '../shared/layouts/admin_layout.dart';

/// Global navigation keys for multi-level routing
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Simple provider to expose the authentication status
final authStateProvider = Provider<bool>((ref) {
  return ref.watch(authGuardProvider).isAuthenticated;
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

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: currentAuth, // Safe listen pipeline
    redirect: (context, state) {
      final isAuthenticated = currentAuth.value;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/splash';
      final isRecovering = state.matchedLocation == '/forgot-password';
      final isResetting = state.matchedLocation == '/reset-password';

      if (!isAuthenticated) {
        // If not authenticated and not already on an auth page, send to login
        if (!isLoggingIn && !isRecovering && !isResetting && !isSplashing)
          return '/splash';
        return null;
      }

      // If authenticated and trying to access login, send to dashboard
      if (isLoggingIn || isRecovering || isResetting) return '/dashboard';

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
