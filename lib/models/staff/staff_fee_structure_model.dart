// =============================================================================
// FILE: lib/models/staff/staff_fee_structure_model.dart
// PURPOSE: Fee structure (read-only) model for the Staff/Clerk portal.
// =============================================================================

class StaffFeeStructureModel {
  final String id;
  final String schoolId;
  final String feeHead;
  final double amount;
  final String academicYear;
  final String frequency; // MONTHLY | QUARTERLY | ANNUALLY | ONE_TIME
  final String? classId;
  final String? className;
  final DateTime createdAt;

  const StaffFeeStructureModel({
    required this.id,
    required this.schoolId,
    required this.feeHead,
    required this.amount,
    required this.academicYear,
    required this.frequency,
    this.classId,
    this.className,
    required this.createdAt,
  });

  factory StaffFeeStructureModel.fromJson(Map<String, dynamic> json) {
    return StaffFeeStructureModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      feeHead: json['fee_head'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      academicYear: json['academic_year'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'ANNUALLY',
      classId: json['class_id'] as String?,
      className: json['class_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
