// =============================================================================
// FILE: lib/core/constants/app_strings.dart
// PURPOSE: Global, centralized string constants preventing hardcoded duplicates.
// =============================================================================

abstract class AppStrings {
  // ── General / Fallback ─────────────────────────────────────────────────────
  static const String errorPrefix = 'Error: ';

  // ── Dashboard Screen ───────────────────────────────────────────────────────
  static const String dashboardTitle = 'Super Admin Dashboard';
  static const String dashboardSubtitle =
      'Platform metrics and high-level insights across all tenants.';
  static const String exportReport = 'Export Report';
  static const String totalSchoolsCard = 'Total Schools';
  static const String activeSchoolsCard = 'Active Schools';
  static const String monthlyRevenueCard = 'Monthly Revenue';
  static const String expiringSoonCard = 'Expiring Soon';
  static const String recentTenantActivity = 'Recent Tenant Activity';

  // ── Auth Screens ──────────────────────────────────────────────────────────
  static const String loginTitle = 'Vidyron One';
  static const String loginSubtitle = 'Protect • Track • Automate';
  static const String emailPlaceholder = 'Platform Email';
  static const String enterEmailError = 'Enter email';
  static const String passwordPlaceholder = 'Security Key';
  static const String enterPasswordError = 'Enter password';
  static const String forgotPasswordAction = 'Forgot Security Key?';
  static const String signInButton = 'Explore Command Center';
  static const String loginSuccess = 'Access Granted';
  static const String loginFailed = 'Login failed';
  static const String demoAccountInfo =
      'Demo Account:\nvishal.vish16@gmail.com\npassword123';
  static const String footerCopyright =
      '© 2026 Vidyron One Infrastructure • v1.0.0';

  // ── Topbar / Nav ───────────────────────────────────────────────────────────
  static const String searchPlatformTooltip = 'Search across platform...';
  static const String exportReportTooltip = 'Download PDF Summary Report';
  static const String accountProfile = 'My Profile';
  static const String accountSettings = 'Account Settings';
  static const String accountLogout = 'Logout';
  static const String roleSuperAdmin = 'Super Admin';
  static const String rolePlatformOwner = 'Platform Owner';
}
