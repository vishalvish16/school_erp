class TeacherProfileModel {
  final String id;
  final String employeeNo;
  final String firstName;
  final String lastName;
  final String designation;
  final String? department;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final List<String> subjects;
  final String? joinDate;
  final TeacherClassInfo? classTeacherOf;
  final List<SubjectAssignment> subjectAssignments;
  final TeacherSchoolInfo? school;

  const TeacherProfileModel({
    required this.id,
    required this.employeeNo,
    required this.firstName,
    required this.lastName,
    required this.designation,
    this.department,
    this.email,
    this.phone,
    this.photoUrl,
    this.subjects = const [],
    this.joinDate,
    this.classTeacherOf,
    this.subjectAssignments = const [],
    this.school,
  });

  String get fullName => '$firstName $lastName';

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    final subjectsRaw = json['subjects'];
    final subjects = subjectsRaw is List
        ? subjectsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final assignmentsRaw = json['subject_assignments'];
    final assignments = assignmentsRaw is List
        ? assignmentsRaw
            .map((e) => SubjectAssignment.fromJson(
                e is Map<String, dynamic> ? e : {}))
            .toList()
        : <SubjectAssignment>[];

    return TeacherProfileModel(
      id: json['id'] as String? ?? '',
      employeeNo: json['employee_no'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      subjects: subjects,
      joinDate: json['join_date'] as String?,
      classTeacherOf: json['class_teacher_of'] is Map<String, dynamic>
          ? TeacherClassInfo.fromJson(
              json['class_teacher_of'] as Map<String, dynamic>)
          : null,
      subjectAssignments: assignments,
      school: json['school'] is Map<String, dynamic>
          ? TeacherSchoolInfo.fromJson(
              json['school'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TeacherClassInfo {
  final String className;
  final String sectionName;
  final int studentCount;

  const TeacherClassInfo({
    required this.className,
    required this.sectionName,
    this.studentCount = 0,
  });

  factory TeacherClassInfo.fromJson(Map<String, dynamic> json) {
    return TeacherClassInfo(
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubjectAssignment {
  final String className;
  final String sectionName;
  final String subject;

  const SubjectAssignment({
    required this.className,
    required this.sectionName,
    required this.subject,
  });

  factory SubjectAssignment.fromJson(Map<String, dynamic> json) {
    return SubjectAssignment(
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
    );
  }
}

class TeacherSchoolInfo {
  final String name;

  const TeacherSchoolInfo({required this.name});

  factory TeacherSchoolInfo.fromJson(Map<String, dynamic> json) {
    return TeacherSchoolInfo(
      name: json['name'] as String? ?? '',
    );
  }
}
