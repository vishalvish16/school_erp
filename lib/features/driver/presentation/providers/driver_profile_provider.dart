// =============================================================================
// FILE: lib/features/driver/presentation/providers/driver_profile_provider.dart
// PURPOSE: FutureProvider for driver profile. Update via service + invalidate.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/driver_service.dart';
import '../../../../models/driver/driver_profile_model.dart';

final driverProfileProvider =
    FutureProvider<DriverProfileModel>((ref) {
  final service = ref.watch(driverServiceProvider);
  return service.getProfile();
});
