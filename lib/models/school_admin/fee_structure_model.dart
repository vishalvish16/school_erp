// =============================================================================
// FILE: lib/models/school_admin/fee_structure_model.dart
// PURPOSE: Fee structure model for School Admin portal.
// =============================================================================

class FeeStructureModel {
  final String id;
  final String schoolId;
  final String? classId;
  final String? className;
  final String academicYear;
  final String feeHead;
  final double amount;
  final String frequency; // MONTHLY | QUARTERLY | ANNUALLY | ONE_TIME
  final int? dueDay;
  final bool isActive;
  final DateTime createdAt;

  const FeeStructureModel({
    required this.id,
    required this.schoolId,
    this.classId,
    this.className,
    required this.academicYear,
    required this.feeHead,
    required this.amount,
    required this.frequency,
    this.dueDay,
    required this.isActive,
    required this.createdAt,
  });

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (API/Prisma) and snake_case
    String str(String k1, String k2) =>
        json[k1] as String? ?? json[k2] as String? ?? '';
    String? strOpt(String k1, String k2) =>
        json[k1] as String? ?? json[k2] as String?;
    final class_ = json['class_'] as Map<String, dynamic>?;
    final className = strOpt('className', 'class_name') ??
        (class_ != null ? class_['name'] as String? : null);
    DateTime date(String k1, String k2) {
      final v = json[k1] ?? json[k2];
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    return FeeStructureModel(
      id: str('id', 'id'),
      schoolId: str('schoolId', 'school_id'),
      classId: strOpt('classId', 'class_id'),
      className: className,
      academicYear: str('academicYear', 'academic_year'),
      feeHead: str('feeHead', 'fee_head'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: str('frequency', 'frequency'),
      dueDay: (json['dueDay'] as num?)?.toInt() ?? (json['due_day'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: date('createdAt', 'created_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (classId != null) 'class_id': classId,
        'academic_year': academicYear,
        'fee_head': feeHead,
        'amount': amount,
        'frequency': frequency,
        if (dueDay != null) 'due_day': dueDay,
        'is_active': isActive,
      };
}
