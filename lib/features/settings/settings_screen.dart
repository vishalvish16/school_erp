import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.neutral800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral800,
              ),
            ),
            AppSpacing.vGapLg,

            // Biometric Settings Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.brXl2,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.primary500,
                    title: 'Biometric Login',
                    subtitle: state.isBiometricSupported
                        ? 'Use fingerprint or face ID to log in'
                        : 'Not supported on this device',
                    trailing: Switch(
                      value: state.isBiometricEnabled,
                      onChanged: state.isBiometricSupported
                          ? (val) => ref
                                .read(settingsProvider.notifier)
                                .toggleBiometric(val)
                          : null,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary500,
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildSettingTile(
                    icon: Icons.security_rounded,
                    iconColor: AppColors.secondary500,
                    title: 'Auto-Lock Session',
                    subtitle: 'Securely lock session after 30 minutes of inactivity',
                    trailing: Switch(
                      value: state.isAutoLockEnabled,
                      onChanged: (val) => ref
                          .read(settingsProvider.notifier)
                          .toggleAutoLock(val),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.secondary500,
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.vGapXl2,
            const Text(
              'Hardware & Infrastructure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral800,
              ),
            ),
            AppSpacing.vGapLg,

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.brXl2,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.api_rounded,
                    iconColor: AppColors.warning500,
                    title: 'System Endpoint',
                    subtitle: '192.168.1.14 (Active Node)',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.neutral400,
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildSettingTile(
                    icon: Icons.cloud_sync_rounded,
                    iconColor: AppColors.success500,
                    title: 'Node Sync Strategy',
                    subtitle: 'Real-time (High Priority)',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            Center(
              child: Text(
                'Enterprise AI OS • v1.0.0 (Stable)',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: AppRadius.brLg,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.neutral800,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.neutral500, fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }
}
