// =============================================================================
// FILE: lib/features/group_admin/presentation/providers/group_admin_profile_provider.dart
// PURPOSE: Shared profile provider for Group Admin — used by profile screen and shell header.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../models/group_admin/group_admin_models.dart';

/// Shared profile provider — keeps profile cached while in group admin shell.
/// Invalidate after profile update to refresh avatar in header and profile page.
final groupAdminProfileProvider =
    FutureProvider.autoDispose<GroupAdminProfileModel>((ref) {
  return ref.read(groupAdminServiceProvider).getProfile();
});
