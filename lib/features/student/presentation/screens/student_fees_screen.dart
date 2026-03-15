// =============================================================================
// FILE: lib/features/student/presentation/screens/student_fees_screen.dart
// PURPOSE: Fees screen for the Student portal — Fee Dues and Payment History.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

const Color _accent = AppColors.info500;

class StudentFeesScreen extends ConsumerStatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  ConsumerState<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends ConsumerState<StudentFeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          child: Row(
            children: [
              Text(
                AppStrings.studentFeesTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        TabBar(
          controller: _tabController,
          labelColor: _accent,
          indicatorColor: _accent,
          tabs: const [
            Tab(text: AppStrings.feeDues),
            Tab(text: AppStrings.paymentHistory),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FeeDuesTab(padding: padding),
              _PaymentHistoryTab(padding: padding),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeeDuesTab extends ConsumerWidget {
  const _FeeDuesTab({required this.padding});

  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDues = ref.watch(studentFeeDuesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentFeeDuesProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncDues.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Card(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  AppSpacing.vGapLg,
                  Text(err.toString().replaceAll('Exception: ', '')),
                  AppSpacing.vGapLg,
                  FilledButton(
                    onPressed: () => ref.invalidate(studentFeeDuesProvider),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (dues) {
            if (dues.dues.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                    AppSpacing.vGapLg,
                    Text(
                      AppStrings.noFeeDues,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dues.academicYear.isNotEmpty)
                  Text(
                    '${AppStrings.dash} ${dues.academicYear}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                AppSpacing.vGapMd,
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dues.dues.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final d = dues.dues[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _accent.withValues(alpha: 0.15),
                          child: const Icon(Icons.receipt_long, size: 18, color: _accent),
                        ),
                        title: Text(d.feeHead),
                        subtitle: d.dueDate != null ? Text(d.dueDate!) : null,
                        trailing: Text(
                          '₹${d.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AppSpacing.vGapMd,
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Due',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '₹${dues.totalDue.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _showReceiptDialog(BuildContext context, WidgetRef ref, String receiptNo) {
  showDialog(
    context: context,
    builder: (ctx) => _ReceiptDialog(receiptNo: receiptNo),
  );
}

class _ReceiptDialog extends ConsumerWidget {
  const _ReceiptDialog({required this.receiptNo});

  final String receiptNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReceipt = ref.watch(studentReceiptProvider(receiptNo));
    return AlertDialog(
      title: Text('${AppStrings.viewReceipt} - $receiptNo'),
      content: asyncReceipt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(e.toString()),
        data: (r) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.dash} ${r.feeHead}: ₹${r.amount.toStringAsFixed(0)}'),
            Text('${AppStrings.dash} ${r.paymentDate} • ${r.paymentMode}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.close),
        ),
      ],
    );
  }
}

class _PaymentHistoryTab extends ConsumerWidget {
  const _PaymentHistoryTab({required this.padding});

  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(_feePaymentsPageProvider);
    final asyncPayments = ref.watch(studentFeePaymentsProvider(page));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentFeePaymentsProvider(page));
        ref.invalidate(_feePaymentsPageProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncPayments.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Card(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  AppSpacing.vGapLg,
                  Text(err.toString().replaceAll('Exception: ', '')),
                  AppSpacing.vGapLg,
                  FilledButton(
                    onPressed: () => ref.invalidate(studentFeePaymentsProvider(page)),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (raw) {
            final data = raw['data'];
            final pagination = raw['pagination'] as Map<String, dynamic>?;
            final list = data is List ? data : [];
            final totalPages = (pagination?['total_pages'] as num?)?.toInt() ?? 1;
            final currentPage = (pagination?['page'] as num?)?.toInt() ?? 1;

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                    AppSpacing.vGapLg,
                    Text(
                      AppStrings.noPaymentsYet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final p = list[i];
                      final feeHead = p['fee_head'] ?? '';
                      final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                      final paymentDate = p['payment_date'] ?? '';
                      final receiptNo = p['receipt_no'] ?? '';
                      final paymentMode = p['payment_mode'] ?? 'CASH';
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.success500.withValues(alpha: 0.15),
                          child: const Icon(Icons.check_circle, size: 18, color: AppColors.success500),
                        ),
                        title: Text(feeHead),
                        subtitle: Text('$receiptNo • $paymentMode'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success500,
                              ),
                            ),
                            Text(
                              paymentDate,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () => _showReceiptDialog(context, ref, receiptNo),
                      );
                    },
                  ),
                ),
                if (totalPages > 1) ...[
                  AppSpacing.vGapLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: currentPage > 1
                            ? () => ref.read(_feePaymentsPageProvider.notifier).state = currentPage - 1
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${AppStrings.dash} $currentPage / $totalPages ${AppStrings.dash}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        onPressed: currentPage < totalPages
                            ? () => ref.read(_feePaymentsPageProvider.notifier).state = currentPage + 1
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

final _feePaymentsPageProvider = StateProvider<int>((ref) => 1);
