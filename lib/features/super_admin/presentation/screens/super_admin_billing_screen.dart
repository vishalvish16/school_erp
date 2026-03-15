// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_billing_screen.dart
// PURPOSE: Super Admin billing — filters, search, row actions, export
// =============================================================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../features/schools/domain/models/pagination_model.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/super_admin/dialogs/assign_plan_dialog.dart';
import '../../../../widgets/super_admin/dialogs/renew_subscription_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SuperAdminBillingScreen extends ConsumerStatefulWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  ConsumerState<SuperAdminBillingScreen> createState() =>
      _SuperAdminBillingScreenState();
}

class _SuperAdminBillingScreenState extends ConsumerState<SuperAdminBillingScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminSchoolSubscriptionModel> _subscriptions = [];
  SuperAdminDashboardStatsModel? _stats;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  int? _expiringDays;
  List<SuperAdminPlanModel> _plans = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  int _pageSize = 15;
  static const _pageSizeOptions = [10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPlans();
    _load();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _page = 1);
        _load();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final p = await ref.read(superAdminServiceProvider).getPlans();
      if (mounted) setState(() => _plans = p);
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final results = await Future.wait([
        service.getSubscriptions(
          page: _page,
          limit: _pageSize,
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          expiringDays: _expiringDays,
        ),
        service.getDashboardStats(),
      ]);
      final result = results[0] as PaginationModel<SuperAdminSchoolSubscriptionModel>;
      final stats = results[1] as SuperAdminDashboardStatsModel;
      if (mounted) {
        setState(() {
          _subscriptions = result.data;
          _total = result.total;
          _totalPages = result.totalPages > 0 ? result.totalPages : ((result.total / _pageSize).ceil()).clamp(1, 999);
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _parseError(e);
          _loading = false;
          _subscriptions = [];
        });
      }
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _page = page);
    _load();
  }

  void _onPageSizeChanged(int? value) {
    if (value == null || value == _pageSize) return;
    setState(() {
      _pageSize = value;
      _page = 1;
    });
    _load();
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      switch (e.response?.statusCode) {
        case 500:
          return AppStrings.serverErrorOccurred;
        case 404:
          return AppStrings.resourceNotFound;
        case 403:
          return AppStrings.accessDenied;
        case 401:
          return 'Session expired. Please log in again.';
        case 400:
          return data is Map && data['message'] != null
              ? data['message'] as String
              : 'Invalid request.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AppStrings.connectionTimedOut;
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Could not connect. Check your network and try again.';
      }
      return AppStrings.serverErrorOccurred;
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<void> _openRenew(SuperAdminSchoolSubscriptionModel s) async {
    showAdaptiveModal(
      context,
      RenewSubscriptionDialog(
        schoolName: s.schoolName,
        planName: s.planName,
        currentEndDate: s.endDate,
        monthlyAmount: s.monthlyAmount,
        onRenew: (months, paymentRef) async {
          await ref.read(superAdminServiceProvider).renewSubscription(s.schoolId, {
            'duration_months': months,
            'payment_ref': paymentRef,
            'plan_id': s.planId,
          });
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _openResolve(SuperAdminSchoolSubscriptionModel s) async {
    final days = s.endDate.isBefore(DateTime.now())
        ? DateTime.now().difference(s.endDate).inDays
        : 0;
    showAdaptiveModal(
      context,
      ResolveOverdueDialog(
        schoolName: s.schoolName,
        overdueDays: days,
        onResolve: (action, paymentRef) async {
          await ref.read(superAdminServiceProvider).resolveOverdue(
            s.schoolId,
            {'action': action, 'payment_ref': paymentRef},
          );
          if (mounted) _load();
        },
      ),
    );
  }

  void _openAssignPlan(SuperAdminSchoolSubscriptionModel s) {
    final plans = _plans.map((e) => {
      'id': e.id,
      'name': e.name,
      'price_per_student': e.pricePerStudent,
      'priceMonthly': e.pricePerStudent,
    }).toList();
    showAdaptiveModal(
      context,
      AssignPlanDialog(
        schoolName: s.schoolName,
        currentPlanName: s.planName,
        currentPlanId: s.planId,
        plans: plans,
        onAssign: (planId, effectiveDate, reason) async {
          await ref.read(superAdminServiceProvider).assignPlan(s.schoolId, {
            'plan_id': planId,
            'effective_date': effectiveDate?.toIso8601String(),
            'reason': reason,
          });
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _exportBilling() async {
    try {
      await ref.read(superAdminServiceProvider).exportBilling();
      if (mounted) {
        AppSnackbar.success(context, AppStrings.billingReportExported);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Export failed: ${_parseError(e)}');
      }
    }
  }

  String _formatCurrency(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _formatArr(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Widget _buildBillingStats() {
    final s = _stats ?? SuperAdminDashboardStatsModel();
    final now = DateTime.now();
    final expiring30 = _subscriptions.where((x) {
      final d = x.endDate.difference(now).inDays;
      return d >= 0 && d <= 30 && x.status != 'suspended';
    }).length;
    final overdue = _subscriptions.where((x) => x.endDate.isBefore(now)).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cards = [
          _billingStatCard(
            icon: Icons.payments,
            value: _formatCurrency(s.mrr),
            label: 'This Month MRR',
            color: AppColors.secondary500,
          ),
          _billingStatCard(
            icon: Icons.trending_up,
            value: _formatArr(s.arr),
            label: 'ARR',
            color: AppColors.success500,
          ),
          _billingStatCard(
            icon: Icons.schedule,
            value: '$expiring30',
            label: 'Expiring in 30 days',
            color: AppColors.warning500,
          ),
          _billingStatCard(
            icon: Icons.warning,
            value: '$overdue',
            label: 'Overdue / Suspended',
            color: AppColors.error500,
          ),
        ];
        if (isWide) {
          return Row(
            children: cards.map((c) => Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: c,
            ))).toList(),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: cards.map((c) => Padding(padding: const EdgeInsets.only(right: 0), child: c)).toList(),
        );
      },
    );
  }

  static Widget _billingStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              AppSpacing.vGapMd,
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppSpacing.vGapXs,
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _columnWidths = [180.0, 100.0, 80.0, 100.0, 110.0, 100.0, 180.0];
  static const _tableContentWidth = 180.0 + 100 + 80 + 100 + 110 + 100 + 180 + 32;

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _page = 1);
        await _load();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 24, isNarrow ? 16 : 24, isNarrow ? 16 : 24, 16,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Billing & Subscriptions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: _loading ? null : _exportBilling,
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(isNarrow ? 'Export' : 'Export CSV'),
                    ),
                  ],
                ),
              ),

              if (!_loading && _error == null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
                  child: _buildBillingStats(),
                ),

              AppSpacing.vGapLg,

              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: AppStrings.searchBySchoolNameHint,
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _page = 1);
                                          _load();
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                              ),
                              onSubmitted: (_) {
                                setState(() => _page = 1);
                                _load();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: SearchableDropdownFormField<String?>.valueItems(
                              value: _expiringDays != null ? '$_expiringDays' : null,
                              valueItems: const [
                                MapEntry(null, 'All'),
                                MapEntry('30', 'Expiring (30 days)'),
                              ],
                              decoration: const InputDecoration(
                                labelText: AppStrings.expiring,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _expiringDays = v != null ? int.tryParse(v) : null;
                                  _page = 1;
                                });
                                _load();
                              },
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.filter_alt_off, size: 18),
                            label: const Text(AppStrings.clearFilters),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _expiringDays = null;
                                _page = 1;
                              });
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              AppSpacing.vGapLg,

              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, isNarrow ? 16 : 24,
                    ),
                    child: _buildContent(isWide),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(bool isWide) {
    if (_loading && _subscriptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }
    if (_error != null && _subscriptions.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(_error!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
            ],
          ),
        ),
      );
    }
    if (_subscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchController.text.isNotEmpty
                    ? "No results for '${_searchController.text}'"
                    : _expiringDays != null
                        ? 'No expiring subscriptions found'
                        : 'No subscriptions',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.isNotEmpty || _expiringDays != null) ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _expiringDays = null;
                      _page = 1;
                    });
                    _load();
                  },
                  child: const Text(AppStrings.clearFilters),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return _buildSubscriptionList(isWide);
  }

  Widget _buildSubscriptionList(bool isWide) {
    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _tableContentWidth),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListTableView(
                    columns: const [
                      'School',
                      'Plan',
                      'Students',
                      'Monthly',
                      'Next Renewal',
                      'Status',
                      'Actions',
                    ],
                    columnWidths: _columnWidths,
                    showSrNo: false,
                    itemCount: _subscriptions.length,
                    rowBuilder: (i) => _buildDataRow(_subscriptions[i]),
                  ),
                ),
                _buildPaginationRow(),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: _subscriptions.map((s) => _buildMobileCard(s)).toList(),
          ),
        ),
        if (_subscriptions.isNotEmpty)
          Card(child: _buildPaginationRow()),
      ],
    );
  }

  DataRow _buildDataRow(SuperAdminSchoolSubscriptionModel s) {
    final isOverdue = s.endDate.isBefore(DateTime.now());
    return DataRow(
      cells: [
        DataCell(Text(s.schoolName, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Chip(
          label: Text(s.planName),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )),
        DataCell(Text('${s.studentCount}', style: const TextStyle(fontFamily: 'monospace'))),
        DataCell(Text(
          '₹${s.monthlyAmount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          ),
        )),
        DataCell(Text(
          DateFormat.yMMMd().format(s.endDate),
          style: TextStyle(
            color: isOverdue ? Theme.of(context).colorScheme.error : null,
            fontSize: 12,
          ),
        )),
        DataCell(Chip(
          label: Text(s.status),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: s.status == 'active'
              ? AppColors.success500.withValues(alpha: 0.2)
              : s.status == 'suspended' || isOverdue
                  ? AppColors.error500.withValues(alpha: 0.2)
                  : AppColors.warning500.withValues(alpha: 0.2),
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _openAssignPlan(s),
              child: const Text(AppStrings.editPlan),
            ),
            TextButton(
              onPressed: () => _openRenew(s),
              child: const Text(AppStrings.renew),
            ),
            if (isOverdue)
              FilledButton(
                onPressed: () => _openResolve(s),
                child: const Text(AppStrings.resolve),
              ),
          ],
        )),
      ],
    );
  }

  Widget _buildMobileCard(SuperAdminSchoolSubscriptionModel s) {
    final isOverdue = s.endDate.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openAssignPlan(s),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.schoolName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Chip(
                    label: Text(s.status, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: s.status == 'active'
                        ? AppColors.success500.withValues(alpha: 0.2)
                        : s.status == 'suspended' || isOverdue
                            ? AppColors.error500.withValues(alpha: 0.2)
                            : AppColors.warning500.withValues(alpha: 0.2),
                  ),
                ],
              ),
              AppSpacing.vGapSm,
              Text('${s.planName} • ${s.studentCount} students'),
              Text(
                '₹${s.monthlyAmount.toStringAsFixed(0)}/mo • Renews ${DateFormat.yMMMd().format(s.endDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? Theme.of(context).colorScheme.error : null,
                ),
              ),
              AppSpacing.vGapMd,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _openAssignPlan(s),
                    child: const Text(AppStrings.editPlan),
                  ),
                  TextButton(
                    onPressed: () => _openRenew(s),
                    child: const Text(AppStrings.renew),
                  ),
                  if (isOverdue)
                    FilledButton(
                      onPressed: () => _openResolve(s),
                      child: const Text(AppStrings.resolve),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    final cs = Theme.of(context).colorScheme;
    final start = _total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;
    final end = (_page * _pageSize).clamp(0, _total);

    Widget pageButton(String label, {required int page, bool active = false}) {
      final enabled = page != _page && page >= 1 && page <= _totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled ? () => _goToPage(page) : null,
            child: Container(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              alignment: Alignment.center,
              padding: AppSpacing.paddingHSm,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
      int rangeStart = (_page - (maxVisible ~/ 2)).clamp(1, _totalPages);
      int rangeEnd = (rangeStart + maxVisible - 1).clamp(1, _totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart = (rangeEnd - maxVisible + 1).clamp(1, _totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages.add(pageButton('$i', page: i, active: i == _page));
      }
      return pages;
    }

    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final mutedStyle = textStyle.copyWith(color: cs.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral300)),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Showing $start to $end of $_total entries', style: mutedStyle),
          AppSpacing.hGapXl,
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(AppStrings.show, style: mutedStyle),
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
                    value: _pageSize,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: textStyle.copyWith(color: cs.onSurface),
                    items: _pageSizeOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                    onChanged: _onPageSizeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(AppStrings.entries, style: mutedStyle),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton('First', page: 1),
              pageButton('Previous', page: _page - 1),
              ...pageNumbers(),
              pageButton('Next', page: _page + 1),
              pageButton('Last', page: _totalPages),
            ],
          ),
        ],
      ),
    );
  }
}
