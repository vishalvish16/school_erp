// =============================================================================
// FILE: lib/models/parent/fee_structure_summary_model.dart
// PURPOSE: Fee structure summary model for Parent Portal.
// =============================================================================

class FeeStructureSummaryModel {
  final String feeHead;
  final String amount;
  final String frequency;

  const FeeStructureSummaryModel({
    required this.feeHead,
    required this.amount,
    required this.frequency,
  });

  factory FeeStructureSummaryModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureSummaryModel(
      feeHead: json['feeHead'] as String? ?? json['fee_head'] as String? ?? '',
      amount: json['amount']?.toString() ?? json['amount'] as String? ?? '0',
      frequency: json['frequency'] as String? ?? 'One-time',
    );
  }
}
