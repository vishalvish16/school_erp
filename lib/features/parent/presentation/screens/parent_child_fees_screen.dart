// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_child_fees_screen.dart
// PURPOSE: Fee structure and payment history for one child.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/fee_payment_summary_model.dart';
import '../../../../models/parent/fee_structure_summary_model.dart';
import '../../data/parent_child_fees_provider.dart';
import '../../data/parent_child_detail_provider.dart';

const Color _accent = AppColors.success500;

class ParentChildFeesScreen extends ConsumerWidget {
  const ParentChildFeesScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(parentChildDetailProvider(studentId));
    final asyncFees = ref.watch(
      parentChildFeesProvider((studentId: studentId, academicYear: null)),
    );
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final padding = isWide ? AppSpacing.xl : AppSpacing.lg;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/parent/children/$studentId'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: AppStrings.back,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: asyncChild.when(
                    loading: () => const Text(AppStrings.childFees),
                    error: (_, _) => const Text(AppStrings.childFees),
                    data: (c) => Text(
                      c != null
                          ? '${AppStrings.childFees} — ${c.fullName}'
                          : AppStrings.childFees,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXl,

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  parentChildFeesProvider(
                    (studentId: studentId, academicYear: null),
                  ),
                ),
                child: asyncFees.when(
                  loading: () =>
                      AppLoaderScreen(),
                  error: (err, _) => _ErrorView(
                    error: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.invalidate(
                      parentChildFeesProvider(
                        (studentId: studentId, academicYear: null),
                      ),
                    ),
                  ),
                  data: (data) {
                    final payments = data['feePayments'] as List<FeePaymentSummaryModel>? ?? [];
                    final structure = data['feeStructure'] as List<FeeStructureSummaryModel>? ?? [];
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (structure.isNotEmpty) ...[
                            Text(
                              AppStrings.feeStructure,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            AppSpacing.vGapMd,
                            Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: structure.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final s = structure[i];
                                  return ListTile(
                                    title: Text(s.feeHead),
                                    trailing: Text(
                                      '₹${s.amount}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(s.frequency),
                                  );
                                },
                              ),
                            ),
                            AppSpacing.vGapXl,
                          ] else ...[
                            Text(
                              AppStrings.noFeeStructure,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            AppSpacing.vGapLg,
                          ],
                          Text(
                            AppStrings.feePayments,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          AppSpacing.vGapMd,
                          if (payments.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    AppStrings.noFeePayments,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            )
                          else
                            Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: payments.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final p = payments[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          _accent.withValues(alpha: 0.15),
                                      child: Icon(Icons.receipt,
                                          size: 20, color: _accent),
                                    ),
                                    title: Text(p.feeHead),
                                    subtitle: Text(
                                      '${p.receiptNo} • ${p.paymentMode}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${p.amount}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success600),
                                        ),
                                        Text(
                                          _formatDate(p.paymentDate),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(
              onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
