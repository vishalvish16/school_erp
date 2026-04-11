// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_edit_profile_screen.dart
// PURPOSE: Edit profile — name, email, phone, avatar with OTP verification.
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/group_admin/group_admin_models.dart';
import '../providers/group_admin_profile_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

class GroupAdminEditProfileScreen extends ConsumerStatefulWidget {
  const GroupAdminEditProfileScreen({super.key});

  @override
  ConsumerState<GroupAdminEditProfileScreen> createState() =>
      _GroupAdminEditProfileScreenState();
}

class _GroupAdminEditProfileScreenState
    extends ConsumerState<GroupAdminEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String? _avatarBase64;
  String? _avatarUrl;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  String? _otpSessionId;
  String? _maskedEmail;
  String? _maskedPhone;
  String? _errorMessage;
  String _originalEmail = '';
  String _originalPhone = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _emailChanged =>
      _emailController.text.trim() != _originalEmail;
  bool get _phoneChanged =>
      _phoneController.text.trim() != _originalPhone;
  bool get _needsOtp => _emailChanged || _phoneChanged;
  bool get _otpSent => _otpSessionId != null;
  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _initFromProfile(GroupAdminProfileModel p) {
    _originalEmail = p.email;
    _originalPhone = p.phone ?? '';
    _firstNameController.text = p.firstName ?? '';
    _lastNameController.text = p.lastName ?? '';
    _emailController.text = p.email;
    _phoneController.text = p.phone ?? '';
    _avatarUrl = p.avatarUrl;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (xfile == null || !mounted) return;
      final bytes = await xfile.readAsBytes();
      final base64 = base64Encode(bytes);
      final mime = xfile.mimeType ?? 'image/jpeg';
      setState(() {
        _avatarBase64 = 'data:$mime;base64,$base64';
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _sendOtp() async {
    if (!_needsOtp) return;
    final email = _emailChanged ? _emailController.text.trim() : null;
    final phone = _phoneChanged ? _phoneController.text.trim() : null;
    if (email == null && phone == null) return;
    if (email != null && email.isEmpty) return;
    if (phone != null && phone.length < 10) {
      AppSnackbar.warning(context, AppStrings.enterValidPhone);
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });
    try {
      final svc = ref.read(groupAdminServiceProvider);
      final result = await svc.sendProfileOtp(email: email, phone: phone);
      if (mounted) {
        setState(() {
          _otpSessionId = result['otp_session_id']?.toString();
          _maskedEmail = result['masked_email']?.toString();
          _maskedPhone = result['masked_phone']?.toString();
          _isSendingOtp = false;
          _errorMessage = null;
        });
        AppSnackbar.success(context, AppStrings.verificationCodeSent);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsOtp && (!_otpSent || _otpCode.length != 6)) {
      AppSnackbar.warning(context, 'Please verify your email/phone with OTP first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final svc = ref.read(groupAdminServiceProvider);
      await svc.updateProfile(
        firstName: _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        avatarBase64: _avatarBase64,
        otpSessionId: _needsOtp ? _otpSessionId : null,
        otpCode: _needsOtp ? _otpCode : null,
      );
      if (mounted) {
        ref.invalidate(groupAdminProfileProvider);
        AppSnackbar.success(context, AppStrings.profileUpdated);
        context.go('/group-admin/profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? get _avatarDisplayUrl {
    if (_avatarBase64 != null) return null;
    if (_avatarUrl == null || _avatarUrl!.isEmpty) return null;
    if (_avatarUrl!.startsWith('http')) return _avatarUrl;
    return '${ApiConfig.baseUrl}$_avatarUrl';
  }

  ImageProvider? _avatarImageProvider(GroupAdminProfileModel profile) {
    if (_avatarBase64 != null) {
      try {
        final base64Data = _avatarBase64!.replaceFirst(RegExp(r'data:image/\w+;base64,'), '');
        final bytes = base64Decode(base64Data);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    if (_avatarDisplayUrl != null) {
      return NetworkImage(_avatarDisplayUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(groupAdminProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/group-admin/profile'),
        ),
      ),
      body: asyncProfile.when(
        loading: () => AppLoaderScreen(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.toString()),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref.invalidate(groupAdminProfileProvider),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (_originalEmail.isEmpty) _initFromProfile(profile);
          return SingleChildScrollView(
            padding: AppSpacing.paddingXl,
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.warning300,
                              backgroundImage: _avatarImageProvider(profile),
                              child: _avatarImageProvider(profile) == null
                                  ? Text(
                                      profile.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_avatarBase64 != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                                ),
                              )
                            else
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Center(
                      child: Text(
                        'Tap to change photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    AppSpacing.vGapXl,
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.firstName,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.vGapLg,
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.lastName,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.vGapLg,
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.email,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.vGapLg,
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    if (_needsOtp) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: AppSpacing.paddingLg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.verified_user,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary),
                                  AppSpacing.hGapSm,
                                  Text(
                                    'Verify changes',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              AppSpacing.vGapMd,
                              if (!_otpSent)
                                FilledButton(
                                  onPressed: _isSendingOtp ? null : _sendOtp,
                                  child: _isSendingOtp
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text(AppStrings.sendOtp),
                                )
                              else ...[
                                Text(
                                  'Enter the 6-digit code sent to ${_maskedEmail ?? _maskedPhone ?? 'you'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                AppSpacing.vGapMd,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    6,
                                    (i) => SizedBox(
                                      width: 40,
                                      child: TextFormField(
                                        controller: _otpControllers[i],
                                        focusNode: _otpFocusNodes[i],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (v) {
                                          if (v.length == 1 && i < 5) {
                                            _otpFocusNodes[i + 1].requestFocus();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      AppSpacing.vGapMd,
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    AppSpacing.vGapXl,
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.saveChanges),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
