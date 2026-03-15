// =============================================================================
// FILE: lib/models/school_admin/staff_timetable_model.dart
// PURPOSE: Staff timetable model for School Admin portal.
// =============================================================================

class StaffSchedulePeriod {
  final int periodNo;
  final String subject;
  final String className;
  final String sectionName;
  final String startTime;
  final String endTime;
  final String? room;

  const StaffSchedulePeriod({
    required this.periodNo,
    required this.subject,
    required this.className,
    required this.sectionName,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory StaffSchedulePeriod.fromJson(Map<String, dynamic> json) {
    // Backend returns camelCase from the service layer
    return StaffSchedulePeriod(
      periodNo: (json['periodNo'] ?? json['period_no']) != null
          ? ((json['periodNo'] ?? json['period_no']) as num).toInt()
          : 0,
      subject: json['subject'] as String? ?? '',
      className: (json['className'] ?? json['class_name']) as String? ?? '',
      sectionName:
          (json['sectionName'] ?? json['section_name']) as String? ?? '',
      startTime: (json['startTime'] ?? json['start_time']) as String? ?? '',
      endTime: (json['endTime'] ?? json['end_time']) as String? ?? '',
      room: json['room'] as String?,
    );
  }

  String get classSectionLabel =>
      sectionName.isNotEmpty ? '$className - $sectionName' : className;
}

class StaffScheduleDay {
  final int dayOfWeek;
  final String dayName;
  final List<StaffSchedulePeriod> periods;

  const StaffScheduleDay({
    required this.dayOfWeek,
    required this.dayName,
    required this.periods,
  });

  factory StaffScheduleDay.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['periods'] as List? ?? [];
    return StaffScheduleDay(
      // Backend returns camelCase from the service layer
      dayOfWeek: (json['dayOfWeek'] ?? json['day_of_week']) != null
          ? ((json['dayOfWeek'] ?? json['day_of_week']) as num).toInt()
          : 0,
      dayName: (json['dayName'] ?? json['day_name']) as String? ?? '',
      periods: rawPeriods
          .map((p) => StaffSchedulePeriod.fromJson(
                p is Map<String, dynamic> ? p : {},
              ))
          .toList(),
    );
  }
}

class StaffTimetableModel {
  final String staffId;
  final String staffName;
  final String academicYear;
  final List<StaffScheduleDay> schedule;

  const StaffTimetableModel({
    required this.staffId,
    required this.staffName,
    required this.academicYear,
    required this.schedule,
  });

  factory StaffTimetableModel.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'] as List? ?? [];
    return StaffTimetableModel(
      // Backend returns camelCase from the service layer
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      staffName: (json['staffName'] ?? json['staff_name']) as String? ?? '',
      academicYear:
          (json['academicYear'] ?? json['academic_year']) as String? ?? '',
      schedule: rawSchedule
          .map((d) => StaffScheduleDay.fromJson(
                d is Map<String, dynamic> ? d : {},
              ))
          .toList(),
    );
  }

  /// Returns all unique period numbers across all days — for building the grid.
  List<int> get allPeriodNumbers {
    final nums = <int>{};
    for (final day in schedule) {
      for (final period in day.periods) {
        nums.add(period.periodNo);
      }
    }
    final sorted = nums.toList()..sort();
    return sorted;
  }

  /// Finds the period for a specific day and period number (null = free period).
  StaffSchedulePeriod? periodAt(int dayOfWeek, int periodNo) {
    final day = schedule.where((d) => d.dayOfWeek == dayOfWeek).firstOrNull;
    if (day == null) return null;
    return day.periods.where((p) => p.periodNo == periodNo).firstOrNull;
  }
}
