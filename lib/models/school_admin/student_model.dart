// =============================================================================
// FILE: lib/models/school_admin/student_model.dart
// PURPOSE: Student model for School Admin portal.
// =============================================================================

class StudentModel {
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
  final String? parentEmail;
  final String? parentRelation;
  final DateTime createdAt;

  const StudentModel({
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
    this.parentEmail,
    this.parentRelation,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // Support both snake_case (API) and camelCase (fallback)
    String _str(String s, String c) =>
        json[s] as String? ?? json[c] as String? ?? '';
    T? _opt<T>(String s, String c) => json[s] as T? ?? json[c] as T?;
    DateTime _date(String s, String c) {
      final v = json[s] ?? json[c];
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return StudentModel(
      id: _str('id', 'id'),
      schoolId: _str('school_id', 'schoolId'),
      admissionNo: _str('admission_no', 'admissionNo'),
      firstName: _str('first_name', 'firstName'),
      lastName: _str('last_name', 'lastName'),
      gender: _str('gender', 'gender'),
      dateOfBirth: _date('date_of_birth', 'dateOfBirth'),
      bloodGroup: _opt<String>('blood_group', 'bloodGroup'),
      phone: _opt<String>('phone', 'phone'),
      email: _opt<String>('email', 'email'),
      address: _opt<String>('address', 'address'),
      photoUrl: _opt<String>('photo_url', 'photoUrl'),
      classId: _opt<String>('class_id', 'classId'),
      className: _opt<String>('class_name', 'className'),
      sectionId: _opt<String>('section_id', 'sectionId'),
      sectionName: _opt<String>('section_name', 'sectionName'),
      rollNo: (json['roll_no'] as num?)?.toInt() ?? (json['rollNo'] as num?)?.toInt(),
      status: _str('status', 'status').isEmpty ? 'ACTIVE' : _str('status', 'status'),
      admissionDate: _date('admission_date', 'admissionDate'),
      parentName: _opt<String>('parent_name', 'parentName'),
      parentPhone: _opt<String>('parent_phone', 'parentPhone'),
      parentEmail: _opt<String>('parent_email', 'parentEmail'),
      parentRelation: _opt<String>('parent_relation', 'parentRelation'),
      createdAt: _date('created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'admission_no': admissionNo,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (classId != null) 'class_id': classId,
        if (sectionId != null) 'section_id': sectionId,
        if (rollNo != null) 'roll_no': rollNo,
        'status': status,
        'admission_date': admissionDate.toIso8601String().split('T').first,
        if (parentName != null) 'parent_name': parentName,
        if (parentPhone != null) 'parent_phone': parentPhone,
        if (parentEmail != null) 'parent_email': parentEmail,
        if (parentRelation != null) 'parent_relation': parentRelation,
      };
}
