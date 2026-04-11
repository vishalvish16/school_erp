// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_classes_screen.dart
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../widgets/common/hover_popup_menu.dart';

import '../providers/school_admin_classes_provider.dart';

class SchoolAdminClassesScreen extends ConsumerStatefulWidget {
  const SchoolAdminClassesScreen({super.key});

  @override
  ConsumerState<SchoolAdminClassesScreen> createState() =>
      _SchoolAdminClassesScreenState();
}

class _SchoolAdminClassesScreenState
    extends ConsumerState<SchoolAdminClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolAdminClassesProvider);
    final cs = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(schoolAdminClassesProvider.notifier).loadClasses(),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(isNarrow ? 16.0 : 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.classes,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          '${state.classes.length} class${state.classes.length == 1 ? '' : 'es'} configured',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddClassDialog(context),
                    icon: const Icon(Icons.add, size: AppIconSize.md),
                    label: Text(AppStrings.addClass),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? AppLoaderScreen()
                  : state.errorMessage != null
                      ? _buildErrorState(context, cs, state.errorMessage!)
                      : state.classes.isEmpty
                          ? _buildEmptyState(context, cs)
                          : isWide
                              ? _buildWideLayout(context, state)
                              : _buildNarrowLayout(context, state, isNarrow),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wide: card-based list (same card design, better padding) ─────────────

  Widget _buildWideLayout(
      BuildContext context, ClassesState state) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: state.classes.length,
      itemBuilder: (context, i) => _ClassCard(
        schoolClass: state.classes[i],
        onEditClass: () =>
            _showEditClassDialog(context, state.classes[i]),
        onDeleteClass: () =>
            _confirmDeleteClass(context, state.classes[i]),
        onAddSection: () =>
            _showAddSectionDialog(context, state.classes[i]),
        onDeleteSection: (sectionId) =>
            _confirmDeleteSection(context, sectionId),
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context,
      ClassesState state, bool isNarrow) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16.0 : 24.0,
      ),
      itemCount: state.classes.length,
      itemBuilder: (context, i) => _ClassCard(
        schoolClass: state.classes[i],
        onEditClass: () =>
            _showEditClassDialog(context, state.classes[i]),
        onDeleteClass: () =>
            _confirmDeleteClass(context, state.classes[i]),
        onAddSection: () =>
            _showAddSectionDialog(context, state.classes[i]),
        onDeleteSection: (sectionId) =>
            _confirmDeleteSection(context, sectionId),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined,
              size: AppIconSize.xl4, color: cs.outline),
          AppSpacing.vGapLg,
          Text(AppStrings.noClassesFound,
              style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.vGapSm,
          Text(
            'Add your first class to get started.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          AppSpacing.vGapLg,
          FilledButton.icon(
            onPressed: () => _showAddClassDialog(context),
            icon: const Icon(Icons.add, size: AppIconSize.md),
            label: Text(AppStrings.addFirstClass),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, ColorScheme cs, String message) {
    return Center(
      child: Card(
        margin: AppSpacing.paddingXl,
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: AppIconSize.xl3, color: cs.error),
              AppSpacing.vGapMd,
              Text(message, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref
                    .read(schoolAdminClassesProvider.notifier)
                    .loadClasses(),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddClassDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final numericCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.addClass),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                  labelText: AppStrings.classNameHint,
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.brMd)),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: numericCtrl,
              decoration: InputDecoration(
                  labelText: AppStrings.sortOrderHint,
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.brMd)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final numeric =
                  int.tryParse(numericCtrl.text.trim());
              final ok = await ref
                  .read(schoolAdminClassesProvider.notifier)
                  .createClass(nameCtrl.text.trim(),
                      numeric: numeric);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  AppToast.showSuccess(
                      context, AppStrings.classCreated);
                }
              }
            },
            child: Text(AppStrings.create),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditClassDialog(
      BuildContext context, SchoolClassModel cls) async {
    final nameCtrl = TextEditingController(text: cls.name);
    final numericCtrl = TextEditingController(
        text: cls.numeric?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.editClass),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                  labelText: AppStrings.className,
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.brMd)),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: numericCtrl,
              decoration: InputDecoration(
                  labelText: AppStrings.sortOrder,
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.brMd)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final numeric =
                  int.tryParse(numericCtrl.text.trim());
              final ok = await ref
                  .read(schoolAdminClassesProvider.notifier)
                  .updateClass(cls.id, nameCtrl.text.trim(),
                      numeric: numeric);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text(AppStrings.update),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteClass(
      BuildContext context, SchoolClassModel cls) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteClassQuestion,
      message:
          'Delete "${cls.name}"? All sections and students in this class will be affected.',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(schoolAdminClassesProvider.notifier)
        .deleteClass(cls.id);
  }

  Future<void> _showAddSectionDialog(
      BuildContext context, SchoolClassModel cls) async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Section to ${cls.name}'),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
              labelText: AppStrings.sectionNameHint,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.brMd)),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final ok = await ref
                  .read(schoolAdminClassesProvider.notifier)
                  .createSection(
                      cls.id, nameCtrl.text.trim().toUpperCase());
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  AppToast.showSuccess(
                      context, AppStrings.sectionCreated);
                }
              }
            },
            child: Text(AppStrings.add),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSection(
      BuildContext context, String sectionId) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteSection,
      message: AppStrings.deleteSectionWarning,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(schoolAdminClassesProvider.notifier)
        .deleteSection(sectionId);
  }
}

