// =============================================================================
// FILE: lib/features/parent/data/parent_child_attendance_provider.dart
// PURPOSE: Child attendance provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/attendance_entry_model.dart';

final parentChildAttendanceProvider = FutureProvider.family<
    List<AttendanceEntryModel>,
    ({String studentId, String? month})>((ref, params) async {
  return ref.read(parentServiceProvider).getChildAttendance(
        params.studentId,
        month: params.month,
        limit: 31,
      );
});
