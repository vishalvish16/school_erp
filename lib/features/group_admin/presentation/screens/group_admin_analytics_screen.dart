// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_analytics_screen.dart
// PURPOSE: Side-by-side school comparison table for all schools in the group.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/group_admin/group_admin_models.dart';

import '../../../../shared/widgets/list_table_view.dart';
import '../../../../core/constants/app_strings.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _comparisonProvider =
    FutureProvider.autoDispose<GroupAdminComparisonReport>((ref) {
  return ref.read(groupAdminServiceProvider).getSchoolComparison();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupAdminAnalyticsScreen extends ConsumerStatefulWidget {
  const GroupAdminAnalyticsScreen({super.key});

  @override
  ConsumerState<GroupAdminAnalyticsScreen> createState() =>
      _GroupAdminAnalyticsScreenState();
}

class _GroupAdminAnalyticsScreenState
    extends ConsumerState<GroupAdminAnalyticsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = true;

  static const _columnWidths = [180.0, 80.0, 120.0, 80.0, 80.0, 80.0, 80.0, 100.0, 60.0];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncReport = ref.watch(_comparisonProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final padding = isNarrow ? AppSpacing.lg : AppSpacing.xl;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_comparisonProvider),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'School Analytics',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        AppSnackbar.info(context, AppStrings.exportComingSoon);
                      },
                      icon: const Icon(Icons.download, size: AppIconSize.sm),
                      label: const Text(AppStrings.export),
                    ),
                  ],
                ),
              ),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: asyncReport.when(
                  loading: () => AppLoaderScreen(),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: _ErrorCard(
                        error: err.toString().replaceAll('Exception: ', ''),
                        onRetry: () => ref.invalidate(_comparisonProvider),
                      ),
                    ),
                  ),
                  data: (report) =>
                      _buildBody(context, report, isNarrow, isWide, padding),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupAdminComparisonReport report,
    bool isNarrow,
    bool isWide,
    double padding,
  ) {
    _searchQuery = _searchController.text.trim();

    final filtered = _searchQuery.isEmpty
        ? List<GroupAdminSchoolComparisonItem>.from(report.schools)
        : report.schools.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.code.toLowerCase().contains(q) ||
                (s.city?.toLowerCase().contains(q) ?? false);
          }).toList();

    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int cmp = 0;
        switch (_sortColumn) {
          case 'name':
            cmp = a.name.compareTo(b.name);
            break;
          case 'users':
            cmp = a.userCount.compareTo(b.userCount);
            break;
          case 'plan':
            cmp = a.subscriptionPlan.compareTo(b.subscriptionPlan);
            break;
          case 'status':
            cmp = a.status.compareTo(b.status);
            break;
          case 'expiry':
            final aDate = a.subscriptionEnd ?? DateTime(2100);
            final bDate = b.subscriptionEnd ?? DateTime(2100);
            cmp = aDate.compareTo(bDate);
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Summary cards ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildSummaryCards(context, report, isNarrow),
        ),
        AppSpacing.vGapLg,

        // ── Search / Filters ───────────────────────────────────────
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppStrings.searchByNameCodeCity,
                          prefixIcon: const Icon(Icons.search, size: AppIconSize.md),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: AppIconSize.sm),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim()),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.filter_alt_off, size: AppIconSize.sm),
                      label: const Text(AppStrings.clearFilters),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _sortColumn = null;
                          _sortAscending = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AppSpacing.vGapLg,

        // ── Table / Cards ──────────────────────────────────────────
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  padding, 0, padding, padding),
              child: _buildContent(context, filtered, isWide),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<GroupAdminSchoolComparisonItem> filtered,
    bool isWide,
  ) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined,
                  size: AppIconSize.xl4, color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchQuery.isNotEmpty
                    ? "No results for '$_searchQuery'"
                    : 'No schools found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _sortColumn = null;
                      _sortAscending = true;
                    });
                  },
                  child: const Text(AppStrings.clearFilters),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (isWide) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListTableView(
                columns: const [
                  'School Name',
                  'Code',
                  'City / State',
                  'Board',
                  'Plan',
                  'Status',
                  'Users',
                  'Sub. Expiry',
                  'Health',
                ],
                columnWidths: _columnWidths,
                sortableColumns: const [0, 4, 5, 6, 7],
                sortColumnIndex: _columnIndex(_sortColumn),
                sortAscending: _sortAscending,
                onSort: (col, asc) {
                  const sortKeys = [
                    'name', null, null, null, 'plan', 'status', 'users',
                    'expiry', null,
                  ];
                  if (col >= 0 && col < sortKeys.length && sortKeys[col] != null) {
                    setState(() {
                      _sortColumn = sortKeys[col];
                      _sortAscending = asc;
                    });
                  }
                },
                showSrNo: false,
                itemCount: filtered.length,
                rowBuilder: (i) => _buildRow(context, filtered[i]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildMobileCard(context, filtered[i]),
    );
  }

  Widget _buildMobileCard(
      BuildContext context, GroupAdminSchoolComparisonItem s) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: () {},
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600)),
                        Text(
                          [s.city, s.state]
                              .where((v) => v != null && v.isNotEmpty)
                              .join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: s.status),
                ],
              ),
              AppSpacing.vGapMd,
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _infoChip(context, 'Code', s.code),
                  _infoChip(context, 'Board', s.board ?? '—'),
                  _infoChip(context, 'Plan', s.subscriptionPlan),
                  _infoChip(context, 'Users', '${s.userCount}'),
                  _infoChip(
                    context,
                    'Expiry',
                    s.subscriptionEnd != null
                        ? _formatDate(s.subscriptionEnd!)
                        : '—',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    GroupAdminComparisonReport report,
    bool isNarrow,
  ) {
    final activeCount = report.statusBreakdown['ACTIVE'] ?? 0;
    final planText = report.planBreakdown.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(' · ');

    final cards = [
      _SummaryCard(
        icon: Icons.school,
        value: '${report.totalSchools}',
        label: 'Total Schools',
        color: AppColors.secondary500,
      ),
      _SummaryCard(
        icon: Icons.people,
        value: '${report.totalUsers}',
        label: 'Total Users',
        color: AppColors.success500,
      ),
      _SummaryCard(
        icon: Icons.check_circle_outline,
        value: '$activeCount',
        label: 'Active Schools',
        color: AppColors.success500,
      ),
      _SummaryCard(
        icon: Icons.workspace_premium_outlined,
        value: planText.isEmpty ? '—' : planText,
        label: 'Plans',
        color: Theme.of(context).colorScheme.tertiary,
        compact: true,
      ),
    ];

    if (!isNarrow) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    }
    return Column(
      children: [
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
      ],
    );
  }

  int? _columnIndex(String? col) {
    const cols = [
      'name', null, null, null, 'plan', 'status', 'users', 'expiry', null,
    ];
    if (col == null) return null;
    final idx = cols.indexOf(col);
    return idx == -1 ? null : idx;
  }

  DataRow _buildRow(BuildContext context, GroupAdminSchoolComparisonItem s) {
    return DataRow(cells: [
      DataCell(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      DataCell(Text(s.code, style: Theme.of(context).textTheme.bodySmall)),
      DataCell(Text(
        [s.city, s.state].where((v) => v != null && v.isNotEmpty).join(', '),
        style: Theme.of(context).textTheme.bodySmall,
      )),
      DataCell(Text(s.board ?? '—', style: Theme.of(context).textTheme.bodySmall)),
      DataCell(_PlanBadge(plan: s.subscriptionPlan)),
      DataCell(_StatusBadge(status: s.status)),
      DataCell(Text('${s.userCount}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
      DataCell(Text(
        s.subscriptionEnd != null ? _formatDate(s.subscriptionEnd!) : '—',
        style: Theme.of(context).textTheme.bodySmall,
      )),
      DataCell(_ExpiryStatusDot(expiryStatus: s.expiryStatus)),
    ]);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppIconSize.md),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: compact
                  ? Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      )
                  : Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});
  final String plan;

  @override
  Widget build(BuildContext context) {
    final color = switch (plan.toUpperCase()) {
      'PREMIUM' => AppColors.secondary500,
      'STANDARD' => AppColors.success500,
      _ => AppColors.neutral400,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brXs,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        plan,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    final color = isActive ? AppColors.success500 : AppColors.error500;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          status,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ExpiryStatusDot extends StatelessWidget {
  const _ExpiryStatusDot({required this.expiryStatus});
  final String expiryStatus;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (expiryStatus) {
      'expired' => (AppColors.error500, 'Expired'),
      'expiring_soon' => (AppColors.warning500, 'Expiring'),
      _ => (AppColors.success500, 'OK'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ],
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
                size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(AppStrings.couldNotLoadAnalytics,
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
