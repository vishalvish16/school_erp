class ActiveSubscriptionModel {
  final String subscriptionId;
  final String planId;
  final String planName;
  final String billingCycle;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  ActiveSubscriptionModel({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.billingCycle,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory ActiveSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ActiveSubscriptionModel(
      subscriptionId: json['subscription_id'].toString(),
      planId: json['plan_id'].toString(),
      planName: json['plan_name'] ?? 'N/A',
      billingCycle: json['billing_cycle'] ?? 'MONTHLY',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'ACTIVE',
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }
}

class SubscriptionHistoryModel {
  final String subscriptionId;
  final String planId;
  final String planName;
  final String billingCycle;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;

  SubscriptionHistoryModel({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.billingCycle,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory SubscriptionHistoryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryModel(
      subscriptionId: json['subscription_id'].toString(),
      planId: json['plan_id'].toString(),
      planName: json['plan_name'] ?? 'N/A',
      billingCycle: json['billing_cycle'] ?? 'MONTHLY',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'ACTIVE',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