class _ClassCard extends StatefulWidget {
  const _ClassCard({
    required this.schoolClass,
    required this.onEditClass,
    required this.onDeleteClass,
    required this.onAddSection,
    required this.onDeleteSection,
  });

  final SchoolClassModel schoolClass;
  final VoidCallback onEditClass;
  final VoidCallback onDeleteClass;
  final VoidCallback onAddSection;
  final void Function(String) onDeleteSection;

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cls = widget.schoolClass;
    final scheme = Theme.of(context).colorScheme;
    final totalStudents =
        cls.sections.fold(0, (sum, s) => sum + s.studentCount);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  AppColors.primary500.withValues(alpha: 0.15),
              child: Text(
                cls.numeric?.toString() ?? cls.name.substring(0, 1),
                style: const TextStyle(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(cls.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600)),
            subtitle: Row(
              children: [
                _InfoChip(
                  label:
                      '${cls.sections.length} section${cls.sections.length == 1 ? '' : 's'}',
                  color: AppColors.primary500,
                ),
                AppSpacing.hGapXs,
                _InfoChip(
                  label: '$totalStudents students',
                  color: AppColors.secondary500,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: widget.onAddSection,
                  icon: const Icon(Icons.add_circle_outline,
                      size: AppIconSize.md),
                  tooltip: AppStrings.addSection,
                  color: scheme.primary,
                ),
                HoverPopupMenu<String>(
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.edit,
                                size: AppIconSize.md),
                            title: Text(AppStrings.editClass))),
                    PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.delete,
                                color: AppColors.error500,
                                size: AppIconSize.md),
                            title: Text(AppStrings.deleteClass,
                                style: const TextStyle(
                                    color: AppColors.error500)))),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') widget.onEditClass();
                    if (v == 'delete') widget.onDeleteClass();
                  },
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: AppIconSize.md,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded && cls.sections.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cls.sections
                    .map((sec) => Chip(
                          label: Text(
                            '${sec.name}  (${sec.studentCount})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close,
                              size: AppIconSize.xs),
                          onDeleted: () =>
                              widget.onDeleteSection(sec.id),
                          backgroundColor: AppColors.primary500
                              .withValues(alpha: 0.1),
                          side: BorderSide(
                              color: AppColors.primary500
                                  .withValues(alpha: 0.3)),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brFull,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          if (_expanded && cls.sections.isEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: AppSpacing.paddingMd,
              child: Text(
                'No sections yet. Tap + to add one.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color),
      ),
    );
  }
}
