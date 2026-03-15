// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_notifications_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../providers/school_admin_notifications_provider.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SchoolAdminNotificationsScreen extends ConsumerStatefulWidget {
  const SchoolAdminNotificationsScreen({super.key});

  @override
  ConsumerState<SchoolAdminNotificationsScreen> createState() =>
      _SchoolAdminNotificationsScreenState();
}

class _SchoolAdminNotificationsScreenState
    extends ConsumerState<SchoolAdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(schoolAdminNotificationsProvider.notifier)
          .loadNotifications();
      ref
          .read(schoolAdminNotificationsProvider.notifier)
          .loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolAdminNotificationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(schoolAdminNotificationsProvider.notifier)
          .loadNotifications(refresh: true),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: AppRadius.brLg,
                            ),
                            child: Text(
                              '${state.unreadCount} new',
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
                    IconButton(
                      onPressed: () => ref
                          .read(schoolAdminNotificationsProvider.notifier)
                          .loadNotifications(refresh: true),
                      icon: const Icon(Icons.refresh),
                      tooltip: AppStrings.refresh,
                    ),
                  ],
                ),
              ),
              AppSpacing.vGapLg,
              if (state.isLoading)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: const ShimmerListLoadingWidget(itemCount: 8),
                  ),
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
                                    .read(schoolAdminNotificationsProvider
                                        .notifier)
                                    .loadNotifications(refresh: true),
                                child: Text(AppStrings.retry),
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
                          AppStrings.noNotifications,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount: state.notifications.length,
                    separatorBuilder: (ctx, i) => const SizedBox.shrink(),
                    itemBuilder: (ctx, i) {
                      final n = state.notifications[i];
                      final isRead = n['is_read'] as bool? ?? false;
                      final id = n['id'] as String? ?? '';
                      return _NotificationTile(
                        notification: n,
                        isRead: isRead,
                        onTap: isRead
                            ? null
                            : () => ref
                                .read(schoolAdminNotificationsProvider
                                    .notifier)
                                .markRead(id),
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
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final Map<String, dynamic> notification;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;
    final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : scheme.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: isRead
                ? scheme.surfaceContainerHighest
                : scheme.primaryContainer,
            child: Icon(
              Icons.notifications,
              size: 20,
              color: isRead ? scheme.onSurfaceVariant : scheme.primary,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isNotEmpty)
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (dt != null)
                Text(
                  _timeAgo(dt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
