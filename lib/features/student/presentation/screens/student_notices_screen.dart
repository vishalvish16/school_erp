// =============================================================================
// FILE: lib/features/student/presentation/screens/student_notices_screen.dart
// PURPOSE: Notices list screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

class StudentNoticesScreen extends ConsumerStatefulWidget {
  const StudentNoticesScreen({super.key});

  @override
  ConsumerState<StudentNoticesScreen> createState() =>
      _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends ConsumerState<StudentNoticesScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final asyncNotices = ref.watch(studentNoticesProvider(_page));
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentNoticesProvider(_page));
        setState(() => _page = 1);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.studentNoticesTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXl,
            asyncNotices.when(
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
                        onPressed: () => ref.invalidate(studentNoticesProvider(_page)),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (raw) {
                final data = raw['data'];
                final pagination = raw['pagination'] as Map<String, dynamic>?;
                final list = data is List ? data : [];
                final totalPages = (pagination?['total_pages'] as num?)?.toInt() ?? 1;
                final currentPage = (pagination?['page'] as num?)?.toInt() ?? 1;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        AppSpacing.vGapLg,
                        Text(
                          AppStrings.noNoticesAvailable,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => AppSpacing.vGapSm,
                      itemBuilder: (ctx, i) {
                        final n = list[i];
                        final id = n['id'] ?? '';
                        final title = n['title'] ?? '';
                        final body = n['body'] ?? n['content'] ?? '';
                        final isPinned = n['is_pinned'] as bool? ?? false;
                        final publishedAt = n['published_at'] as String?;
                        return Card(
                          child: InkWell(
                            onTap: () => context.go('/student/notices/$id'),
                            borderRadius: AppRadius.brLg,
                            child: Padding(
                              padding: AppSpacing.paddingMd,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isPinned) ...[
                                        const Icon(Icons.push_pin, size: 16, color: AppColors.warning500),
                                        AppSpacing.hGapXs,
                                      ],
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, size: 18),
                                    ],
                                  ),
                                  if (body.isNotEmpty) ...[
                                    AppSpacing.vGapXs,
                                    Text(
                                      body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (publishedAt != null) ...[
                                    AppSpacing.vGapSm,
                                    Text(
                                      publishedAt,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (totalPages > 1) ...[
                      AppSpacing.vGapLg,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: currentPage > 1
                                ? () => setState(() => _page = currentPage - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '${AppStrings.dash} $currentPage / $totalPages ${AppStrings.dash}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            onPressed: currentPage < totalPages
                                ? () => setState(() => _page = currentPage + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
