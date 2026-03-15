// =============================================================================
// FILE: lib/features/auth/school_setup_phone_widget.dart
// PURPOSE: Phone number entry for parent/student — auto-detect school
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/dio_client.dart';
import '../../models/school_identity.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class SchoolSetupPhoneWidget extends ConsumerStatefulWidget {
  const SchoolSetupPhoneWidget({
    super.key,
    required this.userType,
    required this.onResolved,
  });

  final String userType; // 'parent' | 'student'
  final ValueChanged<PhoneResolveResult> onResolved;

  @override
  ConsumerState<SchoolSetupPhoneWidget> createState() => _SchoolSetupPhoneWidgetState();
}

class PhoneResolveResult {
  PhoneResolveResult({
    required this.school,
    required this.phone,
    required this.portalType,
    this.otpSessionId,
    this.maskedPhone,
    this.userName,
    this.userRole,
  });

  final SchoolIdentity school;
  final String phone;
  final String portalType;
  final String? otpSessionId;
  final String? maskedPhone;
  final String? userName;
  final String? userRole;
}

class _SchoolSetupPhoneWidgetState extends ConsumerState<SchoolSetupPhoneWidget> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/api/platform/auth/resolve-user-by-phone',
        data: {
          'phone': '+91$digits',
          'user_type': widget.userType,
        },
      );

      if (!mounted) return;

      final data = res.data;
      if (res.statusCode != 200 || data == null) {
        setState(() {
          _error = 'This number isn\'t registered with any school on Vidyron. Ask your school admin to add you.';
          _isLoading = false;
        });
        return;
      }

      final payload = data is Map ? data['data'] ?? data : null;
      if (payload == null) {
        setState(() {
          _error = 'Could not find your school.';
          _isLoading = false;
        });
        return;
      }

      // Single school
      final schoolData = payload['school'];
      if (schoolData != null) {
        final school = SchoolIdentity.fromJson(Map<String, dynamic>.from(schoolData));
        widget.onResolved(PhoneResolveResult(
          school: school,
          phone: '+91$digits',
          portalType: widget.userType,
          otpSessionId: payload['otp_session_id']?.toString(),
          maskedPhone: payload['masked_phone']?.toString(),
          userName: payload['user']?['name']?.toString(),
          userRole: payload['user']?['role']?.toString(),
        ));
        setState(() => _isLoading = false);
        return;
      }

      // Multiple schools
      final schools = payload['schools'] as List?;
      if (schools != null && schools.isNotEmpty) {
        // For now pick first — could show picker
        final school = SchoolIdentity.fromJson(Map<String, dynamic>.from(schools.first));
        widget.onResolved(PhoneResolveResult(
          school: school,
          phone: '+91$digits',
          portalType: widget.userType,
          otpSessionId: payload['otp_session_id']?.toString(),
          maskedPhone: payload['masked_phone']?.toString(),
        ));
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _error = 'This number isn\'t registered with any school on Vidyron. Ask your school admin to add you.';
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Could not connect. ';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          msg += 'Ensure the backend is running and your device can reach it.';
        } else {
          msg += 'Check your connection and try again.';
        }
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect. Check your network and ensure the backend is running.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final canContinue = digits.length == 10 && !_isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.enterMobileNumber,
          style: AuthTextStyles.tagline.copyWith(
            color: AuthColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                border: Border.all(color: AuthColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(AppStrings.indiaFlag, style: TextStyle(fontSize: 20)),
                  AppSpacing.hGapSm,
                  Text(AppStrings.indiaCode, style: AuthTextStyles.inputText),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: AppStrings.tenDigitMobile,
                  hintStyle: AuthTextStyles.inputHint,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                    borderSide: const BorderSide(color: AuthColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                    borderSide: const BorderSide(color: AuthColors.border),
                  ),
                ),
                style: AuthTextStyles.inputText,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Text(
          AppStrings.weFindSchoolAuto,
          style: AuthTextStyles.inputHint.copyWith(
            fontSize: 13,
            color: AuthColors.textSecondary,
          ),
        ),
        if (_error != null) ...[
          AppSpacing.vGapMd,
          Text(_error!, style: AuthTextStyles.tagline.copyWith(color: AppColors.error500, fontSize: 13)),
        ],
        AppSpacing.vGapXl,
        SizedBox(
          height: AuthSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: canContinue ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AuthColors.textHint.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AuthSizes.buttonRadius),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(AppStrings.continueButton),
          ),
        ),
      ],
    );
  }
}
