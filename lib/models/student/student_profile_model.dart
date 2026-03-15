// =============================================================================
// FILE: lib/models/student/student_profile_model.dart
// PURPOSE: Student profile model for the Student portal.
// =============================================================================

class StudentProfileModel {
  final String id;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String gender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? phone;
  final String? email;
  final String? address;
  final String? photoUrl;
  final String? classId;
  final String? sectionId;
  final int? rollNo;
  final StudentClassInfo? class_;
  final StudentSectionInfo? section;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? parentRelation;

  const StudentProfileModel({
    required this.id,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.phone,
    this.email,
    this.address,
    this.photoUrl,
    this.classId,
    this.sectionId,
    this.rollNo,
    this.class_,
    this.section,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.parentRelation,
  });

  String get fullName => '$firstName $lastName';

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] as String? ?? '',
      admissionNo: json['admission_no'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String?,
      bloodGroup: json['blood_group'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
      classId: json['class_id'] as String?,
      sectionId: json['section_id'] as String?,
      rollNo: (json['roll_no'] as num?)?.toInt(),
      class_: json['class'] != null
          ? StudentClassInfo.fromJson(
              json['class'] is Map<String, dynamic> ? json['class'] : {},
            )
          : null,
      section: json['section'] != null
          ? StudentSectionInfo.fromJson(
              json['section'] is Map<String, dynamic> ? json['section'] : {},
            )
          : null,
      parentName: json['parent_name'] as String?,
      parentPhone: json['parent_phone'] as String?,
      parentEmail: json['parent_email'] as String?,
      parentRelation: json['parent_relation'] as String?,
    );
  }
}

class StudentClassInfo {
  final String id;
  final String name;

  const StudentClassInfo({required this.id, required this.name});

  factory StudentClassInfo.fromJson(Map<String, dynamic> json) {
    return StudentClassInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class StudentSectionInfo {
  final String id;
  final String name;

  const StudentSectionInfo({required this.id, required this.name});

  factory StudentSectionInfo.fromJson(Map<String, dynamic> json) {
    return StudentSectionInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
