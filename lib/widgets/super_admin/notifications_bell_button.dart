// =============================================================================
// FILE: lib/widgets/super_admin/notifications_bell_button.dart
// PURPOSE: Bell icon with unread badge; tap shows notifications popover
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/super_admin_service.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_colors.dart';

class NotificationsBellButton extends ConsumerStatefulWidget {
  const NotificationsBellButton({super.key});

  @override
  ConsumerState<NotificationsBellButton> createState() =>
      _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends ConsumerState<NotificationsBellButton> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUnreadCount());
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    try {
      final count = await ref.read(superAdminServiceProvider).getUnreadNotificationCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _showNotificationsPopover() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => _NotificationsPopoverDialog(
        onViewAll: () {
          context.go('/super-admin/notifications');
        },
        onDismiss: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          if (mounted) _fetchUnreadCount();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _showNotificationsPopover,
          tooltip: 'Notifications',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: AppSpacing.paddingXs,
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.error500,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsPopoverDialog extends ConsumerStatefulWidget {
  const _NotificationsPopoverDialog({
    required this.onViewAll,
    required this.onDismiss,
  });

  final VoidCallback onViewAll;
  final VoidCallback onDismiss;

  @override
  ConsumerState<_NotificationsPopoverDialog> createState() =>
      _NotificationsPopoverDialogState();
}

class _NotificationsPopoverDialogState extends ConsumerState<_NotificationsPopoverDialog> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final service = ref.read(superAdminServiceProvider);
      final res = await service.getNotifications(page: 1, limit: 10);
      if (!mounted) return;
      final list = res['data'] is List ? res['data'] as List : [];
      setState(() {
        _items = list
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(superAdminServiceProvider).markAllNotificationsRead();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      widget.onDismiss();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass colors — match app-wide glass system
    final glassBg = isDark
        ? const Color(0xEB060D1C)
        : const Color(0xEBEFF6FF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.60);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : scheme.primary.withValues(alpha: 0.12);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.only(top: 70, right: 12, left: 12, bottom: 40),
      alignment: Alignment.topRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: glassBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined, size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (_items.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _markAllRead,
                            child: Text(
                              AppStrings.markAllRead,
                              style: TextStyle(fontSize: 12, color: scheme.primary),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: scheme.onSurfaceVariant),
                          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: dividerColor),

                  // ── Body ──────────────────────────────────────────────────
                  Flexible(
                    child: _loading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _error != null
                            ? Padding(
                                padding: AppSpacing.paddingXl,
                                child: Text(_error!, textAlign: TextAlign.center),
                              )
                            : _items.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.notifications_none_rounded,
                                              size: 44, color: scheme.outline),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No notifications',
                                            style: TextStyle(
                                                color: scheme.onSurfaceVariant, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, _) =>
                                        Divider(height: 1, color: dividerColor, indent: 56),
                                    itemBuilder: (context, i) {
                                      final n = _items[i];
                                      final title = n['title'] ??
                                          n['message'] ??
                                          n['type'] ??
                                          'Notification';
                                      final body = n['message'] ?? n['body'] ?? '';
                                      final isRead =
                                          n['read'] == true || n['is_read'] == true;
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 2),
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isRead
                                                ? scheme.surfaceContainerHighest
                                                    .withValues(alpha: 0.6)
                                                : scheme.primaryContainer,
                                          ),
                                          child: Icon(
                                            _iconForType(n['type']?.toString()),
                                            size: 18,
                                            color: isRead
                                                ? scheme.onSurfaceVariant
                                                : scheme.onPrimaryContainer,
                                          ),
                                        ),
                                        title: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isRead
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                            color: scheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: body.isNotEmpty
                                            ? Text(
                                                body,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: scheme.onSurfaceVariant),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : null,
                                        trailing: isRead
                                            ? null
                                            : Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: scheme.primary,
                                                ),
                                              ),
                                        onTap: () async {
                                          final id = n['id']?.toString();
                                          if (id != null) {
                                            try {
                                              await ref
                                                  .read(superAdminServiceProvider)
                                                  .markNotificationRead(id);
                                              if (mounted) _load();
                                            } catch (_) {}
                                          }
                                        },
                                      );
                                    },
                                  ),
                  ),

                  // ── Footer ────────────────────────────────────────────────
                  Divider(height: 1, color: dividerColor),
                  InkWell(
                    onTap: () {
                      widget.onViewAll();
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.viewAllNotifications,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'alert':
      case 'warning':
        return Icons.warning_amber;
      case 'billing':
      case 'payment':
        return Icons.payments;
      case 'school':
        return Icons.school;
      default:
        return Icons.notifications;
    }
  }
}
