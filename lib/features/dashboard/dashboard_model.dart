// =============================================================================
// FILE: lib/features/dashboard/dashboard_model.dart
// PURPOSE: Data models for the Super Admin Dashboard
// =============================================================================

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalSchools,
    required this.activeSchools,
    required this.monthlyRevenue,
    required this.expiringSoon,
  });

  final int totalSchools;
  final int activeSchools;
  final double monthlyRevenue;
  final int expiringSoon;

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalSchools: json['total_schools'] as int? ?? 0,
      activeSchools: json['active_schools'] as int? ?? 0,
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0.0,
      expiringSoon: json['expiring_soon'] as int? ?? 0,
    );
  }
}

class TenantActivity {
  const TenantActivity({
    required this.id,
    required this.schoolName,
    required this.branchName,
    required this.action,
    required this.timestamp,
  });

  final String id;
  final String schoolName;
  final String branchName;
  final String action;
  final DateTime timestamp;

  factory TenantActivity.fromJson(Map<String, dynamic> json) {
    return TenantActivity(
      id: json['id'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      action: json['action'] as String? ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.metrics,
    required this.recentActivities,
  });

  final DashboardMetrics metrics;
  final List<TenantActivity> recentActivities;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      metrics: DashboardMetrics.fromJson(json['metrics'] as Map<String, dynamic>? ?? {}),
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((e) => TenantActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
