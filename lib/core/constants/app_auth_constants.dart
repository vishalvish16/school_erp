// =============================================================================
// FILE: lib/core/constants/app_auth_constants.dart
// PURPOSE: Centralized constants for auth screens (login, forgot, reset)
// Labels, titles, colors, sizes, fonts, assets — no hardcoded values in UI
// =============================================================================

import 'package:flutter/material.dart';

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

/// Auth screen colors
abstract final class AuthColors {
  AuthColors._();

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textInput = Color(0xFF1E293B);

  static const Color border = Color(0xFFE2E8F0);
  static const Color primary = Color(0xFF2563EB);
  /// Switch track when OFF — visible on glass background
  static const Color switchInactiveTrack = Color(0xFFCBD5E1);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);

  static Color overlayLight(double alpha) => Colors.white.withValues(alpha: alpha);
  static Color overlayDark(double alpha) => Colors.black.withValues(alpha: alpha);
}

/// Auth screen sizes — heights, widths, padding, radius
abstract final class AuthSizes {
  AuthSizes._();

  // Breakpoints
  static const double breakpointMobile = 900;
  static const double breakpointLogin = 1000;

  // Layout
  static const double maxContentWidth = 1200;
  static const double cardWidthFixed = 450;
  static const double brandingGap = 80;
  static const double sectionGap = 32;
  static const double cardPadding = 40;
  static const double headerPaddingV = 20;
  static const double headerPaddingH = 24;
  static const double scrollPadding = 24;
  static const double taglineGap = 16;
  static const double footerPaddingV = 20;
  static const double footerPaddingH = 24;

  // Logo
  static const double logoHeightMobile = 100;
  static const double logoHeightWeb = 200;

  // Tagline (mobile)
  static const double taglineIconSize = 28;
  static const double taglineIconGap = 12;
  static const double taglineDotSize = 4;
  static const double taglineDotPadding = 8;

  // Footer
  static const double footerIconMobile = 36;
  static const double footerIconWeb = 48;
  static const double footerGapMobile = 32;
  static const double footerGapWeb = 48;
  static const double footerIconPadding = 2;
  static const double footerTextGap = 8;

  // Glass panel
  static const double glassRadius = 32;
  static const double glassBorderWidth = 1.5;
  static const double glassBlur = 4;
  static const double glassBlurStrong = 24;
  static const double glassShadowBlur = 40;
  static const double glassShadowOffset = 10;

  // Branding panel
  static const double brandingPaddingMobile = 28;
  static const double brandingPaddingWeb = 48;
  static const double featurePointGap = 20;
  static const double featurePointIconPadding = 4;
  static const double featurePointIconSize = 14;
  static const double featurePointTextGap = 16;

  // Form
  static const double formTitleSize = 28;
  static const double formFieldRadius = 14;
  static const double formFieldPaddingH = 20;
  static const double formFieldPaddingV = 18;
  static const double formFieldIconSize = 20;
  static const double formFieldShadowBlur = 8;
  static const double formFieldShadowOffset = 2;
  static const double formSpacingSmall = 20;
  static const double formSpacingMedium = 24;
  static const double formSpacingLarge = 32;
  static const double formSpacingBackLink = 28;

  // Button
  static const double buttonHeight = 56;
  static const double buttonRadius = 16;
  static const double buttonShadowBlur = 12;
  static const double buttonShadowOffset = 6;

  // Checkbox
  static const double checkboxSize = 24;
  static const double checkboxRadius = 4;
  static const double checkboxLabelGap = 8;

  // Biometric
  static const double biometricIconSize = 22;
  static const double biometricPaddingV = 16;
  static const double biometricDividerPadding = 16;

  // Success card (forgot/reset)
  static const double successIconSize = 80;
  static const double successSpacing = 32;
  static const double successBodySpacing = 16;
  static const double successButtonSpacing = 48;

  // Stats bubble
  static const double statBubblePaddingH = 16;
  static const double statBubblePaddingV = 12;
  static const double statBubbleRadius = 20;
  static const double statBubbleGap = 12;

  // Loading overlay
  static const double loadingBlur = 4;
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

  static const String background = 'assets/images/auth_background.jpeg';
  static const String logo = 'assets/images/logo2.png';
  static const String protect = 'assets/images/protect.png';
  static const String track = 'assets/images/track.png';
  static const String automate = 'assets/images/automate.png';
}
