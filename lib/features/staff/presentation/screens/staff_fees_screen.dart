// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_fees_screen.dart
// PURPOSE: Fee collection screen for Staff/Clerk portal.
//          Tab 1: Collect Fee form. Tab 2: Payment history with filters.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/staff/staff_payment_model.dart';
import '../../../../models/staff/staff_fee_structure_model.dart';
import '../providers/staff_fees_provider.dart';
import '../providers/staff_students_provider.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.secondary400;
const _pageSizeOptions = [10, 15, 25, 50];

class StaffFeesScreen extends ConsumerStatefulWidget {
  const StaffFeesScreen({super.key});

  @override
  ConsumerState<StaffFeesScreen> createState() => _StaffFeesScreenState();
}

class _StaffFeesScreenState extends ConsumerState<StaffFeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffFeesProvider.notifier).loadStructures();
      ref.read(staffFeesProvider.notifier).loadPayments(page: 1);
      ref.read(staffFeesProvider.notifier).loadSummary();
      ref.read(staffStudentsProvider.notifier).loadClasses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(staffFeesProvider.notifier).loadStructures();
        ref.read(staffFeesProvider.notifier).loadPayments(page: 1);
        ref.read(staffFeesProvider.notifier).loadSummary();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  16,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Fee Collection',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Collect Fee'),
                    Tab(text: 'Payment History'),
                  ],
                  indicatorColor: _accent,
                  labelColor: _accent,
                ),
              ),
              AppSpacing.vGapSm,

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CollectFeeTab(
                      onSuccess: () => _tabController.animateTo(1),
                    ),
                    const _PaymentHistoryTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Collect Fee Tab ───────────────────────────────────────────────────────────

