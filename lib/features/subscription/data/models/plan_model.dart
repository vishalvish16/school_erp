// =============================================================================
// FILE: lib/features/subscription/data/models/plan_model.dart
// PURPOSE: Model for Platform Subscription Plans
// =============================================================================

class PlanModel {
  final int planId;
  final String planName;
  final int maxStudents;
  final int maxTeachers;
  final int maxBranches;
  final double priceMonthly;
  final double priceYearly;
  final bool isActive;
  final int activeSchoolCount;

  PlanModel({
    required this.planId,
    required this.planName,
    required this.maxStudents,
    required this.maxTeachers,
    required this.maxBranches,
    required this.priceMonthly,
    required this.priceYearly,
    required this.isActive,
    required this.activeSchoolCount,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      planId: json['plan_id'] is String
          ? int.parse(json['plan_id'])
          : (json['plan_id'] as num).toInt(),
      planName: json['plan_name'] ?? '',
      maxStudents: (json['max_students'] as num?)?.toInt() ?? 0,
      maxTeachers: (json['max_teachers'] as num?)?.toInt() ?? 0,
      maxBranches: (json['max_branches'] as num?)?.toInt() ?? 0,
      priceMonthly: json['price_monthly'] is String
          ? double.parse(json['price_monthly'])
          : (json['price_monthly'] as num?)?.toDouble() ?? 0.0,
      priceYearly: json['price_yearly'] is String
          ? double.parse(json['price_yearly'])
          : (json['price_yearly'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      activeSchoolCount: (json['active_school_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'plan_name': planName,
      'max_students': maxStudents,
      'max_teachers': maxTeachers,
      'max_branches': maxBranches,
      'price_monthly': priceMonthly,
      'price_yearly': priceYearly,
      'is_active': isActive,
      'active_school_count': activeSchoolCount,
    };
  }

  PlanModel copyWith({
    int? planId,
    String? planName,
    int? maxStudents,
    int? maxTeachers,
    int? maxBranches,
    double? priceMonthly,
    double? priceYearly,
    bool? isActive,
    int? activeSchoolCount,
  }) {
    return PlanModel(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      maxBranches: maxBranches ?? this.maxBranches,
      priceMonthly: priceMonthly ?? this.priceMonthly,
      priceYearly: priceYearly ?? this.priceYearly,
      isActive: isActive ?? this.isActive,
      activeSchoolCount: activeSchoolCount ?? this.activeSchoolCount,
    );
  }
}
