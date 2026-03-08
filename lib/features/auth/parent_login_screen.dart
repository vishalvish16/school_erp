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
import '../../core/services/local_storage_service.dart';
import '../../models/school_identity.dart';
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
    for (final c in _otpControllers) c.dispose();
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
    // TODO: POST /auth/resolve-user-by-phone { phone, user_type }
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
        _detectedUserName = _userType == ParentStudentUserType.parent ? 'Parent Name' : 'Student Name';
        _detectedRole = _userType == ParentStudentUserType.parent
            ? 'Parent of Child, Class X'
            : 'Student · Class X · Roll 12';
      });
    }
  }

  Future<void> _confirmAndSendOtp() async {
    setState(() => _isLoading = true);
    // TODO: Confirm and send OTP
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {
      _isLoading = false;
      _step = 3;
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) return;
    setState(() => _isLoading = true);
    // TODO: Verify OTP
    final phone = _phoneController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_login_phone', phone);
    if (!kIsWeb) {
      final storage = LocalStorageService();
      await storage.saveUserPhone(phone.startsWith('+') ? phone : '+91$phone');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(_userType == ParentStudentUserType.parent ? '/dashboard/parent' : '/dashboard/student');
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
                  const SizedBox(width: 12),
                  _buildWhoToggle(ParentStudentUserType.student, 'Student'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStepPill(1, 'Phone'),
                  _buildStepPill(2, 'School'),
                  _buildStepPill(3, 'OTP'),
                ],
              ),
              const SizedBox(height: 24),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AuthColors.primary.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active || done
              ? AuthColors.primary.withValues(alpha: done ? 0.3 : 0.2)
              : AuthColors.overlayLight(0.3),
          borderRadius: BorderRadius.circular(8),
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
        const Text('Country code', style: AuthTextStyles.tagline),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AuthColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🇮🇳 +91'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Must be registered with your child\'s school',
          style: AuthTextStyles.tagline.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _findSchoolAndSendOtp,
          style: FilledButton.styleFrom(
            backgroundColor: AuthColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            _isLoading ? 'Finding...' : 'Find My School & Send OTP',
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuthColors.overlayLight(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_detectedSchool!.name, style: AuthTextStyles.loginTitle.copyWith(fontSize: 18)),
                Text('${_detectedSchool!.board} · ${_detectedSchool!.code}', style: AuthTextStyles.tagline),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AuthColors.success),
                    const SizedBox(width: 6),
                    Text('Verified', style: AuthTextStyles.tagline.copyWith(color: AuthColors.success)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_detectedUserName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuthColors.overlayLight(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 20, color: AuthColors.primary),
                  const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          Text(
            'Auto-detected from your number. No school code needed.',
            style: AuthTextStyles.tagline.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _confirmAndSendOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AuthColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Confirm & Send OTP', style: AuthTextStyles.buttonPrimary),
          ),
          TextButton(
            onPressed: () {},
            child: Text('Wrong school? Contact your school admin', style: AuthTextStyles.forgotPassword),
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
            'Signing into ${_detectedSchool!.name}',
            style: AuthTextStyles.tagline,
          ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: FilledButton.styleFrom(
            backgroundColor: AuthColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text('Verify & Enter Vidyron', style: AuthTextStyles.buttonPrimary),
        ),
      ],
    );
  }
}
