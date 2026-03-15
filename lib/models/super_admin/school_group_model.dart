// =============================================================================
// FILE: lib/models/super_admin/school_group_model.dart
// PURPOSE: Super Admin school group model
// =============================================================================

import 'school_model.dart';

class SuperAdminSchoolGroupModel {
  final String id;
  final String name;
  final String? slug;
  final String? subdomain;
  final String? type;
  final String? description;
  final String? hqCity;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String status;
  final int schoolCount;
  final int studentCount;
  final int teacherCount;
  final double mrr;
  final Map<String, dynamic>? groupAdmin;
  final Map<String, int>? subscriptionBreakdown;
  final int expiringSoon;
  final List<SuperAdminSchoolModel> schools;

  SuperAdminSchoolGroupModel({
    required this.id,
    required this.name,
    this.slug,
    this.subdomain,
    this.type,
    this.description,
    this.hqCity,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    this.address,
    this.city,
    this.state,
    this.country,
    this.status = 'ACTIVE',
    this.schoolCount = 0,
    this.studentCount = 0,
    this.teacherCount = 0,
    this.mrr = 0,
    this.groupAdmin,
    this.subscriptionBreakdown,
    this.expiringSoon = 0,
    this.schools = const [],
  });

  factory SuperAdminSchoolGroupModel.fromJson(Map<String, dynamic> json) {
    final schoolsList = json['schools'] ?? json['school_list'] ?? [];
    // Parse subscription breakdown
    Map<String, int>? subBreakdown;
    final rawBreakdown = json['subscription_breakdown'] ?? json['subscriptionBreakdown'];
    if (rawBreakdown is Map) {
      subBreakdown = rawBreakdown.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
    }
    // Parse group admin
    Map<String, dynamic>? adminMap;
    final rawAdmin = json['group_admin'] ?? json['groupAdmin'];
    if (rawAdmin is Map) {
      adminMap = Map<String, dynamic>.from(rawAdmin);
    }

    return SuperAdminSchoolGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
      subdomain: json['subdomain'],
      type: json['type'],
      description: json['description'],
      hqCity: json['hq_city'] ?? json['hqCity'],
      contactPerson: json['contact_person'] ?? json['contactPerson'],
      contactEmail: json['contact_email'] ?? json['contactEmail'],
      contactPhone: json['contact_phone'] ?? json['contactPhone'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      status: json['status'] ?? 'ACTIVE',
      schoolCount: json['school_count'] ?? json['schoolCount'] ?? 0,
      studentCount: json['student_count'] ?? json['studentCount'] ?? 0,
      teacherCount: json['teacher_count'] ?? json['teacherCount'] ?? 0,
      mrr: (json['mrr'] ?? 0) is num ? (json['mrr'] ?? 0).toDouble() : 0,
      groupAdmin: adminMap,
      subscriptionBreakdown: subBreakdown,
      expiringSoon: json['expiring_soon'] ?? json['expiringSoon'] ?? 0,
      schools: schoolsList is List
          ? (schoolsList)
              .map((e) => SuperAdminSchoolModel.fromJson(
                    e is Map<String, dynamic> ? e : {},
                  ))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'subdomain': subdomain,
        'type': type,
        'description': description,
        'hq_city': hqCity,
        'contact_person': contactPerson,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'logo_url': logoUrl,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'status': status,
        'school_count': schoolCount,
        'student_count': studentCount,
        'teacher_count': teacherCount,
        'mrr': mrr,
        if (groupAdmin != null) 'group_admin': groupAdmin,
        if (subscriptionBreakdown != null) 'subscription_breakdown': subscriptionBreakdown,
        'expiring_soon': expiringSoon,
      };
}
