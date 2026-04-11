import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/teacher/class_diary_model.dart';
import '../providers/teacher_diary_provider.dart';

const Color _accent = AppColors.success500;

class TeacherDiaryScreen extends ConsumerStatefulWidget {
  const TeacherDiaryScreen({super.key});

  @override
  ConsumerState<TeacherDiaryScreen> createState() =>
      _TeacherDiaryScreenState();
}

class _TeacherDiaryScreenState extends ConsumerState<TeacherDiaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherDiaryListProvider.notifier).loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherDiaryListProvider);
    final notifier = ref.read(teacherDiaryListProvider.notifier);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.loadEntries(refresh: true),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Class Diary',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.go('/teacher/diary/new'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Entry'),
                    style:
                        FilledButton.styleFrom(backgroundColor: _accent),
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
                    : state.entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book_outlined,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline),
                                AppSpacing.vGapLg,
                                Text(AppStrings.noDiaryEntries,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge),
                                AppSpacing.vGapMd,
                                FilledButton.tonal(
                                  onPressed: () =>
                                      context.go('/teacher/diary/new'),
                                  child: const Text(AppStrings.addFirstEntry),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.entries.length,
                            itemBuilder: (context, i) =>
                                _DiaryCard(
                              entry: state.entries[i],
                              onDelete: () async {
                                final ok = await notifier
                                    .deleteEntry(state.entries[i].id);
                                if (ok && context.mounted) {
                                  AppSnackbar.success(context, AppStrings.entryDeleted);
                                }
                              },
                            ),
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
              onPressed: () => context.go('/teacher/diary/new'),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.entry, required this.onDelete});
  final ClassDiaryModel entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(
                    entry.date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ),
                if (entry.periodNo != null) ...[
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary500.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brXs,
                    ),
                    child: Text(
                      'Period ${entry.periodNo}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text(AppStrings.edit)),
                    const PopupMenuItem(
                        value: 'delete', child: Text(AppStrings.delete)),
                  ],
                  onSelected: (action) {
                    if (action == 'edit') {
                      context.go('/teacher/diary/${entry.id}/edit');
                    } else if (action == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  icon: const Icon(Icons.more_vert, size: 20),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              entry.topicCovered,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.subject, size: 14, color: AppColors.neutral600),
                AppSpacing.hGapXs,
                Text(entry.subject,
                    style: const TextStyle(fontSize: 13)),
                AppSpacing.hGapLg,
                Icon(Icons.class_outlined,
                    size: 14, color: AppColors.neutral600),
                AppSpacing.hGapXs,
                Text('${entry.className} - ${entry.sectionName}',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (entry.pageRange.isNotEmpty) ...[
              AppSpacing.vGapXs,
              Row(
                children: [
                  Icon(Icons.auto_stories,
                      size: 14, color: AppColors.neutral600),
                  AppSpacing.hGapXs,
                  Text(entry.pageRange,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
            if (entry.homeworkGiven != null &&
                entry.homeworkGiven!.isNotEmpty) ...[
              AppSpacing.vGapXs,
              Row(
                children: [
                  Icon(Icons.assignment,
                      size: 14, color: AppColors.neutral600),
                  AppSpacing.hGapXs,
                  Expanded(
                    child: Text(
                      'HW: ${entry.homeworkGiven}',
                      style: const TextStyle(
                          fontSize: 13, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteEntryQuestion,
      message: AppStrings.deleteEntryConfirm,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    onDelete();
  }
}
