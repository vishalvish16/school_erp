class TeacherSectionModel {
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final int studentCount;
  final bool isClassTeacher;
  final List<String> subjects;

  const TeacherSectionModel({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.studentCount = 0,
    this.isClassTeacher = false,
    this.subjects = const [],
  });

  String get displayName => '$className - $sectionName';

  factory TeacherSectionModel.fromJson(Map<String, dynamic> json) {
    final subjectsRaw = json['subjects'];
    final subjects = subjectsRaw is List
        ? subjectsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return TeacherSectionModel(
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      isClassTeacher: json['is_class_teacher'] as bool? ?? false,
      subjects: subjects,
    );
  }
}

class SectionAttendanceModel {
  final String sectionId;
  final String className;
  final String sectionName;
  final String date;
  final bool isLocked;
  final AttendanceSummary summary;
  final List<StudentAttendanceRecord> students;

  const SectionAttendanceModel({
    required this.sectionId,
    required this.className,
    required this.sectionName,
    required this.date,
    this.isLocked = false,
    required this.summary,
    this.students = const [],
  });

  factory SectionAttendanceModel.fromJson(Map<String, dynamic> json) {
    final studentsRaw = json['students'];
    final students = studentsRaw is List
        ? studentsRaw
            .map((e) => StudentAttendanceRecord.fromJson(
                e is Map<String, dynamic> ? e : {}))
            .toList()
        : <StudentAttendanceRecord>[];

    return SectionAttendanceModel(
      sectionId: json['section_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isLocked: json['is_locked'] as bool? ?? false,
      summary: AttendanceSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : {},
      ),
      students: students,
    );
  }
}

class AttendanceSummary {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int notMarked;

  const AttendanceSummary({
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.halfDay = 0,
    this.notMarked = 0,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      halfDay: (json['half_day'] as num?)?.toInt() ?? 0,
      notMarked: (json['not_marked'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentAttendanceRecord {
  final String studentId;
  final String admissionNo;
  final String name;
  final int? rollNo;
  String status;
  String? remarks;

  StudentAttendanceRecord({
    required this.studentId,
    required this.admissionNo,
    required this.name,
    this.rollNo,
    this.status = 'PRESENT',
    this.remarks,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      studentId: json['student_id'] as String? ?? '',
      admissionNo: json['admission_no'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNo: (json['roll_no'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'PRESENT',
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'status': status,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class AttendanceReportModel {
  final String sectionId;
  final String className;
  final String sectionName;
  final String fromDate;
  final String toDate;
  final ReportSummary summary;
  final List<StudentReportRecord> students;

  const AttendanceReportModel({
    required this.sectionId,
    required this.className,
    required this.sectionName,
    required this.fromDate,
    required this.toDate,
    required this.summary,
    this.students = const [],
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    final studentsRaw = json['students'];
    final students = studentsRaw is List
        ? studentsRaw
            .map((e) => StudentReportRecord.fromJson(
                e is Map<String, dynamic> ? e : {}))
            .toList()
        : <StudentReportRecord>[];

    return AttendanceReportModel(
      sectionId: json['section_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      fromDate: json['from_date'] as String? ?? '',
      toDate: json['to_date'] as String? ?? '',
      summary: ReportSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : {},
      ),
      students: students,
    );
  }
}

class ReportSummary {
  final int totalWorkingDays;
  final double averageAttendancePct;

  const ReportSummary({
    this.totalWorkingDays = 0,
    this.averageAttendancePct = 0.0,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalWorkingDays: (json['total_working_days'] as num?)?.toInt() ?? 0,
      averageAttendancePct:
          (json['average_attendance_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StudentReportRecord {
  final String studentId;
  final String name;
  final int? rollNo;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final double attendancePct;

  const StudentReportRecord({
    required this.studentId,
    required this.name,
    this.rollNo,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.halfDay = 0,
    this.attendancePct = 0.0,
  });

  factory StudentReportRecord.fromJson(Map<String, dynamic> json) {
    return StudentReportRecord(
      studentId: json['student_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNo: (json['roll_no'] as num?)?.toInt(),
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      halfDay: (json['half_day'] as num?)?.toInt() ?? 0,
      attendancePct: (json['attendance_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
