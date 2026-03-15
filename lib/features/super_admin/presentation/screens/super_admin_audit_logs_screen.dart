// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_audit_logs_screen.dart
// PURPOSE: Super Admin audit logs — tabs, search, date range, infinite scroll
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const List<String> _auditTypes = [
  'super-admin',
  'schools',
  'plans',
  'billing',
  'features',
  'security',
  'hardware',
  'groups',
];

class SuperAdminAuditLogsScreen extends ConsumerStatefulWidget {
  const SuperAdminAuditLogsScreen({super.key});

  @override
  ConsumerState<SuperAdminAuditLogsScreen> createState() =>
      _SuperAdminAuditLogsScreenState();
}

class _SuperAdminAuditLogsScreenState extends ConsumerState<SuperAdminAuditLogsScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<SuperAdminAuditLogModel> _logs = [];
  String _selectedType = 'super-admin';
  int _page = 1;
  int _totalPages = 1;
  final _searchController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (!mounted) return;
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; });
    }
    try {
      final service = ref.read(superAdminServiceProvider);
      final result = await service.getAuditLogs(
        _selectedType,
        page: reset ? 1 : _page,
        limit: 30,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _logs = result.data;
          } else {
            _logs = [..._logs, ...result.data];
          }
          _totalPages = result.totalPages;
          _page = result.page;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _loadingMore = false;
          if (reset) _logs = [];
        });
      }
    }
  }

  void _loadMore() {
    if (_loadingMore || _loading || _page >= _totalPages) return;
    setState(() {
      _loadingMore = true;
      _page = _page + 1;
    });
    _load(reset: false);
  }

  void _showLogDetail(SuperAdminAuditLogModel log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(log.action),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(AppStrings.actor, log.actorName ?? '—'),
              _detailRow(AppStrings.ip, log.actorIp ?? '—'),
              _detailRow(AppStrings.entity, log.entityName ?? '—'),
              _detailRow(AppStrings.auditType, log.entityType ?? '—'),
              if (log.description != null) _detailRow(AppStrings.auditDescription, log.description!),
              _detailRow(AppStrings.status, log.status ?? '—'),
              _detailRow(AppStrings.date, DateFormat.yMMMd().add_Hm().format(log.createdAt)),
              if (log.oldData != null && log.oldData!.isNotEmpty) ...[
                AppSpacing.vGapMd,
                const Text(AppStrings.oldData, style: TextStyle(fontWeight: FontWeight.bold)),
                AppSpacing.vGapXs,
                Text(log.oldData.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
              if (log.newData != null && log.newData!.isNotEmpty) ...[
                AppSpacing.vGapMd,
                const Text(AppStrings.newData, style: TextStyle(fontWeight: FontWeight.bold)),
                AppSpacing.vGapXs,
                Text(log.newData.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.close)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Audit Logs',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _auditTypes.map((t) {
                    final selected = _selectedType == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            _selectedType = t;
                            _load();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            AppSpacing.vGapLg,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildSearchAndDateControls(isNarrow),
            ),
            AppSpacing.vGapLg,
            if (_loading)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: const ShimmerListLoadingWidget(itemCount: 8),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Card(
                    margin: EdgeInsets.all(padding),
                    child: Padding(
                      padding: AppSpacing.paddingXl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                          AppSpacing.vGapLg,
                          Text(_error!, textAlign: TextAlign.center),
                          AppSpacing.vGapLg,
                          FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else if (_logs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_edu_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      AppSpacing.vGapLg,
                      Text(AppStrings.noAuditLogs, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  itemCount: _logs.length + (_page < _totalPages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _logs.length) {
                      if (!_loadingMore) _loadMore();
                      return const Padding(
                        padding: AppSpacing.paddingLg,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _showLogDetail(log),
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _colorForStatus(log.status).withValues(alpha: 0.2),
                            child: Text(
                              _actorInitials(log.actorName),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _colorForStatus(log.status),
                              ),
                            ),
                          ),
                        ),
                        title: Text(log.action),
                        subtitle: Text(
                          '${log.actorName ?? "—"} • ${log.entityName ?? ""} • ${DateFormat.yMMMd().add_Hm().format(log.createdAt)}',
                        ),
                        trailing: log.status != null
                            ? Chip(
                                label: Text(log.status!, style: const TextStyle(fontSize: 11)),
                                backgroundColor: _colorForStatus(log.status).withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndDateControls(bool isNarrow) {
    final searchField = TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: AppStrings.search,
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (_) => _load(),
    );
    final dateControls = [
      TextButton.icon(
        icon: const Icon(Icons.date_range, size: 18),
        label: Text(_dateFrom == null ? AppStrings.from : DateFormat.yMMMd().format(_dateFrom!)),
        onPressed: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _dateFrom ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (d != null && mounted) {
            setState(() { _dateFrom = d; _load(); });
          }
        },
      ),
      TextButton.icon(
        icon: const Icon(Icons.date_range, size: 18),
        label: Text(_dateTo == null ? AppStrings.to : DateFormat.yMMMd().format(_dateTo!)),
        onPressed: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _dateTo ?? DateTime.now(),
            firstDate: _dateFrom ?? DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (d != null && mounted) {
            setState(() { _dateTo = d; _load(); });
          }
        },
      ),
      if (_dateFrom != null || _dateTo != null)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() { _dateFrom = null; _dateTo = null; _load(); });
          },
          tooltip: AppStrings.clearDates,
        ),
      FilledButton(onPressed: () => _load(), child: const Text(AppStrings.apply)),
    ];

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          AppSpacing.vGapMd,
          Wrap(spacing: 8, runSpacing: 8, children: dateControls),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: searchField),
        AppSpacing.hGapSm,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: dateControls,
        ),
      ],
    );
  }

  String _actorInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  Color _colorForStatus(String? status) {
    if (status == null) return AppColors.neutral400;
    switch (status.toLowerCase()) {
      case 'success': return AppColors.success500;
      case 'failed': case 'blocked': return AppColors.error500;
      case 'warning': return AppColors.warning500;
      default: return AppColors.neutral400;
    }
  }
}
