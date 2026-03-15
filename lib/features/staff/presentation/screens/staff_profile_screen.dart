// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_profile_screen.dart
// PURPOSE: View and edit own profile for Staff/Clerk portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/staff/staff_profile_model.dart';
import '../providers/staff_profile_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.secondary400;

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() =>
      _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isEditing = false;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffProfileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _populateFromProfile() {
    final profile = ref.read(staffProfileProvider).profile;
    if (profile != null && !_populated) {
      _firstNameCtrl.text = profile.firstName ?? '';
      _lastNameCtrl.text = profile.lastName ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _populated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffProfileProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    if (state.profile != null && !_populated) {
      _populateFromProfile();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.profile == null
                ? _ErrorView(
                    error: state.errorMessage ?? 'Could not load profile',
                    onRetry: () =>
                        ref.read(staffProfileProvider.notifier).loadProfile(),
                  )
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Profile',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold),
                            ),
                            AppSpacing.vGapXl,

                            // Avatar + name header
                            _AvatarHeader(
                                profile: state.profile!),
                            const SizedBox(height: 20),

                            // Info / Edit card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _isEditing
                                    ? _EditForm(
                                        formKey: _formKey,
                                        firstNameCtrl: _firstNameCtrl,
                                        lastNameCtrl: _lastNameCtrl,
                                        phoneCtrl: _phoneCtrl,
                                        isSaving: state.isSaving,
                                        onSave: _save,
                                        onCancel: () {
                                          setState(() {
                                            _isEditing = false;
                                            _populated = false;
                                            _populateFromProfile();
                                          });
                                        },
                                      )
                                    : _ProfileView(
                                        profile: state.profile!,
                                        onEdit: () => setState(
                                            () => _isEditing = true),
                                      ),
                              ),
                            ),

                            // Error banner
                            if (state.errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: AppSpacing.paddingMd,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  borderRadius:
                                      AppRadius.brMd,
                                ),
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(staffProfileProvider.notifier).updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    if (ok && mounted) {
      setState(() {
        _isEditing = false;
        _populated = false;
      });
      AppSnackbar.success(context, 'Profile updated');
    }
  }
}

// ── Avatar Header ─────────────────────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.profile});

  final StaffProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: _accent.withValues(alpha: 0.15),
          backgroundImage: profile.photoUrl != null
              ? NetworkImage(profile.photoUrl!)
              : null,
          child: profile.photoUrl == null
              ? Text(
                  profile.initials,
                  style: const TextStyle(
                    fontSize: 22,
                    color: _accent,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        AppSpacing.hGapLg,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.fullName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              profile.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            if (profile.designation != null) ...[
              const SizedBox(height: 2),
              Text(
                profile.designation!,
                style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Profile View (read-only) ──────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.onEdit});

  final StaffProfileModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Profile Details',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
          ],
        ),
        const Divider(height: 16),
        _Row('Email', profile.email),
        if (profile.firstName != null)
          _Row('First Name', profile.firstName!),
        if (profile.lastName != null)
          _Row('Last Name', profile.lastName!),
        if (profile.phone != null) _Row('Phone', profile.phone!),
        if (profile.employeeNo != null)
          _Row('Employee No.', profile.employeeNo!),
        if (profile.designation != null)
          _Row('Designation', profile.designation!),
        if (profile.department != null)
          _Row('Department', profile.department!),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Edit Form ─────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;
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
          Text('Edit Profile',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          TextFormField(
            controller: firstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: lastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label:
                      Text(isSaving ? 'Saving...' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                      backgroundColor: _accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
