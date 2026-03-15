// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_notices_screen.dart
// PURPOSE: Broadcast notices to all schools in the group. Full CRUD.
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _noticesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(groupAdminServiceProvider).getNotices();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupAdminNoticesScreen extends ConsumerWidget {
  const GroupAdminNoticesScreen({super.key});

  static const Color _accent = AppColors.warning300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_noticesProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_noticesProvider),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
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
                  FilledButton.icon(
                    onPressed: () => _showNoticeDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Notice'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapXl,

            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: asyncData.when(
                    loading: () =>
                        const ShimmerListLoadingWidget(itemCount: 8),
                    error: (err, _) => Card(
                      child: Padding(
                        padding: AppSpacing.paddingXl,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error),
                            AppSpacing.vGapMd,
                            const Text(AppStrings.couldNotLoadNotices),
                            AppSpacing.vGapMd,
                            FilledButton(
                              onPressed: () =>
                                  ref.invalidate(_noticesProvider),
                              child: const Text(AppStrings.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (data) {
                      final notices = (data['data'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];
                      if (notices.isEmpty) {
                        return _EmptyState(
                          onAdd: () => _showNoticeDialog(context, ref),
                        );
                      }
                      return ListView.builder(
                        itemCount: notices.length,
                        itemBuilder: (context, index) {
                          final n = notices[index];
                          return _NoticeCard(
                            notice: n,
                            onEdit: () => _showNoticeDialog(context, ref,
                                notice: n),
                            onDelete: () => _confirmDelete(
                                context, ref, n['id'] as String),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoticeDialog(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? notice}) {
    showDialog(
      context: context,
      builder: (ctx) => _NoticeDialog(
        notice: notice,
        onSaved: () {
          ref.invalidate(_noticesProvider);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteNoticeQuestion,
      message: 'This notice will be removed from all schools. This cannot be undone.',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(groupAdminServiceProvider).deleteNotice(id);
      ref.invalidate(_noticesProvider);
      if (context.mounted) {
        AppSnackbar.success(context, AppStrings.noticeDeleted);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to delete: $e');
      }
    }
  }
}

// ── Notice Card ────────────────────────────────────────────────────────────────

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPinned = notice['isPinned'] == true || notice['is_pinned'] == true;
    final targetRole = notice['targetRole'] ?? notice['target_role'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPinned) ...[
                  const Icon(Icons.push_pin, size: 16, color: AppColors.warning300),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    notice['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                AppSpacing.hGapSm,
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error500)),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, size: 20),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              notice['body'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (targetRole != null) ...[
                  _Chip(label: targetRole.toString().toUpperCase()),
                  AppSpacing.hGapSm,
                ],
                if (isPinned) ...[
                  _Chip(label: 'PINNED', color: AppColors.warning300),
                  AppSpacing.hGapSm,
                ],
                const Spacer(),
                Text(
                  _formatDate(notice['publishedAt'] ?? notice['published_at'] ??
                      notice['createdAt'] ?? notice['created_at'] ?? ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw).toLocal();
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${m[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color = Colors.blueGrey});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brXs,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: AppSpacing.xl2),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning300.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined,
                  size: 36, color: AppColors.warning300),
            ),
            AppSpacing.vGapLg,
            Text(AppStrings.noNoticesYet,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.vGapSm,
            Text(
              'Create a notice to broadcast information to all schools in your group.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create First Notice'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning300,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notice Dialog ──────────────────────────────────────────────────────────────

class _NoticeDialog extends ConsumerStatefulWidget {
  const _NoticeDialog({this.notice, required this.onSaved});

  final Map<String, dynamic>? notice;
  final VoidCallback onSaved;

  @override
  ConsumerState<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends ConsumerState<_NoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _isPinned = false;
  String? _targetRole;
  bool _submitting = false;

  final _roles = const [
    'school_admin',
    'teacher',
    'staff',
    'parent',
  ];

  @override
  void initState() {
    super.initState();
    final n = widget.notice;
    _titleCtrl = TextEditingController(text: n?['title'] ?? '');
    _bodyCtrl = TextEditingController(text: n?['body'] ?? '');
    _isPinned = n?['isPinned'] == true || n?['is_pinned'] == true;
    _targetRole = n?['targetRole'] ?? n?['target_role'];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final svc = ref.read(groupAdminServiceProvider);
    final body = {
      'title': _titleCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
      'is_pinned': _isPinned,
      if (_targetRole != null) 'target_role': _targetRole,
    };

    try {
      if (widget.notice != null) {
        await svc.updateNotice(widget.notice!['id'] as String, body);
      } else {
        await svc.createNotice(body);
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.notice != null;
    return AlertDialog(
      title: Text(isEdit ? AppStrings.editNotice : AppStrings.newNotice),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.titleRequired,
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              AppSpacing.vGapLg,
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.messageRequired,
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Message is required' : null,
              ),
              AppSpacing.vGapLg,
              DropdownButtonFormField<String?>(
                initialValue: _targetRole,
                decoration: const InputDecoration(
                  labelText: AppStrings.targetAudience,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text(AppStrings.allRoles)),
                  ..._roles.map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.replaceAll('_', ' ').toUpperCase()),
                      )),
                ],
                onChanged: (v) => setState(() => _targetRole = v),
              ),
              AppSpacing.vGapMd,
              CheckboxListTile(
                value: _isPinned,
                onChanged: (v) => setState(() => _isPinned = v ?? false),
                title: const Text(AppStrings.pinThisNotice),
                subtitle: const Text(AppStrings.pinnedNoticesTop),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Publish'),
        ),
      ],
    );
  }
}
