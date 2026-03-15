// =============================================================================
// FILE: lib/models/parent/parent_profile_model.dart
// PURPOSE: Parent profile model for Parent Portal.
// =============================================================================

class ParentProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? relation;
  final String schoolId;
  final String schoolName;

  const ParentProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.relation,
    required this.schoolId,
    required this.schoolName,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (firstName.isNotEmpty) return firstName.substring(0, 1).toUpperCase();
    if (lastName.isNotEmpty) return lastName.substring(0, 1).toUpperCase();
    return 'P';
  }

  factory ParentProfileModel.fromJson(Map<String, dynamic> json) {
    return ParentProfileModel(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      relation: json['relation'] as String?,
      schoolId: json['schoolId'] as String? ?? json['school_id'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? json['school_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'relation': relation,
        'school_id': schoolId,
        'school_name': schoolName,
      };
}
