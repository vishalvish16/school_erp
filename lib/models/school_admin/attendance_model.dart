// =============================================================================
// FILE: lib/models/school_admin/attendance_model.dart
// PURPOSE: Attendance model for School Admin portal.
// =============================================================================

class AttendanceRecord {
  final String id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String sectionId;
  final DateTime date;
  final String status; // PRESENT | ABSENT | LATE | HOLIDAY
  final String markedBy;
  final String? remarks;

  const AttendanceRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.sectionId,
    required this.date,
    required this.status,
    required this.markedBy,
    this.remarks,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'ABSENT',
      markedBy: json['marked_by'] as String? ?? '',
      remarks: json['remarks'] as String?,
    );
  }
}

class AttendanceDayReport {
  final DateTime date;
  final int present;
  final int absent;
  final int late;

  const AttendanceDayReport({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
  });

  factory AttendanceDayReport.fromJson(Map<String, dynamic> json) {
    return AttendanceDayReport(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceReportSummary {
  final int presentDays;
  final int absentDays;
  final int totalDays;

  const AttendanceReportSummary({
    required this.presentDays,
    required this.absentDays,
    required this.totalDays,
  });

  factory AttendanceReportSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceReportSummary(
      presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
      absentDays: (json['absent_days'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceReportModel {
  final List<AttendanceDayReport> calendar;
  final AttendanceReportSummary summary;

  const AttendanceReportModel({
    required this.calendar,
    required this.summary,
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    final calList = json['calendar'];
    final calendar = calList is List
        ? calList
            .map((e) => AttendanceDayReport.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <AttendanceDayReport>[];

    return AttendanceReportModel(
      calendar: calendar,
      summary: json['summary'] != null
          ? AttendanceReportSummary.fromJson(
              json['summary'] as Map<String, dynamic>)
          : const AttendanceReportSummary(
              presentDays: 0, absentDays: 0, totalDays: 0),
    );
  }
}

/// Used in the attendance marking screen — student entry with a mutable status
class AttendanceEntry {
  final String studentId;
  final String studentName;
  final int? rollNo;
  String status;
  String? remarks;

  AttendanceEntry({
    required this.studentId,
    required this.studentName,
    this.rollNo,
    this.status = 'PRESENT',
    this.remarks,
  });
}
