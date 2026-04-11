// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_notices_screen.dart
// PURPOSE: Read-only notice list screen for the Staff/Clerk portal.
//          Pinned notices appear at the top.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/staff/staff_notice_model.dart';

import '../providers/staff_notices_provider.dart';
import '../../../../design_system/design_system.dart';

import '../../../../core/constants/app_strings.dart';

class StaffNoticesScreen extends ConsumerStatefulWidget {
  const StaffNoticesScreen({super.key});

  @override
  ConsumerState<StaffNoticesScreen> createState() =>
      _StaffNoticesScreenState();
}

class _StaffNoticesScreenState extends ConsumerState<StaffNoticesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(staffNoticesProvider);
      if (state.notices.isEmpty && !state.isLoading) {
        ref.read(staffNoticesProvider.notifier).loadNotices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffNoticesProvider);
    final scheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(staffNoticesProvider.notifier).loadNotices(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notices',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGapLg,
              if (state.isLoading)
                Expanded(
                  child: AppLoaderScreen(),
                )
              else if (state.errorMessage != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Card(
                        child: Padding(
                          padding: AppSpacing.paddingXl,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: scheme.error),
                              AppSpacing.vGapLg,
                              Text(state.errorMessage!,
                                  textAlign: TextAlign.center),
                              AppSpacing.vGapLg,
                              FilledButton(
                                onPressed: () => ref
                                    .read(staffNoticesProvider.notifier)
                                    .loadNotices(),
                                child: const Text(AppStrings.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (state.notices.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 64, color: scheme.outline),
                        AppSpacing.vGapLg,
                        Text(
                          'No notices available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount: state.notices.length,
                    itemBuilder: (ctx, i) => _NoticeCard(
                      notice: state.notices[i],
                      onTap: () => context.go(
                          '/staff/notices/${state.notices[i].id}'),
                    ),
                  ),
                ),
              if (!state.isLoading &&
                  state.errorMessage == null &&
                  state.totalPages > 1)
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: padding, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: state.currentPage > 1
                            ? () => ref
                                .read(staffNoticesProvider.notifier)
                                .goToPage(state.currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Page ${state.currentPage} of ${state.totalPages}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        onPressed: state.currentPage < state.totalPages
                            ? () => ref
                                .read(staffNoticesProvider.notifier)
                                .goToPage(state.currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Notice Card ───────────────────────────────────────────────────────────────

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final StaffNoticeModel notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = notice.createdAt;
    final dateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (notice.isPinned) ...[
                    const Icon(Icons.push_pin,
                        size: 16, color: AppColors.warning500),
                    AppSpacing.hGapXs,
                  ],
                  Expanded(
                    child: Text(
                      notice.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notice.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  if (notice.category != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: AppRadius.brLg,
                      ),
                      child: Text(
                        notice.category!,
                        style: TextStyle(
                            fontSize: 11,
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    AppSpacing.hGapSm,
                  ],
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (notice.createdByName != null) ...[
                    const Text('  •  ',
                        style: TextStyle(color: AppColors.neutral400)),
                    Text(
                      notice.createdByName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
