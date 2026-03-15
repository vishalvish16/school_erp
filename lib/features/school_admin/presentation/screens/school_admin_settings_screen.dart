// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_settings_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

void _showComingSoon(BuildContext context, String setting) {
  AppSnackbar.info(context, '$setting — coming soon');
}

class SchoolAdminSettingsScreen extends StatelessWidget {
  const SchoolAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.settings,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXl,
            Card(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications,
                    title: AppStrings.notificationPreferences,
                    subtitle: AppStrings.notifPrefSubtitle,
                    onTap: () => _showComingSoon(context, AppStrings.notificationPreferences),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.language,
                    title: AppStrings.language,
                    subtitle: AppStrings.englishDefault,
                    onTap: () => _showComingSoon(context, AppStrings.language),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.dark_mode,
                    title: AppStrings.theme,
                    subtitle: AppStrings.systemDefault,
                    onTap: () => _showComingSoon(context, AppStrings.theme),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.school,
                    title: AppStrings.academicYearSetting,
                    subtitle: AppStrings.currentAcademicYear,
                    onTap: () => _showComingSoon(context, AppStrings.academicYearSetting),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.backup,
                    title: AppStrings.dataExport,
                    subtitle: AppStrings.dataExportSubtitle,
                    onTap: () => _showComingSoon(context, AppStrings.dataExport),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapLg,
            Center(
              child: Text(
                AppStrings.additionalSettingsComingSoon,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      mouseCursor: SystemMouseCursors.click,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(icon, color: _accent, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
