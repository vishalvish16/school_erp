// =============================================================================
// FILE: lib/core/constants/app_auth_constants.dart
// PURPOSE: Centralized constants for auth screens (login, forgot, reset)
// Labels, titles, colors, sizes, fonts, assets — no hardcoded values in UI
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Auth screen strings — labels, titles, hints, buttons
abstract final class AuthStrings {
  AuthStrings._();

  // ── Shared ─────────────────────────────────────────────────────────────────
  static const String protect = 'Protect';
  static const String track = 'Track';
  static const String automate = 'Automate';
  static const String login = 'Login';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String rememberMe = 'Remember me';
  static const String forgotPassword = 'Forgot Password?';
  static const String or = 'OR';
  static const String biometricEntry = 'Biometric Entry';
  static const String useFingerprint = 'Use Fingerprint';
  static const String useFace = 'Use Face';
  static const String useBiometric = 'Use Face or Fingerprint';

  // ── Feature points ─────────────────────────────────────────────────────────
  static const String featureAiShield = 'Advanced AI Shield Security';
  static const String featureMultiCampus = 'Unified Multi-Campus Control';
  static const String featureAnalytics = 'Real-time Predictive Analytics';
  static const String featureCompliance = 'Automated Compliance Engine';

  // ── Stats ──────────────────────────────────────────────────────────────────
  static const String statStudents = '1.4k+';
  static const String statStudentsLabel = 'Active Students';
  static const String statAttendance = '98%';
  static const String statAttendanceLabel = 'Attendance';
  static const String statIncidents = 'Zero';
  static const String statIncidentsLabel = 'Safety Incidents';

  // ── Forgot password ────────────────────────────────────────────────────────
  static const String recoverAccess = 'Recover Your Access';
  static const String recoverInstructions =
      'Enter your registered email address to receive secure recovery instructions.';
  static const String enterpriseEmail = 'Enterprise Email';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String sendRecoveryLink = 'Send Recovery Link';
  static const String backToLogin = 'Back to Workspace Login';
  static const String recoveryLinkSent = 'Recovery Link Sent!';
  static const String recoveryLinkMessage =
      'We have dispatched a secure recovery link to:\n';
  static const String recoveryLinkFooter =
      '\nPlease check your inbox and follow the instructions.';
  static const String returnToLogin = 'Return to Login';
  static const String recoveryFailed = 'Recovery failed. Please check your email.';

  // ── Reset password ──────────────────────────────────────────────────────────
  static const String secureCredentials = 'Secure Credentials Update';
  static const String secureCredentialsDesc =
      'Establish your new security key for workspace access.';
  static const String newSecurityKey = 'New Security Key';
  static const String authorizeSecurityKey = 'Authorize Security Key';
  static const String passwordRequired = 'Password is required';
  static const String passwordMinLength = 'Minimum 8 characters required';
  static const String keysDoNotMatch = 'Keys do not match';

  // Strong password rules (suggestion toolbox)
  static const String passwordRuleMinLength = 'At least 8 characters';
  static const String passwordRuleUppercase = 'One uppercase letter';
  static const String passwordRuleLowercase = 'One lowercase letter';
  static const String passwordRuleNumber = 'One number';
  static const String passwordRuleSpecial = 'One special character (!@#\$%^&* etc.)';
  static const String finalizeUpdate = 'Finalize Update';
  static const String cancelUpdate = 'Cancel Update';
  static const String passwordUpdated = 'Password updated successfully!';
  static const String resetFailed = 'Failed to reset password';
}

/// Auth screen colors — delegates to the master [AppColors] palette.
abstract final class AuthColors {
  AuthColors._();

  static const Color textPrimary = AppColors.neutral900;     // 0xFF0F172A
  static const Color textSecondary = AppColors.neutral600;   // 0xFF475569
  static const Color textMuted = AppColors.neutral500;       // 0xFF64748B
  static const Color textHint = AppColors.neutral400;        // 0xFF94A3B8
  static const Color textInput = AppColors.neutral800;       // 0xFF1E293B

  static const Color border = AppColors.neutral200;          // 0xFFE2E8F0
  static const Color primary = AppColors.secondary600;       // 0xFF2563EB
  /// Switch track when OFF — visible on glass background
  static const Color switchInactiveTrack = AppColors.neutral300; // 0xFFCBD5E1
  static const Color primaryDark = AppColors.secondary700;   // 0xFF1D4ED8
  static const Color accent = AppColors.secondary500;        // 0xFF3B82F6
  static const Color success = AppColors.success500;         // 0xFF10B981

  static Color overlayLight(double alpha) => Colors.white.withValues(alpha: alpha);
  static Color overlayDark(double alpha) => Colors.black.withValues(alpha: alpha);
}

/// Auth screen sizes — heights, widths, padding, radius.
/// Uses [AppSpacing] / [AppRadius] / [AppBreakpoints] tokens where they map
/// cleanly; auth-specific values that don't fit the 4px grid stay explicit.
abstract final class AuthSizes {
  AuthSizes._();

  // Breakpoints
  static const double breakpointMobile = 900;
  static const double breakpointLogin = 1000;

  // Layout
  static const double maxContentWidth = AppBreakpoints.contentMaxWidth; // 1200
  static const double cardWidthFixed = 450;
  static const double brandingGap = AppSpacing.xl6;       // 80
  static const double sectionGap = AppSpacing.xl2;        // 32
  static const double cardPadding = AppSpacing.xl3;       // 40
  static const double headerPaddingV = 20;
  static const double headerPaddingH = AppSpacing.xl;     // 24
  static const double scrollPadding = AppSpacing.xl;      // 24
  static const double taglineGap = AppSpacing.lg;         // 16
  static const double footerPaddingV = 20;
  static const double footerPaddingH = AppSpacing.xl;     // 24

