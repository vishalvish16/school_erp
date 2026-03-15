// =============================================================================
// FILE: lib/features/parent/data/parent_dashboard_provider.dart
// PURPOSE: Dashboard provider for the Parent Portal — aggregates from APIs.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/notice_summary_model.dart';
import '../../../models/parent/parent_dashboard_model.dart';

final parentDashboardProvider =
    FutureProvider<ParentDashboardModel>((ref) async {
  final service = ref.read(parentServiceProvider);

  final children = await service.getChildren();
  final noticesResult = await service.getNotices(page: 1, limit: 5);
  final noticesList = noticesResult['notices'];
  final notices = noticesList is List
      ? noticesList
          .map((e) => e is NoticeSummaryModel
              ? e
              : NoticeSummaryModel.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
          .toList()
      : <NoticeSummaryModel>[];

  return ParentDashboardModel.aggregate(
    children: children,
    notices: notices,
    todaysPresent: 0,
    todaysAbsent: 0,
  );
});
