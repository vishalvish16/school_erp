// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_notices_screen.dart
// PURPOSE: Paginated notices list for Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/notice_summary_model.dart';
import '../../data/parent_notices_provider.dart';

const Color _accent = AppColors.success500;

class ParentNoticesScreen extends ConsumerStatefulWidget {
  const ParentNoticesScreen({super.key});

  @override
  ConsumerState<ParentNoticesScreen> createState() =>
      _ParentNoticesScreenState();
}

class _ParentNoticesScreenState extends ConsumerState<ParentNoticesScreen> {
  int _page = 1;
  static const int _limit = 20;

  @override
  Widget build(BuildContext context) {
    final asyncNotices = ref.watch(
      parentNoticesPageProvider((page: _page, limit: _limit)),
    );
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          parentNoticesPageProvider((page: _page, limit: _limit)),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.parentNoticesTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXs,
            Text(
              AppStrings.parentNoticesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            AppSpacing.vGapXl,

            asyncNotices.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => _ErrorCard(
                error: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(
                  parentNoticesPageProvider((page: _page, limit: _limit)),
                ),
              ),
              data: (result) {
                if (result.notices.isEmpty) {
                  return _EmptyState();
                }
                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: result.notices.length,
                      separatorBuilder: (_, _) => AppSpacing.vGapMd,
                      itemBuilder: (_, i) {
                        final n = result.notices[i];
                        return _NoticeCard(notice: n);
                      },
                    ),
                    AppSpacing.vGapLg,
                    _buildPagination(context, result.pagination),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(
      BuildContext context, Map<String, dynamic> pagination) {
    final page = (pagination['page'] as num?)?.toInt() ?? 1;
    final totalPages =
        (pagination['total_pages'] as num?)?.toInt() ?? 1;
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1
              ? () => setState(() => _page = page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $totalPages'),
        IconButton(
          onPressed: page < totalPages
              ? () => setState(() => _page = page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final NoticeSummaryModel notice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/parent/notices/${notice.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _accent.withValues(alpha: 0.15),
                child: Icon(Icons.campaign, color: _accent, size: 22),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (notice.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Urgent',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error500,
                              ),
                            ),
                          ),
                        if (notice.isUrgent && notice.isPinned)
                          AppSpacing.hGapXs,
                        if (notice.isPinned)
                          Icon(Icons.push_pin,
                              size: 16, color: AppColors.warning500),
                      ],
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      notice.body.length > 120
                          ? '${notice.body.substring(0, 120)}...'
                          : notice.body,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notice.publishedAt != null) ...[
                      AppSpacing.vGapXs,
                      Text(
                        _formatDate(notice.publishedAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          AppSpacing.vGapLg,
          Text(
            AppStrings.noNotices,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapSm,
          Text(
            AppStrings.noNoticesHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(error, textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(
                onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
