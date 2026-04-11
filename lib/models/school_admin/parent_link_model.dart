// =============================================================================
// FILE: lib/models/school_admin/parent_link_model.dart
// PURPOSE: Represents a parent linked to a student (from StudentParent junction).
// =============================================================================

class ParentLinkModel {
  final String linkId;
  final String parentId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? relation;
  final String linkRelation;
  final bool isPrimary;

  const ParentLinkModel({
    required this.linkId,
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.relation,
    required this.linkRelation,
    required this.isPrimary,
  });

  String get fullName => '$firstName $lastName';

  String get displayRelation =>
      linkRelation.isNotEmpty ? linkRelation : (relation ?? '\u2014');

  factory ParentLinkModel.fromJson(Map<String, dynamic> json) {
    return ParentLinkModel(
      linkId: json['linkId'] as String? ?? json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      relation: json['relation'] as String?,
      linkRelation:
          json['linkRelation'] as String? ?? json['relation'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'linkId': linkId,
        'parentId': parentId,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'relation': relation,
        'linkRelation': linkRelation,
        'isPrimary': isPrimary,
      };
}
