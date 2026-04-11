// =============================================================================
// FILE: lib/models/parent/timetable_slot_model.dart
// PURPOSE: Timetable slot model for Parent Portal child timetable tab.
// =============================================================================

class TimetableSlotModel {
  final String id;
  final String day;
  final int period;
  final String subject;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherName;

  const TimetableSlotModel({
    required this.id,
    required this.day,
    required this.period,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherName,
  });

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) =>
      TimetableSlotModel(
        id: json['id'] as String? ?? '',
        day: json['day'] as String? ?? '',
        period: json['period'] as int? ?? 0,
        subject: json['subject'] as String? ?? 'N/A',
        startTime: json['startTime'] as String? ?? json['start_time'] as String? ?? '',
        endTime: json['endTime'] as String? ?? json['end_time'] as String? ?? '',
        room: json['room'] as String?,
        teacherName: json['teacherName'] as String? ?? json['teacher_name'] as String?,
      );
}
