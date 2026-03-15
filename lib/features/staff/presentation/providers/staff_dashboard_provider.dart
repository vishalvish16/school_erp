// =============================================================================
// FILE: lib/features/staff/presentation/providers/staff_dashboard_provider.dart
// PURPOSE: Dashboard stats provider for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_dashboard_model.dart';

final staffDashboardProvider =
    FutureProvider.autoDispose<StaffDashboardModel>((ref) {
  return ref.read(staffServiceProvider).getDashboardStats();
});
