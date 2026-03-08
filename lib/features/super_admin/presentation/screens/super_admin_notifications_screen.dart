// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_notifications_screen.dart
// PURPOSE: Super Admin notifications — list with mark read, navigate by type
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/super_admin_service.dart';

class SuperAdminNotificationsScreen extends ConsumerStatefulWidget {
  const SuperAdminNotificationsScreen({super.key});

  @override
  ConsumerState<SuperAdminNotificationsScreen> createState() =>
      _SuperAdminNotificationsScreenState();
}

class _SuperAdminNotificationsScreenState
    extends ConsumerState<SuperAdminNotificationsScreen> {
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
      final service = ref.read(superAdminServiceProvider);
      final res = await service.getNotifications(page: 1, limit: 20);
      final list = res['data'] is List ? res['data'] as List : [];
      final pagination = res['pagination'] is Map ? res['pagination'] as Map : {};
      final total = pagination['total'] ?? list.length;
      if (mounted) {
        setState(() {
          _notifications = list
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
          _loading = false;
          _hasMore = _notifications.length < (total is int ? total : list.length + 1);
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
      final service = ref.read(superAdminServiceProvider);
      final res = await service.getNotifications(page: _page + 1, limit: 20);
      final list = res['data'] is List ? res['data'] as List : [];
      final pagination = res['pagination'] is Map ? res['pagination'] as Map : {};
      final total = pagination['total'] ?? 0;
      if (mounted) {
        setState(() {
          _page++;
          for (final e in list) {
            _notifications.add(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{});
          }
          _hasMore = _notifications.length < (total is int ? total : 0);
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      await ref.read(superAdminServiceProvider).markNotificationRead(id);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            if (n['id'] == id || n['id']?.toString() == id) {
              return {...n, 'is_read': true};
            }
            return n;
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(superAdminServiceProvider).markAllNotificationsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => {...n, 'is_read': true}).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> n) {
    final id = n['id']?.toString();
    final type = n['notification_type'] ?? n['type'] ?? '';
    final schoolId = n['school_id']?.toString();

    if (id != null) _markNotificationRead(id);

    switch (type.toString()) {
      case 'school_expiring':
        context.go('/super-admin/billing');
        break;
      case 'school_overdue':
        if (schoolId != null) {
          // Could show ResolveOverdueDialog - for now go to billing
          context.go('/super-admin/billing');
        } else {
          context.go('/super-admin/billing');
        }
        break;
      case 'login_failed':
        context.go('/super-admin/security');
        break;
      case 'school_created':
        if (schoolId != null) {
          context.go('/super-admin/schools');
          // Could show SchoolDetailDialog - for now go to schools
        } else {
          context.go('/super-admin/schools');
        }
        break;
      case 'plan_changed':
        context.go('/super-admin/plans');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (!_loading && _notifications.isNotEmpty)
                      TextButton.icon(
                        onPressed: _markAllRead,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark all read'),
                      ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: scheme.error),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_notifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: scheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _notifications.length) {
                        if (_hasMore && !_loadingMore) {
                          _loadMore();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final n = _notifications[index];
                      final isRead = n['is_read'] == true;
                      final title = n['title'] ?? n['message'] ?? 'Notification';
                      final message = n['message'] ?? n['body'] ?? '';
                      final createdAt = n['created_at'] ?? n['timestamp'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRead ? null : scheme.primaryContainer.withValues(alpha: 0.3),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              _iconForType(n['notification_type'] ?? n['type'] ?? ''),
                              size: 20,
                            ),
                          ),
                          title: Text(title),
                          subtitle: message.isNotEmpty ? Text(message) : null,
                          trailing: Text(
                            createdAt.toString().length > 10
                                ? createdAt.toString().substring(0, 10)
                                : createdAt.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => _handleNotificationTap(n),
                        ),
                      );
                    },
                    childCount: _notifications.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'school_expiring':
      case 'school_overdue':
        return Icons.schedule;
      case 'login_failed':
        return Icons.security;
      case 'school_created':
        return Icons.school;
      case 'plan_changed':
        return Icons.layers;
      default:
        return Icons.notifications;
    }
  }
}
