import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../core/constants/app_strings.dart';
import '../../domain/models/school_model.dart';
import '../../data/providers/schools_providers.dart';
import '../viewmodels/schools_viewmodel.dart';

class AddEditSchoolScreen extends ConsumerStatefulWidget {
  final SchoolModel? school;

  const AddEditSchoolScreen({super.key, this.school});

  @override
  ConsumerState<AddEditSchoolScreen> createState() =>
      _AddEditSchoolScreenState();
}

class _AddEditSchoolScreenState extends ConsumerState<AddEditSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _maxStudentsController;
  late TextEditingController _maxTeachersController;

  DateTime? _subStart;
  DateTime? _subEnd;
  String _status = 'ACTIVE';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.school;

    _nameController = TextEditingController(text: s?.name ?? '');
    _codeController = TextEditingController(text: s?.schoolCode ?? '');
    _emailController = TextEditingController(text: s?.contactEmail ?? '');

    _phoneController = TextEditingController(text: s?.contactPhone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _cityController = TextEditingController(text: s?.city ?? '');
    _stateController = TextEditingController(text: s?.state ?? '');
    _countryController = TextEditingController(text: s?.country ?? '');
    _maxStudentsController = TextEditingController(
      text: s?.maxStudents?.toString() ?? '',
    );
    _maxTeachersController = TextEditingController(
      text: s?.maxTeachers?.toString() ?? '',
    );

    _subEnd = s?.subscriptionEnd;
    _subStart = s?.subscriptionStart ?? (s != null ? null : DateTime.now());

    if (s != null) {
      _status = s.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _maxStudentsController.dispose();
    _maxTeachersController.dispose();
    super.dispose();
  }

  String _generateSchoolCode(String name) {
    if (name.isEmpty)
      return 'SCH${Random().nextInt(9999).toString().padLeft(4, '0')}';
    final prefix = name.length >= 3
        ? name.substring(0, 3).toUpperCase()
        : name.toUpperCase();
    return '$prefix${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_subStart ?? DateTime.now())
        : (_subEnd ?? DateTime.now().add(const Duration(days: 365)));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: child,
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _subStart = pickedDate;
        } else {
          _subEnd = pickedDate;
        }
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_codeController.text.isEmpty) {
      _codeController.text = _generateSchoolCode(_nameController.text);
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'schoolCode': _codeController.text.trim(),
        'contactEmail': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'status': _status,
        'maxStudents': int.tryParse(_maxStudentsController.text) ?? 0,
        'maxTeachers': int.tryParse(_maxTeachersController.text) ?? 0,
        if (_subStart != null)
          'subscriptionStart': _subStart!.toIso8601String(),
        if (_subEnd != null) 'subscriptionEnd': _subEnd!.toIso8601String(),
        'planId': 1,
      };

      final repository = ref.read(schoolsRepositoryProvider);

      if (widget.school == null) {
        await repository.createSchool(payload);
      } else {
        await repository.updateSchool(widget.school!.id, payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.schoolSavedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(schoolsViewModelProvider.notifier).fetchSchools();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorSavingSchool(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.school != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEdit ? AppStrings.editSchool : AppStrings.addNewSchool),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        AppStrings.generalInformation,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          if (isMobile) {
                            return Column(
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  label: AppStrings.schoolNameRequired,
                                  validator: (val) => val == null || val.isEmpty
                                      ? AppStrings.required
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _codeController,
                                  label:
                                      AppStrings.schoolCodeHint,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _nameController,
                                  label: AppStrings.schoolNameRequired,
                                  validator: (val) => val == null || val.isEmpty
                                      ? AppStrings.required
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _codeController,
                                  label:
                                      AppStrings.schoolCodeHint,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          if (isMobile) {
                            return Column(
                              children: [
                                _buildTextField(
                                  controller: _emailController,
                                  label: AppStrings.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: AppStrings.phoneNumber,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _emailController,
                                  label: AppStrings.emailAddress,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _phoneController,
                                  label: AppStrings.phoneNumber,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        AppStrings.addressDetails,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _addressController,
                        label: AppStrings.streetAddress,
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          if (isMobile) {
                            return Column(
                              children: [
                                _buildTextField(
                                  controller: _cityController,
                                  label: AppStrings.city,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _stateController,
                                  label: AppStrings.state,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _countryController,
                                  label: AppStrings.country,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _cityController,
                                  label: AppStrings.city,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _stateController,
                                  label: AppStrings.state,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _countryController,
                                  label: AppStrings.country,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        AppStrings.subscriptionCapacity,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          if (isMobile) {
                            return Column(
                              children: [
                                _buildDateField(
                                  label: AppStrings.subscriptionStart,
                                  date: _subStart,
                                  onTap: () => _selectDate(context, true),
                                ),
                                const SizedBox(height: 16),
                                _buildDateField(
                                  label: AppStrings.subscriptionEnd,
                                  date: _subEnd,
                                  onTap: () => _selectDate(context, false),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: AppStrings.subscriptionStart,
                                  date: _subStart,
                                  onTap: () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateField(
                                  label: AppStrings.subscriptionEnd,
                                  date: _subEnd,
                                  onTap: () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          if (isMobile) {
                            return Column(
                              children: [
                                _buildTextField(
                                  controller: _maxStudentsController,
                                  label: AppStrings.maxStudents,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _maxTeachersController,
                                  label: AppStrings.maxTeachers,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _status,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.statusLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'ACTIVE',
                                      child: Text(AppStrings.statusActive),
                                    ),
                                    DropdownMenuItem(
                                      value: 'SUSPENDED',
                                      child: Text(AppStrings.statusSuspended),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _status = val);
                                  },
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _maxStudentsController,
                                  label: AppStrings.maxStudents,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _maxTeachersController,
                                  label: AppStrings.maxTeachers,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _status,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.statusLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'ACTIVE',
                                      child: Text(AppStrings.statusActive),
                                    ),
                                    DropdownMenuItem(
                                      value: 'SUSPENDED',
                                      child: Text(AppStrings.statusSuspended),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _status = val);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              AppStrings.cancel,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    AppStrings.saveSchool,
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                date != null
                    ? DateFormat('MMM dd, yyyy').format(date)
                    : AppStrings.selectDate,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
