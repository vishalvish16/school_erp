// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_notifications_screen.dart
// PURPOSE: Group Admin notifications — list, mark read on tap, type icons.
// Follows super_admin_notifications_screen.dart pattern exactly.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

class GroupAdminNotificationsScreen extends ConsumerStatefulWidget {
  const GroupAdminNotificationsScreen({super.key});

  @override
  ConsumerState<GroupAdminNotificationsScreen> createState() =>
      _GroupAdminNotificationsScreenState();
}

class _GroupAdminNotificationsScreenState
    extends ConsumerState<GroupAdminNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _notifications = [];
      _hasMore = true;
    });
    try {
      final service = ref.read(groupAdminServiceProvider);
      final res = await service.getNotifications(page: 1, limit: 20);
      final raw = res['data'];
      final list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List)
              ? raw['data'] as List
              : <dynamic>[];
      final pagination =
          res['pagination'] is Map ? res['pagination'] as Map : {};
      final total = pagination['total'] ?? list.length;
      if (mounted) {
        setState(() {
          _notifications = list
              .map((e) =>
                  e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
          _loading = false;
          _hasMore = _notifications.length <
              (total is int ? total : list.length + 1);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _notifications = [];
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || !mounted) return;
    setState(() => _loadingMore = true);
    try {
      final service = ref.read(groupAdminServiceProvider);
      final res =
          await service.getNotifications(page: _page + 1, limit: 20);
      final raw = res['data'];
      final list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List)
              ? raw['data'] as List
              : <dynamic>[];
      final pagination =
          res['pagination'] is Map ? res['pagination'] as Map : {};
      final total = pagination['total'] ?? 0;
      if (mounted) {
        setState(() {
          _page++;
          for (final e in list) {
            _notifications.add(e is Map
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{});
          }
          _hasMore =
              _notifications.length < (total is int ? total : 0);
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      await ref.read(groupAdminServiceProvider).markNotificationRead(id);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            if (n['id']?.toString() == id) {
              return {...n, 'is_read': true};
            }
            return n;
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _handleNotificationTap(Map<String, dynamic> n) {
    final id = n['id']?.toString();
    if (id != null) _markNotificationRead(id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
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
                      'Notifications',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGapLg,
              if (_loading)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: const ShimmerListLoadingWidget(itemCount: 8),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Card(
                        child: Padding(
                          padding: AppSpacing.paddingXl,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: scheme.error),
                              AppSpacing.vGapLg,
                              Text(_error!, textAlign: TextAlign.center),
                              AppSpacing.vGapLg,
                              FilledButton(
                                onPressed: _load,
                                child: const Text(AppStrings.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_notifications.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 64, color: scheme.outline),
                        AppSpacing.vGapLg,
                        Text(
                          'No notifications',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount:
                        _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        if (_hasMore && !_loadingMore) {
                          _loadMore();
                          return const Padding(
                            padding: AppSpacing.paddingLg,
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final n = _notifications[index];
                      final isRead = n['is_read'] == true;
                      final title =
                          n['title'] ?? n['message'] ?? 'Notification';
                      final body = n['body'] ?? n['message'] ?? '';
                      final type =
                          n['type'] ?? n['notification_type'] ?? '';
                      final createdAt =
                          n['created_at'] ?? n['timestamp'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRead
                            ? null
                            : scheme.primaryContainer
                                .withValues(alpha: 0.3),
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircleAvatar(
                              child: Icon(
                                _iconForType(type.toString()),
                                size: 20,
                              ),
                            ),
                          ),
                          title: Text(title.toString()),
                          subtitle: body.toString().isNotEmpty
                              ? Text(body.toString())
                              : null,
                          trailing: Text(
                            createdAt.toString().length > 10
                                ? createdAt.toString().substring(0, 10)
                                : createdAt.toString(),
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => _handleNotificationTap(n),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'success':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.notifications_outlined;
    }
  }
}
