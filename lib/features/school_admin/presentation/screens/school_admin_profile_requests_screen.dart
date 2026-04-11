// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_profile_requests_screen.dart
// PURPOSE: List screen for student profile update requests (school admin + staff).
// Uses standard table structure with ListTableView, Card, and pagination.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/metric_stat_card.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/profile_update_request_model.dart';

import '../providers/profile_requests_provider.dart';

class SchoolAdminProfileRequestsScreen extends ConsumerStatefulWidget {
  const SchoolAdminProfileRequestsScreen(
      {super.key, this.basePath = '/school-admin'});

  final String basePath;

  @override
  ConsumerState<SchoolAdminProfileRequestsScreen> createState() =>
      _SchoolAdminProfileRequestsScreenState();
}

class _SchoolAdminProfileRequestsScreenState
    extends ConsumerState<SchoolAdminProfileRequestsScreen> {
  static const _pageSizeOptions = [10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileRequestsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileRequestsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    // Derived counts for stats row
    final pendingCount =
        state.requests.where((r) => r.status == 'PENDING').length;

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(profileRequestsProvider.notifier).load(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.profileRequests,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            pendingCount > 0
                                ? '$pendingCount pending request${pendingCount == 1 ? '' : 's'}'
                                : AppStrings.profileRequestsSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: pendingCount > 0
                                        ? AppColors.warning500
                                        : scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stats row ─────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24),
                child: _buildStatsRow(state, isWide),
              ),
              AppSpacing.vGapMd,

              // ── Filter Chips ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24),
                child: _FilterChips(
                  currentFilter: state.statusFilter,
                  counts: state.statusTotals,
                  onChanged: (f) => ref
                      .read(profileRequestsProvider.notifier)
                      .setStatusFilter(f),
                ),
              ),
              AppSpacing.vGapMd,

              // ── Error banner ──────────────────────────────────────────
              if (state.errorMessage != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 16 : 24),
                  child: AppFeedback.errorBanner(
                    state.errorMessage!,
                    onRetry: () => ref
                        .read(profileRequestsProvider.notifier)
                        .load(refresh: true),
                  ),
                ),
                AppSpacing.vGapMd,
              ],

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isNarrow ? 16 : 24,
                      0,
                      isNarrow ? 16 : 24,
                      isNarrow ? 16 : 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.contentMaxWidth,
                      ),
                      child: _buildContent(isWide, state, scheme),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(ProfileRequestsState state, bool isWide) {
    final pendingCount =
        state.requests.where((r) => r.status == 'PENDING').length;
    final approvedCount =
        state.requests.where((r) => r.status == 'APPROVED').length;

    final items = <(IconData, String, String, Color)>[
      (Icons.pending_actions_rounded, '$pendingCount', 'Pending',
          AppColors.warning500),
      (Icons.check_circle_rounded, '$approvedCount', 'Approved',
          AppColors.success500),
      (Icons.list_alt_rounded, '${state.total}', 'Total Requests',
          AppColors.primary500),
    ];

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: MetricStatCard(
                icon: items[i].$1,
                value: items[i].$2,
                label: items[i].$3,
                color: items[i].$4,
                compact: false,
              ),
            ),
            if (i < items.length - 1) AppSpacing.hGapSm,
          ],
        ],
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (ctx, i) => SizedBox(
          width: 148,
          child: MetricStatCard(
            icon: items[i].$1,
            value: items[i].$2,
            label: items[i].$3,
            color: items[i].$4,
            compact: true,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      bool isWide, ProfileRequestsState state, ColorScheme scheme) {
    if (state.isLoading && state.requests.isEmpty) {
      return AppLoaderScreen();
    }
    if (state.errorMessage != null && state.requests.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: AppIconSize.xl3, color: scheme.error),
              AppSpacing.vGapLg,
              Text(state.errorMessage!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref
                    .read(profileRequestsProvider.notifier)
                    .load(refresh: true),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.manage_accounts_outlined,
                  size: AppIconSize.xl4, color: scheme.outline),
              AppSpacing.vGapLg,
              Text(
                AppStrings.noProfileRequests,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              Text(
                AppStrings.noProfileRequestsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return _buildRequestList(isWide, state);
  }

  static const _columnWidths = [
    160.0, // Student
    140.0, // Admission No
    140.0, // Requested By
    100.0, // Fields
    100.0, // Status
    150.0, // Date
    60.0, // Actions
  ];
  static final _tableContentWidth =
      _columnWidths.fold<double>(0, (a, b) => a + b) + 32;

  Widget _buildRequestList(bool isWide, ProfileRequestsState state) {
    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: _tableContentWidth),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListTableView(
                    columns: const [
                      'Student',
                      'Admission No',
                      'Requested By',
                      'Fields',
                      'Status',
                      'Date',
                      'Actions',
                    ],
                    columnWidths: _columnWidths,
                    showSrNo: false,
                    itemCount: state.requests.length,
                    rowBuilder: (i) =>
                        _buildDataRow(state.requests[i]),
                  ),
                ),
                _buildPaginationRow(state),
              ],
            ),
          ),
        ),
      );
    }
    final hasMore = state.total > 0 &&
        state.requests.length < state.total &&
        state.page < state.totalPages;
    return MobileInfiniteScrollList(
      itemCount: state.requests.length,
      itemBuilder: (ctx, i) => Padding(
        padding: EdgeInsets.only(
            bottom: i < state.requests.length - 1 ? AppSpacing.sm : 0),
        child: _RequestCard(
          request: state.requests[i],
          onTap: () => context.go(
            '${widget.basePath}/profile-requests/${state.requests[i].id}',
          ),
        ),
      ),
      onLoadMore: () =>
          ref.read(profileRequestsProvider.notifier).loadMore(),
      hasMore: hasMore,
      isLoadingMore: state.isLoadingMore,
      loadingLabel: 'Loading more requests…',
    );
  }

  Widget _buildPaginationRow(ProfileRequestsState state) {
    final notifier = ref.read(profileRequestsProvider.notifier);
    final effectivePageSize = state.pageSize > 0
        ? (_pageSizeOptions.contains(state.pageSize)
            ? state.pageSize
            : _pageSizeOptions.first)
        : _pageSizeOptions.first;
    return ListPaginationBar(
      currentPage: state.page,
      totalPages: state.totalPages,
      totalEntries: state.total,
      pageSize: effectivePageSize,
      pageSizeOptions: _pageSizeOptions,
      onPageSizeChanged: (v) {
        if (v != null) notifier.setPageSize(v);
      },
      onGoToPage: notifier.goToPage,
    );
  }

  DataRow _buildDataRow(ProfileUpdateRequest request) {
    final changesCount = request.requestedChanges.length;

    Color statusColor;
    String statusLabel;
    switch (request.status) {
      case 'APPROVED':
        statusColor = AppColors.success500;
        statusLabel = AppStrings.statusApproved;
      case 'REJECTED':
        statusColor = AppColors.error500;
        statusLabel = AppStrings.statusRejected;
      default:
        statusColor = AppColors.warning500;
        statusLabel = AppStrings.statusPending;
    }

    return DataRow(
      cells: [
        DataCell(Text(
          request.studentName.isNotEmpty
              ? request.studentName
              : AppStrings.notAvailable,
        )),
        DataCell(Text(request.studentAdmissionNo)),
        DataCell(Text(request.parentName.isNotEmpty
            ? request.parentName
            : AppStrings.dash)),
        DataCell(
            Text(AppStrings.fieldsChangedCount(changesCount))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: AppOpacity.focus),
            borderRadius: AppRadius.brFull,
          ),
          child: Text(
            statusLabel,
            style: AppTextStyles.caption(color: statusColor),
          ),
        )),
        DataCell(Text(
          DateFormat('dd MMM yyyy, hh:mm a')
              .format(request.createdAt),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.chevron_right,
                size: AppIconSize.md),
            onPressed: () => context.go(
              '${widget.basePath}/profile-requests/${request.id}',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.currentFilter,
    required this.onChanged,
    this.counts = const {},
  });

  final String? currentFilter;
  final ValueChanged<String?> onChanged;
  final Map<String?, int> counts;

  @override
  Widget build(BuildContext context) {
    final filters = <String?, String>{
      null: AppStrings.filterAll,
      'PENDING': AppStrings.statusPending,
      'APPROVED': AppStrings.statusApproved,
      'REJECTED': AppStrings.statusRejected,
    };

    return Wrap(
      spacing: AppSpacing.sm,
      children: filters.entries.map((e) {
        final isSelected = currentFilter == e.key;
        final count = counts[e.key];
        final label = count != null ? '${e.value} ($count)' : e.value;
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(e.key),
          shape: AppRadius.chipShape,
        );
      }).toList(),
    );
  }
}

