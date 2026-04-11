import 'package:flutter/material.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../widgets/common/address_location_picker.dart';
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
  String? _country;
  String? _state;
  String? _city;
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
    _country = s?.country;
    _state = s?.state;
    _city = s?.city;
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
    _maxStudentsController.dispose();
    _maxTeachersController.dispose();
    super.dispose();
  }

  String _generateSchoolCode(String name) {
    if (name.isEmpty) {
      return 'SCH${Random().nextInt(9999).toString().padLeft(4, '0')}';
    }
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
        'country': _country ?? '',
        'state': _state ?? '',
        'city': _city ?? '',
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
        AppSnackbar.success(context, AppStrings.schoolSavedSuccess);
        ref.read(schoolsViewModelProvider.notifier).fetchSchools();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, AppStrings.errorSavingSchool(e.toString()));
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
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(isEdit ? AppStrings.editSchool : AppStrings.addNewSchool),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral800,
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
                  padding: AppSpacing.paddingXl,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.brLg,
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
                                AppSpacing.vGapLg,
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
                              AppSpacing.hGapLg,
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
                      AppSpacing.vGapLg,
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
                                AppSpacing.vGapLg,
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
                              AppSpacing.hGapLg,
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
                      AppSpacing.vGapXl2,

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
                      AppSpacing.vGapLg,
                      AddressLocationPicker(
                        country: _country,
                        state: _state,
                        city: _city,
                        onCountryChanged: (v) => setState(() => _country = v),
                        onStateChanged: (v) => setState(() => _state = v),
                        onCityChanged: (v) => setState(() => _city = v),
                        countryLabel: AppStrings.country,
                        stateLabel: AppStrings.state,
                        cityLabel: AppStrings.city,
                      ),
                      AppSpacing.vGapXl2,

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
                                AppSpacing.vGapLg,
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
                              AppSpacing.hGapLg,
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
                      AppSpacing.vGapLg,
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
                                AppSpacing.vGapLg,
                                _buildTextField(
                                  controller: _maxTeachersController,
                                  label: AppStrings.maxTeachers,
                                  isNumber: true,
                                ),
                                AppSpacing.vGapLg,
                                SearchableDropdownFormField<String>.valueItems(
                                  value: _status,
                                  valueItems: const [
                                    MapEntry('ACTIVE', AppStrings.statusActive),
                                    MapEntry('SUSPENDED', AppStrings.statusSuspended),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.statusLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _status = val);
                                    }
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
                              AppSpacing.hGapLg,
                              Expanded(
                                child: _buildTextField(
                                  controller: _maxTeachersController,
                                  label: AppStrings.maxTeachers,
                                  isNumber: true,
                                ),
                              ),
                              AppSpacing.hGapLg,
                              Expanded(
                                child: SearchableDropdownFormField<String>.valueItems(
                                  value: _status,
                                  valueItems: const [
                                    MapEntry('ACTIVE', AppStrings.statusActive),
                                    MapEntry('SUSPENDED', AppStrings.statusSuspended),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.statusLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _status = val);
                                    }
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
                                color: AppColors.neutral400,
                              ),
                            ),
                          ),
                          AppSpacing.hGapLg,
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveForm,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl2,
                                vertical: AppSpacing.lg,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.brMd,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
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
            AppSpacing.hGapSm,
            const Icon(Icons.calendar_today, size: 20, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
