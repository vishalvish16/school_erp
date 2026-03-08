// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_audit_logs_screen.dart
// PURPOSE: Super Admin audit logs — tabs, search, date range, infinite scroll
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';

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
              _detailRow('Actor', log.actorName ?? '—'),
              _detailRow('IP', log.actorIp ?? '—'),
              _detailRow('Entity', log.entityName ?? '—'),
              _detailRow('Type', log.entityType ?? '—'),
              if (log.description != null) _detailRow('Description', log.description!),
              _detailRow('Status', log.status ?? '—'),
              _detailRow('Date', DateFormat.yMMMd().add_Hm().format(log.createdAt)),
              if (log.oldData != null && log.oldData!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Old data', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(log.oldData.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
              if (log.newData != null && log.newData!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('New data', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(log.newData.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
    return RefreshIndicator(
      onRefresh: () => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Logs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_dateFrom == null ? 'From' : DateFormat.yMMMd().format(_dateFrom!)),
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
                  label: Text(_dateTo == null ? 'To' : DateFormat.yMMMd().format(_dateTo!)),
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
                    tooltip: 'Clear dates',
                  ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _load(), child: const Text('Apply')),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ))
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
          else if (_logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.history_edu_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No audit logs', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            ..._logs.asMap().entries.map((e) {
              final i = e.key;
              final log = e.value;
              final isLast = i == _logs.length - 1;
              return Column(
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _showLogDetail(log),
                      leading: Icon(
                        _iconForAction(log.action),
                        color: _colorForStatus(log.status),
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
                  ),
                  if (isLast && _page < _totalPages)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _loadingMore
                          ? const Center(child: CircularProgressIndicator())
                          : TextButton(
                              onPressed: _loadMore,
                              child: const Text('Load more'),
                            ),
                    ),
                ],
              );
            }),
        ],
      ),
    ),
    );
  }

  IconData _iconForAction(String? action) {
    if (action == null) return Icons.info_outline;
    if (action.contains('create') || action.contains('add')) return Icons.add_circle_outline;
    if (action.contains('update') || action.contains('edit')) return Icons.edit_outlined;
    if (action.contains('delete') || action.contains('remove')) return Icons.delete_outline;
    if (action.contains('login') || action.contains('auth')) return Icons.login;
    return Icons.info_outline;
  }

  Color _colorForStatus(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'success': return Colors.green;
      case 'failed': case 'blocked': return Colors.red;
      case 'warning': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
