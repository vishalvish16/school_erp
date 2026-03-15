// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_notice_detail_screen.dart
// PURPOSE: Full notice detail for Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/notice_detail_model.dart';
import '../../data/parent_notice_detail_provider.dart';

class ParentNoticeDetailScreen extends ConsumerWidget {
  const ParentNoticeDetailScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotice = ref.watch(parentNoticeDetailProvider(noticeId));
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: asyncNotice.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(parentNoticeDetailProvider(noticeId)),
          ),
          data: (notice) {
            if (notice == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.error),
                    AppSpacing.vGapMd,
                    const Text(AppStrings.notFoundError),
                    AppSpacing.vGapMd,
                    TextButton(
                      onPressed: () => context.go('/parent/notices'),
                      child: const Text(AppStrings.back),
                    ),
                  ],
                ),
              );
            }
            return _buildContent(context, notice);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NoticeDetailModel notice) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/parent/notices'),
                icon: const Icon(Icons.arrow_back),
                tooltip: AppStrings.back,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  notice.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          AppSpacing.vGapXl,

          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notice.isPinned)
                    Row(
                      children: [
                        Icon(Icons.push_pin,
                            size: 18, color: AppColors.warning500),
                        AppSpacing.hGapSm,
                        Text(
                          AppStrings.pinnedNotice,
                          style: TextStyle(
                              color: AppColors.warning600,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  if (notice.isPinned) AppSpacing.vGapMd,
                  if (notice.publishedAt != null) ...[
                    Text(
                      'Published: ${_formatDate(notice.publishedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    AppSpacing.vGapSm,
                  ],
                  if (notice.expiresAt != null) ...[
                    Text(
                      'Expires: ${_formatDate(notice.expiresAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    AppSpacing.vGapLg,
                  ],
                  AppSpacing.vGapMd,
                  Text(
                    notice.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(
              onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
