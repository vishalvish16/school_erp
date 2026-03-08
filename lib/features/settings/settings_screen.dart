import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Biometric Settings Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    iconColor: const Color(0xFF6366F1),
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
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF6366F1),
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildSettingTile(
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Auto-Lock Session',
                    subtitle: 'Securely lock session after 30 minutes of inactivity',
                    trailing: Switch(
                      value: state.isAutoLockEnabled,
                      onChanged: (val) => ref
                          .read(settingsProvider.notifier)
                          .toggleAutoLock(val),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Hardware & Infrastructure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    iconColor: const Color(0xFFF59E0B),
                    title: 'System Endpoint',
                    subtitle: '192.168.1.14 (Active Node)',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildSettingTile(
                    icon: Icons.cloud_sync_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Node Sync Strategy',
                    subtitle: 'Real-time (High Priority)',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }
}
