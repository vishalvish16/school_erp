import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_login_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (mounted) {
        _emailController.text = savedEmail;
        ref.read(loginProvider.notifier).updateEmail(savedEmail);
        ref.read(loginProvider.notifier).toggleRememberMe(true);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginProvider.notifier).updateEmail(_emailController.text.trim());
    ref.read(loginProvider.notifier).updatePassword(_passwordController.text);
    await ref.read(loginProvider.notifier).login();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    ref.listen<LoginState>(loginProvider, (previous, next) {
      if (next.isSuccess && previous?.isSuccess != true) {
        context.go('/dashboard');
      } else if (next.isFailure && previous?.isFailure != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? AppStrings.loginFailed),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    final isMobile = MediaQuery.of(context).size.width < AuthSizes.breakpointLogin;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer
          Image.asset(AuthAssets.background, fit: BoxFit.cover),

          // Light gradient overlay - keeps background visible for glass effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuthColors.overlayLight(0.15),
                  AuthColors.overlayLight(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Responsive Content
          SafeArea(
            child: Column(
              children: [
                // Header: Logo
                _buildHeader(isMobile: isMobile),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AuthSizes.scrollPadding,
                        vertical: AuthSizes.scrollPadding,
                      ),
                      child: isMobile
                          ? _buildMobileLayout(loginState)
                          : _buildWebLayout(loginState),
                    ),
                  ),
                ),
                // Footer: Protect, Track, Automate (web only)
                if (!isMobile) _buildFooter(isMobile: false),
              ],
            ),
          ),

          // Global Loading Indicator
          if (loginState.isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: AuthSizes.glassBlur, sigmaY: AuthSizes.glassBlur),
                child: Container(
                  color: AuthColors.overlayDark(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: AuthSizes.loadingStrokeWidth,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(LoginState state) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AuthSizes.maxContentWidth),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: High-impact Branding
          Expanded(flex: 6, child: _buildBrandingPanel(isMobile: false)),
          const SizedBox(width: AuthSizes.brandingGap),
          // Right Side: Login Card
          Expanded(
            flex: 4,
            child: _buildGlassLoginCard(state, isMobile: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(LoginState state) {
    return Column(
      children: [
        _buildGlassLoginCard(state, isMobile: true),
        SizedBox(height: AuthSizes.sectionGap),
        _buildMobileStatistics(),
      ],
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AuthSizes.headerPaddingV,
        horizontal: AuthSizes.headerPaddingH,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AuthAssets.logo,
            height: isMobile ? AuthSizes.logoHeightMobile : AuthSizes.logoHeightWeb,
            fit: BoxFit.contain,
          ),
          if (isMobile) ...[
            SizedBox(height: AuthSizes.taglineGap),
            _buildMobileTagline(),
          ],
        ],
      ),
    );
  }

  /// Shield icon + "Protect • Track • Automate" — mobile only, below logo
  Widget _buildMobileTagline() {
    final dotSeparator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuthSizes.taglineDotPadding),
      child: Container(
        width: AuthSizes.taglineDotSize,
        height: AuthSizes.taglineDotSize,
        decoration: const BoxDecoration(
          color: AuthColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AuthAssets.protect,
          width: AuthSizes.taglineIconSize,
          height: AuthSizes.taglineIconSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.shield, size: AuthSizes.taglineIconSize, color: AuthColors.primary),
        ),
        const SizedBox(width: AuthSizes.taglineIconGap),
        Text(AuthStrings.protect, style: AuthTextStyles.tagline),
        dotSeparator,
        Text(AuthStrings.track, style: AuthTextStyles.tagline),
        dotSeparator,
        Text(AuthStrings.automate, style: AuthTextStyles.tagline),
      ],
    );
  }

  Widget _buildBrandingPanel({required bool isMobile}) {
    return _buildGlassPanel(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AuthSizes.brandingPaddingMobile : AuthSizes.brandingPaddingWeb),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isMobile
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            _buildFeaturePoint(AuthStrings.featureAiShield),
            _buildFeaturePoint(AuthStrings.featureMultiCampus),
            _buildFeaturePoint(AuthStrings.featureAnalytics),
            _buildFeaturePoint(AuthStrings.featureCompliance),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter({required bool isMobile}) {
    final gap = isMobile ? AuthSizes.footerGapMobile : AuthSizes.footerGapWeb;
    final dotSeparator = Padding(
      padding: EdgeInsets.symmetric(horizontal: gap / 2),
      child: Container(
        width: AuthSizes.taglineDotSize,
        height: AuthSizes.taglineDotSize,
        decoration: const BoxDecoration(
          color: AuthColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AuthSizes.footerPaddingV,
        horizontal: AuthSizes.footerPaddingH,
      ),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFooterIcon(AuthAssets.protect, isMobile),
                      SizedBox(width: isMobile ? AuthSizes.footerGapMobile : AuthSizes.footerGapWeb),
                      _buildFooterIcon(AuthAssets.track, isMobile),
                      SizedBox(width: isMobile ? AuthSizes.footerGapMobile : AuthSizes.footerGapWeb),
                      _buildFooterIcon(AuthAssets.automate, isMobile),
                    ],
                  ),
                  SizedBox(height: AuthSizes.footerTextGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AuthStrings.protect, style: AuthTextStyles.tagline),
                      dotSeparator,
                      Text(AuthStrings.track, style: AuthTextStyles.tagline),
                      dotSeparator,
                      Text(AuthStrings.automate, style: AuthTextStyles.tagline),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFooterIcon(AuthAssets.protect, isMobile),
                    SizedBox(width: AuthSizes.footerGapWeb),
                    _buildFooterIcon(AuthAssets.track, isMobile),
                    SizedBox(width: AuthSizes.footerGapWeb),
                    _buildFooterIcon(AuthAssets.automate, isMobile),
                  ],
                ),
                SizedBox(height: AuthSizes.footerTextGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AuthStrings.protect, style: AuthTextStyles.tagline),
                    dotSeparator,
                    Text(AuthStrings.track, style: AuthTextStyles.tagline),
                    dotSeparator,
                    Text(AuthStrings.automate, style: AuthTextStyles.tagline),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildFooterIcon(String assetPath, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AuthSizes.footerIconPadding),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AuthColors.overlayLight(0.08),
            blurRadius: AuthSizes.formFieldShadowBlur,
            offset: const Offset(0, AuthSizes.formFieldShadowOffset),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        width: isMobile ? AuthSizes.footerIconMobile : AuthSizes.footerIconWeb,
        height: isMobile ? AuthSizes.footerIconMobile : AuthSizes.footerIconWeb,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.verified_user, size: isMobile ? AuthSizes.footerIconMobile : AuthSizes.footerIconWeb, color: AuthColors.primary),
      ),
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuthSizes.featurePointGap),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AuthSizes.featurePointIconPadding),
            decoration: const BoxDecoration(
              color: AuthColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: AuthSizes.featurePointIconSize, color: Colors.white),
          ),
          SizedBox(width: AuthSizes.featurePointTextGap),
          Text(
            text,
            style: AuthTextStyles.featurePoint,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AuthSizes.glassBlur, sigmaY: AuthSizes.glassBlur),
        child: Container(
          decoration: BoxDecoration(
            color: AuthColors.overlayLight(0.25),
            borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            border: Border.all(
              color: AuthColors.overlayLight(0.5),
              width: AuthSizes.glassBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: AuthColors.overlayDark(0.08),
                blurRadius: AuthSizes.glassShadowBlur,
                offset: Offset(0, AuthSizes.glassShadowOffset),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassLoginCard(LoginState state, {required bool isMobile}) {
    return _buildGlassPanel(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AuthSizes.cardPadding),
        child: Form(
          key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    AuthStrings.login,
                    style: AuthTextStyles.loginTitle,
                  ),
                ),
                SizedBox(height: AuthSizes.formSpacingMedium),

                // Email Input
                _buildStyledField(
                  controller: _emailController,
                  hint: AuthStrings.email,
                  icon: Icons.alternate_email_rounded,
                  validator: (v) => v == null || v.isEmpty
                      ? AppStrings.enterEmailError
                      : null,
                ),
                SizedBox(height: AuthSizes.formSpacingSmall),

                // Password Input
                _buildStyledField(
                  controller: _passwordController,
                  hint: AuthStrings.password,
                  icon: Icons.security_rounded,
                  isPassword: true,
                  validator: (v) => v == null || v.isEmpty
                      ? AppStrings.enterPasswordError
                      : null,
                ),

                SizedBox(height: AuthSizes.formSpacingSmall),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => ref
                          .read(loginProvider.notifier)
                          .toggleRememberMe(!state.rememberMe),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: state.rememberMe,
                            onChanged: (val) => ref
                                .read(loginProvider.notifier)
                                .toggleRememberMe(val),
                            activeTrackColor: AuthColors.primary,
                            activeThumbColor: Colors.white,
                            inactiveTrackColor: AuthColors.switchInactiveTrack,
                            inactiveThumbColor: Colors.white,
                          ),
                          SizedBox(width: AuthSizes.checkboxLabelGap),
                          Text(
                            AuthStrings.rememberMe,
                            style: AuthTextStyles.rememberMe,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AuthSizes.formSpacingLarge),

                // Access Button
                Container(
                  height: AuthSizes.buttonHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AuthSizes.buttonRadius),
                    gradient: const LinearGradient(
                      colors: [AuthColors.primary, AuthColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AuthColors.primary.withValues(alpha: 0.3),
                        blurRadius: AuthSizes.buttonShadowBlur,
                        offset: Offset(0, AuthSizes.buttonShadowOffset),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AuthSizes.buttonRadius),
                      ),
                    ),
                    child: Text(
                      AuthStrings.login,
                      style: AuthTextStyles.buttonPrimary,
                    ),
                  ),
                ),

                SizedBox(height: AuthSizes.formSpacingMedium),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      AuthStrings.forgotPassword,
                      style: AuthTextStyles.forgotPassword.copyWith(
                        color: AuthColors.overlayDark(0.6),
                      ),
                    ),
                  ),
                ),
                if (state.isBiometricSupported && state.isBiometricEnabled) ...[
                  SizedBox(height: AuthSizes.formSpacingLarge),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AuthColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AuthSizes.biometricDividerPadding),
                        child: Text(
                          AuthStrings.or,
                          style: AuthTextStyles.orDivider,
                        ),
                      ),
                      Expanded(child: Divider(color: AuthColors.border)),
                    ],
                  ),
                  SizedBox(height: AuthSizes.formSpacingMedium),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(loginProvider.notifier).loginWithBiometrics(),
                    icon: Icon(Icons.fingerprint_rounded, size: AuthSizes.biometricIconSize),
                    label: Text(
                      AuthStrings.biometricEntry,
                      style: AuthTextStyles.biometricLabel,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AuthColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AuthSizes.biometricPaddingV),
                      side: BorderSide(
                        color: AuthColors.border,
                        width: AuthSizes.glassBorderWidth,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AuthSizes.buttonRadius),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
        border: Border.all(color: AuthColors.border),
        boxShadow: [
          BoxShadow(
            color: AuthColors.overlayDark(0.04),
            blurRadius: AuthSizes.formFieldShadowBlur,
            offset: Offset(0, AuthSizes.formFieldShadowOffset),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: AuthTextStyles.inputText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AuthTextStyles.inputHint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuthSizes.formFieldPaddingH,
            vertical: AuthSizes.formFieldPaddingV,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AuthColors.textMuted, size: AuthSizes.formFieldIconSize),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthColors.textHint,
                    size: AuthSizes.formFieldIconSize,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildMobileStatistics() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatBubble(AuthStrings.statStudents, AuthStrings.statStudentsLabel),
          SizedBox(width: AuthSizes.statBubbleGap),
          _buildStatBubble(AuthStrings.statAttendance, AuthStrings.statAttendanceLabel),
          SizedBox(width: AuthSizes.statBubbleGap),
          _buildStatBubble(AuthStrings.statIncidents, AuthStrings.statIncidentsLabel),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuthSizes.statBubblePaddingH,
        vertical: AuthSizes.statBubblePaddingV,
      ),
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.25),
        borderRadius: BorderRadius.circular(AuthSizes.statBubbleRadius),
        border: Border.all(color: AuthColors.overlayLight(0.4)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: AuthTextStyles.statValue,
          ),
          Text(
            label,
            style: AuthTextStyles.statLabel,
          ),
        ],
      ),
    );
  }

}
