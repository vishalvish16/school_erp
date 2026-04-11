// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_fees_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/school_admin/fee_structure_model.dart';
import '../../../../models/school_admin/fee_payment_model.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

import '../providers/school_admin_fees_provider.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';

const Color _accent = AppColors.success500;

class SchoolAdminFeesScreen extends ConsumerStatefulWidget {
  const SchoolAdminFeesScreen({super.key});

  @override
  ConsumerState<SchoolAdminFeesScreen> createState() =>
      _SchoolAdminFeesScreenState();
}

class _SchoolAdminFeesScreenState extends ConsumerState<SchoolAdminFeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref.read(schoolAdminFeesProvider.notifier).loadStructures();
      ref.read(schoolAdminFeesProvider.notifier).loadPayments();
      ref.read(schoolAdminFeesProvider.notifier).loadSummary(month: month);
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await Future.wait([
      ref.read(schoolAdminFeesProvider.notifier).loadStructures(),
      ref.read(schoolAdminFeesProvider.notifier).loadPayments(),
      ref.read(schoolAdminFeesProvider.notifier).loadSummary(month: month),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final feesState = ref.watch(schoolAdminFeesProvider);
    final summary = feesState.summary;
    final totalCollected = summary.values
        .fold<double>(0, (sum, v) => sum + (v is num ? v.toDouble() : 0));

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16.0 : 24.0,
                  isNarrow ? 16.0 : 24.0,
                  isNarrow ? 16.0 : 24.0,
                  0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Fee Management',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        context.go('/school-admin/fees/collection'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppStrings.collectFee),
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                  ),
                ],
              ),
            ),

            // ── Stats row ──
            if (!isNarrow)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: MetricStatCard(
                        icon: Icons.payments_outlined,
                        value: '${feesState.structures.length}',
                        label: 'Fee Structures',
                        color: AppColors.secondary500,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: MetricStatCard(
                        icon: Icons.receipt_long_outlined,
                        value: '${feesState.payments.length}',
                        label: 'Payments',
                        color: AppColors.success500,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: MetricStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        value: totalCollected > 0
                            ? '₹${(totalCollected / 1000).toStringAsFixed(1)}K'
                            : '₹0',
                        label: 'Collected',
                        color: AppColors.warning500,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: MetricStatCard(
                        icon: Icons.pending_actions_outlined,
                        value: summary.isNotEmpty ? 'Active' : '—',
                        label: 'Status',
                        color: AppColors.info500,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 118,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  children: [
                    SizedBox(
                      width: 148,
                      child: MetricStatCard(
                        icon: Icons.payments_outlined,
                        value: '${feesState.structures.length}',
                        label: 'Fee Structures',
                        color: AppColors.secondary500,
                        compact: true,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    SizedBox(
                      width: 148,
                      child: MetricStatCard(
                        icon: Icons.receipt_long_outlined,
                        value: '${feesState.payments.length}',
                        label: 'Payments',
                        color: AppColors.success500,
                        compact: true,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    SizedBox(
                      width: 148,
                      child: MetricStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        value: totalCollected > 0
                            ? '₹${(totalCollected / 1000).toStringAsFixed(1)}K'
                            : '₹0',
                        label: 'Collected',
                        color: AppColors.warning500,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),

            AppSpacing.vGapMd,

            // ── Tab bar ──
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Fee Structures'),
                Tab(text: 'Payments'),
                Tab(text: 'Summary'),
              ],
            ),
            AppSpacing.vGapSm,

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FeeStructuresTab(),
                  _FeePaymentsTab(),
                  _FeeSummaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fee Structures Tab ────────────────────────────────────────────────────────

class _FeeStructuresTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminFeesProvider);
    final classesState = ref.watch(schoolAdminClassesProvider);
    final cs = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return AppLoaderScreen();
    }

    if (state.errorMessage != null) {
      return Center(
        child: Card(
          margin: AppSpacing.paddingXl,
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                AppSpacing.vGapMd,
                Text(state.errorMessage!, textAlign: TextAlign.center),
                AppSpacing.vGapLg,
                FilledButton(
                  onPressed: () => ref
                      .read(schoolAdminFeesProvider.notifier)
                      .loadStructures(),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => ref.read(schoolAdminFeesProvider.notifier).loadStructures(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
              AppSpacing.hGapSm,
              TextButton.icon(
                onPressed: () =>
                    _showAddStructureDialog(context, ref, classesState.classes),
                icon: const Icon(Icons.add, size: 16),
                label: Text(AppStrings.addFeeStructure),
              ),
            ],
          ),
        ),
        AppSpacing.vGapXs,
        if (state.structures.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: cs.outline),
                  AppSpacing.vGapLg,
                  Text('No fee structures defined',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: state.structures.length,
              itemBuilder: (ctx, i) => _FeeStructureCard(
                structure: state.structures[i],
                onDelete: () async {
                  final ok = await ref
                      .read(schoolAdminFeesProvider.notifier)
                      .deleteStructure(state.structures[i].id);
                  if (ok && ctx.mounted) {
                    AppToast.showSuccess(ctx, AppStrings.feeStructureDeleted);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  void _showAddStructureDialog(
      BuildContext context, WidgetRef ref, List classes) {
    final feeHeadCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2025-26');
    String frequency = 'ANNUALLY';
    String? classId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(AppStrings.addFeeStructure),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: feeHeadCtrl,
                    decoration: const InputDecoration(
                        labelText: AppStrings.feeHeadHint,
                        border: OutlineInputBorder()),
                  ),
                  AppSpacing.vGapMd,
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                        labelText: AppStrings.amountLabel,
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  AppSpacing.vGapMd,
                  TextField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Academic Year (e.g. 2025-26)',
                        border: OutlineInputBorder()),
                  ),
                  AppSpacing.vGapMd,
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    decoration: const InputDecoration(
                        labelText: AppStrings.frequency,
                        border: OutlineInputBorder()),
                    items: ['MONTHLY', 'QUARTERLY', 'ANNUALLY', 'ONE_TIME']
                        .map((f) =>
                            DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setSt(() => frequency = v!),
                  ),
                  AppSpacing.vGapMd,
                  DropdownButtonFormField<String?>(
                    initialValue: classId,
                    decoration: const InputDecoration(
                        labelText: AppStrings.classOptional,
                        border: OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text(AppStrings.allClasses)),
                      for (final c in classes)
                        DropdownMenuItem<String?>(
                            value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setSt(() => classId = v),
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
                final amount = double.tryParse(amountCtrl.text.trim());
                if (feeHeadCtrl.text.trim().isEmpty || amount == null) return;
                final data = {
                  'feeHead': feeHeadCtrl.text.trim(),
                  'amount': amount,
                  'academicYear': yearCtrl.text.trim(),
                  'frequency': frequency,
                  'classId': classId,
                };
                final ok = await ref
                    .read(schoolAdminFeesProvider.notifier)
                    .createStructure(data);
                if (ctx.mounted) {
                  if (ok) {
                    Navigator.of(ctx).pop();
                  } else {
                    final err = ref.read(schoolAdminFeesProvider).errorMessage;
                    AppToast.showError(ctx, err ?? AppStrings.failedToCreateFeeStructure);
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: Text(AppStrings.create),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeStructureCard extends StatelessWidget {
  const _FeeStructureCard({
    required this.structure,
    required this.onDelete,
  });
  final FeeStructureModel structure;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accent.withValues(alpha: 0.15),
          child: const Icon(Icons.payments, color: _accent, size: 20),
        ),
        title: Text(structure.feeHead,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${structure.academicYear}  •  ${structure.frequency}'
          '${structure.className != null ? '  •  ${structure.className}' : '  •  All Classes'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${structure.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _accent,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fee Payments Tab ──────────────────────────────────────────────────────────

class _FeePaymentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminFeesProvider);
    final cs = Theme.of(context).colorScheme;

    if (state.isLoadingPayments) {
      return AppLoaderScreen();
    }

    if (state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: cs.outline),
            AppSpacing.vGapLg,
            Text('No payments recorded',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.payments.length,
      itemBuilder: (ctx, i) => _PaymentCard(payment: state.payments[i]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final FeePaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success500.withValues(alpha: 0.15),
          child: const Icon(Icons.receipt, color: AppColors.success500, size: 20),
        ),
        title: Text(
          payment.studentName ?? 'Student',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${payment.feeHead}  •  ${payment.receiptNo}  •  ${payment.paymentMode}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${payment.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.success500,
              ),
            ),
            Text(
              _fmt(payment.paymentDate),
              style: Theme.of(context).textTheme.bodySmall,
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

// ── Fee Summary Tab ───────────────────────────────────────────────────────────

class _FeeSummaryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminFeesProvider);
    final summary = state.summary;
    final cs = Theme.of(context).colorScheme;

    if (summary.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: cs.outline),
            AppSpacing.vGapLg,
            Text('No summary data available',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Collection',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  AppSpacing.vGapLg,
                  ...summary.entries.map((e) => Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(child: Text(e.key.toString())),
                            Text(
                              '₹${e.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _accent,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
