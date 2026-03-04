import 'subscription_models.dart';

class SchoolModel {
  final String id;
  final String schoolCode;
  final String name;
  final String? subdomain;
  final String? contactEmail;
  final String status;
  final bool isActive;
  final int studentCount;
  final int teacherCount;
  final String? contactPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final int? planId;
  final String? planName;
  final int? maxStudents;
  final int? maxTeachers;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final ActiveSubscriptionModel? activeSubscription;
  final List<SubscriptionHistoryModel> subscriptionHistory;

  SchoolModel({
    required this.id,
    required this.schoolCode,
    required this.name,
    this.subdomain,
    this.contactEmail,
    required this.status,
    required this.isActive,
    required this.studentCount,
    required this.teacherCount,
    this.contactPhone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.planId,
    this.planName,
    this.maxStudents,
    this.maxTeachers,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.activeSubscription,
    this.subscriptionHistory = const [],
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'].toString(),
      schoolCode: json['schoolCode'] ?? '',
      name: json['name'] ?? '',
      subdomain: json['subdomain'],
      contactEmail: json['contactEmail'],
      status: json['status'] ?? 'ACTIVE',
      isActive: json['isActive'] ?? true,
      studentCount: json['studentCount'] ?? 0,
      teacherCount: json['teacherCount'] ?? 0,
      contactPhone: json['contactPhone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      planId: json['planId'] != null
          ? int.tryParse(json['planId'].toString())
          : null,
      planName: json['plan'] != null ? json['plan']['name'] : null,
      maxStudents: _extractPlanInt(json, 'maxStudents'),
      maxTeachers: _extractPlanInt(json, 'maxTeachers'),
      subscriptionStart: json['subscriptionStart'] != null
          ? DateTime.tryParse(json['subscriptionStart'])
          : null,
      subscriptionEnd: json['subscriptionEnd'] != null
          ? DateTime.tryParse(json['subscriptionEnd'])
          : null,
      activeSubscription: json['active_subscription'] != null
          ? ActiveSubscriptionModel.fromJson(json['active_subscription'])
          : null,
      subscriptionHistory: json['subscription_history'] != null
          ? (json['subscription_history'] as List)
                .map((e) => SubscriptionHistoryModel.fromJson(e))
                .toList()
          : [],
    );
  }

  static int? _extractPlanInt(Map<String, dynamic> json, String key) {
    if (json[key] != null) return int.tryParse(json[key].toString());
    if (json['plan'] != null && json['plan'][key] != null) {
      return int.tryParse(json['plan'][key].toString());
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolCode': schoolCode,
      'name': name,
      'subdomain': subdomain,
      'contactEmail': contactEmail,
      'status': status,
      'isActive': isActive,
      'studentCount': studentCount,
      'teacherCount': teacherCount,
      if (subscriptionEnd != null)
        'subscriptionEnd': subscriptionEnd!.toIso8601String(),
    };
  }

  SchoolModel copyWith({
    String? id,
    String? schoolCode,
    String? name,
    String? subdomain,
    String? contactEmail,
    String? status,
    bool? isActive,
    int? studentCount,
    int? teacherCount,
    DateTime? subscriptionEnd,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      schoolCode: schoolCode ?? this.schoolCode,
      name: name ?? this.name,
      subdomain: subdomain ?? this.subdomain,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      studentCount: studentCount ?? this.studentCount,
      teacherCount: teacherCount ?? this.teacherCount,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
    );
  }
}
