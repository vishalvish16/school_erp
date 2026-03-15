// =============================================================================
// FILE: lib/models/student/student_dashboard_model.dart
// PURPOSE: Dashboard model for the Student portal.
// =============================================================================

import 'student_fee_models.dart';
import 'student_timetable_model.dart';

class StudentDashboardModel {
  final TodayAttendance? todayAttendance;
  final int presentDaysThisMonth;
  final double totalFeePaidThisYear;
  final List<FeeDueItem> upcomingDues;
  final List<TimetableSlot> todayTimetable;
  final List<NoticeSummary> recentNotices;
  final int unreadNoticesCount;

  const StudentDashboardModel({
    this.todayAttendance,
    this.presentDaysThisMonth = 0,
    this.totalFeePaidThisYear = 0.0,
    this.upcomingDues = const [],
    this.todayTimetable = const [],
    this.recentNotices = const [],
    this.unreadNoticesCount = 0,
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    final todayRaw = json['today_attendance'];
    final todayAttendance = todayRaw != null && todayRaw is Map<String, dynamic>
        ? TodayAttendance.fromJson(todayRaw)
        : null;

    final duesRaw = json['upcoming_dues'];
    final upcomingDues = duesRaw is List
        ? duesRaw
            .map((e) => FeeDueItem.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <FeeDueItem>[];

    final timetableRaw = json['today_timetable'];
    final todayTimetable = timetableRaw is List
        ? timetableRaw
            .map((e) => TimetableSlot.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <TimetableSlot>[];

    final noticesRaw = json['recent_notices'];
    final recentNotices = noticesRaw is List
        ? noticesRaw
            .map((e) => NoticeSummary.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <NoticeSummary>[];

    return StudentDashboardModel(
      todayAttendance: todayAttendance,
      presentDaysThisMonth:
          (json['present_days_this_month'] as num?)?.toInt() ?? 0,
      totalFeePaidThisYear:
          (json['total_fee_paid_this_year'] as num?)?.toDouble() ?? 0.0,
      upcomingDues: upcomingDues,
      todayTimetable: todayTimetable,
      recentNotices: recentNotices,
      unreadNoticesCount:
          (json['unread_notices_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TodayAttendance {
  final String status;

  const TodayAttendance({required this.status});

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      status: json['status'] as String? ?? 'UNKNOWN',
    );
  }
}

class NoticeSummary {
  final String id;
  final String title;
  final String? publishedAt;

  const NoticeSummary({
    required this.id,
    required this.title,
    this.publishedAt,
  });

  factory NoticeSummary.fromJson(Map<String, dynamic> json) {
    return NoticeSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      publishedAt: json['published_at'] as String?,
    );
  }
}
