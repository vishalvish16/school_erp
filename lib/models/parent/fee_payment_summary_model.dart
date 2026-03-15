// =============================================================================
// FILE: lib/models/parent/fee_payment_summary_model.dart
// PURPOSE: Fee payment summary model for Parent Portal.
// =============================================================================

class FeePaymentSummaryModel {
  final String id;
  final String feeHead;
  final String amount;
  final DateTime paymentDate;
  final String receiptNo;
  final String paymentMode;

  const FeePaymentSummaryModel({
    required this.id,
    required this.feeHead,
    required this.amount,
    required this.paymentDate,
    required this.receiptNo,
    required this.paymentMode,
  });

  factory FeePaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['paymentDate'] as String? ?? json['payment_date'] as String?;
    return FeePaymentSummaryModel(
      id: json['id'] as String? ?? '',
      feeHead: json['feeHead'] as String? ?? json['fee_head'] as String? ?? '',
      amount: json['amount']?.toString() ?? json['amount'] as String? ?? '0',
      paymentDate: dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now(),
      receiptNo: json['receiptNo'] as String? ?? json['receipt_no'] as String? ?? '',
      paymentMode: json['paymentMode'] as String? ?? json['payment_mode'] as String? ?? '',
    );
  }
}
