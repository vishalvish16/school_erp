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

  /// Resolves the school's current plan to a plan ID from the plans list.
  /// Backend may return plan.id as 'BASIC'/'STANDARD'/'PREMIUM' (enum) while
  /// getPlans() returns platform_plans with numeric IDs. Match by id or name.
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
    setState(() {
      _loading = true;
      _error = null;
    });
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
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
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
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
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
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<void> _savePlan() async {
    if (_selectedPlanId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(superAdminServiceProvider).assignPlan(widget.schoolId, {
        'plan_id': _selectedPlanId,
        'effective_date': _renewalDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'reason': 'plan_change',
      });
      if (mounted) {
        _load();
        AppSnackbar.success(context, 'Plan updated');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFeature(String key, bool value) async {
    final prev = _features[key] ?? false;
    setState(() => _features[key] = value);
    try {
      await ref.read(superAdminServiceProvider).toggleSchoolFeature(widget.schoolId, key, value);
      if (mounted) {
        AppSnackbar.success(context, '$key ${value ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _features[key] = prev);
        AppSnackbar.error(context, 'Failed: ${e.toString()}');
      }
    }
  }

  void _copyLoginUrl() {
    final sub = _subdomainController.text.trim().isNotEmpty
        ? _subdomainController.text.trim()
        : _school?.subdomain ?? _school?.code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';
    final url = 'https://$sub.vidyron.in';
    Clipboard.setData(ClipboardData(text: url));
    AppSnackbar.success(context, 'URL copied: $url');
  }

  Future<void> _changeSubdomain() async {
    final value = _subdomainController.text.trim().toLowerCase();
    if (value.isEmpty) return;
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
      AppSnackbar.warning(context, 'Subdomain: alphanumeric and hyphens only');
      return;
    }
    final available = await ref.read(superAdminServiceProvider).checkSubdomainAvailable(value);
    if (!available && mounted) {
      AppSnackbar.warning(context, 'Subdomain already taken');
      return;
    }
    final ok = await AppDialogs.confirm(
      context,
      title: 'Change Subdomain?',
      message: 'This will break existing staff bookmarks. Share the new URL with the school.',
      confirmLabel: 'Change',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolSubdomain(widget.schoolId, value);
      if (mounted) {
        _load();
        AppSnackbar.success(context, 'Subdomain updated');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
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
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'New password (min 8 chars)'),
              obscureText: true,
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
            ),
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
      await ref.read(superAdminServiceProvider).resetSchoolAdminPassword(
            widget.schoolId,
            userId,
            result,
          );
      if (mounted) {
        AppSnackbar.success(context, 'Password reset. Admin will be notified.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        filled: true,
        border: OutlineInputBorder(borderRadius: AppRadius.brLg),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: AppRadius.brLg,
                    ),
                    child: Icon(Icons.school_rounded, color: theme.colorScheme.onPrimaryContainer, size: 28),
                  ),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _school?.name ?? 'School Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (_school?.code != null)
                          Text(
                            _school!.code,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onUpdated?.call();
                    },
                  ),
                ],
              ),
            ),
            // Tabs
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
                Tab(icon: Icon(Icons.info_outline_rounded, size: 20), text: 'Info'),
                Tab(icon: Icon(Icons.workspace_premium_rounded, size: 20), text: 'Plan'),
                Tab(icon: Icon(Icons.tune_rounded, size: 20), text: 'Features'),
                Tab(icon: Icon(Icons.admin_panel_settings_rounded, size: 20), text: 'Admin'),
                Tab(icon: Icon(Icons.link_rounded, size: 20), text: 'Subdomain'),
              ],
            ),
            AppSpacing.vGapSm,
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
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
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic info section
          _SectionHeader(title: 'Basic Information', icon: Icons.business_rounded),
          AppSpacing.vGapMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoCol = constraints.maxWidth > 400;
              return useTwoCol
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration('School Name', prefixIcon: const Icon(Icons.school_outlined, size: 20)),
                              ),
                              AppSpacing.vGapMd,
                              _buildReadOnlyField('School Code', _school?.code ?? '—'),
                              AppSpacing.vGapMd,
                              SearchableDropdownFormField<String>(
                                value: _board,
                                items: const ['CBSE', 'ICSE', 'State Board', 'IB'],
                                decoration: _inputDecoration('Board'),
                                onChanged: (v) => setState(() => _board = v ?? 'CBSE'),
                              ),
                              AppSpacing.vGapMd,
                              SearchableDropdownFormField.valueItems(
                                value: _schoolType,
                                valueItems: const [
                                  MapEntry('private', 'Private'),
                                  MapEntry('government', 'Government'),
                                  MapEntry('trust', 'Trust'),
                                ],
                                decoration: _inputDecoration('Type'),
                                onChanged: (v) => setState(() => _schoolType = v ?? 'private'),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.hGapLg,
                        Expanded(
                          child: Column(
                            children: [
                              SearchableDropdownFormField.valueItems(
                                value: _status,
                                valueItems: const [
                                  MapEntry('active', 'Active'),
                                  MapEntry('trial', 'Trial'),
                                  MapEntry('suspended', 'Suspended'),
                                ],
                                decoration: _inputDecoration('Status'),
                                onChanged: (v) => setState(() => _status = v ?? 'active'),
                              ),
                              AppSpacing.vGapMd,
                              SearchableDropdownFormField<String?>.valueItems(
                                value: _groupId,
                                valueItems: [
                                  const MapEntry(null, 'None'),
                                  ..._groups.map((g) => MapEntry<String?, String>(g.id, g.name)),
                                ],
                                decoration: _inputDecoration('Group'),
                                onChanged: (v) => setState(() => _groupId = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('School Name', prefixIcon: const Icon(Icons.school_outlined, size: 20)),
                        ),
                        AppSpacing.vGapMd,
                        _buildReadOnlyField('School Code', _school?.code ?? '—'),
                        AppSpacing.vGapMd,
                        SearchableDropdownFormField<String>(
                          value: _board,
                          items: const ['CBSE', 'ICSE', 'State Board', 'IB'],
                          decoration: _inputDecoration('Board'),
                          onChanged: (v) => setState(() => _board = v ?? 'CBSE'),
                        ),
                        AppSpacing.vGapMd,
                        SearchableDropdownFormField.valueItems(
                          value: _schoolType,
                          valueItems: const [
                            MapEntry('private', 'Private'),
                            MapEntry('government', 'Government'),
                            MapEntry('trust', 'Trust'),
                          ],
                          decoration: _inputDecoration('Type'),
                          onChanged: (v) => setState(() => _schoolType = v ?? 'private'),
                        ),
                        AppSpacing.vGapMd,
                        SearchableDropdownFormField.valueItems(
                          value: _status,
                          valueItems: const [
                            MapEntry('active', 'Active'),
                            MapEntry('trial', 'Trial'),
                            MapEntry('suspended', 'Suspended'),
                          ],
                          decoration: _inputDecoration('Status'),
                          onChanged: (v) => setState(() => _status = v ?? 'active'),
                        ),
                        AppSpacing.vGapMd,
                        SearchableDropdownFormField<String?>.valueItems(
                          value: _groupId,
                          valueItems: [
                            const MapEntry(null, 'None'),
                            ..._groups.map((g) => MapEntry<String?, String>(g.id, g.name)),
                          ],
                          decoration: _inputDecoration('Group'),
                          onChanged: (v) => setState(() => _groupId = v),
                        ),
                      ],
                    );
            },
          ),
          AppSpacing.vGapXl,

          // Location section — Country first, then State, then City (cascading)
          _SectionHeader(title: 'Location', icon: Icons.location_on_outlined),
          AppSpacing.vGapMd,
          AddressLocationPicker(
            country: _country,
            state: _state,
            city: _city,
            onCountryChanged: (v) => setState(() => _country = v),
            onStateChanged: (v) => setState(() => _state = v),
            onCityChanged: (v) => setState(() => _city = v),
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: _pinController,
            decoration: _inputDecoration('PIN Code', prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20)),
            keyboardType: TextInputType.number,
          ),
          AppSpacing.vGapXl,

          // Contact section
          _SectionHeader(title: 'Contact', icon: Icons.contact_phone_outlined),
          AppSpacing.vGapMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoCol = constraints.maxWidth > 400;
              return useTwoCol
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: _inputDecoration('Phone', prefixIcon: const Icon(Icons.phone_outlined, size: 20)),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        AppSpacing.hGapLg,
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email', prefixIcon: const Icon(Icons.email_outlined, size: 20)),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: _inputDecoration('Phone', prefixIcon: const Icon(Icons.phone_outlined, size: 20)),
                          keyboardType: TextInputType.phone,
                        ),
                        AppSpacing.vGapMd,
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration('Email', prefixIcon: const Icon(Icons.email_outlined, size: 20)),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 28),

          // Actions
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 400;
                final suspendBtn = _school?.status != 'suspended'
                    ? TextButton.icon(
                        onPressed: _suspendSchool,
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Suspend School'),
                        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      )
                    : null;
                final saveBtn = FilledButton.icon(
                  onPressed: _saving ? null : _saveInfo,
                  icon: _saving
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                  ),
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?suspendBtn,
                      if (suspendBtn != null) AppSpacing.vGapSm,
                      saveBtn,
                    ],
                  );
                }
                return Row(
                  children: [
                    ?suspendBtn,
                    const Spacer(),
                    Flexible(child: saveBtn),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return InputDecorator(
      decoration: _inputDecoration(label).copyWith(
        filled: true,
        enabled: false,
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPlanTab() {
    final theme = Theme.of(context);
    SuperAdminPlanModel? plan;
    for (final p in _plans) {
      if (p.id == _selectedPlanId) {
        plan = p;
        break;
      }
    }
    plan ??= _plans.isNotEmpty ? _plans.first : null;
    final pricePerStudent = plan?.pricePerStudent ?? 0.0;
    final billEstimate = pricePerStudent * _studentLimit;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: 'Select Plan', icon: Icons.workspace_premium_rounded),
          AppSpacing.vGapMd,
          ..._plans.map((p) {
            final selected = _selectedPlanId == p.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: AppRadius.brLg,
                child: InkWell(
                  onTap: () => setState(() => _selectedPlanId = p.id),
                  borderRadius: AppRadius.brLg,
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        AppSpacing.hGapLg,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              AppSpacing.vGapXs,
                              Text(
                                '₹${p.pricePerStudent.toStringAsFixed(0)}/student/month',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          AppSpacing.vGapXl,
          _SectionHeader(title: 'Subscription Details', icon: Icons.calendar_today_rounded),
          AppSpacing.vGapMd,
          TextFormField(
            controller: _studentLimitController,
            decoration: _inputDecoration('Student limit', prefixIcon: const Icon(Icons.people_outline_rounded, size: 20)),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _studentLimit = int.tryParse(v) ?? _studentLimit),
          ),
          AppSpacing.vGapMd,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Renewal date', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              _renewalDate != null
                  ? '${_renewalDate!.day}/${_renewalDate!.month}/${_renewalDate!.year}'
                  : 'Not set',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: FilledButton.tonal(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _renewalDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (d != null) setState(() => _renewalDate = d);
              },
              child: const Text('Change'),
            ),
          ),
          AppSpacing.vGapLg,
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppRadius.brLg,
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary, size: 28),
                AppSpacing.hGapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated monthly bill', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        '₹${billEstimate.toStringAsFixed(0)}/mo',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('$_studentLimit × ₹${pricePerStudent.toStringAsFixed(0)}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,
          FilledButton.icon(
            onPressed: _saving ? null : _savePlan,
            icon: _saving
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Plan Changes'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
            ),
          ),
        ],
      ),
    );
  }

  /// Must match backend DEFAULT_FEATURE_KEYS (super-admin.service.js).
  /// School-level toggles for modules; aligned with platform/plan features.
  static const _allFeatureKeys = [
    'ai_intelligence',
    'attendance',
    'certificates',
    'chat_system',
    'exams',
    'fees',
    'gps_transport',
    'hostel',
    'library',
    'online_payments',
    'parent_app',
    'reports',
    'rfid_attendance',
    'timetable',
    'transport',
  ];

  Widget _buildFeaturesTab() {
    final theme = Theme.of(context);
    // Always show all features; merge with API response (missing = disabled)
    final keys = [
      ..._allFeatureKeys,
      ..._features.keys.where((k) => !_allFeatureKeys.contains(k)),
    ]..sort();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: 'Feature Toggles', icon: Icons.tune_rounded),
          AppSpacing.vGapSm,
          Text(
            'Enable or disable modules for this school.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          AppSpacing.vGapLg,
          ...keys.map((key) {
            final value = _features[key] ?? false;
            final label = key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1) : ''}').join(' ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: AppRadius.brLg,
                child: SwitchListTile(
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(key, style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  )),
                  value: value,
                  onChanged: (v) => _toggleFeature(key, v),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    final theme = Theme.of(context);
    final admin = _school?.primaryAdmin;
    if (admin == null || admin.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: AppSpacing.paddingXl,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 20),
              Text('No admin assigned', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              AppSpacing.vGapSm,
              Text(
                'Primary admin details will appear here once assigned.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXl,
              FilledButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AssignSchoolAdminDialog(
                      schoolId: widget.schoolId,
                      schoolName: _school?.name ?? 'this school',
                      onAssigned: _load,
                    ),
                  );
                  if (ok == true) widget.onUpdated?.call();
                },
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text('Assign Admin'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final name = admin['name'] ?? admin['email'] ?? 'Admin';
    final email = admin['email'] ?? '';
    final mobile = admin['mobile'] ?? admin['phone'] ?? '';
    final userId = admin['id']?.toString() ?? '';
    return SingleChildScrollView(
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
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          AppSpacing.vGapXs,
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(child: Text(email, style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                          if (mobile.isNotEmpty) ...[
                            AppSpacing.vGapXs,
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(mobile, style: theme.textTheme.bodyMedium),
                              ],
                            ),
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
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => _resetAdminPassword(userId),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_reset_rounded, size: 18),
                            AppSpacing.hGapSm,
                            Text('Reset Password'),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await AppDialogs.confirm(
                            context,
                            title: 'Deactivate Admin?',
                            message: 'This admin will lose access to the school.',
                            confirmLabel: 'Deactivate',
                            isDestructive: true,
                          );
                          if (ok && mounted) {
                            await ref.read(superAdminServiceProvider).deactivateSchoolAdmin(widget.schoolId, userId);
                            _load();
                          }
                        },
                        icon: const Icon(Icons.person_off_rounded, size: 18),
                        label: const Text('Deactivate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.7)),
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubdomainTab() {
    final theme = Theme.of(context);
    final subdomain = _subdomainController.text.trim().isNotEmpty
        ? _subdomainController.text.trim()
        : _school?.subdomain ?? _school?.code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';
    final loginUrl = 'https://$subdomain.vidyron.in';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: 'Subdomain', icon: Icons.link_rounded),
          AppSpacing.vGapSm,
          Text(
            'Schools access the platform via a unique subdomain (e.g. yourschool.vidyron.in).',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          AppSpacing.vGapLg,
          TextFormField(
            controller: _subdomainController,
            decoration: _inputDecoration('Subdomain', prefixIcon: const Icon(Icons.link_rounded, size: 20)).copyWith(
              hintText: 'e.g. greenvalley',
            ),
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
                FilledButton.tonal(
                  onPressed: _copyLoginUrl,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 18),
                      AppSpacing.hGapSm,
                      Text('Copy'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapLg,
          Text(
            'Changing the subdomain will break existing bookmarks. Share the new URL with the school.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _changeSubdomain,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Change Subdomain'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
            ),
          ),
        ],
      ),
    );
  }
}

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
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
