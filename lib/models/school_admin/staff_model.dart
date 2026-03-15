// =============================================================================
// FILE: lib/models/school_admin/staff_model.dart
// PURPOSE: Staff model for School Admin portal — extended with full fields.
// =============================================================================

class StaffModel {
  final String id;
  final String schoolId;
  final String? userId;
  final String employeeNo;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String email;
  final String designation;
  final List<String> subjects;
  final String? qualification;
  final DateTime joinDate;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  // Extended fields
  final String? address;
  final String? city;
  final String? state;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String employeeType;
  final String? department;
  final int? experienceYears;
  final String? salaryGrade;

  const StaffModel({
    required this.id,
    required this.schoolId,
    this.userId,
    required this.employeeNo,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.phone,
    required this.email,
    required this.designation,
    required this.subjects,
    this.qualification,
    required this.joinDate,
    this.photoUrl,
    required this.isActive,
    required this.createdAt,
    this.address,
    this.city,
    this.state,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.employeeType = 'PERMANENT',
    this.department,
    this.experienceYears,
    this.salaryGrade,
  });

  String get fullName => '$firstName $lastName';

  /// Reads value from json supporting both snake_case (API) and camelCase (Prisma).
  static dynamic _v(Map<String, dynamic> json, String snake, String camel) {
    final v = json[snake] ?? json[camel];
    return v;
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final subjectsList = _v(json, 'subjects', 'subjects');
    final subjects = subjectsList is List
        ? subjectsList.map((e) => e.toString()).toList()
        : <String>[];

    final joinDateRaw = _v(json, 'join_date', 'joinDate');
    final createdAtRaw = _v(json, 'created_at', 'createdAt');
    final dateOfBirthRaw = _v(json, 'date_of_birth', 'dateOfBirth');
    final experienceYearsRaw = _v(json, 'experience_years', 'experienceYears');

    return StaffModel(
      id: json['id'] as String? ?? '',
      schoolId: (_v(json, 'school_id', 'schoolId') as String?) ?? '',
      userId: _v(json, 'user_id', 'userId') as String?,
      employeeNo: (_v(json, 'employee_no', 'employeeNo') as String?) ?? '',
      firstName: (_v(json, 'first_name', 'firstName') as String?) ?? '',
      lastName: (_v(json, 'last_name', 'lastName') as String?) ?? '',
      gender: (_v(json, 'gender', 'gender') as String?) ?? '',
      dateOfBirth: dateOfBirthRaw != null
          ? DateTime.tryParse(dateOfBirthRaw.toString())
          : null,
      phone: _v(json, 'phone', 'phone') as String?,
      email: (_v(json, 'email', 'email') as String?) ?? '',
      designation: (_v(json, 'designation', 'designation') as String?) ?? '',
      subjects: subjects,
      qualification: _v(json, 'qualification', 'qualification') as String?,
      joinDate: joinDateRaw != null
          ? DateTime.tryParse(joinDateRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
      photoUrl: _v(json, 'photo_url', 'photoUrl') as String?,
      isActive: (_v(json, 'is_active', 'isActive') as bool?) ?? true,
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
      address: _v(json, 'address', 'address') as String?,
      city: _v(json, 'city', 'city') as String?,
      state: _v(json, 'state', 'state') as String?,
      bloodGroup: _v(json, 'blood_group', 'bloodGroup') as String?,
      emergencyContactName:
          _v(json, 'emergency_contact_name', 'emergencyContactName') as String?,
      emergencyContactPhone:
          _v(json, 'emergency_contact_phone', 'emergencyContactPhone') as String?,
      employeeType:
          (_v(json, 'employee_type', 'employeeType') as String?) ?? 'PERMANENT',
      department: _v(json, 'department', 'department') as String?,
      experienceYears: experienceYearsRaw != null
          ? (experienceYearsRaw as num).toInt()
          : null,
      salaryGrade: _v(json, 'salary_grade', 'salaryGrade') as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_no': employeeNo,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        if (phone != null) 'phone': phone,
        'email': email,
        'designation': designation,
        'subjects': subjects,
        if (qualification != null) 'qualification': qualification,
        'join_date': joinDate.toIso8601String().split('T').first,
        'is_active': isActive,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (emergencyContactName != null)
          'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergency_contact_phone': emergencyContactPhone,
        'employee_type': employeeType,
        if (department != null) 'department': department,
        if (experienceYears != null) 'experience_years': experienceYears,
        if (salaryGrade != null) 'salary_grade': salaryGrade,
      };
}
