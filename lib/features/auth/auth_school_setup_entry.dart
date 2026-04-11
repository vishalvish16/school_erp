// =============================================================================
// FILE: lib/features/auth/auth_school_setup_entry.dart
// PURPOSE: Hidden entry (logo long-press) → clear local role prefs & go to school setup
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/local_storage_service.dart';
import 'auth_guard_provider.dart';

/// Long-press the auth header logo to return to the role / school selection screen.
Future<void> openSchoolSetupRolePicker(BuildContext context) async {
  final path = GoRouterState.of(context).uri.path;
  if (path == '/school-setup') return;

  ProviderContainer? container;
  try {
    container = ProviderScope.containerOf(context, listen: false);
  } catch (_) {
    return;
  }

  await LocalStorageService().resetToSchoolSetupEntry();
  if (!context.mounted) return;
  try {
    await container.read(authGuardProvider.notifier).clearSession();
  } catch (_) {}
  if (!context.mounted) return;
  context.go('/school-setup');
}
