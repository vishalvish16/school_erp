// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_notifications_screen.dart
// PURPOSE: Notifications list for Parent portal (profile request approved/rejected).
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';


import '../providers/parent_notifications_provider.dart';

class ParentNotificationsScreen extends ConsumerStatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  ConsumerState<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState
    extends ConsumerState<ParentNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentNotificationsProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentNotificationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(parentNotificationsProvider.notifier).loadNotifications(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: Row(
                  children: [
                    Text(
                      AppStrings.notifications,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (state.unreadCount > 0) ...[
                      AppSpacing.hGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: AppRadius.brLg,
                        ),
                        child: Text(
                          '${state.unreadCount}',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.vGapLg,
              if (state.isLoading)
                Expanded(
                  child: AppLoaderScreen(),
                )
              else if (state.errorMessage != null)
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
                              Text(state.errorMessage!,
                                  textAlign: TextAlign.center),
                              AppSpacing.vGapLg,
                              FilledButton(
                                onPressed: () => ref
                                    .read(parentNotificationsProvider.notifier)
                                    .loadNotifications(),
                                child: const Text(AppStrings.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (state.notifications.isEmpty)
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
                    itemCount: state.notifications.length,
                    itemBuilder: (ctx, i) {
                      final n = state.notifications[i];
                      return _NotificationTile(
                        title: n.title,
                        message: n.body,
                        isRead: n.isRead,
                        createdAt: n.createdAt,
                        link: n.link,
                        onTap: () {
                          if (!n.isRead) {
                            ref
                                .read(parentNotificationsProvider.notifier)
                                .markRead(n.id);
                          }
                          if (n.link != null && n.link!.isNotEmpty) {
                            context.go(n.link!);
                          }
                        },
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
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.link,
    required this.onTap,
  });

  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : scheme.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRead ? Colors.transparent : scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      message,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      _timeAgo(createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
