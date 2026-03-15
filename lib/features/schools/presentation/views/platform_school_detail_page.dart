import 'package:flutter/material.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:intl/intl.dart';
import '../viewmodels/school_detail_viewmodel.dart';
import '../../domain/models/school_model.dart';
import '../../domain/models/subscription_models.dart';
import '../../../../shared/widgets/reusable_data_table.dart';
import 'assign_plan_dialog.dart';
import 'subscription_history_modal.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class PlatformSchoolDetailPage extends ConsumerWidget {
  final String schoolId;

  const PlatformSchoolDetailPage({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolDetailViewModelProvider(schoolId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkSurface
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(AppStrings.schoolDetails),
        actions: [
          Tooltip(
            message: AppStrings.tooltipRefresh,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref
                  .read(schoolDetailViewModelProvider(schoolId).notifier)
                  .fetchSchool(),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(AppStrings.errorWithMessage(err.toString()))),
        data: (school) => SingleChildScrollView(
          padding: AppSpacing.paddingXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, school),
              AppSpacing.vGapXl2,

              _buildSectionHeader(
                AppStrings.subscriptionInformation,
                Icons.card_membership,
              ),
              AppSpacing.vGapLg,

              _SubscriptionCard(school: school),
              AppSpacing.vGapXl2,

              if (school.subscriptionHistory.isNotEmpty) ...[
                _buildSectionHeader(AppStrings.subscriptionHistory, Icons.history),
                AppSpacing.vGapLg,
                _SubscriptionHistoryTable(history: school.subscriptionHistory),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: AppRadius.brXs,
          ),
        ),
        AppSpacing.hGapMd,
        Icon(icon, size: 20, color: Colors.indigo),
        AppSpacing.hGapSm,
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, SchoolModel school) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brXl,
        side: BorderSide(color: AppColors.neutral400.withOpacity(0.2)),
      ),
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo.shade100,
              child: Text(
                school.name.isEmpty
                    ? 'S'
                    : school.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  school.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppStrings.schoolCodeLabel(school.schoolCode),
                  style: TextStyle(color: AppColors.neutral600),
                ),
                AppSpacing.vGapMd,
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: school.status),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.neutral600,
                        ),
                        AppSpacing.hGapXs,
                        Text(
                          '${school.city ?? AppStrings.notAvailable}, ${school.state ?? AppStrings.notAvailable}',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final SchoolModel school;

  const _SubscriptionCard({required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = school.activeSubscription;
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: AppColors.neutral200,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.brXl3,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildInfoColumn(
                  'Plan Name',
                  sub?.planName ?? 'No Plan Assigned',
                  isBold: true,
                ),
                _buildInfoColumn(AppStrings.tableBilling, sub?.billingCycle ?? AppStrings.notAvailable),
                StatusBadge(status: sub?.status ?? 'NONE'),
              ],
            ),
            const Divider(height: 48),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildInfoColumn(
                  'Start Date',
                  sub != null
                      ? DateFormat('MMM dd, yyyy').format(sub.startDate)
                      : AppStrings.notAvailable,
                ),
                _buildInfoColumn(
                  'End Date',
                  sub != null
                      ? DateFormat('MMM dd, yyyy').format(sub.endDate)
                      : AppStrings.notAvailable,
                ),
                _buildRemainingColumn(sub?.daysRemaining ?? 0),
              ],
            ),
            AppSpacing.vGapXl2,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SubActionButton(
                  label: 'Change Plan',
                  icon: Icons.swap_horiz,
                  onPressed: () => _showChangePlanDialog(context, ref),
                ),
                _SubActionButton(
                  label: 'Extend',
                  icon: Icons.timer_outlined,
                  onPressed: sub != null
                      ? () =>
                            _showExtendDialog(context, ref, sub.subscriptionId)
                      : null,
                ),
                _SubActionButton(
                  label: sub?.status == 'SUSPENDED' ? 'Activate' : 'Suspend',
                  icon: sub?.status == 'SUSPENDED'
                      ? Icons.play_arrow
                      : Icons.pause,
                  color: sub?.status == 'SUSPENDED'
                      ? AppColors.success500
                      : AppColors.warning500,
                  onPressed: sub != null
                      ? () => _toggleStatus(context, ref, sub.subscriptionId)
                      : null,
                ),
                _SubActionButton(
                  label: 'View History',
                  icon: Icons.history,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SubscriptionHistoryModal(
                        history: school.subscriptionHistory,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
        AppSpacing.vGapXs,
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingColumn(int days) {
    final color = days < 7
        ? AppColors.error500
        : (days < 30 ? AppColors.warning500 : AppColors.success500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days Remaining',
          style: TextStyle(fontSize: 12, color: AppColors.neutral400),
        ),
        AppSpacing.vGapXs,
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.brMd,
          ),
          child: Text(
            '$days Days',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePlanDialog(BuildContext context, WidgetRef ref) {
    final sub = school.activeSubscription;
    showDialog(
      context: context,
      builder: (context) => AssignPlanDialog(
        schoolId: school.id,
        currentPlanId: sub?.planId != null ? int.tryParse(sub!.planId) : school.planId,
        currentPlanName: sub?.planName ?? school.planName,
      ),
    );
  }

  void _showExtendDialog(BuildContext context, WidgetRef ref, String subId) {
    int months = 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Extend Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter number of months to extend:'),
            AppSpacing.vGapLg,
            SearchableDropdownFormField<int>.valueItems(
              value: months,
              valueItems: List.generate(12, (i) => MapEntry(i + 1, '${i + 1} Months')),
              onChanged: (v) => months = v ?? 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(schoolDetailViewModelProvider(school.id).notifier)
                  .extendSubscription(subId, months);
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(BuildContext context, WidgetRef ref, String subId) async {
    await ref
        .read(schoolDetailViewModelProvider(school.id).notifier)
        .toggleSubscriptionStatus(subId);
  }
}

class _SubActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const _SubActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
      ),
    );
  }
}

class _SubscriptionHistoryTable extends StatelessWidget {
  final List<SubscriptionHistoryModel> history;

  const _SubscriptionHistoryTable({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brXl,
        side: BorderSide(color: AppColors.neutral400.withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final h = history[index];
          return ListTile(
            title: Text(
              h.planName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${DateFormat('MMM dd, yyyy').format(h.startDate)} - ${DateFormat('MMM dd, yyyy').format(h.endDate)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: h.status),
                AppSpacing.vGapXs,
                Text(h.billingCycle, style: const TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }
}
