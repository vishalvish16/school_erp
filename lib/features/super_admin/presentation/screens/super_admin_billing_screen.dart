// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_billing_screen.dart
// PURPOSE: Super Admin billing — filters, search, row actions, export
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/assign_plan_dialog.dart';
import '../../../../widgets/super_admin/dialogs/renew_subscription_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';

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
  final _searchController = TextEditingController();
  int? _expiringDays;
  List<SuperAdminPlanModel> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _load();
  }

  @override
  void dispose() {
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
      final result = await service.getSubscriptions(
        page: 1,
        limit: 50,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        expiringDays: _expiringDays,
      );
      if (mounted) {
        setState(() {
          _subscriptions = result.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _subscriptions = [];
        });
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Billing report exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Billing & Subscriptions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _loading ? null : _exportBilling,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by school name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _expiringDays == null,
                    onSelected: (_) {
                      setState(() => _expiringDays = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Expiring (30 days)'),
                    selected: _expiringDays == 30,
                    onSelected: (_) {
                      setState(() => _expiringDays = 30);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (_subscriptions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.payments_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? "No results for '${_searchController.text}'"
                            : 'No subscriptions',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              ..._subscriptions.map((s) {
                final isOverdue = s.endDate.isBefore(DateTime.now());
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(s.schoolName),
                    subtitle: Text('${s.planName} • ${s.studentCount} students'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${s.monthlyAmount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Ends: ${DateFormat.yMMMd().format(s.endDate)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isOverdue ? Colors.red : null,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _openAssignPlan(s),
                          child: const Text('Edit Plan'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _openRenew(s),
                          child: const Text('Renew'),
                        ),
                        if (isOverdue)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilledButton(
                              onPressed: () => _openResolve(s),
                              child: const Text('Resolve'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
