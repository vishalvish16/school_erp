// =============================================================================
// FILE: lib/features/auth/parent_login_screen.dart
// PURPOSE: Parent & Student login — vidyron.in/login (no subdomain)
// 3-step flow: Phone → School detected → OTP verify
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/parent_service.dart';
import '../../features/auth/auth_guard_provider.dart';
import '../../models/school_identity.dart';
import '../../shared/widgets/widgets.dart';
import 'auth_screen_layout.dart';

/// User type for parent/student combined login
enum ParentStudentUserType { parent, student }

class ParentLoginScreen extends ConsumerStatefulWidget {
  const ParentLoginScreen({
    super.key,
    this.initialUserType = ParentStudentUserType.parent,
  });

  final ParentStudentUserType initialUserType;

  @override
  ConsumerState<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends ConsumerState<ParentLoginScreen> {
  ParentStudentUserType _userType = ParentStudentUserType.parent;
  int _step = 1; // 1=Phone, 2=School detected, 3=OTP
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  SchoolIdentity? _detectedSchool;
  String? _detectedUserName;
  String? _detectedRole;
  bool _isLoading = false;
  String? _otpSessionId;
  String? _schoolId;
  String? _maskedPhone;

  @override
  void initState() {
    super.initState();
    _userType = widget.initialUserType;
    _loadSavedSchoolAndPhone();
  }

  @override
  void didUpdateWidget(covariant ParentLoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUserType != widget.initialUserType) {
      _userType = widget.initialUserType;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedSchoolAndPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('parent_login_phone');
    if (phone != null && mounted) _phoneController.text = phone;

    if (!kIsWeb) {
      final storage = LocalStorageService();
      final savedSchool = await storage.getSavedSchool();
      if (savedSchool == null && mounted) {
        context.go('/school-setup');
        return;
      }
      if (mounted && savedSchool != null) setState(() => _detectedSchool = savedSchool);
      final storedPhone = await storage.getUserPhone();
      if (storedPhone != null && mounted) _phoneController.text = storedPhone;
    }
  }

  Future<void> _findSchoolAndSendOtp() async {
    if (_phoneController.text.trim().length < 10) return;
    setState(() => _isLoading = true);

    if (_userType == ParentStudentUserType.parent) {
      try {
        final phone = _phoneController.text.trim();
        final normalizedPhone = phone.startsWith('+') ? phone : '+91$phone';
        final service = ref.read(parentServiceProvider);
        final res = await service.resolveUserByPhone(
          phone: normalizedPhone,
          userType: 'parent',
        );

        if (!mounted) return;
        final school = res['school'];
        final user = res['user'];
        final otpSessionId = res['otp_session_id'] as String?;
        final maskedPhone = res['masked_phone'] as String?;

        if (school == null || otpSessionId == null) {
          setState(() => _isLoading = false);
          AppFeedback.showError(context, AppStrings.parentResolveFailed);
          return;
        }

        final schoolMap = school is Map ? school as Map<String, dynamic> : {};
        final schoolId = schoolMap['id']?.toString() ?? schoolMap['school_id']?.toString() ?? '';
        final schoolName = schoolMap['name']?.toString() ?? schoolMap['school_name']?.toString() ?? 'School';
        final code = schoolMap['code']?.toString() ?? '';
        final board = schoolMap['board']?.toString() ?? '';

        final userMap = user is Map ? user as Map<String, dynamic> : {};
        final userName = userMap['name']?.toString() ?? userMap['first_name']?.toString() ?? 'Parent';

        setState(() {
          _isLoading = false;
          _step = 2;
          _otpSessionId = otpSessionId;
          _schoolId = schoolId;
          _maskedPhone = maskedPhone;
          _detectedSchool = SchoolIdentity(
            id: schoolId,
            name: schoolName,
            code: code,
            board: board,
            type: 'school',
            studentCount: 0,
            active: true,
          );
          _detectedUserName = userName;
          _detectedRole = 'Parent';
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppFeedback.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 2;
          _detectedSchool = const SchoolIdentity(
            id: '1',
            name: 'Demo School',
            code: 'DEMO001',
            board: 'CBSE',
            type: 'school',
            studentCount: 500,
            active: true,
          );
          _detectedUserName = 'Student Name';
          _detectedRole = 'Student · Class X · Roll 12';
        });
      }
    }
  }

  Future<void> _confirmAndSendOtp() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _step = 3;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) return;
    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final normalizedPhone = phone.startsWith('+') ? phone : '+91$phone';

