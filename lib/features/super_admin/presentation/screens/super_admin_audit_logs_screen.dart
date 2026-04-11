// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_audit_logs_screen.dart
// PURPOSE: Super Admin audit logs — tabs, search, date range, infinite scroll
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';

import '../../../../design_system/design_system.dart';


const List<String> _kAuditTypes = [
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
    // Try to parse description as JSON map for cleaner display
    Map<String, dynamic>? parsedDesc;
    if (log.description != null) {
      try {
        final decoded = jsonDecode(log.description!);
        if (decoded is Map) {
          parsedDesc = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(log.action),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(AppStrings.actor,      log.actorName ?? '—'),
                _detailRow(AppStrings.ip,          log.actorIp ?? '—'),
                _detailRow(AppStrings.entity,      log.entityName ?? '—'),
                _detailRow(AppStrings.auditType,   log.entityType ?? '—'),
                _detailRow(AppStrings.status,      log.status ?? '—'),
                _detailRow(AppStrings.date,
                    DateFormat.yMMMd().add_Hm().format(log.createdAt)),
                // Description: if it's a JSON map show as key-value, else plain text
                if (parsedDesc != null) ...[
                  AppSpacing.vGapMd,
                  _sectionLabel(AppStrings.auditDescription),
                  AppSpacing.vGapXs,
                  _dataTable(parsedDesc),
                ] else if (log.description != null) ...[
                  _detailRow(AppStrings.auditDescription, log.description!),
                ],
                if (log.oldData != null && log.oldData!.isNotEmpty) ...[
                  AppSpacing.vGapMd,
                  _sectionLabel(AppStrings.oldData),
                  AppSpacing.vGapXs,
                  _dataTable(log.oldData!),
                ],
                if (log.newData != null && log.newData!.isNotEmpty) ...[
                  AppSpacing.vGapMd,
                  _sectionLabel(AppStrings.newData),
                  AppSpacing.vGapXs,
                  _dataTable(log.newData!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.close)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: AppTextStyles.bodyMd(color: Theme.of(context).colorScheme.onSurface)
            .copyWith(fontWeight: FontWeight.w700));
  }

  /// Renders a Map as a clean key → value table (handles nested maps/lists too).
  Widget _dataTable(Map<String, dynamic> data) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((e) {
          final key   = e.key.replaceAll('_', ' ');
          final value = _formatValue(e.value);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    _capitalise(key),
                    style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodySm(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatValue(dynamic v) {
    if (v == null) return '—';
    if (v is Map) {
      // Render nested map as "key: value, key: value"
      return v.entries
          .map((e) => '${_capitalise(e.key.toString().replaceAll('_', ' '))}: ${_formatValue(e.value)}')
          .join('\n');
    }
    if (v is List) {
      if (v.isEmpty) return '—';
      return v.map((item) => _formatValue(item)).join(', ');
    }
    return v.toString();
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
              child: _buildFilterRow(),
            ),
            AppSpacing.vGapLg,
            if (_loading)
              Expanded(
                child: AppLoaderScreen(),
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
                        child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
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

  Widget _buildFilterRow() {
    final scheme = Theme.of(context).colorScheme;
    final hasDateFilter = _dateFrom != null || _dateTo != null;

    // Date range label
    String dateLabel = 'Date Range';
    if (_dateFrom != null && _dateTo != null) {
      dateLabel = '${DateFormat('d MMM').format(_dateFrom!)} – ${DateFormat('d MMM yy').format(_dateTo!)}';
    } else if (_dateFrom != null) {
      dateLabel = 'From ${DateFormat('d MMM yy').format(_dateFrom!)}';
    } else if (_dateTo != null) {
      dateLabel = 'Until ${DateFormat('d MMM yy').format(_dateTo!)}';
    }

    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return Row(
      children: [
        // ── Type dropdown ────────────────────────────────────────────────
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: _selectedType,
            isDense: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: scheme.primary, width: 1.5)),
            ),
            items: _kAuditTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() { _selectedType = v; _load(); });
            },
          ),
        ),
        const SizedBox(width: 8),

        // ── Search ───────────────────────────────────────────────────────
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search logs…',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: scheme.primary, width: 1.5)),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        const SizedBox(width: 8),

        // ── Date range picker ────────────────────────────────────────────
        OutlinedButton.icon(
          icon: Icon(Icons.calendar_month_rounded, size: 16, color: hasDateFilter ? scheme.primary : scheme.onSurfaceVariant),
          label: Text(
            dateLabel,
            style: TextStyle(fontSize: 13, color: hasDateFilter ? scheme.primary : scheme.onSurfaceVariant),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide(color: hasDateFilter ? scheme.primary : scheme.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: (_dateFrom != null && _dateTo != null)
                  ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
                  : null,
              builder: (context, child) => Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
                  child: ClipRRect(borderRadius: AppRadius.brXl, child: child),
                ),
              ),
            );
            if (range != null && mounted) {
              setState(() { _dateFrom = range.start; _dateTo = range.end; });
              _load();
            }
          },
        ),

        // ── Clear dates ──────────────────────────────────────────────────
        if (hasDateFilter) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Clear dates',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
            onPressed: () => setState(() { _dateFrom = null; _dateTo = null; _load(); }),
          ),
        ],
        const SizedBox(width: 8),

        // ── Apply ────────────────────────────────────────────────────────
        FilledButton(
          onPressed: _load,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
          child: const Text('Apply'),
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
