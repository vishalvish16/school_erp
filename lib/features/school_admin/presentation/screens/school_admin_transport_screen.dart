// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_transport_screen.dart
// PURPOSE: Transport management — vehicles, drivers, student assignments, live map.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/transport_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../features/auth/auth_guard_provider.dart';
import '../../../../models/school_admin/transport_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class _ListState<T> {
  final List<T> items;
  final bool loading;
  final String? error;
  final int total;

  const _ListState({this.items = const [], this.loading = false, this.error, this.total = 0});

  _ListState<T> copyWith({List<T>? items, bool? loading, String? error, int? total}) =>
      _ListState(items: items ?? this.items, loading: loading ?? this.loading, error: error, total: total ?? this.total);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _vehiclesProvider = StateNotifierProvider.autoDispose<_VehiclesNotifier, _ListState<TransportVehicleModel>>(
  (ref) => _VehiclesNotifier(ref.watch(transportServiceProvider)),
);

final _driversProvider = StateNotifierProvider.autoDispose<_DriversNotifier, _ListState<TransportDriverModel>>(
  (ref) => _DriversNotifier(ref.watch(transportServiceProvider)),
);

class _VehiclesNotifier extends StateNotifier<_ListState<TransportVehicleModel>> {
  _VehiclesNotifier(this._svc) : super(const _ListState(loading: true)) { load(); }
  final TransportService _svc;
  String _search = '';

  Future<void> load({String? search}) async {
    _search = search ?? _search;
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _svc.getVehicles(search: _search.isEmpty ? null : _search);
      state = state.copyWith(loading: false, items: res['vehicles'] as List<TransportVehicleModel>, total: res['total'] as int);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void remove(String id) => state = state.copyWith(items: state.items.where((v) => v.id != id).toList());
}

class _DriversNotifier extends StateNotifier<_ListState<TransportDriverModel>> {
  _DriversNotifier(this._svc) : super(const _ListState(loading: true)) { load(); }
  final TransportService _svc;
  String _search = '';

