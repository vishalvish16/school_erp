// =============================================================================
// FILE: lib/models/super_admin/school_model.dart
// PURPOSE: Super Admin school model (UUID-based schema)
// =============================================================================

import 'plan_model.dart';

class SuperAdminSchoolModel {
  final String id;
  final String name;
  final String code;
  final String board;
  final String schoolType;
  final String status;
  final String? subdomain;
  final String? country;
  final String? city;
  final String? state;
  final String? pin;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? groupId;
  final SuperAdminPlanModel? plan;
  final int studentLimit;
  final int studentCount;
  /// Teaching/faculty staff rows (`staff` table).
  final int teacherCount;
  final int overdueDays;
  final DateTime? subscriptionEnd;
  final Map<String, bool> features;
  final Map<String, dynamic>? primaryAdmin;

  SuperAdminSchoolModel({
    required this.id,
    required this.name,
    required this.code,
    this.board = 'CBSE',
    this.schoolType = 'private',
    this.status = 'trial',
    this.subdomain,
    this.country,
    this.city,
    this.state,
    this.pin,
    this.phone,
    this.email,
    this.logoUrl,
    this.groupId,
    this.plan,
    this.studentLimit = 500,
    this.studentCount = 0,
    this.teacherCount = 0,
    this.overdueDays = 0,
    this.subscriptionEnd,
    this.features = const {},
    this.primaryAdmin,
  });

  factory SuperAdminSchoolModel.fromJson(Map<String, dynamic> json) {
    final featuresMap = <String, bool>{};
    final sf = json['school_features'] ?? json['features'] ?? [];
    if (sf is List) {
      for (final f in sf) {
        final key = f['feature_key'] ?? f['featureKey'];
        if (key != null) {
          featuresMap[key.toString()] = f['is_enabled'] ?? f['isEnabled'] ?? true;
        }
      }
    } else if (sf is Map) {
      featuresMap.addAll(
        Map.from(sf).map((k, v) => MapEntry(k.toString(), v == true)),
      );
    }
    return SuperAdminSchoolModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? json['school_code'] ?? json['schoolCode'] ?? '',
      board: json['board'] ?? 'CBSE',
      schoolType: json['school_type'] ?? json['schoolType'] ?? 'private',
      status: json['status'] ?? 'trial',
      subdomain: json['subdomain'],
      country: json['country'],
      city: json['city'],
      state: json['state'],
      pin: json['pin'] ?? json['pin_code'] ?? json['pinCode'],
      phone: json['phone'] ?? json['contact_phone'],
      email: json['email'] ?? json['contact_email'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      groupId: json['group_id']?.toString() ?? json['groupId']?.toString(),
      plan: json['plan'] != null
          ? SuperAdminPlanModel.fromJson(
              json['plan'] is Map ? json['plan'] as Map<String, dynamic> : {},
            )
          : null,
      studentLimit: json['student_limit'] ?? json['studentLimit'] ?? 500,
      studentCount: json['student_count'] ?? json['studentCount'] ?? 0,
      teacherCount: json['teacher_count'] ?? json['teacherCount'] ?? 0,
      overdueDays: json['overdue_days'] ?? json['overdueDays'] ?? 0,
      subscriptionEnd: json['subscription_end'] != null
          ? DateTime.tryParse(json['subscription_end'].toString())
          : (json['subscriptionEnd'] != null
              ? DateTime.tryParse(json['subscriptionEnd'].toString())
              : null),
      features: featuresMap,
      primaryAdmin: json['primary_admin'] is Map
          ? Map<String, dynamic>.from(json['primary_admin'] as Map)
          : (json['primaryAdmin'] is Map ? Map<String, dynamic>.from(json['primaryAdmin'] as Map) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'board': board,
        'school_type': schoolType,
        'status': status,
        'subdomain': subdomain,
        'country': country,
        'city': city,
        'state': state,
        'pin': pin,
        'phone': phone,
        'email': email,
        'logo_url': logoUrl,
        'group_id': groupId,
        'student_limit': studentLimit,
        'student_count': studentCount,
        'teacher_count': teacherCount,
        'overdue_days': overdueDays,
        if (subscriptionEnd != null) 'subscription_end': subscriptionEnd!.toIso8601String(),
      };
}
