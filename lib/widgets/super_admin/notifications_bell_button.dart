// =============================================================================
// FILE: lib/widgets/super_admin/notifications_bell_button.dart
// PURPOSE: Bell icon with unread badge; tap shows notifications popover
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/super_admin_service.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

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
      barrierColor: AppColors.neutral300,
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (_items.isNotEmpty)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text(AppStrings.markAllRead),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _loading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ))
                  : _error != null
                      ? Padding(
                          padding: AppSpacing.paddingXl,
                          child: Text(_error!, textAlign: TextAlign.center),
                        )
                      : _items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.notifications_none, size: 48, color: Theme.of(context).colorScheme.outline),
                                    AppSpacing.vGapLg,
                                    Text(
                                      'No notifications',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: AppSpacing.paddingVSm,
                              itemCount: _items.length,
                              itemBuilder: (context, i) {
                                final n = _items[i];
                                final title = n['title'] ?? n['message'] ?? n['type'] ?? 'Notification';
                                final body = n['message'] ?? n['body'] ?? '';
                                final isRead = n['read'] == true || n['is_read'] == true;
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isRead
                                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                                        : Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      _iconForType(n['type']?.toString()),
                                      size: 20,
                                      color: isRead
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: body.isNotEmpty ? Text(body, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                                  onTap: () async {
                                    final id = n['id']?.toString();
                                    if (id != null) {
                                      try {
                                        await ref.read(superAdminServiceProvider).markNotificationRead(id);
                                        if (mounted) _load();
                                      } catch (_) {}
                                    }
                                  },
                                );
                              },
                            ),
            ),
            const Divider(height: 1),
            Padding(
              padding: AppSpacing.paddingMd,
              child: TextButton(
                onPressed: () {
                  widget.onViewAll();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text(AppStrings.viewAllNotifications),
              ),
            ),
          ],
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
