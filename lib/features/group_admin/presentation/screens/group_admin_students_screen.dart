// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_students_screen.dart
// PURPOSE: Cross-school student/user enrollment breakdown for group admin.
//          Shows per-school counts of students, teachers, total users.
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _studentStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(groupAdminServiceProvider).getStudentStats();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupAdminStudentsScreen extends ConsumerStatefulWidget {
  const GroupAdminStudentsScreen({super.key});

  @override
  ConsumerState<GroupAdminStudentsScreen> createState() =>
      _GroupAdminStudentsScreenState();
}

class _GroupAdminStudentsScreenState
    extends ConsumerState<GroupAdminStudentsScreen> {
  String _searchQuery = '';

  static const Color _accent = AppColors.warning300;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(_studentStatsProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_studentStatsProvider),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      'Students & Staff',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGapXs,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Text(
                  'Enrollment and staff breakdown across all campuses',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              AppSpacing.vGapXl,

              // Content
              Expanded(
                child: asyncData.when(
                  loading: () => Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: const ShimmerListLoadingWidget(itemCount: 8),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: _ErrorCard(
                        error:
                            err.toString().replaceAll('Exception: ', ''),
                        onRetry: () =>
                            ref.invalidate(_studentStatsProvider),
                      ),
                    ),
                  ),
                  data: (data) => _buildContent(
                      context, data, isNarrow, isWide, padding),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data,
      bool isNarrow, bool isWide, double padding) {
    final totals = data['totals'] as Map<String, dynamic>? ?? {};
    final allSchools =
        (data['schools'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final schools = _searchQuery.isEmpty
        ? allSchools
        : allSchools.where((s) {
            final q = _searchQuery.toLowerCase();
            final name = (s['name'] as String? ?? '').toLowerCase();
            final code = (s['code'] as String? ?? '').toLowerCase();
            final city = (s['city'] as String? ?? '').toLowerCase();
            return name.contains(q) || code.contains(q) || city.contains(q);
          }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context, totals, isNarrow),
          AppSpacing.vGapXl,

          if (isWide)
            _buildDesktopTable(context, schools)
          else
            _buildMobileList(context, schools),

          if (schools.isEmpty) _buildEmptyState(context),

          AppSpacing.vGapXl,
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, Map<String, dynamic> totals, bool isNarrow) {
    final cards = [
      _StatCard(
        icon: Icons.school,
        value: '${totals['schools'] ?? 0}',
        label: 'Schools',
        color: AppColors.secondary500,
      ),
      _StatCard(
        icon: Icons.people,
        value: '${totals['users'] ?? 0}',
        label: 'Total Users',
        color: AppColors.success500,
      ),
      _StatCard(
        icon: Icons.person_outline,
        value: '${totals['students'] ?? 0}',
        label: 'Est. Students',
        color: Colors.teal,
      ),
      _StatCard(
        icon: Icons.badge_outlined,
        value: '${totals['teachers'] ?? 0}',
        label: 'Teachers',
        color: _accent,
      ),
    ];

    if (!isNarrow) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }
    return Column(children: [
      Row(children: [
        Expanded(child: cards[0]),
        AppSpacing.hGapMd,
        Expanded(child: cards[1]),
      ]),
      AppSpacing.vGapMd,
      Row(children: [
        Expanded(child: cards[2]),
        AppSpacing.hGapMd,
        Expanded(child: cards[3]),
      ]),
    ]);
  }

  Widget _buildDesktopTable(
      BuildContext context, List<Map<String, dynamic>> schools) {
    return Center(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: ListTableView(
                showSrNo: false,
                columns: const [
                  'School',
                  'Code',
                  'City',
                  'Status',
                  'Teachers',
                  'Students',
                  'Total',
                ],
                columnWidths: const [200, 80, 80, 80, 80, 80, 80],
                itemCount: schools.length,
                rowBuilder: (index) {
                  final s = schools[index];
                  final isActive = s['status'] == 'ACTIVE';
                  return DataRow(cells: [
                    DataCell(Text(s['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(s['code'] ?? '',
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(s['city'] ?? '—',
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success500 : AppColors.error500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(s['status'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? AppColors.success500 : AppColors.error500,
                            fontWeight: FontWeight.w500,
                          )),
                    ])),
                    DataCell(Text('${s['totalTeachers'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text('${s['totalStudents'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text('${s['totalUsers'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(
      BuildContext context, List<Map<String, dynamic>> schools) {
    return Column(
      children: schools.map((s) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: AppRadius.brLg,
            onTap: () {},
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(s['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Text(s['code'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.neutral400)),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  Row(children: [
                    _InfoChip(
                        label: 'Teachers',
                        value: '${s['totalTeachers'] ?? 0}'),
                    AppSpacing.hGapSm,
                    _InfoChip(
                        label: 'Students',
                        value: '${s['totalStudents'] ?? 0}'),
                    AppSpacing.hGapSm,
                    _InfoChip(
                        label: 'Total', value: '${s['totalUsers'] ?? 0}'),
                  ]),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: cs.outline),
            AppSpacing.vGapLg,
            Text(
              _searchQuery.isNotEmpty
                  ? "No results for '$_searchQuery'"
                  : 'No schools found in your group.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              AppSpacing.vGapMd,
              TextButton.icon(
                onPressed: () => setState(() => _searchQuery = ''),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text(AppStrings.clearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: AppRadius.brSm,
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.neutral400)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(AppStrings.couldNotLoadStudents,
                style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vGapSm,
            Text(error,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
