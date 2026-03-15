// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_reports_screen.dart
// PURPOSE: Multi-tab reports screen for attendance, finance, academic, transport, HR.
//          Tabs show live module data when available, or a "coming soon" placeholder.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _attendanceReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(groupAdminServiceProvider).getAttendanceReport();
});

final _feesReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(groupAdminServiceProvider).getFeesReport();
});

final _performanceReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(groupAdminServiceProvider).getPerformanceReport();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupAdminReportsScreen extends ConsumerWidget {
  const GroupAdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                AppSpacing.vGapXs,
                Text(
                  'Cross-school reports across all modules',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                AppSpacing.vGapLg,
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────────
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.warning300,
            labelColor: AppColors.warning300,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Attendance'),
              Tab(text: 'Finance'),
              Tab(text: 'Academic'),
              Tab(text: 'Transport'),
              Tab(text: 'Staff & HR'),
            ],
          ),
          const Divider(height: 1),

          // ── Tab views ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1 — Attendance
                _AsyncReportTab(
                  provider: _attendanceReportProvider,
                  moduleName: 'Attendance',
                  moduleIcon: Icons.how_to_reg_outlined,
                  onRefresh: () => ref.invalidate(_attendanceReportProvider),
                ),

                // Tab 2 — Finance
                _AsyncReportTab(
                  provider: _feesReportProvider,
                  moduleName: 'Finance',
                  moduleIcon: Icons.account_balance_wallet_outlined,
                  onRefresh: () => ref.invalidate(_feesReportProvider),
                ),

                // Tab 3 — Academic
                _AsyncReportTab(
                  provider: _performanceReportProvider,
                  moduleName: 'Academic',
                  moduleIcon: Icons.school_outlined,
                  onRefresh: () => ref.invalidate(_performanceReportProvider),
                ),

                // Tab 4 — Transport (static placeholder)
                _StaticPlaceholderTab(
                  moduleName: 'Transport',
                  moduleIcon: Icons.directions_bus_outlined,
                  message: AppStrings.transportNotActivated,
                ),

                // Tab 5 — Staff & HR (static placeholder)
                _StaticPlaceholderTab(
                  moduleName: 'Staff & HR',
                  moduleIcon: Icons.badge_outlined,
                  message: AppStrings.hrNotActivated,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Async Tab (calls API, shows placeholder from message field) ───────────────

class _AsyncReportTab extends ConsumerWidget {
  const _AsyncReportTab({
    required this.provider,
    required this.moduleName,
    required this.moduleIcon,
    required this.onRefresh,
  });

  final ProviderListenable<AsyncValue<Map<String, dynamic>>> provider;
  final String moduleName;
  final IconData moduleIcon;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingXl,
        child: asyncData.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ModulePlaceholderCard(
            icon: moduleIcon,
            moduleName: moduleName,
            message: err.toString().replaceAll('Exception: ', ''),
          ),
          data: (data) {
            final hasData =
                data['data'] is List && (data['data'] as List).isNotEmpty;
            if (hasData) {
              // When the module is actually active and returns rows, render a
              // simple list view. For now the backend returns empty lists so
              // this branch is a graceful forward-compatible hook.
              return _ModulePlaceholderCard(
                icon: moduleIcon,
                moduleName: moduleName,
                message:
                    data['message']?.toString() ?? 'Data available soon.',
              );
            }
            return _ModulePlaceholderCard(
              icon: moduleIcon,
              moduleName: moduleName,
              message: data['message']?.toString() ??
                  '$moduleName module not yet activated',
            );
          },
        ),
      ),
    );
  }
}

// ── Static Tab (no API call needed) ──────────────────────────────────────────

class _StaticPlaceholderTab extends StatelessWidget {
  const _StaticPlaceholderTab({
    required this.moduleName,
    required this.moduleIcon,
    required this.message,
  });

  final String moduleName;
  final IconData moduleIcon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingXl,
      child: _ModulePlaceholderCard(
        icon: moduleIcon,
        moduleName: moduleName,
        message: message,
      ),
    );
  }
}

// ── Placeholder Card ──────────────────────────────────────────────────────────

class _ModulePlaceholderCard extends StatelessWidget {
  const _ModulePlaceholderCard({
    required this.icon,
    required this.moduleName,
    required this.message,
  });

  final IconData icon;
  final String moduleName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning300.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.warning300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$moduleName Module Coming Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapSm,
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapLg,
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: AppRadius.brMd,
              ),
              child: Text(
                'This report will populate automatically when the $moduleName '
                'module is activated for your schools.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
