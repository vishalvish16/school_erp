// =============================================================================
// FILE: lib/features/dashboard/dashboard_repository.dart
// PURPOSE: Repository for retrieving Super Admin Dashboard metrics and activity
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';
import 'dashboard_model.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData();
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._dio);

  final Dio _dio;

  @override
  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/platform/dashboard',
      );
      if (response.statusCode == 200) {
        // The API returns { "success": true, "data": { "metrics": {...}, "recent_activities": [...] } }
        final responseData = response.data['data'] as Map<String, dynamic>;
        return DashboardData.fromJson(responseData);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Dashboard fetch error: $e');
    }
  }
}

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network latency

    return DashboardData(
      metrics: const DashboardMetrics(
        totalSchools: 142,
        activeSchools: 124,
        monthlyRevenue: 128450.0,
        expiringSoon: 12,
      ),
      recentActivities: [
        TenantActivity(
          id: '1',
          schoolName: 'Springfield High School',
          branchName: 'Main Campus',
          action: 'Subscription renewed for 12 months',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        TenantActivity(
          id: '2',
          schoolName: 'Lincoln Elementary',
          branchName: 'North Branch',
          action: 'Added 500 new student accounts',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        TenantActivity(
          id: '3',
          schoolName: 'Evergreen Academy',
          branchName: 'West Wing',
          action: 'Module "Transport" activated',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        TenantActivity(
          id: '4',
          schoolName: 'Sunnyvale Middle School',
          branchName: 'East Branch',
          action: 'System generated monthly report',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        TenantActivity(
          id: '5',
          schoolName: 'Pioneer High School',
          branchName: 'South Campus',
          action: 'Role updated for Tenant Admin',
          timestamp: DateTime.now().subtract(const Duration(hours: 10)),
        ),
      ],
    );
  }
}

/// Define if we are using the mock API for dashboard right now
const bool useMockDashboard = false;

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (useMockDashboard) {
    return MockDashboardRepository();
  }
  return ApiDashboardRepository(ref.watch(dioProvider));
});
