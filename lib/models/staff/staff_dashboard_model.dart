// =============================================================================
// FILE: lib/models/staff/staff_dashboard_model.dart
// PURPOSE: Dashboard stats model for the Staff/Clerk portal.
// =============================================================================

class StaffDashboardModel {
  final double feeCollectedToday;
  final double feeCollectedThisMonth;
  final int totalPaymentsToday;
  final int totalPaymentsThisMonth;
  final int activeNoticesCount;
  final int totalStudents;
  final List<StaffRecentPayment> recentPayments;

  const StaffDashboardModel({
    this.feeCollectedToday = 0.0,
    this.feeCollectedThisMonth = 0.0,
    this.totalPaymentsToday = 0,
    this.totalPaymentsThisMonth = 0,
    this.activeNoticesCount = 0,
    this.totalStudents = 0,
    this.recentPayments = const [],
  });

  factory StaffDashboardModel.fromJson(Map<String, dynamic> json) {
    final paymentsRaw = json['recent_payments'];
    final payments = paymentsRaw is List
        ? paymentsRaw
            .map((e) => StaffRecentPayment.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <StaffRecentPayment>[];

    return StaffDashboardModel(
      feeCollectedToday:
          (json['fee_collected_today'] as num?)?.toDouble() ?? 0.0,
      feeCollectedThisMonth:
          (json['fee_collected_this_month'] as num?)?.toDouble() ?? 0.0,
      totalPaymentsToday:
          (json['total_payments_today'] as num?)?.toInt() ?? 0,
      totalPaymentsThisMonth:
          (json['total_payments_this_month'] as num?)?.toInt() ?? 0,
      activeNoticesCount:
          (json['active_notices_count'] as num?)?.toInt() ?? 0,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      recentPayments: payments,
    );
  }
}

class StaffRecentPayment {
  final String id;
  final String studentName;
  final String feeHead;
  final double amount;
  final String paymentMode;
  final String receiptNo;
  final DateTime paymentDate;

  const StaffRecentPayment({
    required this.id,
    required this.studentName,
    required this.feeHead,
    required this.amount,
    required this.paymentMode,
    required this.receiptNo,
    required this.paymentDate,
  });

  factory StaffRecentPayment.fromJson(Map<String, dynamic> json) {
    return StaffRecentPayment(
      id: json['id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      feeHead: json['fee_head'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode'] as String? ?? 'CASH',
      receiptNo: json['receipt_no'] as String? ?? '',
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