// ── Request Card (mobile) ──────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final ProfileUpdateRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final changesCount = request.requestedChanges.length;

    Color statusColor;
    String statusLabel;
    switch (request.status) {
      case 'APPROVED':
        statusColor = AppColors.success500;
        statusLabel = AppStrings.statusApproved;
      case 'REJECTED':
        statusColor = AppColors.error500;
        statusLabel = AppStrings.statusRejected;
      default:
        statusColor = AppColors.warning500;
        statusLabel = AppStrings.statusPending;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.brLg,
            border: Border(
              left: BorderSide(
                color: request.isPending
                    ? AppColors.warning500
                    : scheme.outlineVariant,
                width: request.isPending
                    ? AppBorderWidth.thick
                    : AppBorderWidth.thin,
              ),
              top: BorderSide(
                  color: scheme.outlineVariant,
                  width: AppBorderWidth.thin),
              right: BorderSide(
                  color: scheme.outlineVariant,
                  width: AppBorderWidth.thin),
              bottom: BorderSide(
                  color: scheme.outlineVariant,
                  width: AppBorderWidth.thin),
            ),
          ),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName.isNotEmpty
                            ? request.studentName
                            : AppStrings.notAvailable,
                        style: AppTextStyles.bodyMd(
                            color: scheme.onSurface),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        '${request.studentAdmissionNo}  |  ${AppStrings.fieldsChangedCount(changesCount)}',
                        style: AppTextStyles.bodySm(
                            color: scheme.onSurfaceVariant),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        '${AppStrings.requestedBy}: ${request.parentName}',
                        style: AppTextStyles.bodySm(
                            color: scheme.onSurfaceVariant),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(request.createdAt),
                        style: AppTextStyles.bodySm(
                            color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapMd,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor
                            .withValues(alpha: AppOpacity.focus),
                        borderRadius: AppRadius.brFull,
                      ),
                      child: Text(
                        statusLabel,
                        style:
                            AppTextStyles.caption(color: statusColor),
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Icon(Icons.chevron_right,
                        size: AppIconSize.lg,
                        color: scheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
