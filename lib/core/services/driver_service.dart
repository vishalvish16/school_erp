// =============================================================================
// FILE: lib/core/services/driver_service.dart
// PURPOSE: Driver Portal API service — dashboard, profile, change password.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/driver/driver_dashboard_model.dart';
import '../../models/driver/driver_profile_model.dart';
import '../../models/driver/driver_trip_model.dart';

class DriverService {
  DriverService(this._dio);

  final Dio _dio;

  Future<DriverDashboardModel> getDashboardStats() async {
    final res = await _dio.get(ApiConfig.driverDashboard);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard response');
    }
    final success = res.data is Map ? res.data['success'] : true;
    if (success == false) {
      throw Exception(
        (res.data is Map ? res.data['error'] ?? res.data['message'] : null)
            ?.toString() ??
            'Failed to load dashboard',
      );
    }
    return DriverDashboardModel.fromJson(data);
  }

  Future<DriverProfileModel> getProfile() async {
    final res = await _dio.get(ApiConfig.driverProfile);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }
    final success = res.data is Map ? res.data['success'] : true;
    if (success == false) {
      throw Exception(
        (res.data is Map ? res.data['error'] ?? res.data['message'] : null)
            ?.toString() ??
            'Failed to load profile',
      );
    }
    return DriverProfileModel.fromJson(data);
  }

  Future<DriverProfileModel> updateProfile({
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (phone != null) body['phone'] = phone;
    if (emergencyContactName != null) {
      body['emergency_contact_name'] = emergencyContactName;
    }
    if (emergencyContactPhone != null) {
      body['emergency_contact_phone'] = emergencyContactPhone;
    }
    if (address != null) body['address'] = address;

    final res = await _dio.put(ApiConfig.driverProfile, data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }
    return DriverProfileModel.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put(ApiConfig.driverChangePassword, data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  /// Start a new trip — enables live location sharing.
  Future<DriverTripModel> startTripWithResult() async {
    final res = await _dio.post(ApiConfig.driverTripStart);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is Map<String, dynamic>) {
      return DriverTripModel.fromJson(data);
    }
    return const DriverTripModel(tripId: '', status: 'IN_PROGRESS');
  }

  /// Start a new trip — fire-and-forget variant (legacy).
  Future<void> startTrip() async {
    await _dio.post(ApiConfig.driverTripStart);
  }

  /// End the active trip — returns trip model with final status.
  Future<DriverTripModel> endTripWithResult({String? notes}) async {
    final res = await _dio.post(
      ApiConfig.driverTripEnd,
      data: notes != null ? {'notes': notes} : <String, dynamic>{},
    );
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is Map<String, dynamic>) {
      return DriverTripModel.fromJson(data);
    }
    return const DriverTripModel(tripId: '', status: 'COMPLETED');
  }

  /// End the active trip — fire-and-forget variant (legacy).
  Future<void> endTrip() async {
    await _dio.post(ApiConfig.driverTripEnd);
  }

  /// Push a GPS coordinate update to the server (simple).
  Future<void> updateLocation(double lat, double lng) async {
    await _dio.post(ApiConfig.driverLocation, data: {
      'lat': lat,
      'lng': lng,
    });
  }

  /// Push a GPS coordinate update with extended telemetry.
  Future<void> postLocation({
    required double lat,
    required double lng,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    await _dio.post(ApiConfig.driverLocation, data: {
      'lat': lat,
      'lng': lng,
      'speed': ?speed,
      'heading': ?heading,
      'accuracy': ?accuracy,
      'recordedAt': DateTime.now().toIso8601String(),
    });
  }
}

final driverServiceProvider = Provider<DriverService>((ref) {
  return DriverService(ref.read(dioProvider));
});
