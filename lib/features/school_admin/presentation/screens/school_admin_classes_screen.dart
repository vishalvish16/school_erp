// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_classes_screen.dart
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

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
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(schoolAdminClassesProvider.notifier).loadClasses(),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.all(isNarrow ? 16.0 : 24.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    AppStrings.classes,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddClassDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppStrings.addClass),
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: state.isLoading
                  ? const ShimmerListLoadingWidget(itemCount: 8)
                  : state.errorMessage != null
                      ? _buildErrorState(context, cs, state.errorMessage!)
                      : state.classes.isEmpty
                          ? _buildEmptyState(context, cs)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 16.0 : 24.0,
                              ),
                              itemCount: state.classes.length,
                              itemBuilder: (context, i) => _ClassCard(
                                schoolClass: state.classes[i],
                                onEditClass: () => _showEditClassDialog(
                                    context, state.classes[i]),
                                onDeleteClass: () => _confirmDeleteClass(
                                    context, state.classes[i]),
                                onAddSection: () => _showAddSectionDialog(
                                    context, state.classes[i]),
                                onDeleteSection: (sectionId) =>
                                    _confirmDeleteSection(context, sectionId),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 64, color: cs.outline),
          AppSpacing.vGapLg,
          Text(AppStrings.noClassesFound,
              style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.vGapSm,
          FilledButton.icon(
            onPressed: () => _showAddClassDialog(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.addFirstClass),
            style: FilledButton.styleFrom(backgroundColor: _accent),
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
              Icon(Icons.error_outline, size: 48, color: cs.error),
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
                  border: const OutlineInputBorder()),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: numericCtrl,
              decoration: InputDecoration(
                  labelText: AppStrings.sortOrderHint,
                  border: const OutlineInputBorder()),
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
              final numeric = int.tryParse(numericCtrl.text.trim());
              final ok = await ref
                  .read(schoolAdminClassesProvider.notifier)
                  .createClass(nameCtrl.text.trim(), numeric: numeric);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  AppSnackbar.success(context, AppStrings.classCreated);
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: Text(AppStrings.create),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditClassDialog(
      BuildContext context, SchoolClassModel cls) async {
    final nameCtrl = TextEditingController(text: cls.name);
    final numericCtrl =
        TextEditingController(text: cls.numeric?.toString() ?? '');
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
                  labelText: AppStrings.className, border: const OutlineInputBorder()),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: numericCtrl,
              decoration: InputDecoration(
                  labelText: AppStrings.sortOrder, border: const OutlineInputBorder()),
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
              final numeric = int.tryParse(numericCtrl.text.trim());
              final ok = await ref
                  .read(schoolAdminClassesProvider.notifier)
                  .updateClass(cls.id, nameCtrl.text.trim(), numeric: numeric);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _accent),
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
      message: 'Delete "${cls.name}"? All sections and students in this class will be affected.',
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
              border: const OutlineInputBorder()),
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
                  .createSection(cls.id, nameCtrl.text.trim().toUpperCase());
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  AppSnackbar.success(context, AppStrings.sectionCreated);
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _accent),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.15),
              child: Text(
                cls.numeric?.toString() ?? cls.name.substring(0, 1),
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(cls.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${cls.sections.length} section(s)  •  '
              '${cls.sections.fold(0, (sum, s) => sum + s.studentCount)} students',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: widget.onAddSection,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: AppStrings.addSection,
                  color: _accent,
                ),
                PopupMenuButton<String>(
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.edit),
                            title: Text(AppStrings.editClass))),
                    PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.delete, color: AppColors.error500),
                            title: Text(AppStrings.deleteClass,
                                style: const TextStyle(color: AppColors.error500)))),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') widget.onEditClass();
                    if (v == 'delete') widget.onDeleteClass();
                  },
                ),
                IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded && cls.sections.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cls.sections
                    .map((sec) => Chip(
                          label: Text(
                            '${sec.name}  (${sec.studentCount})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              widget.onDeleteSection(sec.id),
                          backgroundColor:
                              _accent.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: _accent.withValues(alpha: 0.3)),
                        ))
                    .toList(),
              ),
            ),
          ],
          if (_expanded && cls.sections.isEmpty) ...[
            const Divider(height: 1),
            const Padding(
              padding: AppSpacing.paddingMd,
              child: Text(
                'No sections yet. Tap + to add one.',
                style: TextStyle(color: AppColors.neutral400),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
