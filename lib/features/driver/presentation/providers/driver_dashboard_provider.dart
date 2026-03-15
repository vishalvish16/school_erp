// =============================================================================
// FILE: lib/features/driver/presentation/providers/driver_dashboard_provider.dart
// PURPOSE: FutureProvider for driver dashboard stats.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/driver_service.dart';
import '../../../../models/driver/driver_dashboard_model.dart';

final driverDashboardProvider =
    FutureProvider<DriverDashboardModel>((ref) {
  final service = ref.watch(driverServiceProvider);
  return service.getDashboardStats();
});