  Future<void> load({String? search}) async {
    _search = search ?? _search;
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _svc.getDrivers(search: _search.isEmpty ? null : _search);
      state = state.copyWith(loading: false, items: res['drivers'] as List<TransportDriverModel>, total: res['total'] as int);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void remove(String id) => state = state.copyWith(items: state.items.where((d) => d.id != id).toList());
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class SchoolAdminTransportScreen extends ConsumerStatefulWidget {
  const SchoolAdminTransportScreen({super.key});

  @override
  ConsumerState<SchoolAdminTransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends ConsumerState<SchoolAdminTransportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: scheme.surface,
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus_rounded, color: AppColors.success500, size: AppIconSize.lg),
                  AppSpacing.hGapSm,
                  Text('Transport', style: AppTextStyles.h4(color: scheme.onSurface)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showVehicleForm(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Vehicle'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success500),
                  ),
                  AppSpacing.hGapSm,
                  OutlinedButton.icon(
                    onPressed: () => _showDriverForm(context),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add Driver'),
                  ),
                ],
              ),
              AppSpacing.vGapLg,
              TabBar(
                controller: _tab,
                labelColor: AppColors.success500,
                indicatorColor: AppColors.success500,
                tabs: const [Tab(text: 'Vehicles'), Tab(text: 'Drivers'), Tab(text: 'Live Map')],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _VehiclesTab(onEdit: (v) => _showVehicleForm(context, vehicle: v)),
              _DriversTab(onEdit: (d) => _showDriverForm(context, driver: d)),
              const _LiveMapTab(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showVehicleForm(BuildContext ctx, {TransportVehicleModel? vehicle}) async {
    final result = await showDialog<bool>(context: ctx, barrierDismissible: false, builder: (_) => _VehicleFormDialog(vehicle: vehicle));
    if (result == true && mounted) ref.read(_vehiclesProvider.notifier).load();
  }

  Future<void> _showDriverForm(BuildContext ctx, {TransportDriverModel? driver}) async {
    final result = await showDialog<bool>(context: ctx, barrierDismissible: false, builder: (_) => _DriverFormDialog(driver: driver));
    if (result == true && mounted) ref.read(_driversProvider.notifier).load();
  }
}

// ── Vehicles Tab ──────────────────────────────────────────────────────────────

class _VehiclesTab extends ConsumerStatefulWidget {
  const _VehiclesTab({required this.onEdit});
  final void Function(TransportVehicleModel) onEdit;

  @override
  ConsumerState<_VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends ConsumerState<_VehiclesTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_vehiclesProvider);
    return Column(
      children: [
        Padding(
          padding: AppSpacing.paddingLg,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => ref.read(_vehiclesProvider.notifier).load(search: v));
            },
            decoration: InputDecoration(hintText: 'Search by vehicle no, make, color…', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: AppRadius.brMd), isDense: true),
          ),
        ),
        Expanded(
          child: state.loading
              ? AppLoaderScreen()
              : state.error != null
                  ? _ErrorView(error: state.error!, onRetry: () => ref.read(_vehiclesProvider.notifier).load())
                  : state.items.isEmpty
                      ? const _EmptyView(icon: Icons.directions_bus_outlined, label: 'No vehicles yet.\nTap "Add Vehicle" to register one.')
                      : RefreshIndicator(
                          onRefresh: () => ref.read(_vehiclesProvider.notifier).load(),
                          child: ListView.separated(
                            padding: AppSpacing.paddingHLg,
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) => AppSpacing.vGapSm,
                            itemBuilder: (_, i) => _VehicleCard(
                              vehicle: state.items[i],
                              onEdit: () => widget.onEdit(state.items[i]),
                              onDelete: () => _confirmDelete(context, state.items[i]),
                              onManageStudents: () => _showStudents(context, state.items[i]),
                              onAssignDriver: () => _showAssignDriver(context, state.items[i]),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, TransportVehicleModel v) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Delete ${v.vehicleNo}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error500), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(transportServiceProvider).deleteVehicle(v.id);
      ref.read(_vehiclesProvider.notifier).remove(v.id);
      if (mounted) AppToast.showSuccess(context, 'Vehicle deleted');
    } catch (e) {
      if (mounted) AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _showStudents(BuildContext ctx, TransportVehicleModel v) async {
    await showModalBottomSheet(context: ctx, isScrollControlled: true, useSafeArea: true, builder: (_) => _StudentsSheet(vehicle: v));
    if (mounted) ref.read(_vehiclesProvider.notifier).load();
  }

  Future<void> _showAssignDriver(BuildContext ctx, TransportVehicleModel v) async {
    final result = await showDialog<bool>(context: ctx, builder: (_) => _AssignDriverDialog(vehicle: v));
    if (result == true && mounted) ref.read(_vehiclesProvider.notifier).load();
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onEdit, required this.onDelete, required this.onManageStudents, required this.onAssignDriver});
  final TransportVehicleModel vehicle;
  final VoidCallback onEdit, onDelete, onManageStudents, onAssignDriver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = vehicle;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: scheme.outlineVariant)),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.success500.withValues(alpha: 0.1), borderRadius: AppRadius.brSm),
                  child: Icon(Icons.directions_bus_rounded, color: AppColors.success500, size: AppIconSize.lg),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.vehicleNo, style: AppTextStyles.h6(color: scheme.onSurface)),
                      if (v.make != null || v.vehicleType != null)
                        Text([v.vehicleType, v.make, v.model].whereType<String>().join(' · '), style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _StatusChip(active: v.isActive),
              ],
            ),
            AppSpacing.vGapMd,
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(icon: Icons.people_outline, label: '${v.capacity} seats'),
                _InfoChip(icon: Icons.person_outline, label: v.driver != null ? v.driver!.fullName : 'No driver', color: v.driver != null ? null : AppColors.warning600),
                _InfoChip(icon: Icons.school_outlined, label: '${v.studentCount} students'),
                if (v.color != null) _InfoChip(icon: Icons.color_lens_outlined, label: v.color!),
              ],
            ),
            AppSpacing.vGapMd,
            Row(
              children: [
                _ActionBtn(icon: Icons.person_pin_outlined, label: 'Driver', onTap: onAssignDriver),
                AppSpacing.hGapSm,
                _ActionBtn(icon: Icons.group_add_outlined, label: 'Students', onTap: onManageStudents),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit, tooltip: 'Edit', iconSize: AppIconSize.md),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete, tooltip: 'Delete', color: AppColors.error500, iconSize: AppIconSize.md),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drivers Tab ───────────────────────────────────────────────────────────────

