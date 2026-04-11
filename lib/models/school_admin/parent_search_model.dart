// =============================================================================
// FILE: lib/models/school_admin/parent_search_model.dart
// PURPOSE: Lightweight model for parent search results (phone lookup).
// =============================================================================

class ParentSearchModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? relation;
  final int childrenCount;

  const ParentSearchModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.relation,
    required this.childrenCount,
  });

  String get fullName => '$firstName $lastName';

  factory ParentSearchModel.fromJson(Map<String, dynamic> json) {
    return ParentSearchModel(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      relation: json['relation'] as String?,
      childrenCount:
          (json['_count'] as Map<String, dynamic>?)?['links'] as int? ??
              json['childrenCount'] as int? ??
              0,
    );
  }
}
