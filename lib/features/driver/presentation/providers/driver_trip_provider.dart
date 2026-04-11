// =============================================================================
// FILE: lib/features/driver/presentation/providers/driver_trip_provider.dart
// PURPOSE: State management for trip start/end lifecycle.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/driver/driver_trip_model.dart';
import '../../../../core/services/driver_service.dart';

class DriverTripNotifier extends StateNotifier<AsyncValue<DriverTripModel?>> {
  DriverTripNotifier(this._service) : super(const AsyncValue.data(null));

  final DriverService _service;

  Future<void> startTrip() async {
    state = const AsyncValue.loading();
    try {
      final trip = await _service.startTripWithResult();
      state = AsyncValue.data(trip);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endTrip({String? notes}) async {
    state = const AsyncValue.loading();
    try {
      final trip = await _service.endTripWithResult(notes: notes);
      state = AsyncValue.data(trip);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

final driverTripProvider =
    StateNotifierProvider<DriverTripNotifier, AsyncValue<DriverTripModel?>>(
  (ref) => DriverTripNotifier(ref.watch(driverServiceProvider)),
);