class _DriversTab extends ConsumerStatefulWidget {
  const _DriversTab({required this.onEdit});
  final void Function(TransportDriverModel) onEdit;

  @override
  ConsumerState<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends ConsumerState<_DriversTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_driversProvider);
    return Column(
      children: [
        Padding(
          padding: AppSpacing.paddingLg,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => ref.read(_driversProvider.notifier).load(search: v));
            },
            decoration: InputDecoration(hintText: 'Search drivers…', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: AppRadius.brMd), isDense: true),
          ),
        ),
        Expanded(
          child: state.loading
              ? AppLoaderScreen()
              : state.error != null
                  ? _ErrorView(error: state.error!, onRetry: () => ref.read(_driversProvider.notifier).load())
                  : state.items.isEmpty
                      ? const _EmptyView(icon: Icons.person_off_outlined, label: 'No drivers yet.\nTap "Add Driver" to register one.')
                      : RefreshIndicator(
                          onRefresh: () => ref.read(_driversProvider.notifier).load(),
                          child: ListView.separated(
                            padding: AppSpacing.paddingHLg,
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) => AppSpacing.vGapSm,
                            itemBuilder: (_, i) => _DriverCard(
                              driver: state.items[i],
                              onEdit: () => widget.onEdit(state.items[i]),
                              onDelete: () => _confirmDelete(context, state.items[i]),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, TransportDriverModel d) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Delete ${d.fullName}? Their login access will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error500), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(transportServiceProvider).deleteDriver(d.id);
      ref.read(_driversProvider.notifier).remove(d.id);
      if (mounted) AppToast.showSuccess(context, 'Driver deleted');
    } catch (e) {
      if (mounted) AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.onEdit, required this.onDelete});
  final TransportDriverModel driver;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = driver;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: scheme.outlineVariant)),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.success500.withValues(alpha: 0.12),
              child: Text(d.firstName.isNotEmpty ? d.firstName[0].toUpperCase() : 'D', style: AppTextStyles.h6(color: AppColors.success700)),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.fullName, style: AppTextStyles.bodyMd(color: scheme.onSurface)),
                  if (d.phone != null) Text(d.phone!, style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
                  if (d.vehicles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: d.vehicles.map((v) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.info500.withValues(alpha: 0.12), borderRadius: AppRadius.brSm),
                          child: Text(v.vehicleNo, style: AppTextStyles.caption(color: AppColors.info600)),
                        )).toList(),
                      ),
                    )
                  else
                    Text('No vehicle assigned', style: AppTextStyles.caption(color: AppColors.warning600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(active: d.isActive),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit, iconSize: AppIconSize.md),
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete, color: AppColors.error500, iconSize: AppIconSize.md),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Map Tab ──────────────────────────────────────────────────────────────

class _LiveMapTab extends ConsumerStatefulWidget {
  const _LiveMapTab({super.key});