class _CollectFeeTab extends ConsumerStatefulWidget {
  const _CollectFeeTab({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<_CollectFeeTab> createState() => _CollectFeeTabState();
}

class _CollectFeeTabState extends ConsumerState<_CollectFeeTab> {
  final _formKey = GlobalKey<FormState>();
  final _studentSearchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedFeeHead;
  String _academicYear = '2025-26';
  String _paymentMode = 'CASH';
  DateTime _paymentDate = DateTime.now();

  StaffPaymentModel? _lastReceipt;

  @override
  void dispose() {
    _studentSearchCtrl.dispose();
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feesState = ref.watch(staffFeesProvider);
    final studentsState = ref.watch(staffStudentsProvider);
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.vGapSm,

                if (_lastReceipt != null)
                  _ReceiptBanner(payment: _lastReceipt!),

                if (feesState.errorMessage != null)
                  Card(
                    child: Padding(
                      padding: AppSpacing.paddingXl,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48,
                              color:
                                  Theme.of(context).colorScheme.error),
                          AppSpacing.vGapLg,
                          Text(feesState.errorMessage!,
                              textAlign: TextAlign.center),
                          AppSpacing.vGapLg,
                          FilledButton(
                            onPressed: () {
                              ref
                                  .read(staffFeesProvider.notifier)
                                  .clearError();
                              ref
                                  .read(staffFeesProvider.notifier)
                                  .loadStructures();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Student',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge),
                          const SizedBox(height: 6),
                          _StudentSearchField(
                            controller: _studentSearchCtrl,
                            selectedStudentId: _selectedStudentId,
                            selectedStudentName: _selectedStudentName,
                            students: studentsState.students,
                            onStudentSelected: (id, name) {
                              setState(() {
                                _selectedStudentId = id;
                                _selectedStudentName = name;
                                _studentSearchCtrl.text = name;
                              });
                              ref
                                  .read(staffFeesProvider.notifier)
                                  .loadStructures(
                                      academicYear: _academicYear);
                            },
                            onSearchChanged: (query) {
                              ref
                                  .read(staffStudentsProvider.notifier)
                                  .setSearch(query);
                            },
                            validator: (v) => _selectedStudentId == null
                                ? 'Select a student'
                                : null,
                          ),
                          AppSpacing.vGapLg,

                          DropdownButtonFormField<String>(
                            initialValue: _selectedFeeHead,
                            decoration: const InputDecoration(
                              labelText: 'Fee Head',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                _buildFeeHeadItems(feesState.structures),
                            onChanged: (v) {
                              setState(() => _selectedFeeHead = v);
                              if (v != null) {
                                final match = feesState.structures
                                    .where((s) => s.feeHead == v)
                                    .firstOrNull;
                                if (match != null) {
                                  _amountCtrl.text =
                                      match.amount.toStringAsFixed(0);
                                }
                              }
                            },
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Select a fee head'
                                : null,
                          ),
                          AppSpacing.vGapLg,

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _academicYear,
                                  decoration: const InputDecoration(
                                    labelText: 'Academic Year',
                                    border: OutlineInputBorder(),
                                    hintText: '2025-26',
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _academicYear = v),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              AppSpacing.hGapMd,
                              Expanded(
                                child: TextFormField(
                                  controller: _amountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount (₹)',
                                    border: OutlineInputBorder(),
                                    prefixText: '₹ ',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(v.trim()) ==
                                        null) {
                                      return 'Invalid amount';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vGapLg,

                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _paymentDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(
                                          () => _paymentDate = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Date',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(
                                          Icons.calendar_today,
                                          size: 18),
                                    ),
                                    child: Text(
                                      _fmtDate(_paymentDate),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.hGapMd,
                              Expanded(
                                child:
                                    DropdownButtonFormField<String>(
                                  initialValue: _paymentMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Mode',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'CASH',
                                        child: Text('Cash')),
                                    DropdownMenuItem(
                                        value: 'UPI',
                                        child: Text('UPI')),
                                    DropdownMenuItem(
                                        value: 'BANK_TRANSFER',
                                        child: Text('Bank Transfer')),
                                    DropdownMenuItem(
                                        value: 'CHEQUE',
                                        child: Text('Cheque')),
                                  ],
                                  onChanged: (v) => setState(
                                      () => _paymentMode = v!),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vGapLg,

                          TextFormField(
                            controller: _remarksCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Remarks (optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          AppSpacing.vGapXl,

                          FilledButton.icon(
                            onPressed:
                                feesState.isCollecting ? null : _submit,
                            icon: feesState.isCollecting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.receipt_long),
                            label: Text(feesState.isCollecting
                                ? 'Processing...'
                                : 'Collect & Generate Receipt'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildFeeHeadItems(
      List<StaffFeeStructureModel> structures) {
    final heads = structures.map((s) => s.feeHead).toSet().toList();
    return heads
        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
        .toList();
  }

  Future<void> _submit() async {
    ref.read(staffFeesProvider.notifier).clearError();
    setState(() => _lastReceipt = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) return;

    final data = {
      'student_id': _selectedStudentId!,
      'fee_head': _selectedFeeHead!,
      'academic_year': _academicYear,
      'amount': amount,
      'payment_date':
          _paymentDate.toIso8601String().split('T').first,
      'payment_mode': _paymentMode,
      if (_remarksCtrl.text.trim().isNotEmpty)
        'remarks': _remarksCtrl.text.trim(),
    };

    final payment =
        await ref.read(staffFeesProvider.notifier).collectFee(data);

    if (payment != null && mounted) {
      setState(() => _lastReceipt = payment);
      _formKey.currentState?.reset();
      _amountCtrl.clear();
      _remarksCtrl.clear();
      setState(() {
        _selectedStudentId = null;
        _selectedStudentName = null;
        _selectedFeeHead = null;
        _studentSearchCtrl.clear();
        _paymentDate = DateTime.now();
        _paymentMode = 'CASH';
      });
      AppSnackbar.success(context, 'Receipt ${payment.receiptNo} generated');
    }
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Student Search Field ──────────────────────────────────────────────────────

class _StudentSearchField extends ConsumerStatefulWidget {
  const _StudentSearchField({
    required this.controller,
    required this.selectedStudentId,
    required this.selectedStudentName,
    required this.students,
    required this.onStudentSelected,
    required this.onSearchChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final String? selectedStudentId;
  final String? selectedStudentName;
  final List students;
  final void Function(String id, String name) onStudentSelected;
  final void Function(String query) onSearchChanged;
  final String? Function(String?) validator;

  @override
  ConsumerState<_StudentSearchField> createState() =>
      _StudentSearchFieldState();
}

class _StudentSearchFieldState extends ConsumerState<_StudentSearchField> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: const InputDecoration(
            hintText: 'Search by name or admission no...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search, size: 20),
          ),
          onChanged: (v) {
            setState(() => _showSuggestions = v.isNotEmpty);
            widget.onSearchChanged(v);
          },
          validator: widget.validator,
        ),
        if (_showSuggestions && widget.students.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.students.length.clamp(0, 6),
              itemBuilder: (ctx, i) {
                final s = widget.students[i];
                return ListTile(
                  dense: true,
                  title: Text(s.fullName,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${s.admissionNo}  •  ${s.className ?? ''}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  onTap: () {
                    setState(() => _showSuggestions = false);
                    widget.onStudentSelected(s.id, s.fullName);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Receipt Banner ────────────────────────────────────────────────────────────

class _ReceiptBanner extends StatelessWidget {
  const _ReceiptBanner({required this.payment});

  final StaffPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.success500.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.success500.withValues(alpha: 0.4)),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success500, size: 20),
              AppSpacing.hGapSm,
              Text(
                'Payment Collected Successfully',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.success500,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          _ReceiptRow('Receipt No', payment.receiptNo),
          _ReceiptRow('Student', payment.studentName ?? ''),
          _ReceiptRow('Fee Head', payment.feeHead),
          _ReceiptRow('Amount', '₹${payment.amount.toStringAsFixed(2)}'),
          _ReceiptRow('Mode', payment.paymentMode),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Payment History Tab ───────────────────────────────────────────────────────

class _PaymentHistoryTab extends ConsumerStatefulWidget {
  const _PaymentHistoryTab();

  @override
  ConsumerState<_PaymentHistoryTab> createState() =>
      _PaymentHistoryTabState();
}

class _PaymentHistoryTabState extends ConsumerState<_PaymentHistoryTab> {
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  bool get _hasFilters =>
      _monthCtrl.text.isNotEmpty || _yearCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _monthCtrl.clear();
    _yearCtrl.clear();
    ref.read(staffFeesProvider.notifier).setFilters(
          clearMonth: true,
          clearAcademicYear: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffFeesProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Filters
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 24, vertical: AppSpacing.sm),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _monthCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Month (e.g. 2025-06)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 10),
                        ),
                        onSubmitted: (v) => _applyFilters(),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 10),
                        ),
                        onSubmitted: (v) => _applyFilters(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _applyFilters,
                      style:
                          FilledButton.styleFrom(backgroundColor: _accent),
                      child: const Text('Filter'),
                    ),
                    if (_hasFilters)
                      TextButton.icon(
                        icon: const Icon(Icons.filter_alt_off, size: 18),
                        label: const Text('Clear filters'),
                        onPressed: _clearFilters,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 24),
            child: _buildPaymentContent(state),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentContent(StaffFeesState state) {
    if (state.isLoadingPayments && state.payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }

    if (state.errorMessage != null && state.payments.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(state.errorMessage!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref
                    .read(staffFeesProvider.notifier)
                    .loadPayments(page: 1),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                'No payments found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_hasFilters) ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: state.payments.length,
            itemBuilder: (ctx, i) =>
                _PaymentCard(payment: state.payments[i]),
          ),
        ),
        if (state.payments.isNotEmpty)
          Card(child: _buildPaginationRow(state)),
      ],
    );
  }

  Widget _buildPaginationRow(StaffFeesState state) {
    final cs = Theme.of(context).colorScheme;
    final pageSize = state.pageSize;
    final start =
        state.total == 0 ? 0 : ((state.currentPage - 1) * pageSize) + 1;
    final end = (state.currentPage * pageSize).clamp(0, state.total);

    Widget pageButton(String label,
        {required int page, bool active = false}) {
      final enabled =
          page != state.currentPage && page >= 1 && page <= state.totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled
                ? () => ref
                    .read(staffFeesProvider.notifier)
                    .goToPage(page)
                : null,
            child: Container(
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              alignment: Alignment.center,
              padding: AppSpacing.paddingHSm,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? cs.onPrimary
                      : enabled
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> pageNumbers() {
      final pages = <Widget>[];
      const maxVisible = 5;
      int rangeStart =
          (state.currentPage - (maxVisible ~/ 2)).clamp(1, state.totalPages);
      int rangeEnd =
          (rangeStart + maxVisible - 1).clamp(1, state.totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart =
            (rangeEnd - maxVisible + 1).clamp(1, state.totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages
            .add(pageButton('$i', page: i, active: i == state.currentPage));
      }
      return pages;
    }

    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final mutedStyle =
        textStyle.copyWith(color: cs.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral300)),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Showing $start to $end of ${state.total} entries',
              style: mutedStyle),
          AppSpacing.hGapXl,
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Show', style: mutedStyle),
              const SizedBox(width: 6),
              Container(
                height: 28,
                padding: AppSpacing.paddingHSm,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral400),
                  borderRadius: AppRadius.brXs,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        size: 18),
                    style:
                        textStyle.copyWith(color: cs.onSurface),
                    items: _pageSizeOptions
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(staffFeesProvider.notifier)
                            .setPageSize(v);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('entries', style: mutedStyle),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton('First', page: 1),
              pageButton('Previous', page: state.currentPage - 1),
              ...pageNumbers(),
              pageButton('Next', page: state.currentPage + 1),
              pageButton('Last', page: state.totalPages),
            ],
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    ref.read(staffFeesProvider.notifier).setFilters(
          month: _monthCtrl.text.trim().isEmpty
              ? null
              : _monthCtrl.text.trim(),
          academicYear: _yearCtrl.text.trim().isEmpty
              ? null
              : _yearCtrl.text.trim(),
        );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final StaffPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: () {},
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.success500.withValues(alpha: 0.15),
                    child: const Icon(Icons.receipt,
                        color: AppColors.success500, size: 20),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.studentName ?? 'Student',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${payment.feeHead}  •  ${payment.receiptNo}  •  ${payment.paymentMode}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
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
                        style:
                            Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
