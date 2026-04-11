// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_school_detail_screen.dart
// PURPOSE: Read-only detail view of a single school for group admin.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../models/group_admin/group_admin_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';

final _schoolDetailProvider = FutureProvider.autoDispose
    .family<GroupAdminSchoolDetailModel, String>((ref, id) {
  return ref.read(groupAdminServiceProvider).getSchoolById(id);
});

class GroupAdminSchoolDetailScreen extends ConsumerWidget {
  const GroupAdminSchoolDetailScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(_schoolDetailProvider(schoolId));
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_schoolDetailProvider(schoolId)),
      child: asyncDetail.when(
        loading: () => AppLoaderScreen(),
        error: (err, _) => Center(
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                AppSpacing.vGapLg,
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapLg,
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(_schoolDetailProvider(schoolId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/group-admin/schools'),
                      ),
                    ],
                  ),
                  // 1. Header card
                  _SectionCard(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold),
                                ),
                                AppSpacing.vGapXs,
                                Text(
                                  detail.code,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hGapMd,
                          _StatusChip(status: detail.status),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.vGapMd,

                  // 2. Contact card
                  _SectionCard(
                    title: AppStrings.contactInformation,
                    icon: Icons.contact_mail_outlined,
                    children: [
                      _InfoRow(label: 'Email', value: detail.email),
                      _InfoRow(label: 'Phone', value: detail.phone),
                      _InfoRow(label: 'City', value: detail.city),
                      _InfoRow(label: 'State', value: detail.state),
                      _InfoRow(label: 'Country', value: detail.country),
                      _InfoRow(label: 'Pin Code', value: detail.pinCode),
                    ],
                  ),
                  AppSpacing.vGapMd,

                  // 3. Academics card
                  _SectionCard(
                    title: AppStrings.academics,
                    icon: Icons.school_outlined,
                    children: [
                      _InfoRow(label: 'Board', value: detail.board),
                      _InfoRow(label: 'Timezone', value: detail.timezone),
                    ],
                  ),
                  AppSpacing.vGapMd,

                  // 4. Subscription card
                  _SubscriptionCard(detail: detail),
                  AppSpacing.vGapMd,

                  // 5. Users card
                  _SectionCard(
                    title: AppStrings.users,
                    icon: Icons.people_outlined,
                    children: [
                      _InfoRow(
                        label: 'Total Enrolled',
                        value: '${detail.userCount} users',
                      ),
                    ],
                  ),
                  AppSpacing.vGapMd,

                  // 6. School Admin card
                  _SectionCard(
                    title: AppStrings.schoolAdministrator,
                    icon: Icons.admin_panel_settings_outlined,
                    children: [
                      if (detail.schoolAdminName != null ||
                          detail.schoolAdminEmail != null) ...[
                        _InfoRow(
                            label: 'Name', value: detail.schoolAdminName),
                        _InfoRow(
                            label: 'Email', value: detail.schoolAdminEmail),
                      ] else
                        const Padding(
                          padding: AppSpacing.paddingVSm,
                          child: Text(
                            'No admin assigned',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.neutral400),
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.vGapXl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subscription Card ────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.detail});

  final GroupAdminSchoolDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysRemaining =
        detail.subscriptionEnd?.difference(now).inDays;
    final isExpired = (daysRemaining ?? 0) < 0 && daysRemaining != null;
    final isExpiringSoon = daysRemaining != null &&
        daysRemaining >= 0 &&
        daysRemaining < 30;

    final planColor = _planColor(detail.subscriptionPlan);

    return _SectionCard(
      title: AppStrings.subscription,
      icon: Icons.card_membership_outlined,
      children: [
        Row(
          children: [
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: planColor.withValues(alpha: 0.15),
                borderRadius: AppRadius.brSm,
                border:
                    Border.all(color: planColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                detail.subscriptionPlan,
                style: TextStyle(
                  color: planColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        if (detail.subscriptionStart != null)
          _InfoRow(
            label: 'Start Date',
            value: _formatDate(detail.subscriptionStart!),
          ),
        if (detail.subscriptionEnd != null)
          _InfoRow(
            label: 'End Date',
            value: _formatDate(detail.subscriptionEnd!),
          ),
        if (daysRemaining != null)
          _InfoRow(
            label: 'Days Remaining',
            value: isExpired ? 'Expired' : '$daysRemaining days',
            valueColor: isExpired ? AppColors.error500 : null,
          ),
        if (isExpiringSoon && !isExpired) ...[
          AppSpacing.vGapSm,
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: AppRadius.brMd,
              border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    color: Colors.amber, size: 18),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Subscription expires in $daysRemaining days.',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isExpired) ...[
          AppSpacing.vGapSm,
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error500.withValues(alpha: 0.10),
              borderRadius: AppRadius.brMd,
              border:
                  Border.all(color: AppColors.error500.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error500, size: 18),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Subscription has expired.',
                    style: TextStyle(
                        color: AppColors.error500, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _planColor(String plan) {
    switch (plan.toUpperCase()) {
      case 'PREMIUM':
        return AppColors.secondary500;
      case 'STANDARD':
        return Colors.teal;
      default:
        return AppColors.neutral400;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    this.title,
    this.icon,
    required this.children,
  });

  final String? title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    AppSpacing.hGapSm,
                  ],
                  Text(
                    title!,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              const Divider(height: 1),
              AppSpacing.vGapMd,
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String? value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status.toUpperCase() == 'ACTIVE'
        ? AppColors.success500
        : status.toUpperCase() == 'SUSPENDED'
            ? Colors.amber
            : AppColors.error500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