  @override
  ConsumerState<_LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends ConsumerState<_LiveMapTab> {
  List<TransportVehicleModel> _vehicles = [];
  bool _loading = true;
  String? _error;
  io.Socket? _socket;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _connectSocket();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(transportServiceProvider).getLiveVehicles();
      if (mounted) setState(() { _vehicles = res['vehicles'] as List<TransportVehicleModel>; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  void _connectSocket() {
    final token = ref.read(authGuardProvider).accessToken;
    if (token == null) return;
    _socket = io.io(ApiConfig.socketUrl, io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().build());
    _socket!.connect();
    _socket!.on('driver:location', (data) {
      if (!mounted || data is! Map<String, dynamic>) return;
      final vid = data['vehicleId'] as String? ?? '';
      if (vid.isEmpty) return;
      setState(() {
        final idx = _vehicles.indexWhere((v) => v.id == vid);
        if (idx >= 0) {
          final old = _vehicles[idx];
          final loc = VehicleLocation(
            lat: (data['lat'] as num).toDouble(),
            lng: (data['lng'] as num).toDouble(),
            speed: (data['speed'] as num?)?.toDouble(),
            heading: (data['heading'] as num?)?.toDouble(),
            updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
          );
          _vehicles[idx] = TransportVehicleModel(id: old.id, vehicleNo: old.vehicleNo, vehicleType: old.vehicleType, capacity: old.capacity, make: old.make, model: old.model, year: old.year, color: old.color, rcNumber: old.rcNumber, insuranceExpiry: old.insuranceExpiry, fitnessExpiry: old.fitnessExpiry, isActive: old.isActive, driver: old.driver, studentCount: old.studentCount, lastLocation: loc);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return AppLoaderScreen();
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    final live = _vehicles.where((v) => v.lastLocation != null).toList();
    return Column(
      children: [
        Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              _StatBadge(count: live.length, label: 'On Trip', color: AppColors.success500),
              AppSpacing.hGapXl,
              _StatBadge(count: _vehicles.length - live.length, label: 'Idle', color: AppColors.neutral400),
              AppSpacing.hGapXl,
              _StatBadge(count: _vehicles.length, label: 'Total', color: AppColors.info500),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _vehicles.isEmpty
              ? const _EmptyView(icon: Icons.map_outlined, label: 'No vehicles registered yet.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: AppSpacing.paddingLg,
                    itemCount: _vehicles.length,
                    separatorBuilder: (_, __) => AppSpacing.vGapSm,
                    itemBuilder: (_, i) => _LiveVehicleCard(vehicle: _vehicles[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _LiveVehicleCard extends StatelessWidget {
  const _LiveVehicleCard({required this.vehicle});
  final TransportVehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = vehicle;
    final loc = v.lastLocation;
    final isLive = loc != null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: isLive ? AppColors.success300 : scheme.outlineVariant)),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isLive ? AppColors.success100 : AppColors.neutral100, borderRadius: AppRadius.brSm),
                  child: Icon(Icons.directions_bus_rounded, color: isLive ? AppColors.success600 : AppColors.neutral400, size: AppIconSize.lg),
                ),
                if (isLive)
                  Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.success500, shape: BoxShape.circle))),
              ],
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.vehicleNo, style: AppTextStyles.bodyMd(color: scheme.onSurface)),
                  if (v.driver != null) Text(v.driver!.fullName, style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
                  if (isLive && (loc.speed ?? 0) > 0.5)
                    Text('${(loc.speed! * 3.6).toStringAsFixed(0)} km/h', style: AppTextStyles.caption(color: AppColors.success600)),
                ],
              ),
            ),
            if (isLive)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LIVE', style: AppTextStyles.caption(color: AppColors.success600)),
                  if (loc.updatedAt != null) Text(_ago(loc.updatedAt!), style: AppTextStyles.caption(color: scheme.onSurfaceVariant)),
                ],
              )
            else
              Text('Idle', style: AppTextStyles.caption(color: AppColors.neutral400)),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

// ── Vehicle Form Dialog ───────────────────────────────────────────────────────

class _VehicleFormDialog extends ConsumerStatefulWidget {
  const _VehicleFormDialog({this.vehicle});
  final TransportVehicleModel? vehicle;

  @override
  ConsumerState<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vehicleNo, _make, _model, _year, _color, _capacity, _rcNumber;
  String _vehicleType = 'bus';
  bool _saving = false;
  String? _error;

  static const _types = ['bus', 'van', 'auto', 'minibus', 'other'];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _vehicleNo = TextEditingController(text: v?.vehicleNo ?? '');
    _make = TextEditingController(text: v?.make ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _year = TextEditingController(text: v?.year?.toString() ?? '');
    _color = TextEditingController(text: v?.color ?? '');
    _capacity = TextEditingController(text: (v?.capacity ?? 30).toString());
    _rcNumber = TextEditingController(text: v?.rcNumber ?? '');
    _vehicleType = v?.vehicleType ?? 'bus';
  }

  @override
  void dispose() {
    for (final c in [_vehicleNo, _make, _model, _year, _color, _capacity, _rcNumber]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final svc = ref.read(transportServiceProvider);
      final body = {
        'vehicleNo': _vehicleNo.text.trim().toUpperCase(),
        'vehicleType': _vehicleType,
        'capacity': int.tryParse(_capacity.text) ?? 30,
        if (_make.text.trim().isNotEmpty) 'make': _make.text.trim(),
        if (_model.text.trim().isNotEmpty) 'model': _model.text.trim(),
        if (_year.text.trim().isNotEmpty) 'year': int.tryParse(_year.text.trim()),
        if (_color.text.trim().isNotEmpty) 'color': _color.text.trim(),
        if (_rcNumber.text.trim().isNotEmpty) 'rcNumber': _rcNumber.text.trim(),
      };
      widget.vehicle == null ? await svc.createVehicle(body) : await svc.updateVehicle(widget.vehicle!.id, body);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _saving = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: AppSpacing.paddingLg, child: Row(children: [Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle', style: AppTextStyles.h6()), const Spacer(), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))])),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) _ErrorBanner(message: _error!),
                      TextFormField(controller: _vehicleNo, decoration: const InputDecoration(labelText: 'Vehicle Number *', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                      AppSpacing.vGapMd,
                      DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                        onChanged: (v) => setState(() => _vehicleType = v ?? 'bus'),
                      ),
                      AppSpacing.vGapMd,
                      TextFormField(controller: _capacity, decoration: const InputDecoration(labelText: 'Capacity (seats) *', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                      AppSpacing.vGapMd,
                      Row(children: [
                        Expanded(child: TextFormField(controller: _make, decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder()))),
                        AppSpacing.hGapMd,
                        Expanded(child: TextFormField(controller: _model, decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()))),
                      ]),
                      AppSpacing.vGapMd,
                      Row(children: [
                        Expanded(child: TextFormField(controller: _year, decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                        AppSpacing.hGapMd,
                        Expanded(child: TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()))),
                      ]),
                      AppSpacing.vGapMd,
                      TextFormField(controller: _rcNumber, decoration: const InputDecoration(labelText: 'RC Number', border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                  AppSpacing.hGapSm,
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success500),
                    child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Add Vehicle'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Driver Form Dialog ────────────────────────────────────────────────────────

class _DriverFormDialog extends ConsumerStatefulWidget {
  const _DriverFormDialog({this.driver});
  final TransportDriverModel? driver;

  @override
  ConsumerState<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends ConsumerState<_DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName, _lastName, _phone, _email, _license;
  String _gender = 'MALE';
  bool _saving = false;
  String? _error;
  String? _tempPassword;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _firstName = TextEditingController(text: d?.firstName ?? '');
    _lastName = TextEditingController(text: d?.lastName ?? '');
    _phone = TextEditingController(text: d?.phone ?? '');
    _email = TextEditingController(text: d?.email ?? '');
    _license = TextEditingController(text: d?.licenseNumber ?? '');
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _license]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final svc = ref.read(transportServiceProvider);
      final body = {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'gender': _gender,
        'phone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_license.text.trim().isNotEmpty) 'licenseNumber': _license.text.trim(),
      };
      if (widget.driver == null) {
        final res = await svc.createDriver(body);
        setState(() { _saving = false; _tempPassword = res['tempPassword'] as String?; });
      } else {
        await svc.updateDriver(widget.driver!.id, body);
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() { _saving = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tempPassword != null) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success500, size: 48),
                AppSpacing.vGapMd,
                Text('Driver Created!', style: AppTextStyles.h6()),
                AppSpacing.vGapSm,
                Text('Share these credentials with the driver. They can change their password after first login.', style: AppTextStyles.bodySm(color: AppColors.neutral600), textAlign: TextAlign.center),
                AppSpacing.vGapLg,
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(color: AppColors.neutral50, borderRadius: AppRadius.brMd, border: Border.all(color: AppColors.neutral200)),
                  child: Column(
                    children: [
                      _CredRow(label: 'Login ID', value: 'Vehicle Number (after assignment)'),
                      AppSpacing.vGapSm,
                      _CredRow(label: 'Temp Password', value: _tempPassword!),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,
                FilledButton(onPressed: () => Navigator.of(context).pop(true), style: FilledButton.styleFrom(backgroundColor: AppColors.success500), child: const Text('Done')),
              ],
            ),
          ),
        ),
      );
    }

    final isEdit = widget.driver != null;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: AppSpacing.paddingLg, child: Row(children: [Text(isEdit ? 'Edit Driver' : 'Add Driver', style: AppTextStyles.h6()), const Spacer(), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))])),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_error != null) _ErrorBanner(message: _error!),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                        AppSpacing.hGapMd,
                        Expanded(child: TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                      ]),
                      AppSpacing.vGapMd,
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: const [DropdownMenuItem(value: 'MALE', child: Text('Male')), DropdownMenuItem(value: 'FEMALE', child: Text('Female')), DropdownMenuItem(value: 'OTHER', child: Text('Other'))],
                        onChanged: (v) => setState(() => _gender = v ?? 'MALE'),
                      ),
                      AppSpacing.vGapMd,
                      TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Mobile *', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                      AppSpacing.vGapMd,
                      TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                      AppSpacing.vGapMd,
                      TextFormField(controller: _license, decoration: const InputDecoration(labelText: 'License Number', border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                  AppSpacing.hGapSm,
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success500),
                    child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Add Driver'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assign Driver Dialog ──────────────────────────────────────────────────────

class _AssignDriverDialog extends ConsumerStatefulWidget {
  const _AssignDriverDialog({required this.vehicle});
  final TransportVehicleModel vehicle;

  @override
  ConsumerState<_AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends ConsumerState<_AssignDriverDialog> {
  List<TransportDriverModel> _drivers = [];
  bool _loading = true;
  String? _selectedId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.vehicle.driver?.id;
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(transportServiceProvider).getDrivers(limit: 100);
      setState(() { _drivers = res['drivers'] as List<TransportDriverModel>; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final svc = ref.read(transportServiceProvider);
      _selectedId == null ? await svc.unassignDriver(widget.vehicle.id) : await svc.assignDriver(widget.vehicle.id, _selectedId!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _saving = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Driver — ${widget.vehicle.vehicleNo}'),
      content: SizedBox(
        width: 360,
        child: _loading
            ? AppLoaderScreen()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  RadioListTile<String?>(value: null, groupValue: _selectedId, title: const Text('No driver (unassign)'), onChanged: (v) => setState(() => _selectedId = v), contentPadding: EdgeInsets.zero),
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView(
                      shrinkWrap: true,
                      children: _drivers.map((d) => RadioListTile<String?>(
                        value: d.id,
                        groupValue: _selectedId,
                        title: Text(d.fullName),
                        subtitle: d.phone != null ? Text(d.phone!) : null,
                        onChanged: (v) => setState(() => _selectedId = v),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      )).toList(),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving || _loading ? null : _save, style: FilledButton.styleFrom(backgroundColor: AppColors.success500), child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save')),
      ],
    );
  }
}

// ── Students Sheet ────────────────────────────────────────────────────────────

class _StudentsSheet extends ConsumerStatefulWidget {
  const _StudentsSheet({required this.vehicle});
  final TransportVehicleModel vehicle;

  @override
  ConsumerState<_StudentsSheet> createState() => _StudentsSheetState();
}

class _StudentsSheetState extends ConsumerState<_StudentsSheet> {
  List<VehicleStudentAssignment> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ref.read(transportServiceProvider).getVehicleStudents(widget.vehicle.id);
      setState(() { _students = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _remove(VehicleStudentAssignment s) async {
    try {
      await ref.read(transportServiceProvider).removeStudent(widget.vehicle.id, s.studentId);
      setState(() => _students.removeWhere((a) => a.studentId == s.studentId));
    } catch (e) {
      if (mounted) AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _add() async {
    final added = await showDialog<bool>(context: context, builder: (_) => _AddStudentDialog(vehicleId: widget.vehicle.id));
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: AppRadius.brXl))),
          Padding(
            padding: AppSpacing.paddingLg,
            child: Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Students — ${widget.vehicle.vehicleNo}', style: AppTextStyles.h6()), Text('${_students.length} assigned', style: AppTextStyles.bodySm(color: AppColors.neutral500))]),
                const Spacer(),
                FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: FilledButton.styleFrom(backgroundColor: AppColors.success500, visualDensity: VisualDensity.compact)),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : _students.isEmpty
                        ? const _EmptyView(icon: Icons.school_outlined, label: 'No students assigned to this vehicle.')
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: AppSpacing.paddingLg,
                            itemCount: _students.length,
                            separatorBuilder: (_, __) => const Divider(height: 16),
                            itemBuilder: (_, i) {
                              final s = _students[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(backgroundColor: AppColors.success100, child: Text(s.firstName[0], style: AppTextStyles.bodyMd(color: AppColors.success700))),
                                title: Text(s.fullName, style: AppTextStyles.bodyMd()),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (s.classLabel.isNotEmpty) Text(s.classLabel, style: AppTextStyles.caption()),
                                    if (s.pickupStopName != null) Text('Pickup: ${s.pickupStopName}', style: AppTextStyles.caption(color: AppColors.success600)),
                                    if (s.dropStopName != null) Text('Drop: ${s.dropStopName}', style: AppTextStyles.caption(color: AppColors.error600)),
                                  ],
                                ),
                                trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error500), onPressed: () => _remove(s), tooltip: 'Remove'),
                              );
                            },
                          ),
          ),
          AppSpacing.vGapLg,
        ],
      ),
    );
  }
}

