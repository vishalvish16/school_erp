// =============================================================================
// FILE: lib/models/school_admin/student_report_model.dart
// PURPOSE: Models for the student full report endpoint response.
// =============================================================================

import 'student_model.dart';

class StudentReportModel {
  final StudentModel student;
  final StudentReportStats stats;

  const StudentReportModel({
    required this.student,
    required this.stats,
  });

  factory StudentReportModel.fromJson(Map<String, dynamic> json) {
    return StudentReportModel(
      student: StudentModel.fromJson(
        json['student'] as Map<String, dynamic>? ?? {},
      ),
      stats: StudentReportStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class StudentReportStats {
  final AttendanceStat attendanceThisMonth;
  final double totalFeesDue;
  final double totalFeesPaid;
  final int noticesSentCount;

  const StudentReportStats({
    required this.attendanceThisMonth,
    required this.totalFeesDue,
    required this.totalFeesPaid,
    required this.noticesSentCount,
  });

  factory StudentReportStats.fromJson(Map<String, dynamic> json) {
    return StudentReportStats(
      attendanceThisMonth: AttendanceStat.fromJson(
        json['attendanceThisMonth'] as Map<String, dynamic>? ?? {},
      ),
      totalFeesDue: (json['totalFeesDue'] as num?)?.toDouble() ?? 0.0,
      totalFeesPaid: (json['totalFeesPaid'] as num?)?.toDouble() ?? 0.0,
      noticesSentCount: (json['noticesSentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceStat {
  final int present;
  final int absent;
  final int late;
  final int total;
  final double percentage;

  const AttendanceStat({
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    required this.percentage,
  });

  factory AttendanceStat.fromJson(Map<String, dynamic> json) {
    return AttendanceStat(
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
