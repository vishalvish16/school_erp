// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/school_detail_dialog.dart
// PURPOSE: School detail dialog — 5 tabs: Info, Plan, Features, Admin, Subdomain
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';

const _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
  'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
  'West Bengal', 'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry',
];

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
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
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
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subdomainController.dispose();
    _studentLimitController.dispose();
    super.dispose();
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
          _cityController.text = school.city ?? '';
          _stateController.text = school.state ?? '';
          _pinController.text = school.pin ?? '';
          _phoneController.text = school.phone ?? '';
          _emailController.text = school.email ?? '';
          _subdomainController.text = school.subdomain ?? '';
          _status = school.status;
          _board = school.board;
          _schoolType = school.schoolType;
          _groupId = school.groupId;
          _selectedPlanId = school.plan?.id;
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
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pin': _pinController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'status': _status,
        'group_id': _groupId,
      });
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _suspendSchool() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend School?'),
        content: Text(
          'Suspend ${_school?.name ?? ''}? All staff and students will lose access immediately.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolStatus(widget.schoolId, 'suspended');
      if (mounted) {
        _load();
        widget.onUpdated?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School suspended')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$key ${value ? 'enabled' : 'disabled'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _features[key] = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    }
  }

  void _copyLoginUrl() {
    final sub = _subdomainController.text.trim().isNotEmpty
        ? _subdomainController.text.trim()
        : _school?.subdomain ?? _school?.code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';
    final url = 'https://$sub.vidyron.in';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('URL copied: $url')),
    );
  }

  Future<void> _changeSubdomain() async {
    final value = _subdomainController.text.trim().toLowerCase();
    if (value.isEmpty) return;
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subdomain: alphanumeric and hyphens only')),
      );
      return;
    }
    final available = await ref.read(superAdminServiceProvider).checkSubdomainAvailable(value);
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subdomain already taken')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Subdomain?'),
        content: const Text(
          'This will break existing staff bookmarks. Share the new URL with the school.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Change')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolSubdomain(widget.schoolId, value);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subdomain updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
            const SizedBox(height: 12),
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
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Password must match and be at least 8 characters')),
                );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. Admin will be notified.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _school?.name ?? 'School Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onUpdated?.call();
                },
              ),
            ],
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Plan'),
              Tab(text: 'Features'),
              Tab(text: 'Admin'),
              Tab(text: 'Subdomain'),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'School Name'),
          ),
          const SizedBox(height: 12),
          Text(_school?.code ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
          const SizedBox(height: 4),
          Text('School Code (auto-generated)', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _board,
            decoration: const InputDecoration(labelText: 'Board'),
            items: ['CBSE', 'ICSE', 'State Board', 'IB']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _board = v ?? 'CBSE'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _schoolType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['Private', 'Government', 'Trust']
                .map((v) => DropdownMenuItem(value: v.toLowerCase(), child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _schoolType = v ?? 'private'),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _indianStates.contains(_stateController.text) ? _stateController.text : null,
            decoration: const InputDecoration(labelText: 'State'),
            items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _stateController.text = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _pinController, decoration: const InputDecoration(labelText: 'PIN Code')),
          const SizedBox(height: 12),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ['Active', 'Trial', 'Suspended']
                .map((v) => DropdownMenuItem(value: v.toLowerCase(), child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? 'active'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _groupId,
            decoration: const InputDecoration(labelText: 'Group'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ..._groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
            ],
            onChanged: (v) => setState(() => _groupId = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_school?.status != 'suspended')
                TextButton(
                  onPressed: _suspendSchool,
                  child: Text('Suspend School', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _saveInfo,
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._plans.map((p) {
            final selected = _selectedPlanId == p.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: selected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
              child: InkWell(
                onTap: () => setState(() => _selectedPlanId = p.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('₹${p.pricePerStudent.toStringAsFixed(0)}/student/mo'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentLimitController,
            decoration: const InputDecoration(labelText: 'Student limit'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _studentLimit = int.tryParse(v) ?? _studentLimit),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Renewal date'),
            subtitle: Text(_renewalDate != null
                ? '${_renewalDate!.day}/${_renewalDate!.month}/${_renewalDate!.year}'
                : '—'),
            trailing: TextButton(
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bill estimate: ₹${billEstimate.toStringAsFixed(0)}/mo (${_studentLimit} × ₹${pricePerStudent.toStringAsFixed(0)})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _savePlan,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Plan Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    final keys = _features.keys.toList()..sort();
    if (keys.isEmpty) {
      keys.addAll(['attendance', 'fees', 'exams', 'timetable', 'library', 'transport', 'hostel', 'reports']);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((key) {
          final value = _features[key] ?? false;
          return SwitchListTile(
            title: Text(key.replaceAll('_', ' ')),
            subtitle: Text(key, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
            value: value,
            onChanged: (v) => _toggleFeature(key, v),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdminTab() {
    final admin = _school?.primaryAdmin;
    if (admin == null || admin.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No admin data', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }
    final name = admin['name'] ?? admin['email'] ?? 'Admin';
    final email = admin['email'] ?? '';
    final mobile = admin['mobile'] ?? admin['phone'] ?? '';
    final userId = admin['id']?.toString() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(email),
                            if (mobile.isNotEmpty) Text(mobile),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (userId.isNotEmpty) ...[
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _resetAdminPassword(userId),
                          child: const Text('Reset Password'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Deactivate Admin?'),
                                content: const Text('This admin will lose access.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate')),
                                ],
                              ),
                            );
                            if (ok == true && mounted) {
                              await ref.read(superAdminServiceProvider).deactivateSchoolAdmin(widget.schoolId, userId);
                              _load();
                            }
                          },
                          child: Text('Deactivate', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubdomainTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _subdomainController,
            decoration: const InputDecoration(
              labelText: 'Current subdomain',
              hintText: 'e.g. dpssurat',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: _changeSubdomain,
                child: const Text('Change'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyLoginUrl,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Login URL'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
