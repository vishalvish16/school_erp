// =============================================================================
// FILE: lib/features/dashboard/dashboard_provider.dart
// PURPOSE: Riverpod state management providing reactive Dashboard models
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_model.dart';
import 'dashboard_repository.dart';

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardData();
});
