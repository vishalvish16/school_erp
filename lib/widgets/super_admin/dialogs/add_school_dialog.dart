// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/add_school_dialog.dart
// PURPOSE: Add School 5-step wizard with subdomain check
// =============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/super_admin_service.dart';

const _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
  'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
  'West Bengal', 'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry',
];

class AddSchoolDialog extends ConsumerStatefulWidget {
  const AddSchoolDialog({
    super.key,
    required this.plans,
    required this.groups,
    required this.onCreate,
  });

  final List<dynamic> plans;
  final List<dynamic> groups;
  final Future<void> Function(Map<String, dynamic>) onCreate;

  /// Convenience constructor when groups not needed (standalone only)
  factory AddSchoolDialog.standalone({
    required List<dynamic> plans,
    required Future<void> Function(Map<String, dynamic>) onCreate,
  }) => AddSchoolDialog(plans: plans, groups: [], onCreate: onCreate);

  @override
  ConsumerState<AddSchoolDialog> createState() => _AddSchoolDialogState();
}

class _AddSchoolDialogState extends ConsumerState<AddSchoolDialog> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _estStudentsController = TextEditingController();
  final _studentLimitController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminMobileController = TextEditingController();
  final _tempPasswordController = TextEditingController();
  String? _selectedPlanId;
  String? _groupId;
  String _board = 'CBSE';
  String _schoolType = 'private';
  String _duration = '12';
  int _studentLimit = 500;
  bool _subdomainAvailable = false;
  bool _subdomainChecking = false;
  Timer? _subdomainDebounce;
  final Map<String, bool> _features = {};
  bool _submitting = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_suggestSubdomain);
    _subdomainController.addListener(_checkSubdomainDebounced);
  }

  void _suggestSubdomain() {
    if (_subdomainController.text.isEmpty && _nameController.text.isNotEmpty) {
      final suggested = _nameController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
          .replaceAll(RegExp(r'\s+'), '')
          .substring(0, _nameController.text.length.clamp(0, 20));
      if (suggested.isNotEmpty) {
        _subdomainController.text = suggested;
        _checkSubdomainDebounced();
      }
    }
  }

  void _checkSubdomainDebounced() {
    _subdomainDebounce?.cancel();
    _subdomainDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkSubdomain();
    });
  }

  Future<void> _checkSubdomain() async {
    final value = _subdomainController.text.trim().toLowerCase();
    if (value.isEmpty) {
      setState(() {
        _subdomainAvailable = false;
        _subdomainChecking = false;
      });
      return;
    }
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
      setState(() {
        _subdomainAvailable = false;
        _subdomainChecking = false;
      });
      return;
    }
    setState(() => _subdomainChecking = true);
    try {
      final available = await ref.read(superAdminServiceProvider).checkSubdomainAvailable(value);
      if (mounted) {
        setState(() {
          _subdomainAvailable = available;
          _subdomainChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _subdomainAvailable = false;
          _subdomainChecking = false;
        });
      }
    }
  }

  String _generateSchoolCode() {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final n = name.length >= 3 ? name.substring(0, 3).toUpperCase() : 'SCH';
    final c = city.length >= 3 ? city.substring(0, 3).toUpperCase() : 'XXX';
    final seq = (Random().nextInt(999) + 1).toString().padLeft(3, '0');
    return '$n-$c-$seq';
  }

  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    return List.generate(12, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _subdomainDebounce?.cancel();
    _nameController.removeListener(_suggestSubdomain);
    _subdomainController.removeListener(_checkSubdomainDebounced);
    _nameController.dispose();
    _subdomainController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _estStudentsController.dispose();
    _studentLimitController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminMobileController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  bool _canProceedStep0() => true;
  bool _canProceedStep1() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_subdomainController.text.trim().isEmpty) return false;
    if (!_subdomainAvailable) return false;
    if (_cityController.text.trim().isEmpty) return false;
    if (_stateController.text.trim().isEmpty) return false;
    return true;
  }
  bool _canProceedStep2() => _selectedPlanId != null;
  bool _canProceedStep3() {
    if (_adminNameController.text.trim().isEmpty) return false;
    if (_adminEmailController.text.trim().isEmpty) return false;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(_adminEmailController.text.trim())) return false;
    if (_adminMobileController.text.trim().length != 10) return false;
    if (_tempPasswordController.text.length < 8) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_canProceedStep1() || _selectedPlanId == null || !_canProceedStep3()) return;
    setState(() => _submitting = true);
    try {
      await widget.onCreate({
        'name': _nameController.text.trim(),
        'subdomain': _subdomainController.text.trim().toLowerCase(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pin': _pinController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'board': _board,
        'school_type': _schoolType,
        'est_students': int.tryParse(_estStudentsController.text) ?? _studentLimit,
        'plan_id': _selectedPlanId,
        'group_id': _groupId,
        'duration_months': int.tryParse(_duration) ?? 12,
        'student_limit': _studentLimit,
        'admin_name': _adminNameController.text.trim(),
        'admin_email': _adminEmailController.text.trim(),
        'admin_mobile': _adminMobileController.text.trim(),
        'temp_password': _tempPasswordController.text,
        'features': _features,
      });
      if (mounted) {
        final sub = _subdomainController.text.trim().toLowerCase();
        final url = 'https://$sub.vidyron.in';
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('School created! Login URL: $url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width >= 768;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isWeb ? 560 : double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Add School',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(5, (i) {
                final active = _step >= i;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 0) _buildStep0(),
                    if (_step == 1) _buildStep1(),
                    if (_step == 2) _buildStep2(),
                    if (_step == 3) _buildStep3(),
                    if (_step == 4) _buildStep4(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _submitting ? null : () => setState(() => _step--),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          if (_step == 0 && _canProceedStep0()) {
                            setState(() => _step++);
                          } else if (_step == 1 && _formKey.currentState?.validate() == true && _canProceedStep1()) {
                            setState(() {
                              final est = int.tryParse(_estStudentsController.text);
                              if (est != null) _studentLimit = est;
                              _studentLimitController.text = _studentLimit.toString();
                              _step++;
                            });
                          } else if (_step == 2 && _canProceedStep2()) {
                            setState(() {
                              final est = int.tryParse(_estStudentsController.text);
                              if (est != null) _studentLimit = est;
                              _studentLimitController.text = _studentLimit.toString();
                              _step++;
                            });
                          } else if (_step == 3 && _canProceedStep3()) {
                            setState(() {
                              const defaults = ['attendance', 'fees', 'exams', 'timetable', 'library', 'transport', 'hostel', 'reports'];
                              for (final k in defaults) {
                                _features.putIfAbsent(k, () => true);
                              }
                              _step++;
                            });
                          } else if (_step == 4) {
                            _submit();
                          }
                        },
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step < 4 ? 'Next' : 'Create School'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Group', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('Standalone (no group)'),
            value: 'none',
            groupValue: _groupId == null ? 'none' : 'group',
            onChanged: (v) => setState(() => _groupId = null),
          ),
          RadioListTile<String>(
            title: const Text('Add to existing group'),
            value: 'group',
            groupValue: _groupId == null ? 'none' : 'group',
            onChanged: widget.groups.isEmpty ? null : (v) => setState(() {
              _groupId ??= widget.groups.first['id']?.toString();
            }),
          ),
          if (widget.groups.isNotEmpty && _groupId != null)
            DropdownButtonFormField<String>(
              value: _groupId,
              decoration: const InputDecoration(labelText: 'Group'),
              items: widget.groups.map<DropdownMenuItem<String>>((g) {
                final id = g['id']?.toString() ?? '';
                final name = g['name'] ?? '';
                return DropdownMenuItem(value: id, child: Text(name));
              }).toList(),
              onChanged: (v) => setState(() => _groupId = v),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'School Name *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subdomainController,
            decoration: InputDecoration(
              labelText: 'Subdomain *',
              hintText: 'e.g. dpssurat',
              suffixIcon: _subdomainChecking
                  ? const SizedBox(width: 24, height: 24, child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : Icon(
                      _subdomainAvailable ? Icons.check_circle : Icons.cancel,
                      color: _subdomainAvailable ? Colors.green : Colors.red,
                      size: 24,
                    ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) return 'Alphanumeric and hyphens only';
              if (!_subdomainAvailable) return 'Subdomain not available';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'School Code (auto-generated): ${_generateSchoolCode()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
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
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _indianStates.contains(_stateController.text) ? _stateController.text : null,
            decoration: const InputDecoration(labelText: 'State *'),
            items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _stateController.text = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pinController,
            decoration: const InputDecoration(labelText: 'PIN Code'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Contact Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v != null && v.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _estStudentsController,
            decoration: const InputDecoration(labelText: 'Est. Students'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _studentLimit = int.tryParse(v) ?? _studentLimit),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    Map<String, dynamic>? plan;
    for (final p in widget.plans) {
      if (p is Map && (p['id']?.toString() ?? p['planId']?.toString()) == _selectedPlanId) {
        plan = Map<String, dynamic>.from(p);
        break;
      }
    }
    plan ??= widget.plans.isNotEmpty && widget.plans.first is Map
        ? Map<String, dynamic>.from(widget.plans.first as Map)
        : null;
    final price = (plan?['price_per_student'] ?? plan?['priceMonthly'] ?? 0) is num
        ? (plan?['price_per_student'] ?? plan?['priceMonthly'] ?? 0).toDouble()
        : 0.0;
    final months = int.tryParse(_duration) ?? 12;
    final total = price * _studentLimit * months;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.plans.map<Widget>((p) {
          final id = p['id']?.toString() ?? '';
          final name = p['name'] ?? '';
          final pPrice = (p['price_per_student'] ?? p['priceMonthly'] ?? 0) is num
              ? (p['price_per_student'] ?? p['priceMonthly'] ?? 0).toDouble()
              : 0.0;
          final selected = _selectedPlanId == id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: selected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
            child: InkWell(
              onTap: () => setState(() => _selectedPlanId = id),
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
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${pPrice.toStringAsFixed(0)}/student/mo'),
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
        DropdownButtonFormField<String>(
          value: _duration,
          decoration: const InputDecoration(labelText: 'Duration'),
          items: [
            const DropdownMenuItem(value: '3', child: Text('3 Months (Trial)')),
            const DropdownMenuItem(value: '6', child: Text('6 Months')),
            const DropdownMenuItem(value: '12', child: Text('1 Year')),
          ],
          onChanged: (v) => setState(() => _duration = v ?? '12'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _studentLimitController,
          decoration: const InputDecoration(labelText: 'Student Limit'),
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _studentLimit = int.tryParse(v) ?? _studentLimit),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Estimated: ₹${total.toStringAsFixed(0)} for $months months (${_studentLimit} × ₹${price.toStringAsFixed(0)} × $months)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _adminNameController,
          decoration: const InputDecoration(labelText: 'Admin Name *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _adminEmailController,
          decoration: const InputDecoration(labelText: 'Admin Email *'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _adminMobileController,
          decoration: const InputDecoration(labelText: 'Admin Mobile * (10 digits)'),
          keyboardType: TextInputType.phone,
          maxLength: 10,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tempPasswordController,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            labelText: 'Temp Password * (min 8 chars)',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _tempPasswordController.text = _generatePassword()),
                  tooltip: 'Generate',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Features (based on plan)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ..._features.keys.toList().map((key) => SwitchListTile(
          title: Text(key.replaceAll('_', ' ')),
          value: _features[key] ?? false,
          onChanged: (v) => setState(() => _features[key] = v),
        )),
      ],
    );
  }
}