// ── Add Student Dialog ────────────────────────────────────────────────────────

class _AddStudentDialog extends ConsumerStatefulWidget {
  const _AddStudentDialog({required this.vehicleId});
  final String vehicleId;

  @override
  ConsumerState<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<_AddStudentDialog> {
  List<UnassignedStudent> _students = [];
  bool _loading = true;
  UnassignedStudent? _selected;
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  bool _saving = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() { super.initState(); _loadStudents(); }

  @override
  void dispose() { _pickupCtrl.dispose(); _dropCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  Future<void> _loadStudents({String? search}) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(transportServiceProvider).getUnassignedStudents(search: search);
      setState(() { _students = res['students'] as List<UnassignedStudent>; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(transportServiceProvider).assignStudent(
        widget.vehicleId,
        studentId: _selected!.id,
        pickupStopName: _pickupCtrl.text.trim().isEmpty ? null : _pickupCtrl.text.trim(),
        dropStopName: _dropCtrl.text.trim().isEmpty ? null : _dropCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _saving = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Student to Vehicle'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            TextField(
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () => _loadStudents(search: v.isEmpty ? null : v));
              },
              decoration: const InputDecoration(labelText: 'Search student', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true),
            ),
            AppSpacing.vGapSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: _loading
                  ? AppLoaderScreen()
                  : _students.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No unassigned students found')))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _students.length,
                          itemBuilder: (_, i) {
                            final s = _students[i];
                            return RadioListTile<UnassignedStudent>(
                              value: s,
                              groupValue: _selected,
                              title: Text(s.fullName),
                              subtitle: s.classLabel.isNotEmpty ? Text(s.classLabel) : null,
                              onChanged: (v) => setState(() => _selected = v),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          },
                        ),
            ),
            AppSpacing.vGapMd,
            TextFormField(controller: _pickupCtrl, decoration: const InputDecoration(labelText: 'Pickup Stop Name', border: OutlineInputBorder(), isDense: true)),
            AppSpacing.vGapSm,
            TextFormField(controller: _dropCtrl, decoration: const InputDecoration(labelText: 'Drop Stop Name', border: OutlineInputBorder(), isDense: true)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected == null || _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.success500),
          child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Assign'),
        ),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: active ? AppColors.success100 : AppColors.neutral100, borderRadius: AppRadius.brXl),
      child: Text(active ? 'Active' : 'Inactive', style: AppTextStyles.caption(color: active ? AppColors.success700 : AppColors.neutral600)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: c), const SizedBox(width: 4), Text(label, style: AppTextStyles.caption(color: c))]);
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 12), visualDensity: VisualDensity.compact),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: AppTextStyles.caption(color: AppColors.neutral500)),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: AppColors.error50, borderRadius: AppRadius.brMd),
      child: Text(message, style: AppTextStyles.bodySm(color: AppColors.error700)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xl3, color: AppColors.error300),
            AppSpacing.vGapMd,
            Text(error, textAlign: TextAlign.center, style: AppTextStyles.bodySm(color: AppColors.neutral600)),
            AppSpacing.vGapLg,
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppIconSize.xl4, color: AppColors.neutral300),
          AppSpacing.vGapLg,
          Text(label, textAlign: TextAlign.center, style: AppTextStyles.bodySm(color: AppColors.neutral500)),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySm(color: AppColors.neutral500)),
        Flexible(child: Text(value, style: AppTextStyles.bodyMd(), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
