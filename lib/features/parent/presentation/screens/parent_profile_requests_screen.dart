// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_profile_requests_screen.dart
// PURPOSE: Lists all profile update requests submitted by this parent.
// Uses standard table structure with ListTableView, Card, and pagination.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/profile_update_request_model.dart';

import '../../../school_admin/presentation/providers/profile_requests_provider.dart';

class ParentProfileRequestsScreen extends ConsumerStatefulWidget {
  const ParentProfileRequestsScreen({super.key});

  @override
  ConsumerState<ParentProfileRequestsScreen> createState() =>
      _ParentProfileRequestsScreenState();
}

class _ParentProfileRequestsScreenState
    extends ConsumerState<ParentProfileRequestsScreen> {
  static const _pageSizeOptions = [10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentProfileRequestsProvider(null).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentProfileRequestsProvider(null));
    final scheme = Theme.of(context).colorScheme;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async => ref
          .read(parentProfileRequestsProvider(null).notifier)
          .load(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myProfileRequests,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      AppStrings.myProfileRequestsSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // ── Error banner ──────────────────────────────────────────────
              if (state.errorMessage != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
                  child: AppFeedback.errorBanner(
                    state.errorMessage!,
                    onRetry: () => ref
                        .read(parentProfileRequestsProvider(null).notifier)
                        .load(refresh: true),
                  ),
                ),
                AppSpacing.vGapMd,
              ],

              // ── Content ───────────────────────────────────────────────────
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

  Widget _buildContent(
    bool isWide,
    ParentProfileRequestsState state,
    ColorScheme scheme,
  ) {
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
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              AppSpacing.vGapLg,
              Text(state.errorMessage!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref
                    .read(parentProfileRequestsProvider(null).notifier)
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_outlined,
                size: AppIconSize.xl3, color: scheme.onSurfaceVariant),
            AppSpacing.vGapMd,
            Text(
              AppStrings.noProfileRequests,
              style: AppTextStyles.h6(color: scheme.onSurface),
            ),
          ],
        ),
      );
    }
    return _buildRequestList(isWide, state);
  }

  static const _columnWidths = [
    180.0, // Student
    140.0, // Admission No
    100.0, // Fields
    100.0, // Status
    150.0, // Date
  ];
  static final _tableContentWidth =
      _columnWidths.fold<double>(0, (a, b) => a + b) + 32;

  Widget _buildRequestList(bool isWide, ParentProfileRequestsState state) {
    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _tableContentWidth),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListTableView(
                    columns: const [
                      'Student',
                      'Admission No',
                      'Fields',
                      'Status',
                      'Date',
                    ],
                    columnWidths: _columnWidths,
                    showSrNo: false,
                    itemCount: state.requests.length,
                    rowBuilder: (i) => _buildDataRow(state.requests[i]),
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
        padding: EdgeInsets.only(bottom: i < state.requests.length - 1 ? 8 : 0),
        child: _ParentRequestCard(request: state.requests[i]),
      ),
      onLoadMore: () => ref
          .read(parentProfileRequestsProvider(null).notifier)
          .loadMore(),
      hasMore: hasMore,
      isLoadingMore: state.isLoadingMore,
      loadingLabel: 'Loading more requests…',
    );
  }

  Widget _buildPaginationRow(ParentProfileRequestsState state) {
    final notifier = ref.read(parentProfileRequestsProvider(null).notifier);
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
        DataCell(Text(AppStrings.fieldsChangedCount(changesCount))),
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
          DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt),
        )),
      ],
    );
  }
}

// ── Parent Request Card (mobile) ───────────────────────────────────────────────

class _ParentRequestCard extends StatelessWidget {
  const _ParentRequestCard({required this.request});

  final ProfileUpdateRequest request;

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

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: scheme.outlineVariant,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.studentName.isNotEmpty
                      ? request.studentName
                      : AppStrings.notAvailable,
                  style: AppTextStyles.bodyMd(color: scheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: AppOpacity.focus),
                  borderRadius: AppRadius.brFull,
                ),
                child: Text(statusLabel,
                    style: AppTextStyles.caption(color: statusColor)),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            AppStrings.fieldsChangedCount(changesCount),
            style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
          ),
          AppSpacing.vGapXs,
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt),
            style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
          ),
          if (request.reviewNote != null && request.reviewNote!.isNotEmpty) ...[
            AppSpacing.vGapSm,
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest
                    .withValues(alpha: AppOpacity.medium),
                borderRadius: AppRadius.brSm,
              ),
              child: Text(
                '${AppStrings.reviewNote}: ${request.reviewNote}',
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
