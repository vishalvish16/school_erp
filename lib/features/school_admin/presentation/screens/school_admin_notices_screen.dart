// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_notices_screen.dart
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/school_notice_model.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../widgets/common/hover_popup_menu.dart';

import '../providers/school_admin_notices_provider.dart';

const Color _accent = AppColors.success500;

class SchoolAdminNoticesScreen extends ConsumerStatefulWidget {
  const SchoolAdminNoticesScreen({super.key});

  @override
  ConsumerState<SchoolAdminNoticesScreen> createState() =>
      _SchoolAdminNoticesScreenState();
}

class _SchoolAdminNoticesScreenState
    extends ConsumerState<SchoolAdminNoticesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminNoticesProvider.notifier).loadNotices();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(schoolAdminNoticesProvider.notifier).setSearch(value);
    });
  }

  bool get _hasActiveFilters => _searchCtrl.text.trim().isNotEmpty;

  void _clearFilters() {
    _searchCtrl.clear();
    _debounce?.cancel();
    ref.read(schoolAdminNoticesProvider.notifier).setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolAdminNoticesProvider);
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 600;
    final isWide = screenWidth >= AppBreakpoints.tablet;
    final pad = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(schoolAdminNoticesProvider.notifier)
          .loadNotices(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Notice Board',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showNoticeDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppStrings.newNotice),
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                  ),
                ],
              ),
            ),

            // ── Search / Filters ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchNotices,
                            prefixIcon:
                                const Icon(Icons.search, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: _clearFilters,
                                  )
                                : null,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.brMd,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {});
                            _onSearchChanged(v);
                          },
                        ),
                      ),
                      const Spacer(),
                      if (_hasActiveFilters)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off, size: 18),
                          label: Text(AppStrings.clearFilters),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 900 : double.infinity,
                    ),
                    child: _buildContent(state, cs),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(dynamic state, ColorScheme cs) {
    if (state.isLoading) {
      return AppLoaderScreen();
    }

    if (state.errorMessage != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                AppSpacing.vGapLg,
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapLg,
                FilledButton(
                  onPressed: () => ref
                      .read(schoolAdminNoticesProvider.notifier)
                      .loadNotices(refresh: true),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.notices.isEmpty) {
      final hasFilters = _hasActiveFilters;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: cs.outline),
            AppSpacing.vGapLg,
            Text(
              hasFilters
                  ? 'No notices match your search'
                  : 'No notices yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.vGapSm,
            if (hasFilters)
              TextButton(
                onPressed: _clearFilters,
                child: Text(AppStrings.clearFilters),
              )
            else
              FilledButton.icon(
                onPressed: () => _showNoticeDialog(context),
                icon: const Icon(Icons.add),
                label: Text(AppStrings.postFirstNotice),
                style: FilledButton.styleFrom(backgroundColor: _accent),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.notices.length,
      itemBuilder: (ctx, i) => _NoticeCard(
        notice: state.notices[i],
        onEdit: () =>
            _showNoticeDialog(context, notice: state.notices[i]),
        onDelete: () => _confirmDelete(context, state.notices[i]),
      ),
    );
  }

  Future<void> _showNoticeDialog(BuildContext context,
      {SchoolNoticeModel? notice}) async {
    final titleCtrl =
        TextEditingController(text: notice?.title ?? '');
    final bodyCtrl =
        TextEditingController(text: notice?.body ?? '');
    String? targetRole = notice?.targetRole;
    bool isPinned = notice?.isPinned ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(notice == null ? AppStrings.newNotice : AppStrings.editNotice),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                        labelText: AppStrings.title, border: const OutlineInputBorder()),
                  ),
                  AppSpacing.vGapMd,
                  TextField(
                    controller: bodyCtrl,
                    decoration: InputDecoration(
                        labelText: AppStrings.content, border: const OutlineInputBorder()),
                    maxLines: 5,
                  ),
                  AppSpacing.vGapMd,
                  DropdownButtonFormField<String?>(
                    initialValue: targetRole,
                    decoration: InputDecoration(
                        labelText: AppStrings.targetAudience,
                        border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text(AppStrings.everyone)),
                      DropdownMenuItem<String?>(
                          value: 'teacher', child: Text(AppStrings.teachers)),
                      DropdownMenuItem<String?>(
                          value: 'student', child: Text(AppStrings.students)),
                      DropdownMenuItem<String?>(
                          value: 'parent', child: Text(AppStrings.parents)),
                    ],
                    onChanged: (v) => setSt(() => targetRole = v),
                  ),
                  AppSpacing.vGapSm,
                  SwitchListTile(
                    title: Text(AppStrings.pinNotice),
                    value: isPinned,
                    onChanged: (v) => setSt(() => isPinned = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.cancel)),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    bodyCtrl.text.trim().isEmpty) {
                  return;
                }
                final data = {
                  'title': titleCtrl.text.trim(),
                  'body': bodyCtrl.text.trim(),
                  'target_role': targetRole,
                  'is_pinned': isPinned,
                };
                bool ok;
                if (notice == null) {
                  ok = await ref
                      .read(schoolAdminNoticesProvider.notifier)
                      .createNotice(data);
                } else {
                  ok = await ref
                      .read(schoolAdminNoticesProvider.notifier)
                      .updateNotice(notice.id, data);
                }
                if (ok && ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: Text(notice == null ? AppStrings.publish : AppStrings.update),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SchoolNoticeModel notice) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteNoticeQuestion,
      message: 'Remove "${notice.title}"?',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(schoolAdminNoticesProvider.notifier)
        .deleteNotice(notice.id);
    if (context.mounted) {
      AppToast.showSuccess(context, AppStrings.noticeDeleted);
    }
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });
  final SchoolNoticeModel notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isPinned) ...[
                  const Icon(Icons.push_pin, size: 14, color: _accent),
                  AppSpacing.hGapXs,
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                HoverPopupMenu<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(AppStrings.edit),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.delete_outline,
                            color: AppColors.error500),
                        title: Text(AppStrings.delete,
                            style: const TextStyle(
                                color: AppColors.error500)),
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notice.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            AppSpacing.vGapSm,
            Row(
              children: [
                if (notice.targetRole != null)
                  _Chip(
                    label: notice.targetRole!.toUpperCase(),
                    color: AppColors.secondary500,
                  ),
                const Spacer(),
                Text(
                  _fmt(notice.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
