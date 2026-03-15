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
}

final driverServiceProvider = Provider<DriverService>((ref) {
  return DriverService(ref.read(dioProvider));
});
