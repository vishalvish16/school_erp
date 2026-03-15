// =============================================================================
// FILE: lib/features/parent/data/parent_notices_provider.dart
// PURPOSE: Notices provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/notice_summary_model.dart';

final parentNoticesPageProvider = FutureProvider.family<
    ({List<NoticeSummaryModel> notices, Map<String, dynamic> pagination}),
    ({int page, int limit})>((ref, params) async {
  final result = await ref.read(parentServiceProvider).getNotices(
        page: params.page,
        limit: params.limit,
      );
  final noticesList = result['notices'];
  final notices = noticesList is List
      ? noticesList
          .map((e) => e is NoticeSummaryModel
              ? e
              : NoticeSummaryModel.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
          .toList()
      : <NoticeSummaryModel>[];
  return (
    notices: notices,
    pagination: result['pagination'] is Map
        ? Map<String, dynamic>.from(result['pagination'] as Map)
        : <String, dynamic>{},
  );
});
