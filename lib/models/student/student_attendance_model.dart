// =============================================================================
// FILE: lib/models/student/student_attendance_model.dart
// PURPOSE: Attendance models for the Student portal.
// =============================================================================

class StudentAttendanceModel {
  final List<AttendanceRecord> records;
  final String month;

  const StudentAttendanceModel({
    this.records = const [],
    this.month = '',
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    final recordsRaw = json['records'];
    final records = recordsRaw is List
        ? recordsRaw
            .map((e) => AttendanceRecord.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <AttendanceRecord>[];

    return StudentAttendanceModel(
      records: records,
      month: json['month'] as String? ?? '',
    );
  }
}

class AttendanceRecord {
  final String date;
  final String status;

  const AttendanceRecord({required this.date, required this.status});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'UNKNOWN',
    );
  }
}

class AttendanceSummaryModel {
  final String month;
  final int present;
  final int absent;
  final int late;
  final int halfDay;

  const AttendanceSummaryModel({
    this.month = '',
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.halfDay = 0,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      month: json['month'] as String? ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      halfDay: (json['half_day'] as num?)?.toInt() ?? 0,
    );
  }
}
