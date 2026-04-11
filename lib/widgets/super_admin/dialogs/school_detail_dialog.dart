// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/school_detail_dialog.dart
// PURPOSE: School detail dialog — 5 tabs: Info, Plan, Features, Admin, Subdomain
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../common/address_location_picker.dart';
import '../../common/searchable_dropdown_form_field.dart';
import 'assign_school_admin_dialog.dart';
import '../../../design_system/tokens/app_spacing.dart';

class SchoolDetailDialog extends ConsumerStatefulWidget {
  const SchoolDetailDialog({
    super.key,
    required this.schoolId,
    this.onUpdated,
  });

  final String schoolId;
  final VoidCallback? onUpdated;

  @override
  ConsumerState<SchoolDetailDialog> createState() => _SchoolDetailDialogState();
}

class _SchoolDetailDialogState extends ConsumerState<SchoolDetailDialog>
    with SingleTickerProviderStateMixin {
  SuperAdminSchoolModel? _school;
  Map<String, bool> _features = {};
  List<SuperAdminSchoolGroupModel> _groups = [];
  List<SuperAdminPlanModel> _plans = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  final _nameController = TextEditingController();
  String? _country;
  String? _state;
  String? _city;
  final _pinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _studentLimitController = TextEditingController();
  String _status = 'active';
  String _board = 'CBSE';
  String _schoolType = 'private';
  String? _groupId;
  String? _selectedPlanId;
  int _studentLimit = 500;
  DateTime? _renewalDate;
  bool _saving = false;

  // Feature tab state
  String _featureSearch = '';
  Map<String, bool> _pendingFeatures = {};

  // Info tab change tracking
  bool _infoChanged = false;
  bool _planChanged = false;
  bool _subdomainChanged = false;

  /// Returns the set of feature keys that are included in the currently selected plan.
  /// Empty set means no plan selected or plan has no features configured yet.
  Set<String> get _planAllowedFeatures {
    if (_selectedPlanId == null || _plans.isEmpty) return {};
    try {
      final plan = _plans.firstWhere((p) => p.id == _selectedPlanId);
      if (plan.features.isEmpty) return Set<String>.from(_allFeatureKeys);
      return plan.features.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toSet();
    } catch (_) {
      return Set<String>.from(_allFeatureKeys);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subdomainController.dispose();
    _studentLimitController.dispose();
    super.dispose();
  }

  String? _resolveSelectedPlanId(SuperAdminPlanModel? schoolPlan, List<SuperAdminPlanModel> plans) {
    if (schoolPlan == null || plans.isEmpty) return schoolPlan?.id;
    final schoolPlanId = schoolPlan.id;
    final schoolPlanName = schoolPlan.name.toLowerCase();
    for (final p in plans) {
      if (p.id == schoolPlanId) return p.id;
      if (p.name.toLowerCase() == schoolPlanName) return p.id;
    }
    return schoolPlanId;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(superAdminServiceProvider);
      final school = await service.getSchoolById(widget.schoolId);
      final features = await service.getSchoolFeatures(widget.schoolId);
      final groups = await service.getGroups();
      final plans = await service.getPlans();
      if (mounted) {
        setState(() {
          _school = school;
          _features = features;
          _pendingFeatures = Map.from(features);
          _infoChanged = false;
          _planChanged = false;
          _subdomainChanged = false;
          _groups = groups;
          _plans = plans;
          _loading = false;
          _nameController.text = school.name;
          _country = school.country;
          _state = school.state;
          _city = school.city;
          _pinController.text = school.pin ?? '';
          _phoneController.text = school.phone ?? '';
          _emailController.text = school.email ?? '';
          _subdomainController.text = school.subdomain ?? '';
          _status = school.status;
          _board = school.board;
          _schoolType = school.schoolType;
          _groupId = school.groupId;
          _selectedPlanId = _resolveSelectedPlanId(school.plan, plans);
          _studentLimit = school.studentLimit;
          _studentLimitController.text = school.studentLimit.toString();
          _renewalDate = school.subscriptionEnd;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
      }
    }
  }

  Future<void> _saveInfo() async {
    if (_school == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(superAdminServiceProvider).updateSchool(widget.schoolId, {
        'name': _nameController.text.trim(),
        'board': _board,
        'school_type': _schoolType,
        'country': _country ?? '',
        'state': _state ?? '',
        'city': _city ?? '',
        'pin': _pinController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'status': _status,
        'group_id': _groupId,
      });
      if (mounted) {
        await _load();
        widget.onUpdated?.call();
        AppSnackbar.success(context, 'School updated');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _suspendSchool() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Suspend School?',
      message: 'Suspend ${_school?.name ?? ''}? All staff and students will lose access immediately.',
      confirmLabel: 'Suspend',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolStatus(widget.schoolId, 'suspended');
      if (mounted) {
        _load();
        widget.onUpdated?.call();
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'School suspended');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _savePlan() async {
    if (_selectedPlanId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(superAdminServiceProvider).assignPlan(widget.schoolId, {
        'plan_id': _selectedPlanId,
        'effective_date': _renewalDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'student_limit': _studentLimit,
        'reason': 'plan_change',
      });
      if (mounted) { _load(); AppSnackbar.success(context, 'Plan updated'); }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveFeatures() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(superAdminServiceProvider);
      for (final entry in _pendingFeatures.entries) {
        if ((_features[entry.key] ?? false) != entry.value) {
          await service.toggleSchoolFeature(widget.schoolId, entry.key, entry.value);
        }
      }
      if (mounted) { await _load(); AppSnackbar.success(context, 'Features saved'); }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copyLoginUrl() {
    final sub = _subdomainController.text.trim().isNotEmpty
        ? _subdomainController.text.trim()
        : _school?.subdomain ?? _school?.code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';
    Clipboard.setData(ClipboardData(text: 'https://$sub.vidyron.in'));
    AppSnackbar.success(context, 'URL copied: https://$sub.vidyron.in');
  }

  Future<void> _changeSubdomain() async {
    final value = _subdomainController.text.trim().toLowerCase();
    if (value.isEmpty) return;
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
      AppSnackbar.warning(context, 'Subdomain: alphanumeric and hyphens only');
      return;
    }
    final available = await ref.read(superAdminServiceProvider).checkSubdomainAvailable(value);
    if (!available && mounted) { AppSnackbar.warning(context, 'Subdomain already taken'); return; }
    final ok = await AppDialogs.confirm(
      context,
      title: 'Change Subdomain?',
      message: 'This will break existing staff bookmarks. Share the new URL with the school.',
      confirmLabel: 'Change',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolSubdomain(widget.schoolId, value);
      if (mounted) { _load(); AppSnackbar.success(context, 'Subdomain updated'); }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _resetAdminPassword(String userId) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'New password (min 8 chars)'), obscureText: true),
            AppSpacing.vGapMd,
            TextField(controller: confirmController, decoration: const InputDecoration(labelText: 'Confirm password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final pwd = passwordController.text;
              if (pwd.length >= 8 && pwd == confirmController.text) {
                Navigator.pop(ctx, pwd);
              } else {
                AppSnackbar.warning(ctx, 'Password must match and be at least 8 characters');
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).resetSchoolAdminPassword(widget.schoolId, userId, result);
      if (mounted) AppSnackbar.success(context, 'Password reset. Admin will be notified.');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) => InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        isDense: true,
        filled: true,
        border: OutlineInputBorder(borderRadius: AppRadius.brMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 680,
        maxHeight: isMobile
            ? MediaQuery.sizeOf(context).height * 0.95
            : MediaQuery.sizeOf(context).height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),

          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(isMobile ? 14 : 20, isMobile ? 10 : 14, isMobile ? 8 : 10, isMobile ? 8 : 12),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: AppRadius.brLg),
                  child: Icon(Icons.school_rounded, color: theme.colorScheme.onPrimaryContainer, size: isMobile ? 22 : 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _school?.name ?? 'School Details',
                        style: (isMobile ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      if (_school?.code != null)
                        Text(_school!.code, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  iconSize: isMobile ? 18 : 20,
                  icon: const Icon(Icons.close),
                  onPressed: () { Navigator.of(context).pop(); widget.onUpdated?.call(); },
                ),
              ],
            ),
          ),

          // ── Tab Bar ──────────────────────────────────────────────────────────
          if (isMobile)
            TabBar(
              controller: _tabController,
              isScrollable: false,
              dividerColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tooltip(message: 'Info',      child: Tab(icon: Icon(Icons.info_outline_rounded, size: 22))),
                Tooltip(message: 'Plan',      child: Tab(icon: Icon(Icons.workspace_premium_rounded, size: 22))),
                Tooltip(message: 'Features',  child: Tab(icon: Icon(Icons.tune_rounded, size: 22))),
                Tooltip(message: 'Admin',     child: Tab(icon: Icon(Icons.admin_panel_settings_rounded, size: 22))),
                Tooltip(message: 'Subdomain', child: Tab(icon: Icon(Icons.link_rounded, size: 22))),
              ],
            )
          else
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              padding: AppSpacing.paddingHLg,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline_rounded, size: 20),         text: 'Info'),
                Tab(icon: Icon(Icons.workspace_premium_rounded, size: 20),    text: 'Plan'),
                Tab(icon: Icon(Icons.tune_rounded, size: 20),                 text: 'Features'),
                Tab(icon: Icon(Icons.admin_panel_settings_rounded, size: 20), text: 'Admin'),
                Tab(icon: Icon(Icons.link_rounded, size: 20),                 text: 'Subdomain'),
              ],
            ),

          Expanded(
            child: _loading
                ? AppLoaderScreen()
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInfoTab(),
                          _buildPlanTab(),
                          _buildFeaturesTab(),
                          _buildAdminTab(),
                          _buildSubdomainTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapLg,
          Text(_error!, textAlign: TextAlign.center),
          AppSpacing.vGapLg,
          AppPrimaryButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ===========================================================================
  // INFO TAB — card-per-section with sticky footer
  // ===========================================================================

  Widget _buildInfoTab() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Basic Information ────────────────────────────────────────
                _InfoSectionCard(
                  icon: Icons.business_rounded,
                  title: 'Basic Information',
                  chips: [
                    _statusChip(_status),
                    _chip(_board),
                    _chip(_schoolType == 'private' ? 'Private' : _schoolType == 'government' ? 'Govt' : 'Trust'),
                  ],
                  child: LayoutBuilder(builder: (ctx, c) {
                    final wide = c.maxWidth > 380;
                    if (wide) {
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Column(children: [
                          TextFormField(controller: _nameController, decoration: _inputDecoration('School Name', prefixIcon: const Icon(Icons.school_outlined, size: 18)), onChanged: (_) => setState(() => _infoChanged = true)),
                          const SizedBox(height: 8),
                          _buildReadOnlyField('School Code', _school?.code ?? '—'),
                          const SizedBox(height: 8),
                          SearchableDropdownFormField<String>(value: _board, items: const ['CBSE', 'ICSE', 'State Board', 'IB'], decoration: _inputDecoration('Board'), onChanged: (v) => setState(() { _board = v ?? 'CBSE'; _infoChanged = true; })),
                          const SizedBox(height: 8),
                          SearchableDropdownFormField.valueItems(value: _schoolType, valueItems: const [MapEntry('private', 'Private'), MapEntry('government', 'Government'), MapEntry('trust', 'Trust')], decoration: _inputDecoration('Type'), onChanged: (v) => setState(() { _schoolType = v ?? 'private'; _infoChanged = true; })),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(children: [
                          SearchableDropdownFormField.valueItems(value: _status, valueItems: const [MapEntry('active', 'Active'), MapEntry('trial', 'Trial'), MapEntry('suspended', 'Suspended')], decoration: _inputDecoration('Status'), onChanged: (v) => setState(() { _status = v ?? 'active'; _infoChanged = true; })),
                          const SizedBox(height: 8),
                          SearchableDropdownFormField<String?>.valueItems(value: _groupId, valueItems: [const MapEntry(null, 'None'), ..._groups.map((g) => MapEntry<String?, String>(g.id, g.name))], decoration: _inputDecoration('Group'), onChanged: (v) => setState(() { _groupId = v; _infoChanged = true; })),
                        ])),
                      ]);
                    }
                    return Column(children: [
                      TextFormField(controller: _nameController, decoration: _inputDecoration('School Name', prefixIcon: const Icon(Icons.school_outlined, size: 18)), onChanged: (_) => setState(() => _infoChanged = true)),
                      const SizedBox(height: 8),
                      _buildReadOnlyField('School Code', _school?.code ?? '—'),
                      const SizedBox(height: 8),
                      SearchableDropdownFormField<String>(value: _board, items: const ['CBSE', 'ICSE', 'State Board', 'IB'], decoration: _inputDecoration('Board'), onChanged: (v) => setState(() { _board = v ?? 'CBSE'; _infoChanged = true; })),
                      const SizedBox(height: 8),
                      SearchableDropdownFormField.valueItems(value: _schoolType, valueItems: const [MapEntry('private', 'Private'), MapEntry('government', 'Government'), MapEntry('trust', 'Trust')], decoration: _inputDecoration('Type'), onChanged: (v) => setState(() { _schoolType = v ?? 'private'; _infoChanged = true; })),
                      const SizedBox(height: 8),
                      SearchableDropdownFormField.valueItems(value: _status, valueItems: const [MapEntry('active', 'Active'), MapEntry('trial', 'Trial'), MapEntry('suspended', 'Suspended')], decoration: _inputDecoration('Status'), onChanged: (v) => setState(() { _status = v ?? 'active'; _infoChanged = true; })),
                      const SizedBox(height: 8),
                      SearchableDropdownFormField<String?>.valueItems(value: _groupId, valueItems: [const MapEntry(null, 'None'), ..._groups.map((g) => MapEntry<String?, String>(g.id, g.name))], decoration: _inputDecoration('Group'), onChanged: (v) => setState(() { _groupId = v; _infoChanged = true; })),
                    ]);
                  }),
                ),
                const SizedBox(height: 8),

                // ── Location ──────────────────────────────────────────────────
                _InfoSectionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  chips: [
                    if (_city != null && _city!.isNotEmpty) _chip(_city!),
                    if (_state != null && _state!.isNotEmpty) _chip(_state!),
                  ],
                  child: Column(children: [
                    AddressLocationPicker(
                      country: _country, state: _state, city: _city, compact: true,
                      countryDecoration: _inputDecoration('Country'),
                      stateDecoration: _inputDecoration('State'),
                      cityDecoration: _inputDecoration('City'),
                      onCountryChanged: (v) => setState(() { _country = v; _infoChanged = true; }),
                      onStateChanged: (v) => setState(() { _state = v; _infoChanged = true; }),
                      onCityChanged: (v) => setState(() { _city = v; _infoChanged = true; }),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(controller: _pinController, decoration: _inputDecoration('PIN Code', prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18)), keyboardType: TextInputType.number, onChanged: (_) => setState(() => _infoChanged = true)),
                  ]),
                ),
                const SizedBox(height: 8),

                // ── Contact ───────────────────────────────────────────────────
                _InfoSectionCard(
                  icon: Icons.contact_phone_outlined,
                  title: 'Contact',
                  chips: [
                    if (_phoneController.text.isNotEmpty) _chip(_phoneController.text),
                  ],
                  child: LayoutBuilder(builder: (ctx, c) {
                    if (c.maxWidth > 380) {
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone', prefixIcon: const Icon(Icons.phone_outlined, size: 18)), keyboardType: TextInputType.phone, onChanged: (_) => setState(() => _infoChanged = true))),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: TextFormField(controller: _emailController, decoration: _inputDecoration('Email', prefixIcon: const Icon(Icons.email_outlined, size: 18)), keyboardType: TextInputType.emailAddress, onChanged: (_) => setState(() => _infoChanged = true))),
                      ]);
                    }
                    return Column(children: [
                      TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone', prefixIcon: const Icon(Icons.phone_outlined, size: 18)), keyboardType: TextInputType.phone, onChanged: (_) => setState(() => _infoChanged = true)),
                      const SizedBox(height: 8),
                      TextFormField(controller: _emailController, decoration: _inputDecoration('Email', prefixIcon: const Icon(Icons.email_outlined, size: 18)), keyboardType: TextInputType.emailAddress, onChanged: (_) => setState(() => _infoChanged = true)),
                    ]);
                  }),
                ),
                const SizedBox(height: 8),

                // ── Danger zone ───────────────────────────────────────────────
                if (_school?.status != 'suspended')
                  AppOutlineButton(
                    onPressed: _suspendSchool,
                    color: scheme.error,
                    icon: const Icon(Icons.block, size: 18),
                    child: const Text('Suspend School'),
                  ),
              ],
            ),
          ),
        ),

        _buildStickyFooter(
          hasUnsaved: _infoChanged,
          onCancel: () => setState(() {
            _nameController.text = _school?.name ?? '';
            _board = _school?.board ?? 'CBSE';
            _schoolType = _school?.schoolType ?? 'private';
            _status = _school?.status ?? 'active';
            _groupId = _school?.groupId;
            _country = _school?.country;
            _state = _school?.state;
            _city = _school?.city;
            _pinController.text = _school?.pin ?? '';
            _phoneController.text = _school?.phone ?? '';
            _emailController.text = _school?.email ?? '';
            _infoChanged = false;
          }),
          onSave: _saving ? null : _saveInfo,
          isSaving: _saving,
          saveLabel: 'Save Changes',
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return InputDecorator(
      decoration: _inputDecoration(label).copyWith(filled: true, enabled: false),
      child: Text(value, style: TextStyle(fontFamily: 'monospace', color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  // ===========================================================================
  // PLAN TAB
  // ===========================================================================

  Widget _buildPlanTab() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Sort by sortOrder for consistent display
    final sortedPlans = [..._plans]..sort((a, b) => (a.sortOrder ?? 99).compareTo(b.sortOrder ?? 99));

    SuperAdminPlanModel? plan;
    for (final p in sortedPlans) {
      if (p.id == _selectedPlanId) { plan = p; break; }
    }
    plan ??= sortedPlans.isNotEmpty ? sortedPlans.first : null;

    final pricePerStudent = plan?.pricePerStudent ?? 0.0;
    final billEstimate = pricePerStudent * _studentLimit;

    // "Popular" = middle plan by sort order
    final popularIdx = sortedPlans.length > 2 ? sortedPlans.length ~/ 2 : -1;

    // Renewal date display
    String? renewalLabel;
    if (_renewalDate != null) {
      final days = _renewalDate!.difference(DateTime.now()).inDays;
      renewalLabel = '${_renewalDate!.day}/${_renewalDate!.month}/${_renewalDate!.year} (in $days days)';
    }

    // Feature bullets for detail card — use actual plan features
    List<String> planFeatureLabels = [];
    if (plan != null) {
      if (plan.features.isNotEmpty) {
        final enabledKeys = plan.features.entries.where((e) => e.value).map((e) => e.key).toList();
        planFeatureLabels = enabledKeys.map((k) {
          return k.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
        }).toList();
      } else {
        planFeatureLabels = ['Core school modules included'];
      }
      if (plan.supportLevel != null && !planFeatureLabels.any((f) => f.toLowerCase().contains('support'))) {
        planFeatureLabels.add('${plan.supportLevel} support');
      }
    }

    // Savings: vs the next higher-priced plan
    double? savingsPerStudent;
    String? savingsVsPlan;
    if (plan != null) {
      final higher = (sortedPlans.where((p) => p.pricePerStudent > plan!.pricePerStudent).toList()
        ..sort((a, b) => a.pricePerStudent.compareTo(b.pricePerStudent)));
      if (higher.isNotEmpty) {
        savingsPerStudent = higher.first.pricePerStudent - plan.pricePerStudent;
        savingsVsPlan = higher.first.name;
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          // ── Plan selector: horizontal card row ───────────────────────────
          Text('Select Plan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          SizedBox(
            height: 74,
            child: Row(
              children: sortedPlans.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isSelected = _selectedPlanId == p.id;
                final isPopular = idx == popularIdx;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: idx == 0 ? 0 : 6),
                    child: GestureDetector(
                      onTap: () => setState(() { _selectedPlanId = p.id; _planChanged = true; }),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: AppRadius.brMd,
                              border: Border.all(color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5), width: isSelected ? 2 : 1),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isPopular) const SizedBox(height: 6),
                                  Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : scheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                  const SizedBox(height: 2),
                                  Text('₹${p.pricePerStudent.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white.withAlpha(200) : scheme.onSurfaceVariant)),
                                  if (p.features.isNotEmpty)
                                    Text(
                                      '${p.features.values.where((v) => v).length} features',
                                      style: TextStyle(fontSize: 10, color: isSelected ? Colors.white.withAlpha(180) : scheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isPopular)
                            Positioned(
                              top: -9,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(6)),
                                child: const Text('POPULAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // ── Selected plan detail card ─────────────────────────────────────
          if (plan != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: AppRadius.brLg,
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
                            TextSpan(text: '₹${plan.pricePerStudent.toStringAsFixed(0)} ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)),
                            TextSpan(text: '/student /month', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ]),
                        ),
                        if (plan.description != null && plan.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(plan.description!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...planFeatureLabels.take(5).map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_rounded, size: 14, color: scheme.primary),
                            const SizedBox(width: 5),
                            Flexible(child: Text(f, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                        )),
                        if (plan.features.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${plan.features.values.where((v) => v).length} of ${_allFeatureKeys.length} features included',
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // ── Student limit + Renewal date (2-col) ──────────────────────────
          Row(
            children: [
              // Student limit
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Student limit', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 26,
                              child: TextFormField(
                                controller: _studentLimitController,
                                keyboardType: TextInputType.number,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                onChanged: (v) => setState(() { _studentLimit = int.tryParse(v) ?? _studentLimit; _planChanged = true; }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Renewal date
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _renewalDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (d != null) setState(() { _renewalDate = d; _planChanged = true; });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Renewal date', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(renewalLabel ?? 'Tap to set', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Estimated Monthly Bill ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppRadius.brMd,
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Estimated Monthly Bill', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${_fmtIndian(billEstimate.toInt())}/mo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('$_studentLimit × ₹${pricePerStudent.toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),

          // ── Savings banner ────────────────────────────────────────────────
          if (savingsPerStudent != null && savingsPerStudent > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: AppRadius.brMd,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re saving ₹${savingsPerStudent.toStringAsFixed(0)}/student vs ${savingsVsPlan ?? 'next'} plan',
                      style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

              ],
            ),
          ),
        ),
        _buildStickyFooter(
          hasUnsaved: _planChanged,
          onCancel: () => setState(() {
            _selectedPlanId = _resolveSelectedPlanId(_school?.plan, _plans);
            _studentLimit = _school?.studentLimit ?? 500;
            _studentLimitController.text = (_school?.studentLimit ?? 500).toString();
            _renewalDate = _school?.subscriptionEnd;
            _planChanged = false;
          }),
          onSave: _saving ? null : _savePlan,
          isSaving: _saving,
          saveLabel: 'Save Plan',
          saveIcon: Icons.workspace_premium_rounded,
        ),
      ],
    );
  }

  /// Indian number formatting: 224550 → 2,24,550
  static String _fmtIndian(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    var result = s.substring(s.length - 3);
    var rem = s.substring(0, s.length - 3);
    while (rem.length > 2) {
      result = '${rem.substring(rem.length - 2)},$result';
      rem = rem.substring(0, rem.length - 2);
    }
    return rem.isNotEmpty ? '$rem,$result' : result;
  }

  // ===========================================================================
  // FEATURES TAB — grouped layout with sticky footer
  // ===========================================================================

  /// Must match backend DEFAULT_FEATURE_KEYS (super-admin.service.js).
  static const _allFeatureKeys = [
    'ai_intelligence', 'attendance', 'certificates', 'chat_system',
    'exams', 'fees', 'gps_transport', 'hostel', 'library',
    'online_payments', 'parent_app', 'reports', 'rfid_attendance',
    'timetable', 'transport',
  ];

  static List<_FeatGroupDef> get _featGroupDefs => [
    const _FeatGroupDef(title: 'Core Modules',   icon: Icons.school_rounded,       color: Color(0xFF2563EB), description: 'Essential daily operations',      keys: ['attendance', 'fees', 'exams', 'timetable', 'certificates']),
    const _FeatGroupDef(title: 'Smart Features', icon: Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), description: 'AI-powered insights & tools',     keys: ['ai_intelligence', 'reports']),
    const _FeatGroupDef(title: 'Infrastructure', icon: Icons.hub_rounded,          color: Color(0xFF059669), description: 'Connectivity & integrations',     keys: ['parent_app', 'chat_system', 'online_payments', 'rfid_attendance']),
    const _FeatGroupDef(title: 'Academic Tools', icon: Icons.menu_book_rounded,    color: Color(0xFFD97706), description: 'Resources & campus services',     keys: ['library', 'transport', 'gps_transport', 'hostel']),
  ];

  Widget _buildFeaturesTab() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allKeys = ({..._allFeatureKeys, ..._features.keys, ..._pendingFeatures.keys}.toList()..sort());
    final query = _featureSearch.toLowerCase().trim();
    final filtered = query.isEmpty
        ? allKeys
        : allKeys.where((k) { final m = _featureMeta(k); return k.contains(query) || m.title.toLowerCase().contains(query); }).toList();
    final enabledCount = allKeys.where((k) => _pendingFeatures[k] ?? _features[k] ?? false).length;
    final allowed = _planAllowedFeatures;
    final lockedCount = allowed.isEmpty ? 0 : allKeys.where((k) => !allowed.contains(k)).length;
    final availableCount = allKeys.length - lockedCount;
    final hasUnsaved = _pendingFeatures.entries.any((e) => (_features[e.key] ?? false) != e.value);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Row(children: [
                        Text('Feature Toggles', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                          child: Text('$enabledCount/$availableCount on', style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                        ),
                        if (lockedCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.lock_outline_rounded, size: 10, color: scheme.outlineVariant),
                              const SizedBox(width: 3),
                              Text('$lockedCount locked', style: theme.textTheme.labelSmall?.copyWith(color: scheme.outlineVariant, fontWeight: FontWeight.w600, fontSize: 10)),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                    _featureActionBtn('All On',  Icons.check_circle_outline_rounded, scheme.primary, () {
                      setState(() {
                        for (final k in allKeys) {
                          if (allowed.isEmpty || allowed.contains(k)) _pendingFeatures[k] = true;
                        }
                      });
                    }),
                    _featureActionBtn('All Off', Icons.cancel_outlined,              scheme.error,             () { setState(() { for (final k in allKeys) _pendingFeatures[k] = false; }); }),
                    _featureActionBtn('Reset',   Icons.restore_rounded,              scheme.onSurfaceVariant,  () { setState(() => _pendingFeatures = Map.from(_features)); }),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Search ────────────────────────────────────────────────────
                TextField(
                  onChanged: (v) => setState(() => _featureSearch = v),
                  decoration: _inputDecoration('Search features…', prefixIcon: const Icon(Icons.search_rounded, size: 18)),
                ),
                const SizedBox(height: 12),

                // ── Plan restriction banner ─────────────────────────────────
                Builder(builder: (ctx) {
                  if (allowed.isEmpty || allowed.length >= _allFeatureKeys.length) return const SizedBox.shrink();
                  SuperAdminPlanModel? currentPlan;
                  try { currentPlan = _plans.firstWhere((p) => p.id == _selectedPlanId); } catch (_) {}
                  final planName = currentPlan?.name ?? 'current plan';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: scheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$lockedCount features locked by $planName plan. Upgrade plan to unlock.',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer, fontSize: 11),
                        ),
                      ),
                    ]),
                  );
                }),

                // ── Groups (2-col on wide, 1-col on narrow) ───────────────────
                LayoutBuilder(builder: (ctx, constraints) {
                  final wide = constraints.maxWidth > 480;
                  final groups = _featGroupDefs;
                  if (wide) {
                    final rows = <Widget>[];
                    for (int i = 0; i < groups.length; i += 2) {
                      rows.add(Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildFeatureGroup(groups[i], filtered, theme, scheme)),
                            const SizedBox(width: 8),
                            Expanded(child: i + 1 < groups.length ? _buildFeatureGroup(groups[i + 1], filtered, theme, scheme) : const SizedBox()),
                          ],
                        ),
                      ));
                    }
                    return Column(children: rows);
                  }
                  return Column(
                    children: groups.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildFeatureGroup(g, filtered, theme, scheme),
                    )).toList(),
                  );
                }),

                // ── Ungrouped features ────────────────────────────────────────
                Builder(builder: (ctx) {
                  final ungrouped = filtered.where((k) => !_featGroupDefs.any((g) => g.keys.contains(k))).toList();
                  if (ungrouped.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildFeatureGroupRaw('Other', Icons.extension_rounded, const Color(0xFF6B7280), 'Additional features', ungrouped, theme, scheme),
                  );
                }),

                // ── AI Suggestion banner ──────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [scheme.primaryContainer.withValues(alpha: 0.7), scheme.tertiaryContainer.withValues(alpha: 0.5)]),
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: scheme.primaryContainer),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Suggestion', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)),
                            Text('Enable Attendance + Reports + Parent App for best engagement.', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() { _pendingFeatures['attendance'] = true; _pendingFeatures['reports'] = true; _pendingFeatures['parent_app'] = true; }),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                        child: const Text('Apply', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildStickyFooter(
          hasUnsaved: hasUnsaved,
          onCancel: () => setState(() => _pendingFeatures = Map.from(_features)),
          onSave: _saving ? null : _saveFeatures,
          isSaving: _saving,
          saveLabel: 'Save Features',
        ),
      ],
    );
  }

  Widget _buildFeatureGroup(_FeatGroupDef g, List<String> filtered, ThemeData theme, ColorScheme scheme) {
    final keys = g.keys.where((k) => filtered.contains(k)).toList();
    if (keys.isEmpty) return const SizedBox.shrink();
    return _buildFeatureGroupRaw(g.title, g.icon, g.color, g.description, keys, theme, scheme);
  }

  Widget _buildFeatureGroupRaw(String title, IconData icon, Color color, String desc, List<String> keys, ThemeData theme, ColorScheme scheme) {
    final enabledCount = keys.where((k) => _pendingFeatures[k] ?? _features[k] ?? false).length;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: AppRadius.brSm),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(desc, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: enabledCount > 0 ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$enabledCount/${keys.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: enabledCount > 0 ? scheme.primary : scheme.onSurfaceVariant)),
                ),
                TextButton(
                  onPressed: () {
                    final planAllowed = _planAllowedFeatures;
                    setState(() {
                      for (final k in keys) {
                        if (planAllowed.isEmpty || planAllowed.contains(k)) _pendingFeatures[k] = true;
                      }
                    });
                  },
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('On', style: TextStyle(fontSize: 11, color: scheme.primary)),
                ),
                TextButton(
                  onPressed: () => setState(() { for (final k in keys) _pendingFeatures[k] = false; }),
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), tapTargetSize: MaterialTapTargetSize.shrinkWrap, foregroundColor: scheme.error),
                  child: Text('Off', style: TextStyle(fontSize: 11, color: scheme.error)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: keys.map((k) {
                final planAllowed = _planAllowedFeatures;
                final locked = planAllowed.isNotEmpty && !planAllowed.contains(k);
                return _buildFeatureItem(k, theme, scheme, isLocked: locked);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String key, ThemeData theme, ColorScheme scheme, {bool isLocked = false}) {
    final meta = _featureMeta(key);
    final enabled = !isLocked && (_pendingFeatures[key] ?? _features[key] ?? false);
    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: enabled ? scheme.primaryContainer.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          children: [
            Icon(meta.icon, size: 15, color: enabled ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meta.title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: enabled ? scheme.onSurface : scheme.onSurfaceVariant),
                  ),
                  Text(meta.desc,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 10, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text('Locked', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              Transform.scale(
                scale: 0.75,
                child: Switch(value: enabled, onChanged: (v) => setState(() => _pendingFeatures[key] = v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
          ],
        ),
      ),
    );
  }

  static ({IconData icon, String title, String desc}) _featureMeta(String key) {
    switch (key) {
      case 'ai_intelligence': return (icon: Icons.auto_awesome_rounded,        title: 'AI Intelligence',   desc: 'Smart insights & predictions');
      case 'attendance':      return (icon: Icons.how_to_reg_rounded,           title: 'Attendance',        desc: 'Daily student/staff tracking');
      case 'certificates':    return (icon: Icons.workspace_premium_rounded,    title: 'Certificates',      desc: 'Achievement certificates');
      case 'chat_system':     return (icon: Icons.chat_bubble_outline_rounded,  title: 'Chat System',       desc: 'Staff & parent messaging');
      case 'exams':           return (icon: Icons.assignment_rounded,           title: 'Examinations',      desc: 'Marks, results & report cards');
      case 'fees':            return (icon: Icons.payments_rounded,             title: 'Fees & Finance',    desc: 'Fee collection & receipts');
      case 'gps_transport':   return (icon: Icons.gps_fixed_rounded,            title: 'GPS Tracking',      desc: 'Real-time bus location');
      case 'hostel':          return (icon: Icons.hotel_rounded,                title: 'Hostel',            desc: 'Boarding rooms & occupancy');
      case 'library':         return (icon: Icons.local_library_rounded,        title: 'Library',           desc: 'Books issue & return');
      case 'online_payments': return (icon: Icons.credit_card_rounded,          title: 'Online Payments',   desc: 'Razorpay integration');
      case 'parent_app':      return (icon: Icons.family_restroom_rounded,      title: 'Parent App',        desc: 'Parent portal & alerts');
      case 'reports':         return (icon: Icons.bar_chart_rounded,            title: 'Reports',           desc: 'Analytics & data exports');
      case 'rfid_attendance': return (icon: Icons.nfc_rounded,                  title: 'RFID Attendance',   desc: 'Smart card reader');
      case 'timetable':       return (icon: Icons.calendar_view_week_rounded,   title: 'Timetable',         desc: 'Weekly schedule builder');
      case 'transport':       return (icon: Icons.directions_bus_rounded,       title: 'Transport',         desc: 'Buses, routes & assignment');
      default:
        final t = key.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
        return (icon: Icons.toggle_on_rounded, title: t, desc: 'Custom feature');
    }
  }

  Widget _featureActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================

  Widget _buildStickyFooter({
    required bool hasUnsaved,
    required VoidCallback? onCancel,
    VoidCallback? onSave,
    bool isSaving = false,
    String? saveLabel,
    IconData saveIcon = Icons.save_rounded,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (hasUnsaved) ...[
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Unsaved changes', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 11)),
          ],
          const Spacer(),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          if (saveLabel != null) ...[
            const SizedBox(width: 6),
            AppPrimaryButton(onPressed: onSave, isLoading: isSaving, icon: Icon(saveIcon, size: 16), child: Text(saveLabel)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
    );
  }

  Widget _statusChip(String status) {
    switch (status) {
      case 'active':    return _colorChip('Active',    const Color(0xFFD1FAE5), const Color(0xFF065F46));
      case 'trial':     return _colorChip('Trial',     const Color(0xFFFEF3C7), const Color(0xFF92400E));
      case 'suspended': return _colorChip('Suspended', const Color(0xFFFEE2E2), const Color(0xFF991B1B));
      default:          return _chip(status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : status);
    }
  }

  Widget _colorChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ===========================================================================
  // ADMIN TAB
  // ===========================================================================

  Widget _buildAdminTab() {
    final theme = Theme.of(context);
    final admin = _school?.primaryAdmin;
    if (admin == null || admin.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: AppSpacing.paddingXl,
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 20),
                    Text('No admin assigned', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                    AppSpacing.vGapSm,
                    Text('Primary admin details will appear here once assigned.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          _buildStickyFooter(
            hasUnsaved: false,
            onCancel: () => Navigator.of(context).pop(),
            onSave: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AssignSchoolAdminDialog(schoolId: widget.schoolId, schoolName: _school?.name ?? 'this school', onAssigned: _load),
              );
              if (ok == true && mounted) widget.onUpdated?.call();
            },
            saveLabel: 'Assign Admin',
            saveIcon: Icons.person_add_rounded,
          ),
        ],
      );
    }
    final name   = admin['name'] ?? admin['email'] ?? 'Admin';
    final email  = admin['email'] ?? '';
    final mobile = admin['mobile'] ?? admin['phone'] ?? '';
    final userId = admin['id']?.toString() ?? '';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          _SectionHeader(title: 'Primary Admin', icon: Icons.admin_panel_settings_rounded),
          AppSpacing.vGapLg,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: AppRadius.brXl,
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          AppSpacing.vGapXs,
                          Row(children: [Icon(Icons.email_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 6), Expanded(child: Text(email, style: theme.textTheme.bodyMedium))]),
                          if (mobile.isNotEmpty) ...[
                            AppSpacing.vGapXs,
                            Row(children: [Icon(Icons.phone_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 6), Text(mobile, style: theme.textTheme.bodyMedium)]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (userId.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  AppSpacing.vGapMd,
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      AppSecondaryButton(onPressed: () => _resetAdminPassword(userId), icon: const Icon(Icons.lock_reset_rounded, size: 18), child: const Text('Reset Password')),
                      AppOutlineButton(
                        onPressed: () async {
                          final ok = await AppDialogs.confirm(context, title: 'Deactivate Admin?', message: 'This admin will lose access to the school.', confirmLabel: 'Deactivate', isDestructive: true);
                          if (ok && mounted) { await ref.read(superAdminServiceProvider).deactivateSchoolAdmin(widget.schoolId, userId); _load(); }
                        },
                        color: theme.colorScheme.error,
                        icon: const Icon(Icons.person_off_rounded, size: 18),
                        child: const Text('Deactivate'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
        ),
        _buildStickyFooter(
          hasUnsaved: false,
          onCancel: () => Navigator.of(context).pop(),
          saveLabel: null,
        ),
      ],
    );
  }

  // ===========================================================================
  // SUBDOMAIN TAB
  // ===========================================================================

  Widget _buildSubdomainTab() {
    final theme = Theme.of(context);
    final subdomain = _subdomainController.text.trim().isNotEmpty
        ? _subdomainController.text.trim()
        : _school?.subdomain ?? _school?.code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';
    final loginUrl = 'https://$subdomain.vidyron.in';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(title: 'Subdomain', icon: Icons.link_rounded),
                AppSpacing.vGapSm,
                Text('Schools access the platform via a unique subdomain (e.g. yourschool.vidyron.in).', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                AppSpacing.vGapLg,
                TextFormField(
                  controller: _subdomainController,
                  decoration: _inputDecoration('Subdomain', prefixIcon: const Icon(Icons.link_rounded, size: 20)).copyWith(hintText: 'e.g. greenvalley'),
                  onChanged: (_) => setState(() => _subdomainChanged = true),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded, color: theme.colorScheme.primary, size: 24),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Login URL', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            Text(loginUrl, style: theme.textTheme.titleSmall?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      AppSecondaryButton(onPressed: _copyLoginUrl, icon: const Icon(Icons.copy_rounded, size: 18), child: const Text('Copy')),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,
                Text('Changing the subdomain will break existing bookmarks. Share the new URL with the school.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ),
        _buildStickyFooter(
          hasUnsaved: _subdomainChanged,
          onCancel: () => setState(() {
            _subdomainController.text = _school?.subdomain ?? '';
            _subdomainChanged = false;
          }),
          onSave: _changeSubdomain,
          saveLabel: 'Change Subdomain',
          saveIcon: Icons.edit_rounded,
        ),
      ],
    );
  }
}

// =============================================================================
// Section header widget (shared across tabs)
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        AppSpacing.hGapSm,
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary, letterSpacing: 0.2)),
      ],
    );
  }
}

// =============================================================================
// Info tab card wrapper
// =============================================================================

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.icon,
    required this.title,
    required this.chips,
    required this.child,
  });
  final IconData icon;
  final String title;
  final List<Widget> chips;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.5), borderRadius: AppRadius.brSm),
                  child: Icon(icon, size: 15, color: scheme.primary),
                ),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (chips.isNotEmpty)
                  Wrap(spacing: 4, children: chips),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

// =============================================================================
// Feature group definition
// =============================================================================

class _FeatGroupDef {
  const _FeatGroupDef({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.keys,
  });
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> keys;
}
