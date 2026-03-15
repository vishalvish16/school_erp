// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_notice_detail_screen.dart
// PURPOSE: Full notice detail view for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_notice_model.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.secondary400;

final _noticeDetailProvider =
    FutureProvider.autoDispose.family<StaffNoticeModel, String>((ref, id) {
  return ref.read(staffServiceProvider).getNoticeById(id);
});

class StaffNoticeDetailScreen extends ConsumerWidget {
  const StaffNoticeDetailScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotice = ref.watch(_noticeDetailProvider(noticeId));
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Notice'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: asyncNotice.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapMd,
              Text(err.toString().replaceAll('Exception: ', '')),
              AppSpacing.vGapMd,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(_noticeDetailProvider(noticeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notice) => SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 700),
              child: Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pin indicator
                      if (notice.isPinned)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.warning500.withValues(alpha: 0.12),
                            borderRadius: AppRadius.brMd,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin,
                                  size: 14, color: AppColors.warning500),
                              AppSpacing.hGapXs,
                              Text('Pinned Notice',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning500,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                      // Title
                      Text(
                        notice.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vGapSm,

                      // Meta row
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (notice.category != null)
                            _MetaChip(
                              icon: Icons.label_outline,
                              label: notice.category!,
                              color: _accent,
                            ),
                          _MetaChip(
                            icon: Icons.calendar_today,
                            label: _fmtDate(notice.createdAt),
                            color: AppColors.neutral400,
                          ),
                          if (notice.createdByName != null)
                            _MetaChip(
                              icon: Icons.person_outline,
                              label: notice.createdByName!,
                              color: AppColors.neutral400,
                            ),
                          if (notice.expiresAt != null)
                            _MetaChip(
                              icon: Icons.schedule,
                              label:
                                  'Expires ${_fmtDate(notice.expiresAt!)}',
                              color: AppColors.error500,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      AppSpacing.vGapLg,

                      // Content
                      Text(
                        notice.content,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        AppSpacing.hGapXs,
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