  // Logo
  static const double logoHeightMobile = 100;
  static const double logoHeightWeb = 200;

  // Tagline (mobile)
  static const double taglineIconSize = 28;
  static const double taglineIconGap = AppSpacing.md;     // 12
  static const double taglineDotSize = AppSpacing.xs;     // 4
  static const double taglineDotPadding = AppSpacing.sm;  // 8

  // Footer
  static const double footerIconMobile = 36;
  static const double footerIconWeb = AppSpacing.xl4;     // 48
  static const double footerGapMobile = AppSpacing.xl2;   // 32
  static const double footerGapWeb = AppSpacing.xl4;      // 48
  static const double footerIconPadding = 2;
  static const double footerTextGap = AppSpacing.sm;      // 8

  // Glass panel
  static const double glassRadius = AppSpacing.xl2;       // 32
  static const double glassBorderWidth = 1.5;
  static const double glassBlur = AppSpacing.xs;          // 4
  static const double glassBlurStrong = AppSpacing.xl;    // 24
  static const double glassShadowBlur = AppSpacing.xl3;   // 40
  static const double glassShadowOffset = 10;

  // Branding panel
  static const double brandingPaddingMobile = 28;
  static const double brandingPaddingWeb = AppSpacing.xl4; // 48
  static const double featurePointGap = 20;
  static const double featurePointIconPadding = AppSpacing.xs; // 4
  static const double featurePointIconSize = 14;
  static const double featurePointTextGap = AppSpacing.lg; // 16

  // Form
  static const double formTitleSize = 28;
  static const double formFieldRadius = 14;
  static const double formFieldPaddingH = 20;
  static const double formFieldPaddingV = 18;
  static const double formFieldIconSize = 20;
  static const double formFieldShadowBlur = AppSpacing.sm; // 8
  static const double formFieldShadowOffset = 2;
  static const double formSpacingSmall = 20;
  static const double formSpacingMedium = AppSpacing.xl;   // 24
  static const double formSpacingLarge = AppSpacing.xl2;   // 32
  static const double formSpacingBackLink = 28;

  // Button
  static const double buttonHeight = 56;
  static const double buttonRadius = AppSpacing.lg;        // 16
  static const double buttonShadowBlur = AppSpacing.md;    // 12
  static const double buttonShadowOffset = 6;

  // Checkbox
  static const double checkboxSize = AppSpacing.xl;        // 24
  static const double checkboxRadius = AppSpacing.xs;      // 4
  static const double checkboxLabelGap = AppSpacing.sm;    // 8

  // Biometric
  static const double biometricIconSize = 22;
  static const double biometricPaddingV = AppSpacing.lg;   // 16
  static const double biometricDividerPadding = AppSpacing.lg; // 16

  // Success card (forgot/reset)
  static const double successIconSize = AppSpacing.xl6;    // 80
  static const double successSpacing = AppSpacing.xl2;     // 32
  static const double successBodySpacing = AppSpacing.lg;  // 16
  static const double successButtonSpacing = AppSpacing.xl4; // 48

  // Stats bubble
  static const double statBubblePaddingH = AppSpacing.lg;  // 16
  static const double statBubblePaddingV = AppSpacing.md;  // 12
  static const double statBubbleRadius = 20;
  static const double statBubbleGap = AppSpacing.md;       // 12

  // Loading overlay
  static const double loadingBlur = AppSpacing.xs;         // 4
  static const double loadingStrokeWidth = 3;
}

/// Auth typography — text styles
abstract final class AuthTextStyles {
  AuthTextStyles._();

  static const TextStyle loginTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AuthColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle tagline = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AuthColors.textSecondary,
  );

  static const TextStyle featurePoint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AuthColors.textPrimary,
  );

  static const TextStyle rememberMe = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AuthColors.textSecondary,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle forgotPassword = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle orDivider = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AuthColors.textHint,
  );

  static const TextStyle biometricLabel = TextStyle(
    fontWeight: FontWeight.w700,
  );

  static const TextStyle inputText = TextStyle(
    fontWeight: FontWeight.w600,
    color: AuthColors.textInput,
    fontSize: 15,
  );

  static const TextStyle inputHint = TextStyle(
    color: AuthColors.textHint,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle statValue = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 16,
  );

  static const TextStyle statLabel = TextStyle(
    color: Colors.white70,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  // Forgot / Reset
  static const TextStyle screenTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AuthColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle screenSubtitle = TextStyle(
    fontSize: 14,
    color: AuthColors.textSecondary,
    height: 1.6,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle successTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AuthColors.textPrimary,
  );

  static const TextStyle successBody = TextStyle(
    color: AuthColors.textSecondary,
    height: 1.6,
    fontSize: 15,
  );

  static const TextStyle successEmail = TextStyle(
    fontWeight: FontWeight.w800,
    color: AuthColors.textInput,
  );
}

/// Auth asset paths
abstract final class AuthAssets {
  AuthAssets._();

  static const String background = 'assets/images/auth_background.jpg';
  static const String logo = 'assets/images/logo2.png';
  static const String protect = 'assets/images/protect.png';
  static const String track = 'assets/images/track.png';
  static const String automate = 'assets/images/automate.png';
}
