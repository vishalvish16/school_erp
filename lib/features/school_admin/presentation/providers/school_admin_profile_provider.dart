// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_profile_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';

final schoolAdminProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(schoolAdminServiceProvider).getProfile();
});
