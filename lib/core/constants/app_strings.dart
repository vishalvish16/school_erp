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
  static const String menuTooltip = 'Menu';
  static const String notificationsTooltip = 'Notifications';

  // ── Tooltips (operation icons) ──────────────────────────────────────────────
  static const String tooltipAddNewSchool = 'Add new school';
  static const String tooltipViewDetails = 'View details';
  static const String tooltipEditSchool = 'Edit school';
  static const String tooltipSuspendSchool = 'Suspend school';
  static const String tooltipActivateSchool = 'Activate school';
  static const String tooltipRefresh = 'Refresh';
  static const String tooltipEditPlan = 'Edit plan';
  static const String tooltipDeletePlan = 'Delete plan';
  static const String tooltipDismissError = 'Dismiss error';
  static const String tooltipDeactivate = 'Deactivate';
  static const String tooltipActivate = 'Activate';
  static const String tooltipClose = 'Close';
  static const String tooltipRequirements = 'Requirements';
  static const String tooltipExtend = 'Extend';
  static const String tooltipViewHistory = 'View History';

  // ── Schools Management ─────────────────────────────────────────────────────
  static const String schoolsManagement = 'Schools Management';
  static const String addSchool = 'Add School';
  static const String suspendSchoolTitle = 'Suspend School';
  static String suspendSchoolConfirm(String name) =>
      'Are you sure you want to suspend $name?';
  static const String activateSchoolTitle = 'Activate School';
  static String activateSchoolConfirm(String name) =>
      'Are you sure you want to activate $name?';
  static const String cancel = 'Cancel';
  static const String suspend = 'Suspend';
  static const String searchBySchoolName = 'Search by school name...';
  static const String filterByCode = 'Filter by code...';
  static const String searchByNameOrCode = 'Search by name or code...';
  static const String allPlans = 'All Plans';
  static const String allStatus = 'All Status';
  static const String statusActive = 'Active';
  static const String statusSuspended = 'Suspended';
  static const String noSchoolsFound = 'No schools found';
  static String errorWithMessage(String msg) => 'Error: $msg';
  static const String tableCode = 'Code';
  static const String tableSchoolName = 'School Name';
  static const String tablePlan = 'Plan';
  static const String tableStatus = 'Status';
  static const String tableStudents = 'Students';
  static const String tableTeachers = 'Teachers';
  static const String tableExpDate = 'Exp. Date';
  static const String tableActions = 'Actions';
  static const String schoolDetails = 'School Details';
  static const String subscriptionInformation = 'Subscription Information';
  static const String subscriptionHistory = 'Subscription History';
  static String schoolCodeLabel(String code) => 'School Code: $code';
  static const String extend = 'Extend';
  static const String activate = 'Activate';
  static const String viewHistory = 'View History';
  static const String notAvailable = 'N/A';

  // ── Subscription Plans ─────────────────────────────────────────────────────
  static const String subscriptionPlans = 'Subscription Plans';
  static const String subscriptionPlansSubtitle =
      'Manage SaaS pricing and platform limits';
  static const String searchPlans = 'Search plans...';
  static const String createPlan = 'Create Plan';
  static const String noPlansFound = 'No plans found';
  static const String detailedComparison = 'Detailed Comparison';
  static const String planName = 'Plan Name';
  static const String monthly = 'Monthly';
  static const String yearly = 'Yearly';
  static const String students = 'Students';
  static const String teachers = 'Teachers';
  static const String branches = 'Branches';
  static const String activeSchools = 'Active Schools';
  static const String deletePlanTitle = 'Delete Plan';
  static String deletePlanConfirm(String planName) =>
      'Are you sure you want to delete "$planName"? This action cannot be undone.';
  static const String planDeletedSuccess = 'Plan deleted successfully';
  static const String failedToDeletePlan = 'Failed to delete plan';
  static const String edit = 'Edit';
  static const String perMonth = ' /mo';
  static const String assignSubscriptionPlan = 'Assign Subscription Plan';
  static const String choosePlan = 'Choose a Plan';
  static const String selectPlan = 'Select Plan';
  static const String billingCycle = 'Billing Cycle';
  static const String monthlyBilling = 'Monthly';
  static const String yearlyBilling = 'Yearly';
  static const String customDuration = 'Custom Duration (Optional)';
  static const String enterMonthsHint = 'Enter months (e.g. 6)';
  static const String months = 'Months';
  static const String assign = 'Assign';
  static const String planAssignedSuccess = 'Plan assigned successfully';
  static const String fullSubscriptionHistory = 'Full Subscription History';
  static const String tableBilling = 'Billing';
  static const String tableStartDate = 'Start Date';
  static const String tableEndDate = 'End Date';
  static const String tableCreatedAt = 'Created At';
  static String totalRecords(int count) => 'Total Records: $count';

  // ── Add/Edit School ────────────────────────────────────────────────────────
  static const String editSchool = 'Edit School';
  static const String addNewSchool = 'Add New School';
  static const String generalInformation = 'General Information';
  static const String schoolNameRequired = 'School Name *';
  static const String emailAddress = 'Email Address';
  static const String phoneNumber = 'Phone Number';
  static const String schoolCodeHint = 'School Code (Auto-generated if empty)';
  static const String required = 'Required';
  static const String addressDetails = 'Address Details';
  static const String streetAddress = 'Street Address';
  static const String city = 'City';
  static const String state = 'State';
  static const String country = 'Country';
  static const String subscriptionCapacity = 'Subscription & Capacity';
  static const String subscriptionStart = 'Subscription Start';
  static const String subscriptionEnd = 'Subscription End';
  static const String maxStudents = 'Max Students';
  static const String maxTeachers = 'Max Teachers';
  static const String statusLabel = 'Status';
  static const String saveSchool = 'Save School';
  static const String schoolSavedSuccess = 'School saved successfully!';
  static String errorSavingSchool(String e) => 'Error saving school: $e';
  static const String selectDate = 'Select Date';

  // ── Common ─────────────────────────────────────────────────────────────────
  static const String delete = 'Delete';
  static const String noRecordsFound = 'No records found';
}
