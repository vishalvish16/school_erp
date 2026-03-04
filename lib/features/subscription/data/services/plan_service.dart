// =============================================================================
// FILE: lib/features/subscription/data/services/plan_service.dart
// PURPOSE: API Service for managing Platform Subscription Plans
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/plan_model.dart';

final planServiceProvider = Provider<PlanService>((ref) {
  return PlanService(ref.read(dioProvider));
});

class PlanService {
  final Dio _dio;
  static const String _endpoint = '/api/platform/plans';

  PlanService(this._dio);

  /// Fetch all platform plans
  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await _dio.get(_endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PlanModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch plans');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Create a new platform plan
  Future<void> createPlan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_endpoint, data: data);

      if (response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Failed to create plan');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Update an existing platform plan
  Future<void> updatePlan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$_endpoint/$id', data: data);

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to update plan');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Delete a platform plan
  Future<void> deletePlan(int id) async {
    try {
      final response = await _dio.delete('$_endpoint/$id');

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to delete plan');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Toggle plan active/inactive status
  Future<void> togglePlanStatus(int id) async {
    try {
      final response = await _dio.patch('$_endpoint/$id/toggle-status');

      if (response.statusCode != 200) {
        throw Exception(
          response.data['message'] ?? 'Failed to toggle plan status',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  String _handleDioError(DioException error) {
    if (error.response != null && error.response?.data != null) {
      return error.response?.data['message'] ?? 'Server error occurred';
    }
    return 'Connection to server failed';
  }
}
