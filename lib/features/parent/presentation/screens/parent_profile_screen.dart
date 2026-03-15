// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_profile_screen.dart
// PURPOSE: View and edit own profile for Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/parent_profile_model.dart';
import '../../data/parent_profile_provider.dart';
import '../../../../shared/widgets/widgets.dart';

const Color _accent = AppColors.success500;

class ParentProfileScreen extends ConsumerStatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  ConsumerState<ParentProfileScreen> createState() =>
      _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isEditing = false;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentProfileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _populateFromProfile() {
    final profile = ref.read(parentProfileProvider).profile;
    if (profile != null && !_populated) {
      _firstNameCtrl.text = profile.firstName;
      _lastNameCtrl.text = profile.lastName;
      _emailCtrl.text = profile.email ?? '';
      _populated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentProfileProvider);
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
                    error: state.errorMessage ?? AppStrings.genericError,
                    onRetry: () =>
                        ref.read(parentProfileProvider.notifier).loadProfile(),
                  )
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.parentProfileTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold),
                            ),
                            AppSpacing.vGapXs,
                            Text(
                              AppStrings.parentProfileSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            ),
                            AppSpacing.vGapXl,

                            _AvatarHeader(profile: state.profile!),
                            const SizedBox(height: 20),

                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _isEditing
                                    ? _EditForm(
                                        formKey: _formKey,
                                        firstNameCtrl: _firstNameCtrl,
                                        lastNameCtrl: _lastNameCtrl,
                                        emailCtrl: _emailCtrl,
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
                                        onEdit: () =>
                                            setState(() => _isEditing = true),
                                      ),
                              ),
                            ),

                            if (state.errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: AppSpacing.paddingMd,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  borderRadius: AppRadius.brMd,
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
    final ok = await ref.read(parentProfileProvider.notifier).updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty
          ? null
          : _emailCtrl.text.trim(),
    });
    if (ok && mounted) {
      setState(() {
        _isEditing = false;
        _populated = false;
      });
      AppFeedback.showSuccess(context, AppStrings.updatedSuccess);
    } else if (mounted && ref.read(parentProfileProvider).errorMessage != null) {
      AppFeedback.showError(
        context,
        ref.read(parentProfileProvider).errorMessage!,
      );
    }
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.profile});

  final ParentProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: _accent.withValues(alpha: 0.15),
          child: Text(
            profile.initials,
            style: const TextStyle(
              fontSize: 22,
              color: _accent,
              fontWeight: FontWeight.bold,
            ),
          ),
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
              profile.email ?? profile.phone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            if (profile.relation != null) ...[
              const SizedBox(height: 2),
              Text(
                profile.relation!,
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

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.onEdit});

  final ParentProfileModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              AppStrings.profileDetails,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(AppStrings.edit),
            ),
          ],
        ),
        const Divider(height: 16),
        _Row(AppStrings.firstName, profile.firstName),
        _Row(AppStrings.lastName, profile.lastName),
        _Row(AppStrings.phone, profile.phone),
        if (profile.email != null && profile.email!.isNotEmpty)
          _Row(AppStrings.email, profile.email!),
        if (profile.relation != null) _Row(AppStrings.parentRelationLabel, profile.relation!),
        if (profile.schoolName.isNotEmpty)
          _Row(AppStrings.parentSchoolLabel, profile.schoolName),
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
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
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
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
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
          Text(
            AppStrings.editProfile,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          TextFormField(
            controller: firstNameCtrl,
            decoration: const InputDecoration(
              labelText: AppStrings.firstName,
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? AppStrings.required : null,
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: lastNameCtrl,
            decoration: const InputDecoration(
              labelText: AppStrings.lastName,
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.vGapMd,
          TextFormField(
            controller: emailCtrl,
            decoration: const InputDecoration(
              labelText: AppStrings.email,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text(AppStrings.cancel),
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSaving ? AppStrings.savingLabel : AppStrings.save),
                  style: FilledButton.styleFrom(backgroundColor: _accent),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(
              onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
