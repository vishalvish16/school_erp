// =============================================================================
// FILE: lib/models/parent/attendance_entry_model.dart
// PURPOSE: Attendance entry model for Parent Portal child attendance.
// =============================================================================

class AttendanceEntryModel {
  final DateTime date;
  final String status; // PRESENT, ABSENT, LATE, HOLIDAY
  final String? remarks;

  const AttendanceEntryModel({
    required this.date,
    required this.status,
    this.remarks,
  });

  factory AttendanceEntryModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    return AttendanceEntryModel(
      date: dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now(),
      status: json['status'] as String? ?? 'ABSENT',
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'status': status,
        'remarks': remarks,
      };
}
