// =============================================================================
// FILE: lib/models/staff/staff_payment_model.dart
// PURPOSE: Fee payment model for the Staff/Clerk portal.
// =============================================================================

class StaffPaymentModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String? studentName;
  final String? admissionNo;
  final String feeHead;
  final String academicYear;
  final double amount;
  final DateTime paymentDate;
  final String paymentMode; // CASH | UPI | BANK_TRANSFER | CHEQUE
  final String receiptNo;
  final String collectedBy;
  final String? remarks;
  final DateTime createdAt;

  const StaffPaymentModel({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.studentName,
    this.admissionNo,
    required this.feeHead,
    required this.academicYear,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    required this.receiptNo,
    required this.collectedBy,
    this.remarks,
    required this.createdAt,
  });

  factory StaffPaymentModel.fromJson(Map<String, dynamic> json) {
    return StaffPaymentModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String?,
      admissionNo: json['admission_no'] as String?,
      feeHead: json['fee_head'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      paymentMode: json['payment_mode'] as String? ?? 'CASH',
      receiptNo: json['receipt_no'] as String? ?? '',
      collectedBy: json['collected_by'] as String? ?? '',
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'fee_head': feeHead,
        'academic_year': academicYear,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'payment_mode': paymentMode,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}
