import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../design_system/design_system.dart';
import 'forgot_password_provider.dart';
import 'forgot_password_state.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(forgotPasswordProvider.notifier)
        .updateEmail(_emailController.text.trim());
    await ref.read(forgotPasswordProvider.notifier).sendResetLink();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final isMobile =
        MediaQuery.of(context).size.width < AuthSizes.breakpointMobile;

    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (previous, next) {
      if (next.isFailure && previous?.isFailure != true) {
        final msg = next.errorMessage ?? AuthStrings.recoveryFailed;
        final isRateLimit = msg.toLowerCase().contains('too many') || msg.contains('429');
        AppSnackbar.error(context, isRateLimit
                ? AppStrings.tooManyAttemptsWait
                : msg);
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Premium Background
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: state.isSuccess
                            ? _buildSuccessCard(context, state.email)
                            : _buildRecoveryCard(context, state, isMobile),
                      ),
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

  Widget _buildRecoveryCard(
    BuildContext context,
    ForgotPasswordState state,
    bool isMobile,
  ) {
    return ClipRRect(
      key: const ValueKey('recovery_card'),
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
                  AuthStrings.recoverAccess,
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.screenTitle,
                ),
                SizedBox(height: AuthSizes.formSpacingMedium - 12),
                Text(
                  AuthStrings.recoverInstructions,
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.screenSubtitle,
                ),
                SizedBox(height: AuthSizes.cardPadding),

                // Email Field
                _buildStyledInput(
                  context: context,
                  controller: _emailController,
                  hint: AuthStrings.enterpriseEmail,
                  icon: Icons.alternate_email_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AuthStrings.emailRequired;
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v)) {
                      return AuthStrings.emailInvalid;
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
                            AuthStrings.sendRecoveryLink,
                            style: AuthTextStyles.buttonPrimary.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: AuthSizes.formSpacingBackLink),

                // Back to Login Link
                TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AuthColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AuthSizes.formSpacingSmall - 4,
                      vertical: AuthSizes.formFieldIconSize - 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: AuthSizes.formFieldIconSize - 2,
                      ),
                      SizedBox(width: AuthSizes.formFieldIconSize - 2),
                      Text(
                        AuthStrings.backToLogin,
                        style: AuthTextStyles.tagline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledInput({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
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
        ),
        keyboardType: TextInputType.emailAddress,
        validator: validator,
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context, String email) {
    return ClipRRect(
      key: const ValueKey('success_card'),
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuthSizes.glassBlurStrong,
          sigmaY: AuthSizes.glassBlurStrong,
        ),
        child: Container(
          width: AuthSizes.cardWidthFixed,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: AuthSizes.successIconSize,
                color: AuthColors.success,
              ),
              SizedBox(height: AuthSizes.successSpacing),
              Text(
                AuthStrings.recoveryLinkSent,
                style: AuthTextStyles.successTitle,
              ),
              SizedBox(height: AuthSizes.successBodySpacing),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AuthTextStyles.successBody,
                  children: [
                    const TextSpan(text: AuthStrings.recoveryLinkMessage),
                    TextSpan(text: email, style: AuthTextStyles.successEmail),
                    const TextSpan(text: AuthStrings.recoveryLinkFooter),
                  ],
                ),
              ),
              SizedBox(height: AuthSizes.successButtonSpacing),
              SizedBox(
                width: double.infinity,
                height: AuthSizes.buttonHeight,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AuthColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AuthSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    AuthStrings.returnToLogin,
                    style: AuthTextStyles.buttonPrimary.copyWith(
                      color: AuthColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
