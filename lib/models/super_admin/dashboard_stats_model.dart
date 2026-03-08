// =============================================================================
// FILE: lib/models/super_admin/dashboard_stats_model.dart
// PURPOSE: Super Admin dashboard stats model
// =============================================================================

import 'school_model.dart';
import 'plan_model.dart';

class SuperAdminPlanDistributionModel {
  final String planId;
  final String planName;
  final String? planIcon;
  final int schoolCount;
  final double percentage;
  final double mrr;

  SuperAdminPlanDistributionModel({
    required this.planId,
    required this.planName,
    this.planIcon,
    this.schoolCount = 0,
    this.percentage = 0,
    this.mrr = 0,
  });

  factory SuperAdminPlanDistributionModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminPlanDistributionModel(
      planId: json['plan_id']?.toString() ?? json['planId']?.toString() ?? '',
      planName: json['plan_name'] ?? json['planName'] ?? '',
      planIcon: json['plan_icon'] ?? json['planIcon'],
      schoolCount: json['school_count'] ?? json['schoolCount'] ?? 0,
      percentage: (json['percentage'] ?? 0) is num ? (json['percentage'] ?? 0).toDouble() : 0,
      mrr: (json['mrr'] ?? 0) is num ? (json['mrr'] ?? 0).toDouble() : 0,
    );
  }
}

class SuperAdminDashboardStatsModel {
  final int totalSchools;
  final int activeSchools;
  final int trialSchools;
  final int suspendedSchools;
  final int totalStudents;
  final int totalGroups;
  final double mrr;
  final double arr;
  final List<SuperAdminSchoolModel> expiringSchools;
  final List<SuperAdminSchoolModel> overdueSchools;
  final List<SuperAdminSchoolModel> recentSchools;
  final List<SuperAdminPlanDistributionModel> planDistribution;

  SuperAdminDashboardStatsModel({
    this.totalSchools = 0,
    this.activeSchools = 0,
    this.trialSchools = 0,
    this.suspendedSchools = 0,
    this.totalStudents = 0,
    this.totalGroups = 0,
    this.mrr = 0,
    this.arr = 0,
    this.expiringSchools = const [],
    this.overdueSchools = const [],
    this.recentSchools = const [],
    this.planDistribution = const [],
  });

  factory SuperAdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminDashboardStatsModel(
      totalSchools: json['total_schools'] ?? json['totalSchools'] ?? 0,
      activeSchools: json['active_schools'] ?? json['activeSchools'] ?? 0,
      trialSchools: json['trial_schools'] ?? json['trialSchools'] ?? 0,
      suspendedSchools: json['suspended_schools'] ?? json['suspendedSchools'] ?? 0,
      totalStudents: json['total_students'] ?? json['totalStudents'] ?? 0,
      totalGroups: json['total_groups'] ?? json['totalGroups'] ?? 0,
      mrr: (json['mrr'] ?? 0) is num ? (json['mrr'] ?? 0).toDouble() : 0,
      arr: (json['arr'] ?? 0) is num ? (json['arr'] ?? 0).toDouble() : 0,
      expiringSchools: _parseSchools(json['schools_expiring_7_days'] ?? json['expiringSchools'] ?? []),
      overdueSchools: _parseSchools(json['schools_overdue'] ?? json['overdueSchools'] ?? []),
      recentSchools: _parseSchools(json['recent_schools'] ?? json['recentSchools'] ?? []),
      planDistribution: _parsePlanDist(
        json['plan_distribution'] ?? json['planDistribution'] ?? [],
      ),
    );
  }

  static List<SuperAdminSchoolModel> _parseSchools(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminSchoolModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  static List<SuperAdminPlanDistributionModel> _parsePlanDist(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminPlanDistributionModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }
}
