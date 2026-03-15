// =============================================================================
// FILE: lib/utils/portal_resolver.dart
// PURPOSE: Platform-aware portal type and route resolution (web vs mobile)
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/services/local_storage_service.dart';
import 'subdomain_resolver.dart';

class PortalResolver {
  PortalResolver._();

  /// Resolve portal type from platform context
  static Future<String> resolvePortalType() async {
    if (kIsWeb) {
      final subdomain = await SubdomainResolver.getCurrentSubdomain();
      if (subdomain == 'admin') return 'super_admin';
      if (subdomain != null && subdomain.isNotEmpty) return 'school_staff';
      return 'unknown';
    } else {
      final storage = LocalStorageService();
      return (await storage.getPortalType()) ?? 'unknown';
    }
  }

  static String getLoginRoute(String portalType) {
    switch (portalType) {
      case 'super_admin':
        return '/login';
      case 'group_admin':
        return '/login/group';
      case 'school_admin':
        return '/login/school';
      case 'school_staff':
        return '/login/staff';
      case 'driver':
        return '/login/driver';
      case 'parent':
        return '/login/parent';
      case 'student':
        return '/login/student';
      default:
        return '/school-setup';
    }
  }

  static String getDashboardRoute(String role) {
    switch (role) {
      case 'super_admin':
        return '/super-admin/dashboard';
      case 'group_admin':
        return '/dashboard';
      case 'principal':
      case 'school_admin':
        return '/dashboard';
      case 'teacher':
      case 'clerk':
      case 'accountant':
        return '/dashboard';
      case 'driver':
        return '/driver/dashboard';
      case 'parent':
        return '/dashboard';
      case 'student':
        return '/student/dashboard';
      default:
        return '/login';
    }
  }
}
