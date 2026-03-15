// =============================================================================
// FILE: lib/models/parent/parent_dashboard_model.dart
// PURPOSE: Parent dashboard model — aggregated or from backend.
// =============================================================================

import 'child_summary_model.dart';
import 'notice_summary_model.dart';

class ParentDashboardModel {
  final int childrenCount;
  final int todaysPresent;
  final int todaysAbsent;
  final List<NoticeSummaryModel> recentNotices;
  final String? feeDuesMessage;

  const ParentDashboardModel({
    required this.childrenCount,
    this.todaysPresent = 0,
    this.todaysAbsent = 0,
    this.recentNotices = const [],
    this.feeDuesMessage,
  });

  factory ParentDashboardModel.fromJson(Map<String, dynamic> json) {
    final noticesRaw = json['recentNotices'] ?? json['recent_notices'] ?? json['notices'];
    List<NoticeSummaryModel> notices = [];
    if (noticesRaw is List) {
      notices = noticesRaw
          .map((e) => NoticeSummaryModel.fromJson(
                e is Map<String, dynamic> ? e : {},
              ))
          .toList();
    }

    return ParentDashboardModel(
      childrenCount: (json['childrenCount'] ?? json['children_count']) as int? ?? 0,
      todaysPresent: (json['todaysPresent'] ?? json['todays_present']) as int? ?? 0,
      todaysAbsent: (json['todaysAbsent'] ?? json['todays_absent']) as int? ?? 0,
      recentNotices: notices,
      feeDuesMessage: json['feeDuesMessage'] as String? ?? json['fee_dues_message'] as String?,
    );
  }

  /// Build from aggregated API responses (when no dashboard endpoint exists)
  factory ParentDashboardModel.aggregate({
    required List<ChildSummaryModel> children,
    required List<NoticeSummaryModel> notices,
    int todaysPresent = 0,
    int todaysAbsent = 0,
  }) {
    return ParentDashboardModel(
      childrenCount: children.length,
      todaysPresent: todaysPresent,
      todaysAbsent: todaysAbsent,
      recentNotices: notices,
    );
  }
}
