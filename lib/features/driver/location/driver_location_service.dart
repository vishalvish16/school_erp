// =============================================================================
// FILE: lib/features/driver/location/driver_location_service.dart
// PURPOSE: Background location service for driver GPS tracking during trips.
//          Runs in a foreground service isolate — cannot use Riverpod/Dio.
//          Uses plain http package for API calls from the background isolate.
// =============================================================================

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ── Background isolate entry point ──────────────────────────────────────────
// Must be a top-level function annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {

  String? accessToken;
  String? baseUrl;

  service.on('stopService').listen((_) => service.stopSelf());

  service.on('config').listen((data) {
    accessToken = data?['accessToken'] as String?;
    baseUrl = data?['baseUrl'] as String?;
  });

  // GPS interval — every 10 seconds
  Timer.periodic(const Duration(seconds: 10), (_) async {
    if (accessToken == null || baseUrl == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await http
          .post(
            Uri.parse('$baseUrl/api/driver/location'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'lat': pos.latitude,
              'lng': pos.longitude,
              if (pos.speed >= 0) 'speed': pos.speed,
              if (pos.heading >= 0) 'heading': pos.heading,
              'accuracy': pos.accuracy,
              'recordedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      service.invoke('locationUpdate', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
        'heading': pos.heading,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail — never crash the background service
      print('[BGService] location error: $e');
    }
  });
}

// ── Service Manager ──────────────────────────────────────────────────────────

class DriverLocationService {
  static final _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'driver_location_channel',
        initialNotificationTitle: 'Vidyron Driver',
        initialNotificationContent: 'Starting trip...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: null,
      ),
    );
  }

  static Future<bool> start({
    required String accessToken,
    required String baseUrl,
  }) async {
    final started = await _service.startService();
    if (started) {
      await Future.delayed(const Duration(milliseconds: 300));
      _service.invoke('config', {
        'accessToken': accessToken,
        'baseUrl': baseUrl,
      });
    }
    return started;
  }

  static Future<void> stop() async {
    _service.invoke('stopService');
  }

  static Future<bool> get isRunning => _service.isRunning();

  static Stream<Map<String, dynamic>?> get locationStream =>
      _service.on('locationUpdate');
}