    if (_userType == ParentStudentUserType.parent &&
        _otpSessionId != null &&
        _schoolId != null) {
      try {
        final service = ref.read(parentServiceProvider);
        final res = await service.verifyParentOtp(
          otpSessionId: _otpSessionId!,
          otp: code,
          phone: normalizedPhone,
          schoolId: _schoolId!,
        );

        final token = res['access_token'] as String?;
        if (token == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            AppFeedback.showError(context, AppStrings.parentOtpFailed);
          }
          return;
        }

        await ref.read(authGuardProvider.notifier).establishSession(
              token,
              portalTypeOverride: 'parent',
            );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('parent_login_phone', normalizedPhone);
        if (!kIsWeb) {
          final storage = LocalStorageService();
          await storage.saveUserPhone(normalizedPhone);
        }

        if (mounted) {
          setState(() => _isLoading = false);
          AppFeedback.showSuccess(context, AppStrings.parentLoginSuccess);
          context.go('/parent/dashboard');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppFeedback.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_login_phone', normalizedPhone);
      if (!kIsWeb) {
        final storage = LocalStorageService();
        await storage.saveUserPhone(normalizedPhone);
      }
      if (mounted) {
        setState(() => _isLoading = false);
        context.go(_userType == ParentStudentUserType.parent
            ? '/parent/dashboard'
            : '/student/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      loading: _isLoading,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AuthSizes.glassBlur, sigmaY: AuthSizes.glassBlur),
        child: Container(
          padding: const EdgeInsets.all(AuthSizes.cardPadding),
          decoration: BoxDecoration(
            color: AuthColors.overlayLight(0.25),
            borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            border: Border.all(color: AuthColors.overlayLight(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _buildWhoToggle(ParentStudentUserType.parent, 'Parent'),
                  AppSpacing.hGapMd,
                  _buildWhoToggle(ParentStudentUserType.student, 'Student'),
                ],
              ),
              AppSpacing.vGapXl,
              Row(
                children: [
                  _buildStepPill(1, 'Phone'),
                  _buildStepPill(2, 'School'),
                  _buildStepPill(3, 'OTP'),
                ],
              ),
              AppSpacing.vGapXl,
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhoToggle(ParentStudentUserType type, String label) {
    final selected = _userType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = type),
        child: Container(
          padding: AppSpacing.paddingVMd,
          decoration: BoxDecoration(
            color: selected ? AuthColors.primary.withValues(alpha: 0.2) : null,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: selected ? AuthColors.primary : AuthColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == ParentStudentUserType.parent ? Icons.family_restroom : Icons.school,
                size: 20,
                color: selected ? AuthColors.primary : AuthColors.textMuted,
              ),
              AppSpacing.hGapSm,
              Text(label, style: AuthTextStyles.tagline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPill(int step, String label) {
    final active = _step == step;
    final done = _step > step;
    return Expanded(
      child: Container(
        padding: AppSpacing.paddingVSm,
        decoration: BoxDecoration(
          color: active || done
              ? AuthColors.primary.withValues(alpha: done ? 0.3 : 0.2)
              : AuthColors.overlayLight(0.3),
          borderRadius: AppRadius.brMd,
        ),
        child: Center(
          child: Text(
            label,
            style: AuthTextStyles.tagline.copyWith(
              fontSize: 12,
              color: active || done ? AuthColors.primary : AuthColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.countryCode, style: AuthTextStyles.tagline),
        AppSpacing.vGapXs,
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AuthColors.border),
                borderRadius: AppRadius.brMd,
              ),
              child: const Text(AppStrings.indiaFlagWithCode),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: AppStrings.mobileNumber,
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Text(
          AppStrings.mustBeRegisteredWithSchool,
          style: AuthTextStyles.tagline.copyWith(fontSize: 12),
        ),
        AppSpacing.vGapXl,
        FilledButton(
          onPressed: _isLoading ? null : _findSchoolAndSendOtp,
          style: FilledButton.styleFrom(
            backgroundColor: AuthColors.primary,
            padding: AppSpacing.paddingVLg,
          ),
          child: Text(
            _isLoading ? AppStrings.findingSchool : AppStrings.findSchoolSendOtp,
            style: AuthTextStyles.buttonPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_detectedSchool != null) ...[
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AuthColors.overlayLight(0.3),
              borderRadius: AppRadius.brLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_detectedSchool!.name, style: AuthTextStyles.loginTitle.copyWith(fontSize: 18)),
                Text('${_detectedSchool!.board} · ${_detectedSchool!.code}', style: AuthTextStyles.tagline),
                AppSpacing.vGapSm,
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AuthColors.success),
                    const SizedBox(width: 6),
                    Text(AppStrings.verified, style: AuthTextStyles.tagline.copyWith(color: AuthColors.success)),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vGapLg,
          if (_detectedUserName != null)
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AuthColors.overlayLight(0.2),
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 20, color: AuthColors.primary),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_detectedUserName!, style: AuthTextStyles.tagline.copyWith(fontWeight: FontWeight.w600)),
                        if (_detectedRole != null)
                          Text(_detectedRole!, style: AuthTextStyles.tagline.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          AppSpacing.vGapMd,
          Text(
            AppStrings.autoDetectedFromNumber,
            style: AuthTextStyles.tagline.copyWith(fontSize: 12),
          ),
          AppSpacing.vGapXl,
          FilledButton(
            onPressed: _isLoading ? null : _confirmAndSendOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AuthColors.primary,
              padding: AppSpacing.paddingVLg,
            ),
            child: Text(AppStrings.confirmAndSendOtp, style: AuthTextStyles.buttonPrimary),
          ),
          TextButton(
            onPressed: () => setState(() => _step = 1),
            child: Text(AppStrings.wrongSchoolContactSchoolAdmin, style: AuthTextStyles.forgotPassword),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_detectedSchool != null)
          Text(
            '${AppStrings.signingInto} ${_detectedSchool!.name}',
            style: AuthTextStyles.tagline,
          ),
        if (_maskedPhone != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppStrings.otpSentTo(_maskedPhone!),
              style: AuthTextStyles.tagline.copyWith(fontSize: 12),
            ),
          ),
        AppSpacing.vGapLg,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (i) => SizedBox(
              width: 44,
              child: TextField(
                controller: _otpControllers[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (v) {
                  if (v.length == 1 && i < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            ),
          ),
        ),
        AppSpacing.vGapXl,
        FilledButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: FilledButton.styleFrom(
            backgroundColor: AuthColors.primary,
            padding: AppSpacing.paddingVLg,
          ),
          child: Text(AppStrings.verifyAndEnterVidyron, style: AuthTextStyles.buttonPrimary),
        ),
      ],
    );
  }
}
