// =============================================================================
// FILE: lib/models/staff/staff_student_model.dart
// PURPOSE: Read-only student model for the Staff/Clerk portal.
// =============================================================================

class StaffStudentModel {
  final String id;
  final String schoolId;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime dateOfBirth;
  final String? bloodGroup;
  final String? phone;
  final String? email;
  final String? address;
  final String? photoUrl;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final int? rollNo;
  final String status;
  final DateTime admissionDate;
  final String? parentName;
  final String? parentPhone;
  final DateTime createdAt;

  const StaffStudentModel({
    required this.id,
    required this.schoolId,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    this.bloodGroup,
    this.phone,
    this.email,
    this.address,
    this.photoUrl,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.rollNo,
    required this.status,
    required this.admissionDate,
    this.parentName,
    this.parentPhone,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory StaffStudentModel.fromJson(Map<String, dynamic> json) {
    return StaffStudentModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      admissionNo: json['admission_no'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String) ?? DateTime.now()
          : DateTime.now(),
      bloodGroup: json['blood_group'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
      classId: json['class_id'] as String?,
      className: json['class_name'] as String?,
      sectionId: json['section_id'] as String?,
      sectionName: json['section_name'] as String?,
      rollNo: (json['roll_no'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'ACTIVE',
      admissionDate: json['admission_date'] != null
          ? DateTime.tryParse(json['admission_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      parentName: json['parent_name'] as String?,
      parentPhone: json['parent_phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
