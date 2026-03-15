// =============================================================================
// FILE: lib/features/parent/data/parent_children_provider.dart
// PURPOSE: Children list provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/child_summary_model.dart';

final parentChildrenProvider =
    FutureProvider<List<ChildSummaryModel>>((ref) async {
  return ref.read(parentServiceProvider).getChildren();
});
