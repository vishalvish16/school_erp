// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_profile_screen.dart
// PURPOSE: Group Admin profile — read-only display of user + group info.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/api_config.dart';
import '../../../../features/auth/auth_guard_provider.dart';
import '../../../../models/group_admin/group_admin_models.dart';
import '../providers/group_admin_profile_provider.dart';
import '../../../../design_system/design_system.dart';

import '../../../../core/constants/app_strings.dart';

class GroupAdminProfileScreen extends ConsumerWidget {
  const GroupAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(groupAdminProfileProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupAdminProfileProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: asyncProfile.when(
              loading: () => Padding(
                padding: EdgeInsets.all(48),
                child: AppLoaderScreen(),
              ),
              error: (err, _) => Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error),
                    AppSpacing.vGapLg,
                    Text(
                      err.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vGapLg,
                    FilledButton(
                      onPressed: () => ref.invalidate(groupAdminProfileProvider),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
              data: (profile) => _ProfileContent(profile: profile),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final GroupAdminProfileModel profile;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Profile',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/group-admin/profile/edit'),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text(AppStrings.edit),
            ),
          ],
        ),
        AppSpacing.vGapXl,

        // Avatar + name card
        Card(
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              children: [
                _ProfileAvatar(
                  avatarUrl: profile.avatarUrl,
                  initials: profile.initials,
                  radius: 40,
                ),
                AppSpacing.vGapLg,
                Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName
                      : profile.email,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapXs,
                Text(
                  profile.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (profile.phone != null) ...[
                  AppSpacing.vGapXs,
                  Text(
                    profile.phone!,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        AppSpacing.vGapMd,

        // Group info card
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 18, color: scheme.primary),
                    AppSpacing.hGapSm,
                    Text(
                      'Group',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,
                const Divider(height: 1),
                AppSpacing.vGapMd,
                _ProfileRow(label: 'Group Name', value: profile.groupName),
                if (profile.groupSlug != null)
                  _ProfileRow(
                      label: 'Slug', value: '@${profile.groupSlug}'),
                if (profile.groupCountry != null)
                  _ProfileRow(
                      label: 'Country', value: profile.groupCountry),
              ],
            ),
          ),
        ),
        AppSpacing.vGapMd,

        // Activity card
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_outlined,
                        size: 18, color: scheme.primary),
                    AppSpacing.hGapSm,
                    Text(
                      'Activity',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,
                const Divider(height: 1),
                AppSpacing.vGapMd,
                _ProfileRow(
                  label: 'Last Login',
                  value: profile.lastLogin != null
                      ? _formatDate(profile.lastLogin!)
                      : 'Never',
                ),
              ],
            ),
          ),
        ),
        AppSpacing.vGapXl,

        // Action buttons
        FilledButton.icon(
          onPressed: () => context.go('/group-admin/change-password'),
          icon: const Icon(Icons.lock_reset, size: 18),
          label: const Text(AppStrings.changePassword),
        ),
        AppSpacing.vGapMd,
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authGuardProvider.notifier).clearSession();
            if (context.mounted) context.go('/login/group');
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text(AppStrings.signOut),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
                color: Theme.of(context).colorScheme.error),
          ),
        ),
        AppSpacing.vGapXl,
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.initials,
    this.radius = 40,
  });

  final String? avatarUrl;
  final String initials;
  final double radius;

  String get _fullUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return '';
    return avatarUrl!.startsWith('http')
        ? avatarUrl!
        : '${ApiConfig.baseUrl}$avatarUrl';
  }

  @override
  Widget build(BuildContext context) {
    if (_fullUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.warning300,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        _fullUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.warning300,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
