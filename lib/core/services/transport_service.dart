// =============================================================================
// FILE: lib/core/services/transport_service.dart
// PURPOSE: Transport module API calls — vehicles, drivers, assignments.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart'; // provides dioProvider
import '../config/api_config.dart';
import '../../models/school_admin/transport_model.dart';

class TransportService {
  TransportService(this._dio);

  final Dio _dio;

  // ── Vehicles ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get(ApiConfig.schoolTransportVehicles, queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final d = res.data['data'] as Map<String, dynamic>;
    final list = (d['vehicles'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(TransportVehicleModel.fromJson)
        .toList();
    return {
      'vehicles': list,
      'total': d['total'] as int? ?? 0,
      'page': d['page'] as int? ?? 1,
      'total_pages': d['total_pages'] as int? ?? 1,
    };
  }

  Future<Map<String, dynamic>> getLiveVehicles() async {
    final res = await _dio.get(ApiConfig.schoolTransportVehiclesLive);
    final d = res.data['data'] as Map<String, dynamic>;
    final list = (d['vehicles'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(TransportVehicleModel.fromJson)
        .toList();
    return {'vehicles': list};
  }

  Future<TransportVehicleModel> getVehicle(String id) async {
    final res = await _dio.get('${ApiConfig.schoolTransportVehicles}/$id');
    return TransportVehicleModel.fromJson(
      res.data['data']['vehicle'] as Map<String, dynamic>,
    );
  }

  Future<TransportVehicleModel> createVehicle(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.schoolTransportVehicles, data: body);
    return TransportVehicleModel.fromJson(
      res.data['data']['vehicle'] as Map<String, dynamic>,
    );
  }

  Future<TransportVehicleModel> updateVehicle(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConfig.schoolTransportVehicles}/$id', data: body);
    return TransportVehicleModel.fromJson(
      res.data['data']['vehicle'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteVehicle(String id) async {
    await _dio.delete('${ApiConfig.schoolTransportVehicles}/$id');
  }

  // ── Driver Assignment ──────────────────────────────────────────────────────

  Future<void> assignDriver(String vehicleId, String driverId) async {
    await _dio.post(
      '${ApiConfig.schoolTransportVehicles}/$vehicleId/assign-driver',
      data: {'driver_id': driverId},
    );
  }

  Future<void> unassignDriver(String vehicleId) async {
    await _dio.delete('${ApiConfig.schoolTransportVehicles}/$vehicleId/unassign-driver');
  }

  // ── Student Assignment ─────────────────────────────────────────────────────

  Future<List<VehicleStudentAssignment>> getVehicleStudents(String vehicleId) async {
    final res = await _dio.get('${ApiConfig.schoolTransportVehicles}/$vehicleId/students');
    final list = (res.data['data']['students'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(VehicleStudentAssignment.fromJson)
        .toList();
    return list;
  }

  Future<void> assignStudent(
    String vehicleId, {
    required String studentId,
    String? pickupStopName,
    double? pickupLat,
    double? pickupLng,
    String? dropStopName,
    double? dropLat,
    double? dropLng,
  }) async {
    await _dio.post(
      '${ApiConfig.schoolTransportVehicles}/$vehicleId/students',
      data: {
        'student_id': studentId,
        'pickup_stop_name': pickupStopName,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_stop_name': dropStopName,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
      },
    );
  }

  Future<void> removeStudent(String vehicleId, String studentId) async {
    await _dio.delete(
      '${ApiConfig.schoolTransportVehicles}/$vehicleId/students/$studentId',
    );
  }

  Future<Map<String, dynamic>> getUnassignedStudents({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final res = await _dio.get(
      ApiConfig.schoolTransportStudentsUnassigned,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final d = res.data['data'] as Map<String, dynamic>;
    final list = (d['students'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(UnassignedStudent.fromJson)
        .toList();
    return {'students': list, 'total': d['total'] ?? 0};
  }

  // ── Drivers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDrivers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get(ApiConfig.schoolTransportDrivers, queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final d = res.data['data'] as Map<String, dynamic>;
    final list = (d['drivers'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(TransportDriverModel.fromJson)
        .toList();
    return {
      'drivers': list,
      'total': d['total'] as int? ?? 0,
      'page': d['page'] as int? ?? 1,
      'total_pages': d['total_pages'] as int? ?? 1,
    };
  }

  Future<TransportDriverModel> getDriver(String id) async {
    final res = await _dio.get('${ApiConfig.schoolTransportDrivers}/$id');
    return TransportDriverModel.fromJson(
      res.data['data']['driver'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.schoolTransportDrivers, data: body);
    final d = res.data['data'] as Map<String, dynamic>;
    return {
      'driver': TransportDriverModel.fromJson(d['driver'] as Map<String, dynamic>),
      'tempPassword': d['tempPassword'] as String? ?? '',
    };
  }

  Future<TransportDriverModel> updateDriver(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConfig.schoolTransportDrivers}/$id', data: body);
    return TransportDriverModel.fromJson(
      res.data['data']['driver'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteDriver(String id) async {
    await _dio.delete('${ApiConfig.schoolTransportDrivers}/$id');
  }
}

final transportServiceProvider = Provider<TransportService>((ref) {
  return TransportService(ref.watch(dioProvider));
});
