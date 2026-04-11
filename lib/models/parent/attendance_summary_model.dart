// =============================================================================
// FILE: lib/models/parent/attendance_summary_model.dart
// PURPOSE: Attendance summary model for Parent Portal child detail overview.
// =============================================================================

class AttendanceSummaryModel {
  final String month;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int total;

  const AttendanceSummaryModel({
    required this.month,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.total,
  });

  double get attendancePercent => total == 0 ? 0 : (present / total * 100);

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) =>
      AttendanceSummaryModel(
        month: json['month'] as String? ?? '',
        present: json['present'] as int? ?? 0,
        absent: json['absent'] as int? ?? 0,
        late: json['late'] as int? ?? 0,
        halfDay: json['halfDay'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );
}
