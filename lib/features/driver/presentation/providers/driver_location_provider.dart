// =============================================================================
// FILE: lib/features/driver/presentation/providers/driver_location_provider.dart
// PURPOSE: StateNotifier managing driver GPS streaming and trip lifecycle.
// =============================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/driver_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

class DriverLocationState {
  const DriverLocationState({
    this.tripActive = false,
    this.isStreaming = false,
    this.error,
    this.lat,
    this.lng,
    this.isStarting = false,
    this.isStopping = false,
  });

  final bool tripActive;
  final bool isStreaming;
  final String? error;
  final double? lat;
  final double? lng;
  final bool isStarting;
  final bool isStopping;

  DriverLocationState copyWith({
    bool? tripActive,
    bool? isStreaming,
    String? error,
    double? lat,
    double? lng,
    bool? isStarting,
    bool? isStopping,
    bool clearError = false,
  }) {
    return DriverLocationState(
      tripActive: tripActive ?? this.tripActive,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isStarting: isStarting ?? this.isStarting,
      isStopping: isStopping ?? this.isStopping,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class DriverLocationNotifier extends StateNotifier<DriverLocationState> {
  DriverLocationNotifier(this._service) : super(const DriverLocationState());

  final DriverService _service;
  StreamSubscription<Position>? _positionSub;

  /// Request location permission, call API, then start GPS stream.
  Future<bool> startTrip() async {
    state = state.copyWith(isStarting: true, clearError: true);

    // Check location services and permissions
    final permissionOk = await _ensureLocationPermission();
    if (!permissionOk) {
      state = state.copyWith(isStarting: false);
      return false;
    }

    try {
      await _service.startTrip();
      state = state.copyWith(
        tripActive: true,
        isStarting: false,
      );
      _startPositionStream();
      return true;
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Stop the GPS stream and call the end-trip API.
  Future<bool> endTrip() async {
    state = state.copyWith(isStopping: true, clearError: true);

    try {
      await _service.endTrip();
      _cancelPositionStream();
      state = state.copyWith(
        tripActive: false,
        isStreaming: false,
        isStopping: false,
        lat: null,
        lng: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isStopping: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Ensure location services are enabled and permission is granted.
  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        error: 'Location services are disabled. Please enable them.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          error: 'Location permission denied. Please enable it in settings.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        error: 'Location permission denied. Please enable it in settings.',
      );
      return false;
    }

    return true;
  }

  /// Subscribe to Geolocator position stream and push updates to server.
  void _startPositionStream() {
    _cancelPositionStream();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        state = state.copyWith(
          lat: position.latitude,
          lng: position.longitude,
          isStreaming: true,
        );
        // Fire-and-forget — do not await to avoid blocking the stream
        _service.updateLocation(position.latitude, position.longitude);
      },
      onError: (Object error) {
        state = state.copyWith(
          error: error.toString(),
          isStreaming: false,
        );
      },
    );
  }

  void _cancelPositionStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  @override
  void dispose() {
    _cancelPositionStream();
    super.dispose();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final driverLocationProvider =
    StateNotifierProvider<DriverLocationNotifier, DriverLocationState>((ref) {
  return DriverLocationNotifier(ref.watch(driverServiceProvider));
});
