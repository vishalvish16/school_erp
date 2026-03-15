// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_profile_screen.dart
// PURPOSE: Super Admin profile page with sign out
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/auth_guard_provider.dart';
import '../../../../widgets/super_admin/logout_button_widget.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SuperAdminProfileScreen extends ConsumerWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final scheme = Theme.of(context).colorScheme;
    final initials = _getInitials(authState.userEmail ?? 'SA');
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.accountProfile,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXl,

              Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppSpacing.vGapLg,
                      Text(
                        authState.userEmail ?? AppStrings.superAdmin,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.vGapXs,
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: AppRadius.brXs,
                        ),
                        child: Text(
                          AppStrings.superAdmin,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGapXl,

              OutlinedButton.icon(
                onPressed: () => _showLogoutConfirmation(context, ref),
                icon: Icon(Icons.logout, size: 18, color: scheme.error),
                label: Text(
                  AppStrings.signOut,
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
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
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmSuperAdmin,
      confirmLabel: AppStrings.signOut,
    );

    if (!confirmed || !context.mounted) return;

    await SuperAdminLogoutButton.performLogout(context, ref);
  }
}

