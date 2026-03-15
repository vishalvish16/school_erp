// =============================================================================
// FILE: lib/features/student/presentation/screens/student_notice_detail_screen.dart
// PURPOSE: Notice detail screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

class StudentNoticeDetailScreen extends ConsumerWidget {
  const StudentNoticeDetailScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotice = ref.watch(studentNoticeByIdProvider(noticeId));
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentNoticeByIdProvider(noticeId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncNotice.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Card(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  AppSpacing.vGapLg,
                  Text(err.toString().replaceAll('Exception: ', '')),
                  AppSpacing.vGapLg,
                  FilledButton(
                    onPressed: () => ref.invalidate(studentNoticeByIdProvider(noticeId)),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (notice) => Card(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notice.isPinned) ...[
                    const Row(
                      children: [
                        Icon(Icons.push_pin, size: 18, color: AppColors.warning500),
                        SizedBox(width: 6),
                        Text('Pinned', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning500,
                        )),
                      ],
                    ),
                    AppSpacing.vGapMd,
                  ],
                  Text(
                    notice.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (notice.publishedAt != null) ...[
                    AppSpacing.vGapSm,
                    Text(
                      notice.publishedAt!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  AppSpacing.vGapXl,
                  AppDivider.horizontal,
                  AppSpacing.vGapLg,
                  Text(
                    notice.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (notice.expiresAt != null) ...[
                    AppSpacing.vGapXl,
                    Text(
                      'Expires: ${notice.expiresAt}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
