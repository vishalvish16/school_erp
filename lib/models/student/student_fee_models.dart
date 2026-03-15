// =============================================================================
// FILE: lib/models/student/student_fee_models.dart
// PURPOSE: Fee models for the Student portal.
// =============================================================================

class StudentFeeDuesModel {
  final String academicYear;
  final List<FeeDueItem> dues;
  final double totalDue;

  const StudentFeeDuesModel({
    this.academicYear = '',
    this.dues = const [],
    this.totalDue = 0.0,
  });

  factory StudentFeeDuesModel.fromJson(Map<String, dynamic> json) {
    final duesRaw = json['dues'];
    final dues = duesRaw is List
        ? duesRaw
            .map((e) => FeeDueItem.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <FeeDueItem>[];

    return StudentFeeDuesModel(
      academicYear: json['academic_year'] as String? ?? '',
      dues: dues,
      totalDue: (json['total_due'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FeeDueItem {
  final String id;
  final String feeHead;
  final double amount;
  final String? dueDate;

  const FeeDueItem({
    required this.id,
    required this.feeHead,
    required this.amount,
    this.dueDate,
  });

  factory FeeDueItem.fromJson(Map<String, dynamic> json) {
    return FeeDueItem(
      id: json['id'] as String? ?? '',
      feeHead: json['fee_head'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] as String?,
    );
  }
}

class StudentPaymentModel {
  final String id;
  final String feeHead;
  final double amount;
  final String paymentDate;
  final String receiptNo;
  final String paymentMode;

  const StudentPaymentModel({
    required this.id,
    required this.feeHead,
    required this.amount,
    required this.paymentDate,
    required this.receiptNo,
    required this.paymentMode,
  });

  factory StudentPaymentModel.fromJson(Map<String, dynamic> json) {
    return StudentPaymentModel(
      id: json['id'] as String? ?? '',
      feeHead: json['fee_head'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] as String? ?? '',
      receiptNo: json['receipt_no'] as String? ?? '',
      paymentMode: json['payment_mode'] as String? ?? 'CASH',
    );
  }
}

class StudentReceiptModel {
  final String id;
  final String receiptNo;
  final String feeHead;
  final double amount;
  final String paymentDate;
  final String paymentMode;
  final String? remarks;

  const StudentReceiptModel({
    required this.id,
    required this.receiptNo,
    required this.feeHead,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    this.remarks,
  });

  factory StudentReceiptModel.fromJson(Map<String, dynamic> json) {
    return StudentReceiptModel(
      id: json['id'] as String? ?? '',
      receiptNo: json['receipt_no'] as String? ?? '',
      feeHead: json['fee_head'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] as String? ?? '',
      paymentMode: json['payment_mode'] as String? ?? 'CASH',
      remarks: json['remarks'] as String?,
    );
  }
}
