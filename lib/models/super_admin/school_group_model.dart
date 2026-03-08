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
  final String? hqCity;
  final String? contactPerson;
  final String? contactEmail;
  final String? status;
  final int schoolCount;
  final int studentCount;
  final double mrr;
  final List<SuperAdminSchoolModel> schools;

  SuperAdminSchoolGroupModel({
    required this.id,
    required this.name,
    this.slug,
    this.subdomain,
    this.type,
    this.hqCity,
    this.contactPerson,
    this.contactEmail,
    this.status,
    this.schoolCount = 0,
    this.studentCount = 0,
    this.mrr = 0,
    this.schools = const [],
  });

  factory SuperAdminSchoolGroupModel.fromJson(Map<String, dynamic> json) {
    final schoolsList = json['schools'] ?? json['school_list'] ?? [];
    return SuperAdminSchoolGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
      subdomain: json['subdomain'],
      type: json['type'],
      hqCity: json['hq_city'] ?? json['hqCity'],
      contactPerson: json['contact_person'] ?? json['contactPerson'],
      contactEmail: json['contact_email'] ?? json['contactEmail'],
      status: json['status'],
      schoolCount: json['school_count'] ?? json['schoolCount'] ?? 0,
      studentCount: json['student_count'] ?? json['studentCount'] ?? 0,
      mrr: (json['mrr'] ?? 0) is num ? (json['mrr'] ?? 0).toDouble() : 0,
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
        'hq_city': hqCity,
        'contact_person': contactPerson,
        'contact_email': contactEmail,
        'status': status,
        'school_count': schoolCount,
        'student_count': studentCount,
        'mrr': mrr,
      };
}
