// =============================================================================
// FILE: lib/models/student/student_timetable_model.dart
// PURPOSE: Timetable model for the Student portal.
// =============================================================================

class StudentTimetableModel {
  final List<TimetableSlot> slots;

  const StudentTimetableModel({this.slots = const []});

  factory StudentTimetableModel.fromJson(Map<String, dynamic> json) {
    final slotsRaw = json['slots'];
    final slots = slotsRaw is List
        ? slotsRaw
            .map((e) => TimetableSlot.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <TimetableSlot>[];

    return StudentTimetableModel(slots: slots);
  }
}

class TimetableSlot {
  final int dayOfWeek;
  final int periodNo;
  final String subject;
  final String startTime;
  final String endTime;
  final String? room;
  final String? staffName;

  const TimetableSlot({
    required this.dayOfWeek,
    required this.periodNo,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.room,
    this.staffName,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
      periodNo: (json['period_no'] as num?)?.toInt() ?? 0,
      subject: json['subject'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      room: json['room'] as String?,
      staffName: json['staff_name'] as String?,
    );
  }
}
