// =============================================================================
// FILE: lib/features/parent/data/parent_child_fees_provider.dart
// PURPOSE: Child fees provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';

final parentChildFeesProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({String studentId, String? academicYear})>((ref, params) async {
  return ref.read(parentServiceProvider).getChildFees(
        params.studentId,
        academicYear: params.academicYear,
      );
});
