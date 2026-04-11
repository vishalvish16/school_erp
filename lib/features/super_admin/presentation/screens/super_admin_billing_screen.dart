// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_billing_screen.dart
// PURPOSE: Super Admin billing — filters, search, row actions, export
// =============================================================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../features/schools/domain/models/pagination_model.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_screen_mobile_toolbar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';

import '../../../../widgets/super_admin/dialogs/assign_plan_dialog.dart';
import '../../../../widgets/super_admin/dialogs/renew_subscription_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

class SuperAdminBillingScreen extends ConsumerStatefulWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  ConsumerState<SuperAdminBillingScreen> createState() =>
      _SuperAdminBillingScreenState();
}

class _SuperAdminBillingScreenState extends ConsumerState<SuperAdminBillingScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<SuperAdminSchoolSubscriptionModel> _subscriptions = [];
  SuperAdminDashboardStatsModel? _stats;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  int? _expiringDays;
  /// Subscription status filter (billing API). Null = all.
  String? _statusFilter;
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

  Future<void> _load({bool append = false}) async {
    if (!mounted) return;
    if (append) {
      if (_loadingMore || _loading) return;
      if (_subscriptions.isNotEmpty &&
          _subscriptions.length >= _total &&
          _total > 0) {
        return;
      }
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final service = ref.read(superAdminServiceProvider);
      final requestPage = append
          ? (_subscriptions.length ~/ _pageSize) + 1
          : _page;
      if (append) {
        final result = await service.getSubscriptions(
          page: requestPage,
          limit: _pageSize,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          expiringDays: _expiringDays,
          status: _statusFilter,
        );
        if (mounted) {
          setState(() {
            final merged = [..._subscriptions, ...result.data];
            final seen = <String>{};
            _subscriptions = merged.where((s) => seen.add(s.id)).toList();
            _total = result.total;
            _totalPages = result.totalPages > 0
                ? result.totalPages
                : ((result.total / _pageSize).ceil()).clamp(1, 999);
            _loadingMore = false;
          });
        }
      } else {
        final results = await Future.wait([
          service.getSubscriptions(
            page: requestPage,
            limit: _pageSize,
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            expiringDays: _expiringDays,
            status: _statusFilter,
          ),
          service.getDashboardStats(),
        ]);
        final result =
            results[0] as PaginationModel<SuperAdminSchoolSubscriptionModel>;
        final stats = results[1] as SuperAdminDashboardStatsModel;
        if (mounted) {
          setState(() {
            _subscriptions = result.data;
            _total = result.total;
            _totalPages = result.totalPages > 0
                ? result.totalPages
                : ((result.total / _pageSize).ceil()).clamp(1, 999);
            _stats = stats;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (append) {
            _loadingMore = false;
          } else {
            _error = _parseError(e);
            _loading = false;
            _subscriptions = [];
          }
        });
      }
    }
  }

  bool get _hasMoreSubscriptions =>
      _subscriptions.isNotEmpty && _total > 0 && _subscriptions.length < _total;

  Future<void> _loadMoreSubscriptions() => _load(append: true);

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

  String _statusLabel(String raw) {
    if (raw.isEmpty) return raw;
    return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
  }

  /// Mobile-only: same strip pattern as Super Admin → Schools (pill search + 3 filter slots).
  Widget _buildMobileFilterCard() {
    return ListScreenMobileFilterStrip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListScreenMobilePillSearchField(
            controller: _searchController,
            hintText: AppStrings.searchSchools,
            onChanged: (_) => setState(() {}),
            onSubmitted: () {
              setState(() => _page = 1);
              _load();
            },
            onClear: () {
              _searchController.clear();
              setState(() => _page = 1);
              _load();
            },
          ),
          AppSpacing.vGapMd,
          ListScreenMobileFilterRow(
            children: [
              SearchableDropdownFormField<String?>.valueItems(
                value: _expiringDays != null ? '$_expiringDays' : null,
                valueItems: const [
                  MapEntry(null, 'All'),
                  MapEntry('30', 'Expiring'),
                ],
                hintText: AppStrings.expiring,
                decoration: listScreenMobileFilterFieldDecoration(context),
                onChanged: (v) {
                  setState(() {
                    _expiringDays = v != null ? int.tryParse(v) : null;
                    _page = 1;
                  });
                  _load();
                },
              ),
              SearchableDropdownFormField<String?>.valueItems(
                value: _statusFilter,
                valueItems: const [
                  MapEntry(null, 'All'),
                  MapEntry('active', 'Active'),
                  MapEntry('suspended', 'Suspended'),
                  MapEntry('expired', 'Expired'),
                ],
                hintText: AppStrings.status,
                decoration: listScreenMobileFilterFieldDecoration(context),
                onChanged: (v) {
                  setState(() {
                    _statusFilter = v;
                    _page = 1;
                  });
                  _load();
                },
              ),
              ListScreenMobileMoreFiltersButton(
                onPressed: _openBillingFiltersSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openBillingFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Expiring within 30 days'),
                trailing: _expiringDays == 30
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _expiringDays = 30;
                    _page = 1;
                  });
                  Navigator.pop(ctx);
                  _load();
                },
              ),
              ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: const Text('Show all subscriptions'),
                trailing: _expiringDays == null
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _expiringDays = null;
                    _page = 1;
                  });
                  Navigator.pop(ctx);
                  _load();
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _expiringDays = null;
                      _statusFilter = null;
                      _page = 1;
                    });
                    Navigator.pop(ctx);
                    _load();
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text(AppStrings.clearFilters),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionViewSheet(SuperAdminSchoolSubscriptionModel s) {
    final scheme = Theme.of(context).colorScheme;
    final isOverdue = s.endDate.isBefore(DateTime.now());
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.paddingOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.schoolName,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.vGapSm,
            Text(
              s.planName,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            AppSpacing.vGapLg,
            _subscriptionDetailRow(
              ctx,
              Icons.payments_outlined,
              'Monthly',
              '₹${s.monthlyAmount.toStringAsFixed(0)} / month',
            ),
            _subscriptionDetailRow(
              ctx,
              Icons.people_outline,
              'Students',
              '${s.studentCount}',
            ),
            _subscriptionDetailRow(
              ctx,
              Icons.calendar_today_outlined,
              'Renews',
              DateFormat('d MMM yyyy').format(s.endDate),
            ),
            _subscriptionDetailRow(
              ctx,
              Icons.info_outline,
              'Status',
              _statusLabel(s.status),
            ),
            if (isOverdue) ...[
              AppSpacing.vGapMd,
              Text(
                'Renewal date has passed — review payment.',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
            AppSpacing.vGapLg,
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionDetailRow(
    BuildContext ctx,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingStats() {
    final s = _stats ?? SuperAdminDashboardStatsModel();
    final now = DateTime.now();
    final expiring30 = _subscriptions.where((x) {
      final d = x.endDate.difference(now).inDays;
      return d >= 0 && d <= 30 && x.status != 'suspended';
    }).length;
    final overdueLocal =
        _subscriptions.where((x) => x.endDate.isBefore(now)).length;
    final expiringCount =
        s.expiringSchools.isNotEmpty ? s.expiringSchools.length : expiring30;
    final issueCount =
        s.overdueSchools.isNotEmpty ? s.overdueSchools.length : overdueLocal;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Match mobile filter card breakpoint (< 600): horizontal metric chips.
        final useRow = MediaQuery.sizeOf(context).width >= 600;
        final items = [
          (
            Icons.account_balance_wallet_outlined,
            _formatCurrency(s.mrr),
            'MRR',
            AppColors.secondary500,
          ),
          (
            Icons.trending_up,
            _formatArr(s.arr),
            'ARR',
            AppColors.success500,
          ),
          (
            Icons.schedule,
            '$expiringCount',
            'Expiring',
            AppColors.warning500,
          ),
          (
            Icons.warning_amber_rounded,
            '$issueCount',
            'Issue',
            AppColors.error500,
          ),
        ];
        if (useRow) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: MetricStatCard(
                    icon: items[i].$1,
                    value: items[i].$2,
                    label: items[i].$3,
                    color: items[i].$4,
                    compact: false,
                  ),
                ),
                if (i < items.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }
        // Mobile: horizontal scroll (matches design reference)
        return SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final e = items[i];
              return SizedBox(
                width: 148,
                child: MetricStatCard(
                  icon: e.$1,
                  value: e.$2,
                  label: e.$3,
                  color: e.$4,
                  compact: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  static const _columnWidths = [180.0, 100.0, 80.0, 100.0, 110.0, 100.0, 60.0];
  static const _tableContentWidth = 180.0 + 100 + 80 + 100 + 110 + 100 + 60 + 32;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
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
              if (isNarrow)
                ListScreenMobileHeader(
                  title: 'Billing & Subscriptions',
                  onExport: _exportBilling,
                  exportEnabled: !_loading,
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                        label: const Text('Export CSV'),
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
                  child: isNarrow
                      ? _buildMobileFilterCard()
                      : Card(
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
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md, vertical: 10),
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
                                    value: _expiringDays != null
                                        ? '$_expiringDays'
                                        : null,
                                    valueItems: const [
                                      MapEntry(null, 'All'),
                                      MapEntry('30', 'Expiring (30 days)'),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.expiring,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        _expiringDays =
                                            v != null ? int.tryParse(v) : null;
                                        _page = 1;
                                      });
                                      _load();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: SearchableDropdownFormField<String?>.valueItems(
                                    value: _statusFilter,
                                    valueItems: const [
                                      MapEntry(null, 'All'),
                                      MapEntry('active', 'Active'),
                                      MapEntry('suspended', 'Suspended'),
                                      MapEntry('expired', 'Expired'),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.status,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        _statusFilter = v;
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
                                      _statusFilter = null;
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isNarrow ? 16 : 24,
                            0,
                            isNarrow ? 16 : 24,
                            isNarrow ? 16 : 24,
                          ),
                          child: _buildContent(isWide),
                        ),
                      ),
                    ),
                    if (isNarrow && !_loading && _error == null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton(
                          onPressed: () =>
                              context.push('/super-admin/schools'),
                          tooltip: 'Schools',
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
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
      return AppLoaderScreen();
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
                        : _statusFilter != null
                            ? 'No subscriptions for this status'
                            : 'No subscriptions',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.isNotEmpty ||
                  _expiringDays != null ||
                  _statusFilter != null) ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _expiringDays = null;
                      _statusFilter = null;
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
    return MobileInfiniteScrollList(
      itemCount: _subscriptions.length,
      itemBuilder: (context, i) => _buildMobileCard(_subscriptions[i]),
      hasMore: _hasMoreSubscriptions,
      isLoadingMore: _loadingMore,
      onLoadMore: _loadMoreSubscriptions,
      loadingLabel: 'Loading more subscriptions…',
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
        DataCell(Center(
          child: HoverPopupMenu<String>(
            onSelected: (v) {
              if (v == 'edit') {
                _openAssignPlan(s);
              } else if (v == 'renew') {
                _openRenew(s);
              } else if (v == 'resolve') {
                _openResolve(s);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(AppStrings.editPlan),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'renew',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text(AppStrings.renew),
                  ],
                ),
              ),
              if (isOverdue)
                const PopupMenuItem(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18),
                      SizedBox(width: 8),
                      Text(AppStrings.resolve),
                    ],
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMobileCard(SuperAdminSchoolSubscriptionModel s) {
    final isOverdue = s.endDate.isBefore(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final Color statusBg;
    final Color statusFg;
    if (s.status == 'active') {
      statusBg = AppColors.success500.withValues(alpha: 0.15);
      statusFg = AppColors.success500;
    } else if (s.status == 'suspended' || isOverdue) {
      statusBg = AppColors.error500.withValues(alpha: 0.15);
      statusFg = AppColors.error500;
    } else {
      statusBg = AppColors.warning500.withValues(alpha: 0.18);
      statusFg = AppColors.warning500;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showSubscriptionViewSheet(s),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.schoolName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: AppRadius.brFull,
                          ),
                          child: Text(
                            _statusLabel(s.status),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.planName}  ·  ₹${s.monthlyAmount.toStringAsFixed(0)}/mo  ·  ${DateFormat('d MMM yy').format(s.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: scheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'edit') {
                    _openAssignPlan(s);
                  } else if (v == 'renew') {
                    _openRenew(s);
                  } else if (v == 'resolve') {
                    _openResolve(s);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit_outlined, size: 18),
                      title: Text(AppStrings.editPlan),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'renew',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.refresh, size: 18),
                      title: Text(AppStrings.renew),
                    ),
                  ),
                  if (isOverdue)
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.check_circle_outline, size: 18),
                        title: Text(AppStrings.resolve),
                      ),
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
    return ListPaginationBar(
      currentPage: _page,
      totalPages: _totalPages,
      totalEntries: _total,
      pageSize: _pageSize,
      pageSizeOptions: _pageSizeOptions,
      onPageSizeChanged: _onPageSizeChanged,
      onGoToPage: _goToPage,
    );
  }
}
