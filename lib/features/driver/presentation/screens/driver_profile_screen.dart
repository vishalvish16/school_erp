// =============================================================================
// FILE: lib/features/driver/presentation/screens/driver_profile_screen.dart
// PURPOSE: View and edit driver profile.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/driver/driver_profile_model.dart';
import '../../../../core/services/driver_service.dart';
import '../providers/driver_profile_provider.dart';

const Color _accentColor = AppColors.driverAccent;

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isEditing = false;
  bool _populated = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _populateFromProfile(DriverProfileModel profile) {
    if (!_populated) {
      _phoneCtrl.text = profile.driver.phone ?? '';
      _emergencyNameCtrl.text = profile.driver.emergencyContactName ?? '';
      _emergencyPhoneCtrl.text = profile.driver.emergencyContactPhone ?? '';
      _addressCtrl.text = profile.driver.address ?? '';
      _populated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(driverProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final padding = AppSpacing.pagePadding;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(driverProfileProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: asyncProfile.when(
          loading: () => Center(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ErrorView(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(driverProfileProvider),
          ),
          data: (profile) {
            if (!_populated) _populateFromProfile(profile);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.driverProfileTitle,
                  style: AppTextStyles.h4(color: scheme.onSurface),
                ),
                AppSpacing.vGapXl,

                // Avatar + name header
                _AvatarHeader(driver: profile.driver),
                AppSpacing.vGapXl,

                // Profile card
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: _isEditing
                        ? _EditForm(
                            formKey: _formKey,
                            phoneCtrl: _phoneCtrl,
                            emergencyNameCtrl: _emergencyNameCtrl,
                            emergencyPhoneCtrl: _emergencyPhoneCtrl,
                            addressCtrl: _addressCtrl,
                            isSaving: _isSaving,
                            onSave: () => _save(profile),
                            onCancel: () {
                              setState(() {
                                _isEditing = false;
                                _populated = false;
                                _populateFromProfile(profile);
                              });
                            },
                          )
                        : _ProfileView(
                            profile: profile,
                            onEdit: () => setState(() => _isEditing = true),
                          ),
                  ),
                ),
                AppSpacing.vGapLg,

                // Change Password button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/driver/change-password'),
                    icon: const Icon(Icons.lock_reset, size: AppIconSize.sm),
                    label: Text(AppStrings.changePassword),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(DriverProfileModel profile) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(driverServiceProvider).updateProfile(
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            emergencyContactName:
                _emergencyNameCtrl.text.trim().isEmpty
                    ? null
                    : _emergencyNameCtrl.text.trim(),
            emergencyContactPhone:
                _emergencyPhoneCtrl.text.trim().isEmpty
                    ? null
                    : _emergencyPhoneCtrl.text.trim(),
            address:
                _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          );
      ref.invalidate(driverProfileProvider);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
          _populated = false;
        });
        AppSnackbar.success(context, AppStrings.updatedSuccess);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.error(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.driver});

  final DriverDetail driver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: _accentColor.withValues(alpha: AppOpacity.focus),
          backgroundImage:
              driver.photoUrl != null && driver.photoUrl!.isNotEmpty
                  ? NetworkImage(driver.photoUrl!)
                  : null,
          child: driver.photoUrl == null || driver.photoUrl!.isEmpty
              ? Text(
                  driver.fullName.isNotEmpty
                      ? driver.fullName
                          .split(' ')
                          .map((s) => s.isNotEmpty ? s[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase()
                      : 'DR',
                  style: AppTextStyles.h5(color: _accentColor),
                )
              : null,
        ),
        AppSpacing.hGapLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.fullName,
                style: AppTextStyles.h5(color: scheme.onSurface),
              ),
              AppSpacing.vGapXs,
              Text(
                driver.email,
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              ),
              if (driver.employeeNo.isNotEmpty) ...[
                AppSpacing.vGapXs,
                Text(
                  '${AppStrings.driverEmployeeNo}: ${driver.employeeNo}',
                  style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.onEdit});

  final DriverProfileModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final d = profile.driver;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              AppStrings.driverProfileDetails,
              style: AppTextStyles.h6(color: scheme.onSurface),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: AppIconSize.sm),
              label: Text(AppStrings.driverEditProfile),
            ),
          ],
        ),
        AppDivider.horizontal,
        _Row(AppStrings.driverEmployeeNo, d.employeeNo),
        _Row(AppStrings.firstName, d.firstName),
        _Row(AppStrings.lastName, d.lastName),
        _Row(AppStrings.email, d.email),
        if (d.gender.isNotEmpty) _Row(AppStrings.gender, d.gender),
        if (d.dateOfBirth != null)
          _Row(AppStrings.dateOfBirth, _formatDate(d.dateOfBirth!)),
        if (d.phone != null && d.phone!.isNotEmpty) _Row(AppStrings.phone, d.phone!),
        if (d.licenseNumber != null && d.licenseNumber!.isNotEmpty)
          _Row(AppStrings.driverLicenseNumber, d.licenseNumber!),
        if (d.licenseExpiry != null)
          _Row(AppStrings.driverLicenseExpiry, _formatDate(d.licenseExpiry!)),
        if (d.address != null && d.address!.isNotEmpty)
          _Row(AppStrings.address, d.address!),
        if (d.emergencyContactName != null && d.emergencyContactName!.isNotEmpty)
          _Row(
            AppStrings.driverEmergencyContact,
            '${d.emergencyContactName!}${d.emergencyContactPhone != null ? ' • ${d.emergencyContactPhone}' : ''}',
          ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSpacing.paddingVSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMd(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.formKey,
    required this.phoneCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
    required this.addressCtrl,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;
  final TextEditingController addressCtrl;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: phoneCtrl,
            decoration: const InputDecoration(
              labelText: AppStrings.phone,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: emergencyNameCtrl,
            decoration: const InputDecoration(
              labelText: '${AppStrings.driverEmergencyContact} Name',
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: emergencyPhoneCtrl,
            decoration: const InputDecoration(
              labelText: '${AppStrings.driverEmergencyContact} Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: addressCtrl,
            decoration: const InputDecoration(
              labelText: AppStrings.address,
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          AppSpacing.vGapXl,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: Text(AppStrings.cancel),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? SizedBox(
                          width: AppIconSize.sm,
                          height: AppIconSize.sm,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: AppIconSize.sm),
                  label: Text(isSaving ? AppStrings.savingLabel : AppStrings.save),
                  style: FilledButton.styleFrom(backgroundColor: _accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: AppIconSize.xl3,
            color: scheme.error,
          ),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(
            onPressed: onRetry,
            child: Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
