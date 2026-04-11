import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../design_system/design_system.dart';
import 'reset_password_provider.dart';
import 'reset_password_state.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _passwordFieldKey = GlobalKey();
  bool _isPasswordVisible = false;
  OverlayEntry? _tooltipOverlay;

  static final List<({String label, bool Function(String) check})>
  _passwordRules = [
    (label: AuthStrings.passwordRuleMinLength, check: (s) => s.length >= 8),
    (
      label: AuthStrings.passwordRuleUppercase,
      check: (s) => s.contains(RegExp(r'[A-Z]')),
    ),
    (
      label: AuthStrings.passwordRuleLowercase,
      check: (s) => s.contains(RegExp(r'[a-z]')),
    ),
    (
      label: AuthStrings.passwordRuleNumber,
      check: (s) => s.contains(RegExp(r'[0-9]')),
    ),
    (
      label: AuthStrings.passwordRuleSpecial,
      check: (s) =>
          s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]')),
    ),
  ];

  bool _hasUnsatisfiedPasswordRules(String? value) {
    if (value == null || value.isEmpty) return true;
    return _passwordRules.any((r) => !r.check(value));
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    if (mounted) setState(() {});
  }

  void _updateTooltipVisibility() {
    if (!mounted) return;
    final hasUnsatisfied = _hasUnsatisfiedPasswordRules(
      _passwordController.text,
    );
    final hasText = _passwordController.text.isNotEmpty;

    if (hasText && hasUnsatisfied) {
      if (_tooltipOverlay != null) {
        _tooltipOverlay!.markNeedsBuild();
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showTooltipOverlay(),
        );
      }
    } else {
      _hideTooltip();
    }
  }

  void _showTooltipOverlay() {
    if (!mounted || _tooltipOverlay != null) return;
    final overlay = Overlay.of(context);
    final box =
        _passwordFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final isMobile =
        MediaQuery.of(context).size.width < AuthSizes.breakpointMobile;

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: isMobile ? pos.dx : pos.dx + size.width + 12,
        top: isMobile ? pos.dy + size.height + 8 : pos.dy,
        child: _buildPasswordTooltip(_passwordController.text),
      ),
    );
    overlay.insert(_tooltipOverlay!);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateTooltipVisibility);
  }

  @override
  void dispose() {
    _hideTooltip();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(resetPasswordProvider.notifier);
    notifier.setToken(widget.token);
    notifier.updatePassword(_passwordController.text);
    notifier.updateConfirmPassword(_confirmController.text);
    await notifier.resetPassword();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);
    final isMobile =
        MediaQuery.of(context).size.width < AuthSizes.breakpointMobile;

    ref.listen<ResetPasswordState>(resetPasswordProvider, (previous, next) {
      if (next.isSuccess && previous?.isSuccess != true) {
        AppSnackbar.success(context, AuthStrings.passwordUpdated);
        context.go('/login');
      } else if (next.isFailure && previous?.isFailure != true) {
        AppSnackbar.error(context, next.errorMessage ?? AuthStrings.resetFailed);
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
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

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Header: Logo + Mobile Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AuthSizes.headerPaddingV,
                    horizontal: AuthSizes.headerPaddingH,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AuthAssets.logo,
                        height: isMobile
                            ? AuthSizes.logoHeightMobile
                            : AuthSizes.logoHeightWeb,
                        fit: BoxFit.contain,
                      ),
                      if (isMobile) ...[
                        SizedBox(height: AuthSizes.taglineGap),
                        _buildMobileTagline(),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AuthSizes.scrollPadding),
                      child: _buildResetCard(context, state, isMobile),
                    ),
                  ),
                ),
                // Footer: Protect, Track, Automate (web only)
                if (!isMobile) _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final gap = AuthSizes.footerGapWeb;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFooterIcon(AuthAssets.protect),
              SizedBox(width: AuthSizes.footerGapWeb),
              _buildFooterIcon(AuthAssets.track),
              SizedBox(width: AuthSizes.footerGapWeb),
              _buildFooterIcon(AuthAssets.automate),
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

  Widget _buildFooterIcon(String assetPath) {
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
        width: AuthSizes.footerIconWeb,
        height: AuthSizes.footerIconWeb,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.verified_user,
          size: AuthSizes.footerIconWeb,
          color: AuthColors.primary,
        ),
      ),
    );
  }

  Widget _buildMobileTagline() {
    final dotSeparator = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuthSizes.taglineDotPadding,
      ),
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
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.shield,
            size: AuthSizes.taglineIconSize,
            color: AuthColors.primary,
          ),
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

  Widget _buildResetCard(
    BuildContext context,
    ResetPasswordState state,
    bool isMobile,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuthSizes.glassBlurStrong,
          sigmaY: AuthSizes.glassBlurStrong,
        ),
        child: Container(
          width: isMobile ? double.infinity : AuthSizes.cardWidthFixed,
          padding: const EdgeInsets.all(AuthSizes.cardPadding),
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AuthStrings.secureCredentials,
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.screenTitle,
                ),
                SizedBox(height: AuthSizes.formSpacingMedium - 12),
                Text(
                  AuthStrings.secureCredentialsDesc,
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.screenSubtitle,
                ),
                SizedBox(height: AuthSizes.cardPadding),

                // Password Field (tooltip shows as overlay on blur)
                Container(
                  key: _passwordFieldKey,
                  child: _buildStyledInput(
                    context: context,
                    controller: _passwordController,
                    hint: AuthStrings.newSecurityKey,
                    icon: Icons.vpn_key_rounded,
                    isPassword: true,
                    focusNode: _passwordFocusNode,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AuthStrings.passwordRequired;
                      }
                      for (final r in _passwordRules) {
                        if (!r.check(v)) return '${r.label} required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: AuthSizes.formSpacingSmall),

                // Confirm Password Field
                _buildStyledInput(
                  context: context,
                  controller: _confirmController,
                  hint: AuthStrings.authorizeSecurityKey,
                  icon: Icons.check_circle_outline_rounded,
                  isPassword: true,
                  focusNode: _confirmFocusNode,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return AuthStrings.keysDoNotMatch;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AuthSizes.sectionGap),

                // Action Button
                Container(
                  width: double.infinity,
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
                    onPressed: state.isLoading ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AuthSizes.buttonRadius,
                        ),
                      ),
                    ),
                    child: state.isLoading
                        ? SizedBox(
                            width: AuthSizes.formSpacingMedium,
                            height: AuthSizes.formSpacingMedium,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            AuthStrings.finalizeUpdate,
                            style: AuthTextStyles.buttonPrimary.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: AuthSizes.formSpacingBackLink),

                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    AuthStrings.cancelUpdate,
                    style: AuthTextStyles.tagline.copyWith(
                      color: AuthColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTooltip(String password) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
      shadowColor: AuthColors.overlayDark(0.15),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AuthColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  AppStrings.tooltipRequirements,
                  style: AuthTextStyles.inputHint.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textPrimary,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            ..._passwordRules.map((r) {
              final satisfied = r.check(password);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      satisfied ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: satisfied ? AuthColors.success : AppColors.error500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.label,
                        style: AuthTextStyles.inputHint.copyWith(
                          fontSize: 11,
                          color: satisfied
                              ? AuthColors.success
                              : AppColors.error500,
                          fontWeight: satisfied
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledInput({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    FocusNode? focusNode,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark ||
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final inputTextColor = isDark ? AppColors.neutral50 : AppColors.neutral800;
    final hintColor = isDark ? AppColors.neutral400 : colorScheme.onSurfaceVariant;
    final iconColor = isDark ? AppColors.neutral400 : colorScheme.onSurfaceVariant;
    final fieldBgColor = isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
        border: Border.all(color: colorScheme.outlineVariant),
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
        focusNode: focusNode,
        obscureText: isPassword && !_isPasswordVisible,
        cursorColor: colorScheme.primary,
        style: AuthTextStyles.inputText.copyWith(color: inputTextColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AuthTextStyles.inputHint.copyWith(color: hintColor),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuthSizes.formFieldPaddingH,
            vertical: AuthSizes.formFieldPaddingV,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            icon,
            color: iconColor,
            size: AuthSizes.formFieldIconSize,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: iconColor,
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
}
