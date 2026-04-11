import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/teacher/homework_model.dart';
import '../providers/teacher_homework_provider.dart';
import '../../../../design_system/design_system.dart';

const Color _accent = AppColors.success500;

class TeacherHomeworkScreen extends ConsumerStatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  ConsumerState<TeacherHomeworkScreen> createState() =>
      _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState
    extends ConsumerState<TeacherHomeworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherHomeworkListProvider.notifier).loadHomework();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherHomeworkListProvider);
    final notifier = ref.read(teacherHomeworkListProvider.notifier);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.loadHomework(refresh: true),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Homework',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.go('/teacher/homework/new'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.newHomework),
                    style: FilledButton.styleFrom(
                        backgroundColor: _accent),
                  ),
                ],
              ),
              AppSpacing.vGapLg,

              // Filter chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusFilterChip(
                    label: 'All',
                    selected: state.statusFilter == null,
                    onTap: () => notifier.setStatusFilter(null),
                  ),
                  _StatusFilterChip(
                    label: 'Active',
                    selected: state.statusFilter == 'ACTIVE',
                    onTap: () => notifier.setStatusFilter('ACTIVE'),
                    color: _accent,
                  ),
                  _StatusFilterChip(
                    label: 'Reviewed',
                    selected: state.statusFilter == 'REVIEWED',
                    onTap: () => notifier.setStatusFilter('REVIEWED'),
                    color: AppColors.secondary500,
                  ),
                  _StatusFilterChip(
                    label: 'Cancelled',
                    selected: state.statusFilter == 'CANCELLED',
                    onTap: () => notifier.setStatusFilter('CANCELLED'),
                    color: AppColors.error500,
                  ),
                ],
              ),
              AppSpacing.vGapLg,

              if (state.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMd,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.1),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Text(state.errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),

              Expanded(
                child: state.isLoading
                    ? AppLoaderScreen()
                    : state.homework.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assignment_outlined,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline),
                                AppSpacing.vGapLg,
                                Text(AppStrings.noHomeworkFound,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.homework.length,
                            itemBuilder: (context, i) =>
                                _HomeworkCard(homework: state.homework[i]),
                          ),
              ),

              if (state.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: state.currentPage > 1
                            ? () =>
                                notifier.goToPage(state.currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                          'Page ${state.currentPage} of ${state.totalPages}'),
                      IconButton(
                        onPressed:
                            state.currentPage < state.totalPages
                                ? () => notifier
                                    .goToPage(state.currentPage + 1)
                                : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton(
              backgroundColor: _accent,
              onPressed: () => context.go('/teacher/homework/new'),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: (color ?? _accent).withValues(alpha: 0.15),
      checkmarkColor: color ?? _accent,
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.homework});
  final HomeworkModel homework;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (homework.status) {
      'ACTIVE' => _accent,
      'REVIEWED' => AppColors.secondary500,
      'CANCELLED' => AppColors.error500,
      _ => AppColors.neutral400,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/teacher/homework/${homework.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      homework.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brXs,
                    ),
                    child: Text(
                      homework.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  Icon(Icons.subject, size: 14, color: AppColors.neutral600),
                  AppSpacing.hGapXs,
                  Text(homework.subject,
                      style: const TextStyle(fontSize: 13)),
                  AppSpacing.hGapLg,
                  Icon(Icons.class_outlined,
                      size: 14, color: AppColors.neutral600),
                  AppSpacing.hGapXs,
                  Text(
                    '${homework.className} - ${homework.sectionName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  Text(
                    'Assigned: ${homework.assignedDate}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  AppSpacing.hGapLg,
                  Text(
                    'Due: ${homework.dueDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: homework.isOverdue ? AppColors.error500 : null,
                        ),
                  ),
                  if (homework.status == 'ACTIVE' &&
                      !homework.isOverdue &&
                      homework.daysRemaining >= 0) ...[
                    AppSpacing.hGapSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: homework.daysRemaining <= 1
                            ? AppColors.warning500.withValues(alpha: 0.12)
                            : _accent.withValues(alpha: 0.12),
                        borderRadius: AppRadius.brXs,
                      ),
                      child: Text(
                        homework.daysRemaining == 0
                            ? 'Due today'
                            : '${homework.daysRemaining}d left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: homework.daysRemaining <= 1
                              ? AppColors.warning500
                              : _accent,
                        ),
                      ),
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
