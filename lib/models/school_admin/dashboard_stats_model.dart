// =============================================================================
// FILE: lib/models/school_admin/dashboard_stats_model.dart
// PURPOSE: Dashboard statistics model for School Admin portal.
// =============================================================================

class RecentActivityItem {
  final String type;
  final String message;
  final DateTime createdAt;

  const RecentActivityItem({
    required this.type,
    required this.message,
    required this.createdAt,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class DashboardStatsModel {
  final int totalStudents;
  final int totalStaff;
  final int totalClasses;
  final int totalSections;
  final double todayAttendancePercent;
  final double feeCollectedThisMonth;
  final int noticesCount;
  final List<RecentActivityItem> recentActivity;

  const DashboardStatsModel({
    required this.totalStudents,
    required this.totalStaff,
    required this.totalClasses,
    required this.totalSections,
    required this.todayAttendancePercent,
    required this.feeCollectedThisMonth,
    required this.noticesCount,
    required this.recentActivity,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final activityList = json['recent_activity'];
    final activities = activityList is List
        ? activityList
            .map((e) => RecentActivityItem.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <RecentActivityItem>[];

    return DashboardStatsModel(
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      totalStaff: (json['total_staff'] as num?)?.toInt() ?? 0,
      totalClasses: (json['total_classes'] as num?)?.toInt() ?? 0,
      totalSections: (json['total_sections'] as num?)?.toInt() ?? 0,
      todayAttendancePercent:
          (json['today_attendance_percent'] as num?)?.toDouble() ?? 0.0,
      feeCollectedThisMonth:
          (json['fee_collected_this_month'] as num?)?.toDouble() ?? 0.0,
      noticesCount: (json['notices_count'] as num?)?.toInt() ?? 0,
      recentActivity: activities,
    );
  }
}
