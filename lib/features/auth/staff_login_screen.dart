// =============================================================================
// FILE: lib/features/auth/staff_login_screen.dart
// PURPOSE: Staff/Teacher login — same URL as school admin, role auto-detected
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/services/local_storage_service.dart';
import '../../design_system/design_system.dart';
import '../../core/constants/app_strings.dart';
import '../../models/school_identity.dart';
import '../../utils/subdomain_resolver.dart';
import '../../widgets/school_identity_banner.dart';
import 'auth_screen_layout.dart';
import 'school_staff_login_provider.dart';
import 'school_setup_search_widget.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  int _selectedTab = 0; // 0=Password, 1=OTP, 2=QR
  SchoolIdentity? _identity;
  bool _isLoading = false;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedSchool();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSchool() async {
    if (kIsWeb) {
      final resolver = ref.read(subdomainResolverProvider);
      final sub = await SubdomainResolver.getCurrentSubdomain();
      if (sub == null || sub.isEmpty) return;
      final identity = await resolver.resolve(sub);
      if (mounted && identity != null) setState(() => _identity = identity);
    } else {
      final storage = LocalStorageService();
      final savedSchool = await storage.getSavedSchool();
      if (mounted && savedSchool != null) setState(() => _identity = savedSchool);
    }
  }

  Future<void> _onChangeSchool() async {
    final ok = await AppDialogs.confirm(
      context,
      title: AppStrings.changeSchoolQuestion,
      message: AppStrings.changeSchoolMessage,
      confirmLabel: AppStrings.yesChange,
    );
    if (!ok || !mounted) return;
    setState(() {
      _identity = null;
      _errorMessage = null;
    });
    if (!kIsWeb) {
      final storage = LocalStorageService();
      await storage.clearSchool();
      await storage.clearSession();
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_identity == null) {
      setState(() => _errorMessage = AppStrings.selectSchoolAbove);
      return;
    }
    ref.read(schoolStaffLoginProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
          schoolId: _identity!.id,
          portalType: 'staff',
          schoolIdentity: _identity,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SchoolStaffLoginState>(schoolStaffLoginProvider, (prev, next) {
      if (!mounted) return;
      setState(() {
        _isLoading = next.isLoading;
        _errorMessage = next.errorMessage;
      });
      if (next.requiresOtp &&
          prev?.requiresOtp != true &&
          next.otpSessionId != null &&
          next.otpSessionId!.isNotEmpty) {
        final q =
            'otp_session_id=${next.otpSessionId!}&masked_phone=${Uri.encodeComponent(next.maskedPhone ?? '')}&masked_email=${Uri.encodeComponent(next.maskedEmail ?? '')}&otp_sent_to=${Uri.encodeComponent(next.otpSentTo ?? '')}&portal_type=staff${next.devOtp != null ? '&dev_otp=${next.devOtp}' : ''}';
        context.push('/device-verification?$q');
      }
      if (next.requires2fa &&
          prev?.requires2fa != true &&
          next.tempToken != null &&
          next.tempToken!.isNotEmpty) {
        final q = 'temp_token=${Uri.encodeComponent(next.tempToken!)}&portal_type=staff';
        context.push('/verify-2fa?$q');
      }
      if (next.isSuccess && prev?.isSuccess != true) {
        context.go('/staff/dashboard');
      }
    });

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_identity == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SchoolSetupSearchWidget(
              onSchoolSelected: (school) {
                setState(() {
                  _identity = school;
                  _errorMessage = null;
                });
              },
              layout: SchoolSearchLayout.popup,
              middleContent: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error700),
                      ),
                    ),
                  _buildLoginCard(),
                ],
              ),
            ),
          )
        else ...[
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: AppColors.error700),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SchoolIdentityBanner(
              identity: _identity!,
              showStats: true,
              showChangeLink: true,
              onChangeTap: _onChangeSchool,
            ),
          ),
          _buildLoginCard(),
        ],
      ],
    );

    return AuthScreenLayout(
      loading: _isLoading,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: content,
      ),
    );
  }

  Widget _buildLoginCard() {
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  controller: _tabController,
                  onTap: (i) => setState(() => _selectedTab = i),
                  labelColor: AuthColors.primary,
                  tabs: const [
                    Tab(text: AppStrings.passwordTab),
                    Tab(text: AppStrings.otpTab),
                    Tab(text: AppStrings.qrScanTab),
                  ],
                ),
                AppSpacing.vGapXl,
                if (_selectedTab == 0) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.emailMobileRequired,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? AppStrings.enterEmailOrMobileError : null,
                  ),
                  AppSpacing.vGapLg,
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: AuthStrings.password,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.enterPasswordError : null,
                  ),
                  AppSpacing.vGapSm,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(AuthStrings.forgotPassword, style: AuthTextStyles.forgotPassword),
                    ),
                  ),
                  Text(
                    AppStrings.autoDetectedRole,
                    style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                  ),
                ] else if (_selectedTab == 1) ...[
                  const TextField(
                    decoration: InputDecoration(
                      labelText: AppStrings.mobileNumber,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    AppStrings.autoDetectedFromNumber,
                    style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                  ),
                  AppSpacing.vGapLg,
                  FilledButton(onPressed: () {}, child: const Text(AppStrings.sendOtp)),
                ] else ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AuthColors.overlayLight(0.3),
                      borderRadius: AppRadius.brLg,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 64, color: AuthColors.primary),
                          AppSpacing.vGapMd,
                          Text(
                            AppStrings.scanQrOnIdCard,
                            style: AuthTextStyles.tagline,
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            AppStrings.driversQrAutoAssigns,
                            style: AuthTextStyles.tagline.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                AppSpacing.vGapXl,
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    padding: AppSpacing.paddingVLg,
                  ),
                  child: Text(AuthStrings.login, style: AuthTextStyles.buttonPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
