// =============================================================================
// FILE: lib/features/parent/data/parent_child_detail_provider.dart
// PURPOSE: Child detail provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/child_detail_model.dart';

final parentChildDetailProvider =
    FutureProvider.family<ChildDetailModel?, String>((ref, studentId) async {
  return ref.read(parentServiceProvider).getChildById(studentId);
});
