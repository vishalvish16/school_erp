// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_hardware_screen.dart
// PURPOSE: Super Admin hardware — search, filters, Register, Config, Ping, Alert
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';

import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_screen_mobile_toolbar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/metric_stat_card.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/register_hardware_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../design_system/design_system.dart';

class SuperAdminHardwareScreen extends ConsumerStatefulWidget {
  const SuperAdminHardwareScreen({super.key});

  @override
  ConsumerState<SuperAdminHardwareScreen> createState() =>
      _SuperAdminHardwareScreenState();
}

class _SuperAdminHardwareScreenState extends ConsumerState<SuperAdminHardwareScreen> {
  bool _loading = true;
  bool _loadingMore = false;
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

  Future<void> _load({bool append = false}) async {
    if (!mounted) return;
    if (append) {
      if (_loadingMore || _loading) return;
      if (_devices.isNotEmpty && _devices.length >= _total && _total > 0) {
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
      final requestPage =
          append ? (_devices.length ~/ _pageSize) + 1 : _page;
      final result = await service.getHardware(
        page: requestPage,
        limit: _pageSize,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        type: _typeFilter,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          if (append) {
            final merged = [..._devices, ...result.data];
            final seen = <String>{};
            _devices = merged.where((d) => seen.add(d.id)).toList();
            _loadingMore = false;
          } else {
            _devices = result.data;
            _loading = false;
          }
          _total = result.total;
          _totalPages = result.totalPages > 0
              ? result.totalPages
              : ((result.total / _pageSize).ceil()).clamp(1, 999);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (append) {
            _loadingMore = false;
          } else {
            _error = e.toString().replaceAll('Exception: ', '');
            _loading = false;
            _devices = [];
          }
        });
      }
    }
  }

  bool get _hasMoreDevices =>
      _devices.isNotEmpty && _total > 0 && _devices.length < _total;

  Future<void> _loadMoreDevices() => _load(append: true);

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
        AppSnackbar.success(context, AppStrings.deviceResponded);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, AppStrings.deviceNotResponding);
      }
    }
  }

  Future<void> _alertSchool(SuperAdminHardwareDeviceModel d) async {
    try {
      await ref.read(superAdminServiceProvider).alertSchool(d.id);
      if (mounted) {
        AppSnackbar.success(context, AppStrings.schoolAdminNotified);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          '${AppStrings.errorPrefix}${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  void _showDeviceConfigModal(SuperAdminHardwareDeviceModel d) {
    showAdaptiveModal(
      context,
      Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${AppStrings.deviceLabel}: ${d.deviceId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${AppStrings.typeColon}${d.deviceType}'),
            Text('${AppStrings.schoolColumn}: ${d.schoolName ?? "-"}'),
            Text('${AppStrings.location}: ${d.locationLabel ?? "-"}'),
            Text('${AppStrings.firmwareLabel}: ${d.firmwareVersion ?? "-"}'),
          ],
        ),
      ),
    );
  }

  void _onDeviceMenu(SuperAdminHardwareDeviceModel d, String v) {
    switch (v) {
      case 'config':
        _showDeviceConfigModal(d);
        break;
      case 'ping':
        _pingDevice(d);
        break;
      case 'track':
        AppSnackbar.info(context, AppStrings.trackDeviceSnack);
        break;
      case 'alert':
        _alertSchool(d);
        break;
    }
  }

  List<PopupMenuEntry<String>> _deviceMenuItems(
    SuperAdminHardwareDeviceModel d, {
    required bool includeConfig,
  }) {
    final isGps = d.deviceType.toLowerCase().contains('gps');
    final isOnline = d.status.toLowerCase() == 'online';
    return [
      if (includeConfig)
        PopupMenuItem(
          value: 'config',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 8),
              Text(AppStrings.configAction),
            ],
          ),
        ),
      PopupMenuItem(
        value: 'ping',
        child: Row(
          children: [
            Icon(Icons.speed_outlined, size: 18),
            SizedBox(width: 8),
            Text(AppStrings.pingAction),
          ],
        ),
      ),
      if (isGps)
        PopupMenuItem(
          value: 'track',
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18),
              SizedBox(width: 8),
              Text(AppStrings.trackAction),
            ],
          ),
        ),
      if (!isOnline)
        PopupMenuItem(
          value: 'alert',
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined, size: 18),
              SizedBox(width: 8),
              Text(AppStrings.alertSchoolAction),
            ],
          ),
        ),
    ];
  }

  bool get _hardwareFiltersActive =>
      _typeFilter != null ||
      _statusFilter != null ||
      _searchController.text.trim().isNotEmpty;

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _typeFilter = null;
      _statusFilter = null;
      _page = 1;
    });
    _load();
  }

  Future<void> _showMobileFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.filters,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              AppSpacing.vGapMd,
              TextButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _clearAllFilters();
                },
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: Text(AppStrings.clearFilters),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileSearchFilters(BuildContext context) {
    return ListScreenMobileFilterStrip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListScreenMobilePillSearchField(
            controller: _searchController,
            hintText: AppStrings.searchSchoolDeviceId,
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
                value: _typeFilter,
                valueItems: [
                  MapEntry(null, AppStrings.allDeviceTypes),
                  MapEntry('rfid', AppStrings.hardwareTypeRfid),
                  MapEntry('gps', AppStrings.hardwareTypeGps),
                  MapEntry('biometric', AppStrings.hardwareTypeBiometric),
                  MapEntry('tablet', AppStrings.hardwareTypeTablet),
                ],
                hintText: AppStrings.type,
                decoration: listScreenMobileFilterFieldDecoration(context),
                onChanged: (v) {
                  setState(() {
                    _typeFilter = v;
                    _page = 1;
                  });
                  _load();
                },
              ),
              SearchableDropdownFormField<String?>.valueItems(
                value: _statusFilter,
                valueItems: [
                  MapEntry(null, AppStrings.filterAll),
                  MapEntry('online', AppStrings.statusOnline),
                  MapEntry('offline', AppStrings.statusOffline),
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
                showActiveDot: _hardwareFiltersActive,
                onPressed: _showMobileFiltersSheet,
              ),
            ],
          ),
        ],
      ),
    );
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
        return AppColors.warning500;
      default:
        return AppColors.neutral400;
    }
  }

  Widget _buildHardwareStats() {
    final rfid = _devices.where((d) => d.deviceType.toLowerCase().contains('rfid')).length;
    final gps = _devices.where((d) => d.deviceType.toLowerCase().contains('gps')).length;
    final bio = _devices.where((d) => d.deviceType.toLowerCase().contains('biometric')).length;
    final offline = _devices.where((d) => d.status.toLowerCase() != 'online').length;

    final useRow = MediaQuery.sizeOf(context).width >= 600;
    final items = <(IconData, String, String, Color)>[
      (Icons.nfc, '$rfid', AppStrings.rfidReaders, AppColors.secondary500),
      (Icons.directions_bus, '$gps', AppStrings.gpsUnits, AppColors.success500),
      (Icons.fingerprint, '$bio', AppStrings.biometricUnits, AppColors.info600),
      (Icons.warning_amber_rounded, '$offline', AppStrings.offlineOrIssues, AppColors.warning500),
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
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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
  }

  String _formatLastPing(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return AppStrings.justNow;
    if (diff.inMinutes < 60) return AppStrings.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return AppStrings.hoursAgo(diff.inHours);
    return DateFormat.Md().add_Hm().format(dt);
  }

  static const _columnWidths = [120.0, 100.0, 160.0, 120.0, 100.0, 100.0, 60.0];
  static const _tableContentWidth = 120.0 + 100 + 160 + 120 + 100 + 100 + 60 + 32;

  DataRow _buildDataRow(SuperAdminHardwareDeviceModel d) {
    final isOnline = d.status.toLowerCase() == 'online';
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
        DataCell(Text(
          d.schoolName ?? AppStrings.unassigned,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
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
        DataCell(Center(
          child: HoverPopupMenu<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            padding: EdgeInsets.zero,
            onSelected: (v) => _onDeviceMenu(d, v),
            itemBuilder: (context) => _deviceMenuItems(d, includeConfig: true),
          ),
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
                  columns: [
                    AppStrings.deviceColumn,
                    AppStrings.type,
                    AppStrings.schoolColumn,
                    AppStrings.location,
                    AppStrings.status,
                    AppStrings.lastPingColumn,
                    AppStrings.actionsColumn,
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
    return MobileInfiniteScrollList(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final d = _devices[index];
        final cs = Theme.of(context).colorScheme;
        final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            );
        final isOnline = d.status.toLowerCase() == 'online';
        final schoolLine = (d.schoolName ?? '').trim();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: AppRadius.brLg,
            onTap: () => _showDeviceConfigModal(d),
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          d.deviceId,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      HoverPopupMenu<String>(
                        icon: const Icon(Icons.more_vert, size: 22),
                        padding: EdgeInsets.zero,
                        onSelected: (v) => _onDeviceMenu(d, v),
                        itemBuilder: (ctx) =>
                            _deviceMenuItems(d, includeConfig: false),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (schoolLine.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      schoolLine,
                                      style: smallMuted,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              d.locationLabel ?? '—',
                              style: smallMuted,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Chip(
                                label: Text(
                                  d.deviceType,
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                side: BorderSide(color: cs.outlineVariant),
                                backgroundColor:
                                    cs.surfaceContainerHighest.withValues(alpha: 0.5),
                              ),
                              Chip(
                                label: Row(
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
                                        ),
                                      ),
                                    Text(
                                      d.status,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                backgroundColor:
                                    _statusColor(d.status).withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppStrings.lastPingPrefix} ${_formatLastPing(d.lastPingAt)}',
                            style: smallMuted,
                            textAlign: TextAlign.end,
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
      },
      hasMore: _hasMoreDevices,
      isLoadingMore: _loadingMore,
      onLoadMore: _loadMoreDevices,
      loadingLabel: AppStrings.loadingMoreDevices,
    );
  }

  Widget _buildContent(bool isWide) {
    if (_loading && _devices.isEmpty) {
      return AppLoaderScreen();
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
              FilledButton(onPressed: _load, child: Text(AppStrings.retry)),
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
                    ? AppStrings.noSearchResultsFor(_searchController.text)
                    : AppStrings.noDevicesRegistered,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(AppStrings.clearFilters),
              ),
            ],
          ),
        ),
      );
    }
    return isWide ? _buildDevicesTable() : _buildDevicesCards();
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
                  title: AppStrings.hardwareDevicesTitle,
                  primaryLabel: AppStrings.register,
                  onPrimary: _openRegisterDevice,
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
                        AppStrings.hardwareDevicesTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      FilledButton.icon(
                        onPressed: _openRegisterDevice,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(AppStrings.registerDevice),
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

              if (isNarrow)
                _buildMobileSearchFilters(context)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                  hintText: AppStrings.searchSchoolDeviceId,
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
                                    horizontal: AppSpacing.md,
                                    vertical: 10,
                                  ),
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
                                valueItems: [
                                  MapEntry(null, AppStrings.allDeviceTypes),
                                  MapEntry('rfid', AppStrings.hardwareTypeRfid),
                                  MapEntry('gps', AppStrings.hardwareTypeGps),
                                  MapEntry('biometric', AppStrings.hardwareTypeBiometric),
                                  MapEntry('tablet', AppStrings.hardwareTypeTablet),
                                ],
                                decoration: const InputDecoration(
                                  labelText: AppStrings.type,
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _typeFilter = v;
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
                                valueItems: [
                                  MapEntry(null, AppStrings.filterAll),
                                  MapEntry('online', AppStrings.statusOnline),
                                  MapEntry('offline', AppStrings.statusOffline),
                                ],
                                decoration: const InputDecoration(
                                  labelText: AppStrings.status,
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
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
                              onPressed: _clearAllFilters,
                              icon: const Icon(Icons.filter_alt_off, size: 18),
                              label: Text(AppStrings.clearFilters),
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
