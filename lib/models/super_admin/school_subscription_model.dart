// =============================================================================
// FILE: lib/models/super_admin/school_subscription_model.dart
// PURPOSE: Super Admin school subscription model
// =============================================================================

class SuperAdminSchoolSubscriptionModel {
  final String id;
  final String schoolId;
  final String schoolName;
  final String planId;
  final String planName;
  final String? planIcon;
  final String status;
  final double pricePerStudent;
  final double monthlyAmount;
  final int studentCount;
  final int durationMonths;
  final DateTime startDate;
  final DateTime endDate;
  final String? paymentRef;

  SuperAdminSchoolSubscriptionModel({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.planId,
    required this.planName,
    this.planIcon,
    required this.status,
    required this.pricePerStudent,
    required this.monthlyAmount,
    required this.studentCount,
    required this.durationMonths,
    required this.startDate,
    required this.endDate,
    this.paymentRef,
  });

  factory SuperAdminSchoolSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminSchoolSubscriptionModel(
      id: json['id']?.toString() ?? '',
      schoolId: json['school_id']?.toString() ?? json['schoolId']?.toString() ?? '',
      schoolName: json['school_name'] ?? json['schoolName'] ?? '',
      planId: json['plan_id']?.toString() ?? json['planId']?.toString() ?? '',
      planName: json['plan_name'] ?? json['planName'] ?? '',
      planIcon: json['plan_icon'] ?? json['planIcon'],
      status: json['status'] ?? 'active',
      pricePerStudent: (json['price_per_student'] ?? json['pricePerStudent'] ?? 0) is num
          ? (json['price_per_student'] ?? json['pricePerStudent'] ?? 0).toDouble()
          : 0,
      monthlyAmount: (json['monthly_amount'] ?? json['monthlyAmount'] ?? 0) is num
          ? (json['monthly_amount'] ?? json['monthlyAmount'] ?? 0).toDouble()
          : 0,
      studentCount: json['student_count'] ?? json['studentCount'] ?? 0,
      durationMonths: json['duration_months'] ?? json['durationMonths'] ?? 12,
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
      paymentRef: json['payment_ref'] ?? json['paymentRef'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'school_name': schoolName,
        'plan_id': planId,
        'plan_name': planName,
        'status': status,
        'price_per_student': pricePerStudent,
        'monthly_amount': monthlyAmount,
        'student_count': studentCount,
        'duration_months': durationMonths,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'payment_ref': paymentRef,
      };
}
