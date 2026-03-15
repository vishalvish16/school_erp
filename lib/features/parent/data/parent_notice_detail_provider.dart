// =============================================================================
// FILE: lib/features/parent/data/parent_notice_detail_provider.dart
// PURPOSE: Notice detail provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/notice_detail_model.dart';

final parentNoticeDetailProvider =
    FutureProvider.family<NoticeDetailModel?, String>((ref, noticeId) async {
  return ref.read(parentServiceProvider).getNoticeById(noticeId);
});
