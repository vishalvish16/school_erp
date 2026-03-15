// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_hardware_screen.dart
// PURPOSE: Super Admin hardware — search, filters, Register, Config, Ping, Alert
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../shared/widgets/list_table_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/register_hardware_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SuperAdminHardwareScreen extends ConsumerStatefulWidget {
  const SuperAdminHardwareScreen({super.key});

  @override
  ConsumerState<SuperAdminHardwareScreen> createState() =>
      _SuperAdminHardwareScreenState();
}

class _SuperAdminHardwareScreenState extends ConsumerState<SuperAdminHardwareScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminHardwareDeviceModel> _devices = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  int _pageSize = 15;
  static const _pageSizeOptions = [10, 15, 25, 50];
  final _searchController = TextEditingController();
  Timer? _refreshTimer;
  Timer? _debounceTimer;
  String? _typeFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _page = 1);
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final result = await service.getHardware(
        page: _page,
        limit: _pageSize,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        type: _typeFilter,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _devices = result.data;
          _total = result.total;
          _totalPages = result.totalPages > 0
              ? result.totalPages
              : ((result.total / _pageSize).ceil()).clamp(1, 999);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _devices = [];
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

  void _openRegisterDevice() {
    showAdaptiveModal(
      context,
      RegisterHardwareDialog(
        onRegister: (body) async {
          await ref.read(superAdminServiceProvider).registerHardware(body);
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _pingDevice(SuperAdminHardwareDeviceModel d) async {
    try {
      await ref.read(superAdminServiceProvider).pingDevice(d.id);
      if (mounted) {
        _load();
        AppSnackbar.success(context, 'Device responded');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Device not responding');
      }
    }
  }

  Future<void> _alertSchool(SuperAdminHardwareDeviceModel d) async {
    try {
      await ref.read(superAdminServiceProvider).alertSchool(d.id);
      if (mounted) {
        AppSnackbar.success(context, 'School admin notified');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed: ${e.toString()}');
      }
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'online':
        return AppColors.success500;
      case 'offline':
        return AppColors.error500;
      case 'error':
        return AppColors.warning500;
      case 'maintenance':
        return Colors.amber;
      default:
        return AppColors.neutral400;
    }
  }

  Widget _buildHardwareStats() {
    final rfid = _devices.where((d) => d.deviceType.toLowerCase().contains('rfid')).length;
    final gps = _devices.where((d) => d.deviceType.toLowerCase().contains('gps')).length;
    final bio = _devices.where((d) => d.deviceType.toLowerCase().contains('biometric')).length;
    final offline = _devices.where((d) => d.status.toLowerCase() != 'online').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cards = [
          _HardwareStatCard(icon: Icons.nfc, value: '$rfid', label: 'RFID Readers', color: AppColors.secondary500),
          _HardwareStatCard(icon: Icons.directions_bus, value: '$gps', label: 'GPS Units', color: AppColors.success500),
          _HardwareStatCard(icon: Icons.fingerprint, value: '$bio', label: 'Biometric Units', color: Colors.purple),
          _HardwareStatCard(icon: Icons.warning, value: '$offline', label: 'Offline / Issues', color: AppColors.warning500),
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
          children: cards.map((c) => c).toList(),
        );
      },
    );
  }

  String _formatLastPing(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return DateFormat.Md().add_Hm().format(dt);
  }

  static const _columnWidths = [120.0, 100.0, 160.0, 120.0, 100.0, 100.0, 180.0];
  static const _tableContentWidth = 120.0 + 100 + 160 + 120 + 100 + 100 + 180 + 32;

  DataRow _buildDataRow(SuperAdminHardwareDeviceModel d) {
    final isOnline = d.status.toLowerCase() == 'online';
    final isGps = d.deviceType.toLowerCase().contains('gps');
    return DataRow(
      cells: [
        DataCell(Text(d.deviceId, style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ))),
        DataCell(Chip(
          label: Text(d.deviceType),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: _statusColor(d.status).withValues(alpha: 0.2),
        )),
        DataCell(Text(d.schoolName ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(d.locationLabel ?? '—')),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOnline)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.success500,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.success500.withValues(alpha: 0.5), blurRadius: 4)],
                ),
              ),
            Chip(
              label: Text(d.status),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: _statusColor(d.status).withValues(alpha: 0.2),
            ),
          ],
        )),
        DataCell(Text(_formatLastPing(d.lastPingAt), style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ))),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                showAdaptiveModal(
                  context,
                  Padding(
                    padding: AppSpacing.paddingXl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Device: ${d.deviceId}', style: Theme.of(context).textTheme.titleMedium),
                        Text('Type: ${d.deviceType}'),
                        Text('School: ${d.schoolName ?? "-"}'),
                        Text('Location: ${d.locationLabel ?? "-"}'),
                        Text('Firmware: ${d.firmwareVersion ?? "-"}'),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Config'),
            ),
            TextButton(
              onPressed: () => _pingDevice(d),
              child: const Text('Ping'),
            ),
            if (isGps)
              TextButton(
                onPressed: () {
                  AppSnackbar.info(context, 'Track (opens school transport view)');
                },
                child: const Text('Track'),
              ),
            if (!isOnline)
              FilledButton.tonal(
                onPressed: () => _alertSchool(d),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error500.withValues(alpha: 0.2),
                  foregroundColor: AppColors.error500,
                ),
                child: const Text('Alert School'),
              ),
          ],
        )),
      ],
    );
  }

  Widget _buildDevicesTable() {
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
                    'Device ID',
                    'Type',
                    'School',
                    'Location',
                    'Status',
                    'Last Ping',
                    'Actions',
                  ],
                  columnWidths: _columnWidths,
                  showSrNo: false,
                  itemCount: _devices.length,
                  rowBuilder: (i) => _buildDataRow(_devices[i]),
                ),
              ),
              _buildPaginationRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesCards() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: _devices.map((d) {
              final isOnline = d.status.toLowerCase() == 'online';
              final isGps = d.deviceType.toLowerCase().contains('gps');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: AppRadius.brLg,
                  onTap: () {
                    showAdaptiveModal(
                      context,
                      Padding(
                        padding: AppSpacing.paddingXl,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Device: ${d.deviceId}', style: Theme.of(context).textTheme.titleMedium),
                            Text('Type: ${d.deviceType}'),
                            Text('School: ${d.schoolName ?? "-"}'),
                            Text('Location: ${d.locationLabel ?? "-"}'),
                            Text('Firmware: ${d.firmwareVersion ?? "-"}'),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isOnline)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.success500,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.success500.withValues(alpha: 0.5), blurRadius: 4)],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                d.deviceId,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(d.status, style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: _statusColor(d.status).withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text('${d.deviceType} • ${d.schoolName ?? 'Unassigned'}'),
                        Text(
                          '${d.locationLabel ?? '—'} • ${_formatLastPing(d.lastPingAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        AppSpacing.vGapMd,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton(onPressed: () => _pingDevice(d), child: const Text('Ping')),
                            if (isGps)
                              TextButton(
                                onPressed: () {
                                  AppSnackbar.info(context, 'Track (opens school transport view)');
                                },
                                child: const Text('Track'),
                              ),
                            if (!isOnline)
                              FilledButton.tonal(
                                onPressed: () => _alertSchool(d),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error500.withValues(alpha: 0.2),
                                  foregroundColor: AppColors.error500,
                                ),
                                child: const Text('Alert School'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_devices.isNotEmpty)
          Card(child: _buildPaginationRow()),
      ],
    );
  }

  Widget _buildContent(bool isWide) {
    if (_loading && _devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }
    if (_error != null && _devices.isEmpty) {
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
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchController.text.isNotEmpty
                    ? "No results for '${_searchController.text}'"
                    : 'No devices registered',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _typeFilter = null;
                    _statusFilter = null;
                    _page = 1;
                  });
                  _load();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }
    return isWide ? _buildDevicesTable() : _buildDevicesCards();
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
              Text('entries', style: mutedStyle),
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
                padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, isNarrow ? 16 : 24, isNarrow ? 16 : 24, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Hardware Devices',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    FilledButton.icon(
                      onPressed: _openRegisterDevice,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(isNarrow ? 'Register' : 'Register Device'),
                    ),
                  ],
                ),
              ),

              if (!_loading && _error == null && _devices.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
                  child: _buildHardwareStats(),
                ),
                AppSpacing.vGapLg,
              ],

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
                                hintText: 'Search school, device ID...',
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
                              value: _typeFilter,
                              valueItems: const [
                                MapEntry(null, 'All Types'),
                                MapEntry('rfid', 'RFID'),
                                MapEntry('gps', 'GPS'),
                                MapEntry('biometric', 'Biometric'),
                                MapEntry('tablet', 'Tablet'),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              ),
                              onChanged: (v) {
                                setState(() { _typeFilter = v; _page = 1; });
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
                                MapEntry('online', 'Online'),
                                MapEntry('offline', 'Offline'),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              ),
                              onChanged: (v) {
                                setState(() { _statusFilter = v; _page = 1; });
                                _load();
                              },
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _typeFilter = null;
                                _statusFilter = null;
                                _page = 1;
                              });
                              _load();
                            },
                            icon: const Icon(Icons.filter_alt_off, size: 18),
                            label: const Text('Clear filters'),
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
                    padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, isNarrow ? 16 : 24),
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
}

class _HardwareStatCard extends StatelessWidget {
  const _HardwareStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }
}
