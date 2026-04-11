// =============================================================================
// FILE: lib/models/school_admin/fee_payment_model.dart
// PURPOSE: Fee payment model for School Admin portal.
// =============================================================================

class FeePaymentModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String? studentName;
  final String feeHead;
  final String academicYear;
  final double amount;
  final DateTime paymentDate;
  final String paymentMode; // CASH | UPI | BANK_TRANSFER | CHEQUE
  final String receiptNo;
  final String collectedBy;
  final String? remarks;
  final DateTime createdAt;

  const FeePaymentModel({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.studentName,
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

  factory FeePaymentModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (API/Prisma) and snake_case
    String str(String k1, String k2) =>
        json[k1] as String? ?? json[k2] as String? ?? '';
    String? strOpt(String k1, String k2) =>
        json[k1] as String? ?? json[k2] as String?;
    DateTime date(String k1, String k2) {
      final v = json[k1] ?? json[k2];
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is DateTime) return v;
      return DateTime.now();
    }
    return FeePaymentModel(
      id: str('id', 'id'),
      schoolId: str('schoolId', 'school_id'),
      studentId: str('studentId', 'student_id'),
      studentName: strOpt('studentName', 'student_name'),
      feeHead: str('feeHead', 'fee_head'),
      academicYear: str('academicYear', 'academic_year'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: date('paymentDate', 'payment_date'),
      paymentMode: str('paymentMode', 'payment_mode'),
      receiptNo: str('receiptNo', 'receipt_no'),
      collectedBy: str('collectedBy', 'collected_by'),
      remarks: strOpt('remarks', 'remarks'),
      createdAt: date('createdAt', 'created_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'fee_head': feeHead,
        'academic_year': academicYear,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'payment_mode': paymentMode,
        'receipt_no': receiptNo,
        if (remarks != null) 'remarks': remarks,
      };
}
