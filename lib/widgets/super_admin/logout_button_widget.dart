// =============================================================================
// FILE: lib/widgets/super_admin/logout_button_widget.dart
// PURPOSE: Super Admin logout — avatar button with confirmation dialog
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../features/auth/auth_guard_provider.dart';

/// Avatar button that shows confirmation dialog and performs logout.
/// Reuse in TopBar (web) and Drawer (mobile).
class SuperAdminLogoutButton extends ConsumerWidget {
  const SuperAdminLogoutButton({
    super.key,
    this.size = 36,
    this.showLabel = false,
  });

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authGuardProvider);
    final initials = _getInitials(authState.userEmail ?? 'SA');

    if (showLabel) {
      return ListTile(
        leading: CircleAvatar(
          radius: size / 2,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.4,
            ),
          ),
        ),
        title: const Text('Sign Out'),
        onTap: () => _showLogoutConfirmation(context, ref),
      );
    }

    return IconButton(
      onPressed: () => _showLogoutConfirmation(context, ref),
      icon: CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.4,
          ),
        ),
      ),
      tooltip: 'Sign Out',
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'SA';
    final parts = email.split('@').first.split(RegExp(r'[.\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'SA';
  }

  Future<void> _showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Sign Out?',
      message: 'You will be logged out of the Super Admin portal.',
      confirmLabel: 'Sign Out',
    );

    if (!confirmed || !context.mounted) return;

    await performLogout(context, ref);
  }

  /// Static method to perform logout. Use from profile screen or elsewhere.
  static Future<void> performLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).logout();
    } catch (_) {
      // Never block logout due to API failure — clear local state anyway
    }

    await ref.read(authGuardProvider.notifier).clearSession();
    await _clearAllSessionData();

    if (!context.mounted) return;
    context.go('/login');
  }

  static Future<void> _clearAllSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    const keys = [
      'access_token',
      'refresh_token',
      'session_token',
      'portal_type',
      'user_data',
      'school_data',
      'group_data',
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
