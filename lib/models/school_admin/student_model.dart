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
  final String? userId;
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
    this.userId,
    required this.createdAt,
  });

  bool get hasLogin => userId != null && userId!.isNotEmpty;

  String get fullName => '$firstName $lastName';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // Support both snake_case (API) and camelCase (fallback)
    String str(String s, String c) =>
        json[s] as String? ?? json[c] as String? ?? '';
    T? opt<T>(String s, String c) => json[s] as T? ?? json[c] as T?;
    DateTime date(String s, String c) {
      final v = json[s] ?? json[c];
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return StudentModel(
      id: str('id', 'id'),
      schoolId: str('school_id', 'schoolId'),
      admissionNo: str('admission_no', 'admissionNo'),
      firstName: str('first_name', 'firstName'),
      lastName: str('last_name', 'lastName'),
      gender: str('gender', 'gender'),
      dateOfBirth: date('date_of_birth', 'dateOfBirth'),
      bloodGroup: opt<String>('blood_group', 'bloodGroup'),
      phone: opt<String>('phone', 'phone'),
      email: opt<String>('email', 'email'),
      address: opt<String>('address', 'address'),
      photoUrl: opt<String>('photo_url', 'photoUrl'),
      classId: opt<String>('class_id', 'classId'),
      className: opt<String>('class_name', 'className'),
      sectionId: opt<String>('section_id', 'sectionId'),
      sectionName: opt<String>('section_name', 'sectionName'),
      rollNo: (json['roll_no'] as num?)?.toInt() ?? (json['rollNo'] as num?)?.toInt(),
      status: str('status', 'status').isEmpty ? 'ACTIVE' : str('status', 'status'),
      admissionDate: date('admission_date', 'admissionDate'),
      parentName: opt<String>('parent_name', 'parentName'),
      parentPhone: opt<String>('parent_phone', 'parentPhone'),
      parentEmail: opt<String>('parent_email', 'parentEmail'),
      parentRelation: opt<String>('parent_relation', 'parentRelation'),
      userId: opt<String>('user_id', 'userId'),
      createdAt: date('created_at', 'createdAt'),
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
