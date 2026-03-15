// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_dashboard_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/dashboard_stats_model.dart';

final schoolAdminDashboardProvider =
    FutureProvider.autoDispose<DashboardStatsModel>((ref) {
  return ref.read(schoolAdminServiceProvider).getDashboardStats();
});
