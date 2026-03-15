import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/teacher/homework_model.dart';
import '../providers/teacher_homework_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class TeacherHomeworkDetailScreen extends ConsumerWidget {
  const TeacherHomeworkDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHw = ref.watch(teacherHomeworkDetailProvider(id));
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: asyncHw.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                AppSpacing.vGapMd,
                Text(err.toString().replaceAll('Exception: ', '')),
                AppSpacing.vGapMd,
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(teacherHomeworkDetailProvider(id)),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
          data: (hw) => _DetailBody(hw: hw, id: id),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.hw, required this.id});
  final HomeworkModel hw;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (hw.status) {
      'ACTIVE' => _accent,
      'REVIEWED' => AppColors.secondary500,
      'CANCELLED' => AppColors.error500,
      _ => AppColors.neutral400,
    };

    final canEdit = !hw.isOverdue && hw.status != 'CANCELLED';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/teacher/homework'),
                icon: const Icon(Icons.arrow_back),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  hw.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(
                  hw.status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapXl,

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                              'Subject', hw.subject, Icons.subject),
                          AppSpacing.vGapMd,
                          _InfoRow('Class',
                              '${hw.className} - ${hw.sectionName}',
                              Icons.class_outlined),
                          AppSpacing.vGapMd,
                          _InfoRow('Assigned Date', hw.assignedDate,
                              Icons.event_available),
                          AppSpacing.vGapMd,
                          _InfoRow(
                            'Due Date',
                            hw.dueDate,
                            Icons.event,
                            valueColor:
                                hw.isOverdue ? AppColors.error500 : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.vGapLg,

                  if (hw.description != null &&
                      hw.description!.isNotEmpty) ...[
                    Text('Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    AppSpacing.vGapSm,
                    Card(
                      child: Padding(
                        padding: AppSpacing.paddingLg,
                        child: Text(hw.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium),
                      ),
                    ),
                    AppSpacing.vGapLg,
                  ],

                  if (hw.attachmentUrls.isNotEmpty) ...[
                    Text('Attachments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    AppSpacing.vGapSm,
                    ...hw.attachmentUrls.map((url) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text(url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        )),
                    AppSpacing.vGapLg,
                  ],

                  // Action buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (canEdit)
                        FilledButton.icon(
                          onPressed: () =>
                              context.go('/teacher/homework/$id/edit'),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      if (hw.status == 'ACTIVE')
                        FilledButton.tonal(
                          onPressed: () async {
                            final ok = await ref
                                .read(
                                    teacherHomeworkListProvider.notifier)
                                .updateStatus(id, 'REVIEWED');
                            if (ok && context.mounted) {
                              ref.invalidate(
                                  teacherHomeworkDetailProvider(id));
                              AppSnackbar.success(context, AppStrings.markedAsReviewed);
                            }
                          },
                          child: const Text(AppStrings.markAsReviewed),
                        ),
                      if (canEdit)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, ref),
                          icon: Icon(Icons.delete_outline,
                              size: 18,
                              color:
                                  Theme.of(context).colorScheme.error),
                          label: Text('Delete',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteHomeworkQuestion,
      message: 'This action cannot be undone. Delete this homework assignment?',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref
        .read(teacherHomeworkListProvider.notifier)
        .deleteHomework(id);
    if (ok && context.mounted) {
      context.go('/teacher/homework');
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, this.icon, {this.valueColor});

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.neutral600),
        AppSpacing.hGapMd,
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.neutral400)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
