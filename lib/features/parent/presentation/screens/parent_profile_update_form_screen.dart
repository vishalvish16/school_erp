// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_profile_update_form_screen.dart
// PURPOSE: Parent submits a profile update request for their child.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/profile_request_service.dart';
import '../../../../core/services/parent_service.dart';
import '../../../../models/parent/parent_models.dart';

class ParentProfileUpdateFormScreen extends ConsumerStatefulWidget {
  const ParentProfileUpdateFormScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<ParentProfileUpdateFormScreen> createState() =>
      _ParentProfileUpdateFormScreenState();
}

class _ParentProfileUpdateFormScreenState
    extends ConsumerState<ParentProfileUpdateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();

  bool _isSubmitting = false;
  ChildDetailModel? _child;

  // Original values for change detection
  final Map<String, String> _originalValues = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChild());
  }

  Future<void> _loadChild() async {
    try {
      final service = ref.read(parentServiceProvider);
      final results = await Future.wait([
        service.getChildById(widget.studentId),
        service.getProfile(),
      ]);
      final child = results[0] as ChildDetailModel?;
      final parentProfile = results[1] as ParentProfileModel;
      if (child != null && mounted) {
        setState(() {
          _child = child;
          _firstNameCtrl.text = child.firstName;
          _lastNameCtrl.text = child.lastName;
          _dobCtrl.text = child.dateOfBirth != null
              ? '${child.dateOfBirth!.year}-${child.dateOfBirth!.month.toString().padLeft(2, '0')}-${child.dateOfBirth!.day.toString().padLeft(2, '0')}'
              : '';
          _bloodGroupCtrl.text = child.bloodGroup ?? '';
          _addressCtrl.text = child.address ?? '';

          final parentName = parentProfile.fullName;
          final parentPhone = parentProfile.phone;
          final parentEmail = parentProfile.email ?? '';
          _parentNameCtrl.text = parentName;
          _parentPhoneCtrl.text = parentPhone;
          _parentEmailCtrl.text = parentEmail;

          _originalValues['firstName'] = child.firstName;
          _originalValues['lastName'] = child.lastName;
          _originalValues['dateOfBirth'] = _dobCtrl.text;
          _originalValues['bloodGroup'] = child.bloodGroup ?? '';
          _originalValues['address'] = child.address ?? '';
          _originalValues['parentName'] = parentName;
          _originalValues['parentPhone'] = parentPhone;
          _originalValues['parentEmail'] = parentEmail;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppStrings.genericError);
      }
    }
  }

  Map<String, dynamic> _getChangedFields() {
    final changes = <String, dynamic>{};
    if (_firstNameCtrl.text.trim() != _originalValues['firstName']) {
      changes['firstName'] = _firstNameCtrl.text.trim();
    }
    if (_lastNameCtrl.text.trim() != _originalValues['lastName']) {
      changes['lastName'] = _lastNameCtrl.text.trim();
    }
    if (_dobCtrl.text.trim() != _originalValues['dateOfBirth']) {
      changes['dateOfBirth'] = _dobCtrl.text.trim();
    }
    if (_bloodGroupCtrl.text.trim() != _originalValues['bloodGroup']) {
      changes['bloodGroup'] = _bloodGroupCtrl.text.trim();
    }
    if (_addressCtrl.text.trim() != _originalValues['address']) {
      changes['address'] = _addressCtrl.text.trim();
    }
    if (_parentNameCtrl.text.trim() != (_originalValues['parentName'] ?? '')) {
      changes['parentName'] = _parentNameCtrl.text.trim();
    }
    if (_parentPhoneCtrl.text.trim() != (_originalValues['parentPhone'] ?? '')) {
      changes['parentPhone'] = _parentPhoneCtrl.text.trim();
    }
    if (_parentEmailCtrl.text.trim() != (_originalValues['parentEmail'] ?? '')) {
      changes['parentEmail'] = _parentEmailCtrl.text.trim();
    }
    return changes;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final changes = _getChangedFields();
    if (changes.isEmpty) {
      AppFeedback.showWarning(context, AppStrings.noChangesDetected);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(profileRequestServiceProvider);
      await service.submitProfileUpdateRequest(
        studentId: widget.studentId,
        requestedChanges: changes,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, AppStrings.requestSubmitted);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/parent/children/${widget.studentId}');
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _addressCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _parentEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _child == null
          ? AppLoaderScreen()
          : Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppBreakpoints.formMaxWidth),
                child: SingleChildScrollView(
                  padding:
                      isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ────────────────────────────────────────
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/parent/children/${widget.studentId}');
                                }
                              },
                              icon: const Icon(Icons.arrow_back),
                              tooltip: AppStrings.back,
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppStrings.requestProfileUpdate,
                                      style: AppTextStyles.h5(
                                          color: scheme.onSurface)),
                                  Text(
                                    AppStrings.requestProfileUpdateSubtitle,
                                    style: AppTextStyles.bodySm(
                                        color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapXl,

                        // ── Student Info Fields ───────────────────────────
                        Text(AppStrings.personalInformation,
                            style: AppTextStyles.h6(color: scheme.onSurface)),
                        AppSpacing.vGapMd,

                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameCtrl,
                                  decoration: InputDecoration(
                                      labelText: AppStrings.firstName),
                                ),
                              ),
                              AppSpacing.hGapLg,
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameCtrl,
                                  decoration: InputDecoration(
                                      labelText: AppStrings.lastName),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          TextFormField(
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(
                                labelText: AppStrings.firstName),
                          ),
                          AppSpacing.vGapMd,
                          TextFormField(
                            controller: _lastNameCtrl,
                            decoration: InputDecoration(
                                labelText: AppStrings.lastName),
                          ),
                        ],
                        AppSpacing.vGapMd,

                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dobCtrl,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.dateOfBirth,
                                    hintText: 'YYYY-MM-DD',
                                    hintStyle: AppTextStyles.body(
                                        color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              AppSpacing.hGapLg,
                              Expanded(
                                child: TextFormField(
                                  controller: _bloodGroupCtrl,
                                  decoration: InputDecoration(
                                      labelText: AppStrings.bloodGroup),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          TextFormField(
                            controller: _dobCtrl,
                            decoration: InputDecoration(
                              labelText: AppStrings.dateOfBirth,
                              hintText: 'YYYY-MM-DD',
                              hintStyle: AppTextStyles.body(
                                  color: scheme.onSurfaceVariant),
                            ),
                          ),
                          AppSpacing.vGapMd,
                          TextFormField(
                            controller: _bloodGroupCtrl,
                            decoration: InputDecoration(
                                labelText: AppStrings.bloodGroup),
                          ),
                        ],
                        AppSpacing.vGapMd,

                        TextFormField(
                          controller: _addressCtrl,
                          decoration:
                              InputDecoration(labelText: AppStrings.address),
                          maxLines: 2,
                        ),
                        AppSpacing.vGapXl,

                        // ── Parent Info Fields ────────────────────────────
                        Text(AppStrings.parentGuardian,
                            style: AppTextStyles.h6(color: scheme.onSurface)),
                        AppSpacing.vGapMd,

                        TextFormField(
                          controller: _parentNameCtrl,
                          decoration: InputDecoration(
                              labelText: AppStrings.parentName),
                        ),
                        AppSpacing.vGapMd,

                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _parentPhoneCtrl,
                                  decoration: InputDecoration(
                                      labelText: AppStrings.parentPhone),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              AppSpacing.hGapLg,
                              Expanded(
                                child: TextFormField(
                                  controller: _parentEmailCtrl,
                                  decoration: InputDecoration(
                                      labelText: AppStrings.parentEmail),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          TextFormField(
                            controller: _parentPhoneCtrl,
                            decoration: InputDecoration(
                                labelText: AppStrings.parentPhone),
                            keyboardType: TextInputType.phone,
                          ),
                          AppSpacing.vGapMd,
                          TextFormField(
                            controller: _parentEmailCtrl,
                            decoration: InputDecoration(
                                labelText: AppStrings.parentEmail),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                        AppSpacing.vGapXl,

                        // ── Submit Button ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: AppSpacing.paddingVMd,
                              shape: AppRadius.cardShape,
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    width: AppIconSize.md,
                                    height: AppIconSize.md,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: AppBorderWidth.medium,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(AppStrings.submitRequest),
                          ),
                        ),
                        AppSpacing.vGapXl,
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
