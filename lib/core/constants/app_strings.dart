// =============================================================================
// FILE: lib/core/constants/app_strings.dart
// PURPOSE: Global, centralized string constants preventing hardcoded duplicates.
// =============================================================================

abstract class AppStrings {
  // ── General / Common ──────────────────────────────────────────────────────
  static const String errorPrefix = 'Error: ';
  static const String ok     = 'OK';
  static const String cancel = 'Cancel';
  static const String next   = 'Next';
  static const String submit = 'Submit';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String save = 'Save';
  static const String create = 'Create';
  static const String update = 'Update';
  static const String add = 'Add';
  static const String assign = 'Assign';
  static const String remove = 'Remove';
  static const String confirm = 'Confirm';
  static const String close = 'Close';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String back = 'Back';
  static const String apply = 'Apply';
  static const String activate = 'Activate';
  static const String deactivate = 'Deactivate';
  static const String suspend = 'Suspend';
  static const String extend = 'Extend';
  static const String export = 'Export';
  static const String view = 'View';
  static const String viewAll = 'View All';
  static const String viewAllArrow = 'View All →';
  static const String clearFilters = 'Clear filters';
  static const String noRecordsFound = 'No records found';
  static const String notAvailable   = 'N/A';
  static const String dash           = '—';
  static const String required       = 'Required';

  // ── Feedback — Loading states ───────────────────────────────────────────────
  static const String loadingLabel   = 'Please wait…';
  static const String savingLabel    = 'Saving…';
  static const String deletingLabel  = 'Deleting…';
  static const String uploadingLabel = 'Uploading…';
  static const String submittingLabel = 'Submitting…';

  // ── Feedback — Delete confirmation ─────────────────────────────────────────
  static const String deleteConfirmTitle = 'Confirm Delete';
  static String deleteConfirmMessage(String name) =>
      'Are you sure you want to delete "$name"? This action cannot be undone.';

  // ── Feedback — Generic success messages ────────────────────────────────────
  static const String savedSuccess   = 'Saved successfully';
  static const String createdSuccess = 'Created successfully';
  static const String updatedSuccess = 'Updated successfully';
  static const String deletedSuccess = 'Deleted successfully';

  // ── Feedback — Generic error messages ──────────────────────────────────────
  static const String genericError     = 'Something went wrong. Please try again.';
  static const String networkError     = 'Network error. Check your connection.';
  static const String sessionExpired   = 'Session expired. Please log in again.';
  static const String unauthorisedError = 'You do not have permission to perform this action.';
  static const String notFoundError    = 'Record not found.';
  static const String validationError  = 'Please fix the errors before submitting.';
  static const String signOut = 'Sign Out';
  static const String signOutQuestion = 'Sign Out?';
  static const String changePassword = 'Change Password';
  static const String currentPassword = 'Current Password';
  static const String newPassword = 'New Password';
  static const String confirmNewPassword = 'Confirm New Password';
  static const String confirmPassword = 'Confirm Password';
  static const String resetPassword = 'Reset Password';
  static const String passwordUpdatedSuccess = 'Password updated successfully';
  static const String clear = 'Clear';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String verified = 'Verified';
  static const String active = 'Active';
  static const String statusActive    = 'Active';
  static const String statusSuspended = 'Suspended';
  static const String statusPending   = 'Pending';
  static const String statusDraft     = 'Draft';
  static const String statusInactive  = 'Inactive';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String dashboard = 'Dashboard';
  static const String students = 'Students';
  static const String teachers = 'Teachers';
  static const String branches = 'Branches';
  static const String email = 'Email';
  static const String phone = 'Phone';
  static const String address = 'Address';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String remarks = 'Remarks';
  static const String description = 'Description';
  static String errorWithMessage(String msg) => 'Error: $msg';

  // ── Pagination ─────────────────────────────────────────────────────────────
  static String showingEntries(int start, int end, int total) =>
      'Showing $start to $end of $total entries';
  static const String show = 'Show';
  static const String entries = 'entries';

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
  static const String reportExported = 'Report exported';
  static String exportFailed(String e) => 'Export failed: $e';
  static const String needsAttention = 'Needs Attention';
  static String schoolsExpiring(int count) =>
      '$count schools expiring in 7 days';
  static String schoolsOverdue(int count) => '$count schools overdue';
  static const String renew = 'Renew';
  static const String resolve = 'Resolve';
  static const String recentlyAdded = 'Recently Added';
  static const String noSchoolsYet = 'No schools yet';
  static const String planDistribution = 'Plan Distribution';
  static const String noPlans = 'No plans';

  // ── Auth Screens ──────────────────────────────────────────────────────────
  static const String loginTitle = 'Vidyron One';
  static const String loginSubtitle = 'Protect • Track • Automate';
  static const String emailPlaceholder = 'Platform Email';
  static const String enterEmailError = 'Enter email';
  static const String enterEmailOrMobileError = 'Enter email or mobile number';
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
  static const String platformLoginBanner =
      'Platform login is at admin.vidyron.in';

  // ── Device Verification ────────────────────────────────────────────────────
  static const String verifyYourIdentity = 'Verify your identity';
  static const String codeExpired = 'Code expired';
  static String expiresIn(int minutes, String seconds) =>
      'Expires in $minutes:$seconds';
  static const String sending = 'Sending…';
  static const String resendCode = 'Resend code';
  static const String resend = 'Resend';
  static const String newCodeSentPhoneEmail =
      'New code sent to your phone and email';
  static const String newCodeSent = 'New code sent';
  static const String rememberDevice30Days =
      'Remember this device for 30 days';
  static const String skipStepNextTime =
      'Skip this step next time on this device';
  static const String verifyAndContinue = 'Verify & Continue';
  static const String reportSuspiciousLogin =
      'Not you? Report suspicious login';
  static const String tooManyAttemptsGoBack =
      'Too many attempts. Please go back and try again.';
  static const String verificationFailed = 'Verification failed';

  // ── 2FA ────────────────────────────────────────────────────────────────────
  static const String twoFactorAuth = 'Two-Factor Authentication';
  static const String enter6DigitCode =
      'Enter the 6-digit code from your authenticator app';
  static const String skipDeviceVerificationNextTime =
      'Skip device verification next time';
  static const String backToLogin = 'Back to login';
  static const String tooManyAttemptsLoginAgain =
      'Too many attempts. Please go back and log in again.';
  static const String enable2fa = 'Enable Two-Factor Authentication';
  static const String disable2fa = 'Disable Two-Factor Authentication';
  static const String scanQrCode =
      'Scan this QR code with your authenticator app';
  static const String enterKeyManually = 'Or enter this key manually:';
  static const String copiedToClipboard = 'Copied to clipboard';
  static const String enterCodeFromApp =
      'Enter the 6-digit code from your app:';
  static const String enter6DigitCodeSnack = 'Enter 6-digit code';
  static const String twoFaEnabled = '2FA enabled successfully';
  static const String twoFaDisabled = '2FA disabled';
  static const String enterPasswordToDisable2fa =
      'Enter your password to disable 2FA:';
  static const String password = 'Password';

  // ── Lock Screen ────────────────────────────────────────────────────────────
  static const String sessionLocked = 'Session Locked';
  static const String vidyronSecurityActive =
      'Vidyron One Security active. Enter key.';
  static const String securityKey = 'Security Key';
  static const String unlockSession = 'Unlock Session';
  static const String unlockWithFace = 'Unlock with Face';
  static const String unlockWithFingerprint = 'Unlock with Fingerprint';
  static const String unlockWithFaceOrFingerprint =
      'Unlock with Face or Fingerprint';
  static const String switchAccountLogout = 'Switch Account / Logout';
  static const String invalidSecurityKey =
      'Invalid security key. Please try again.';
  static const String biometricFailed = 'Biometric authentication failed.';

  // ── School Setup ──────────────────────────────────────────────────────────
  static const String welcomeToVidyron = 'Welcome to Vidyron';
  static const String findSchoolFirst = "Let's find your school first";
  static const String whoAreYou = 'Who are you?';
  static const String schoolStaff = 'School Staff';
  static const String schoolStaffSubtitle = 'Teacher, Admin, Driver, Clerk';
  static const String parent = 'Parent';
  static const String parentSubtitle = "Track your child's safety";
  static const String student = 'Student';
  static const String studentSubtitle = 'Access your school portal';
  static const String groupAdminOrSuperAdmin =
      'Are you a Group Admin or Super Admin?';
  static const String signInHere = 'Sign in here →';
  static const String searchYourSchool = 'Search your school';
  static const String typeSchoolNameOrCity = 'Type school name or city...';
  static const String noResults = 'No results?';
  static const String askSchoolAdmin =
      'Ask your school admin for the setup link';
  static const String couldNotConnect = 'Could not connect.';
  static const String checkConnectionTryAgain =
      'Check your connection and try again.';
  static const String searchFailed = 'Search failed. Try again.';
  static const String couldNotConnectNetwork =
      'Could not connect. Check your network.';

  // ── School Found Bottom Sheet ──────────────────────────────────────────────
  static const String weFoundYourSchool = 'We found your school! 🎉';
  static const String thisIsMySchool = 'This is my school';
  static const String wrongSchoolContactAdmin = 'Wrong school? Contact admin';
  static const String verifiedBadge = '✓ Verified';
  static const String user = 'User';

  // ── School Setup Phone ────────────────────────────────────────────────────
  static const String enterMobileNumber = 'Enter your mobile number';
  static const String tenDigitMobile = '10-digit mobile';
  static const String weFindSchoolAuto =
      "We'll find your school automatically";
  static const String continueButton = 'Continue';
  static const String countryCode = 'Country code';
  static const String indiaFlag = '🇮🇳';
  static const String indiaCode = '+91';
  static const String indiaFlagWithCode = '🇮🇳 +91';

  // ── Parent Login ──────────────────────────────────────────────────────────
  static const String mobileNumber = 'Mobile number';
  static const String findingSchool = 'Finding...';
  static const String findSchoolSendOtp = 'Find My School & Send OTP';
  static const String confirmAndSendOtp = 'Confirm & Send OTP';
  static const String wrongSchoolContactSchoolAdmin =
      'Wrong school? Contact your school admin';
  static const String verifyAndEnterVidyron = 'Verify & Enter Vidyron';

  // ── Staff Login ───────────────────────────────────────────────────────────
  static const String changeSchoolQuestion = 'Change School?';
  static const String changeSchoolMessage =
      'You will need to search for your school again.';
  static const String yesChange = 'Yes, Change';
  static const String selectSchoolAbove = 'Please select your school above';
  static const String passwordTab = 'Password';
  static const String otpTab = 'OTP';
  static const String qrScanTab = 'QR Scan';
  static const String emailMobileLabel = 'Email / Mobile';
  static const String emailMobileRequired = 'Email / Mobile *';
  static const String sendOtp = 'Send OTP';
  static const String autoDetectedRole =
      'Your role is auto-detected from your credentials';
  static const String autoDetectedFromNumber =
      'Role auto-detected from this number';
  static const String scanQrOnIdCard =
      'Scan the QR on your Vidyron ID card';
  static const String driversQrAutoAssigns =
      'Drivers: QR auto-assigns your vehicle';

  // ── School Admin Login ────────────────────────────────────────────────────
  static const String signingInAsSchoolAdmin =
      'Signing in as: School Admin / Principal';

  // ── Group Admin Login ─────────────────────────────────────────────────────
  static const String groupSlugOrId = 'Group slug or ID';
  static const String groupSlugHint =
      'e.g. dpsgroup (required for localhost)';
  static const String groupSlugRequired =
      'Group slug is required when not using subdomain';
  static const String otpLoginTagline =
      'OTP login — Enter mobile, send OTP';
  static const String contactPlatformAdminUnlock =
      'Contact your platform administrator to unlock the account in Super Admin → Groups.';
  static const String ensureAssignedGroupAdmin =
      'Ensure you are assigned as group admin in Super Admin → Groups.';

  // ── Returning User ────────────────────────────────────────────────────────
  static const String welcomeBack = 'Welcome back';
  static String continueToContext(String label) => 'Continue to $label';
  static const String signInDifferentUser = 'Sign in as different user';

  // ── Forgot Password ──────────────────────────────────────────────────────
  static const String forgotPassword = 'Forgot Password';
  static const String emailAddress = 'Email Address';
  static const String sendResetInstructions = 'Send Reset Instructions';
  static const String tooManyAttemptsWait =
      'Too many attempts. Try again in 60 minutes.';
  static const String goToLogin = 'Go to Login';
  static const String verificationCodeSent = 'Verification code sent';

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
  static const String openMenu = 'Open menu';
  static const String markAllRead = 'Mark all read';
  static const String viewAllNotifications = 'View all notifications';

  // ── Tooltips ──────────────────────────────────────────────────────────────
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
  static const String searchBySchoolName = 'Search by school name...';
  static const String filterByCode = 'Filter by code...';
  static const String searchByNameOrCode = 'Search by name, code, or city...';
  static const String searchSchools = 'Search schools...';
  static const String allPlans = 'All Plans';
  static const String allStatus = 'All Status';
  static const String noSchoolsFound = 'No schools found';
  static const String tableSrNo = 'Sr. No';
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
  static const String viewHistory = 'View History';
  static const String schoolCreated = 'School created';
  static const String schoolReactivated = 'School reactivated';
  static const String schoolsExported = 'Schools exported';
  static const String unsuspendSchoolQuestion = 'Unsuspend School?';
  static String unsuspendSchoolConfirm(String name) =>
      'Reactivate $name? Staff and students will regain access.';
  static const String unsuspend = 'Unsuspend';
  static const String manage = 'Manage';
  static const String assignPlan = 'Assign Plan';
  static const String copyUrl = 'Copy URL';
  static const String overdue = 'Overdue';
  static String loginUrlCopied(String url) => 'Login URL copied: $url';
  static const String status = 'Status';
  static const String plan = 'Plan';
  static const String country = 'Country';
  static const String state = 'State';
  static const String city = 'City';

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
  static const String activeSchools = 'Active Schools';
  static const String deletePlanTitle = 'Delete Plan';
  static String deletePlanConfirm(String planName) =>
      'Are you sure you want to delete "$planName"? This action cannot be undone.';
  static const String planDeletedSuccess = 'Plan deleted successfully';
  static const String failedToDeletePlan = 'Failed to delete plan';
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
  static const String planAssignedSuccess = 'Plan assigned successfully';
  static const String planAssigned = 'Plan assigned';
  static const String fullSubscriptionHistory = 'Full Subscription History';
  static const String tableBilling = 'Billing';
  static const String tableStartDate = 'Start Date';
  static const String tableEndDate = 'End Date';
  static const String tableCreatedAt = 'Created At';
  static String totalRecords(int count) => 'Total Records: $count';
  static const String deactivatePlanQuestion = 'Deactivate Plan?';
  static String deactivatePlanConfirm(int count, String name) =>
      '$count schools are on $name. Deactivating hides it from new subscriptions.';
  static const String deactivateAnyway = 'Deactivate Anyway';
  static const String planDeactivated = 'Plan deactivated';
  static const String planActivated = 'Plan activated';
  static const String planChange = 'Plan change';
  static const String standard = 'Standard';
  static const String planUpdatedSuccess = 'Plan updated successfully';
  static const String planCreatedSuccess = 'Plan created successfully';
  static const String failedToSavePlan = 'Failed to save plan';
  static const String editSubscriptionPlan = 'Edit Subscription Plan';
  static const String createNewPlan = 'Create New Plan';
  static const String planNameHint = 'e.g. Professional, Enterprise';
  static const String maxStudents = 'Max Students';
  static const String maxTeachers = 'Max Teachers';
  static const String maxBranches = 'Max Branches';
  static const String priceMonthly = 'Price Monthly (₹)';
  static const String priceYearly = 'Price Yearly (₹)';
  static const String isActive = 'Is Active';
  static const String inactivePlanHidden =
      'Inactive plans are hidden from new subscriptions';
  static const String saveAsDraft = 'Save as Draft';
  static const String selectPlanPrompt = 'Please select a plan';
  static const String nameRequired = 'Name is required';
  static const String validPriceRequired = 'Valid price is required';

  // ── Add/Edit School ────────────────────────────────────────────────────────
  static const String editSchool = 'Edit School';
  static const String addNewSchool = 'Add New School';
  static const String generalInformation = 'General Information';
  static const String schoolNameRequired = 'School Name *';
  static const String phoneNumber = 'Phone Number';
  static const String schoolCodeHint = 'School Code (Auto-generated if empty)';
  static const String addressDetails = 'Address Details';
  static const String streetAddress = 'Street Address';
  static const String subscriptionCapacity = 'Subscription & Capacity';
  static const String subscriptionStart = 'Subscription Start';
  static const String subscriptionEnd = 'Subscription End';
  static const String statusLabel = 'Status';
  static const String saveSchool = 'Save School';
  static const String schoolSavedSuccess = 'School saved successfully!';
  static String errorSavingSchool(String e) => 'Error saving school: $e';
  static const String selectDate = 'Select Date';

  // ── Add School Dialog ─────────────────────────────────────────────────────
  static const String group = 'Group';
  static const String standaloneNoGroup = 'Standalone (no group)';
  static const String addToExistingGroup = 'Add to existing group';
  static const String subdomainRequired = 'Subdomain *';
  static const String subdomainHint = 'e.g. dpssurat';
  static const String board = 'Board';
  static const String type = 'Type';
  static const String pinCode = 'PIN Code';
  static const String contactEmail = 'Contact Email';
  static const String estStudents = 'Est. Students';
  static const String duration = 'Duration';
  static const String studentLimit = 'Student Limit';
  static const String adminNameRequired = 'Admin Name *';
  static const String adminEmailRequired = 'Admin Email *';
  static const String adminMobileRequired = 'Admin Mobile * (10 digits)';
  static const String tempPasswordRequired = 'Temp Password * (min 8 chars)';
  static String schoolCreatedWithUrl(String url) =>
      'School created! Login URL: $url';

  // ── Export ──────────────────────────────────────────────────────────────────
  static const String exportTooltip = 'Download listed or selected records';
  static const String exportSuccess = 'Export completed';
  static const String exportFailedGeneric = 'Export failed';
  static const String billingReportExported = 'Billing report exported';

  // ── Super Admin Shell / Nav ───────────────────────────────────────────────
  static const String superAdmin = 'SUPER ADMIN';
  static const String schools = 'Schools';
  static const String groups = 'Groups';
  static const String plans = 'Plans';
  static const String billing = 'Billing';
  static const String featureFlags = 'Feature Flags';
  static const String hardware = 'Hardware';
  static const String adminUsers = 'Admin Users';
  static const String auditLogs = 'Audit Logs';
  static const String security = 'Security';
  static const String infraStatus = 'Infra Status';
  static const String more = 'More';

  // ── Super Admin Change Password ───────────────────────────────────────────
  static const String changePasswordDescription =
      'Update your security key. Use a strong password with uppercase, lowercase, numbers, and special characters.';
  static String fieldRequired(String label) => '$label required';
  static const String currentPasswordRequired =
      'Current password is required';

  // ── Super Admin Schools Screen ────────────────────────────────────────────
  static const String searchByNameAdmNo = 'Search by name or admission no...';
  static const String searchByNameEmpNo = 'Search by name or employee no...';

  // ── Super Admin Groups ────────────────────────────────────────────────────
  static const String createGroup = 'Create Group';
  static const String noSchoolGroups = 'No school groups';
  static const String deleteGroupQuestion = 'Delete Group?';
  static String deleteGroupConfirmWithSchools(String name, int schoolCount) =>
      '$name has $schoolCount school(s). Schools will become standalone. Are you sure you want to delete "$name"?';
  static String deleteGroupConfirm(String name) =>
      'Are you sure you want to delete "$name"?';
  static const String groupDeleted = 'Group deleted';
  static String toggleGroupConfirmTitle(String action) => '$action Group?';
  static String deactivateGroupConfirm(String name) =>
      'Deactivating "$name" will hide it from dashboards.';
  static String activateGroupConfirm(String name) =>
      'Activating "$name" will make it visible.';
  static String groupToggled(bool isActive) =>
      'Group ${isActive ? 'deactivated' : 'activated'}';
  static const String unlock = 'Unlock';
  static const String lock = 'Lock';
  static const String assignAdmin = 'Assign Admin';
  static const String groupAdminLocked =
      'Group admin account locked. They cannot log in for 30 minutes.';
  static const String accountUnlocked =
      'Account unlocked. Admin can log in now.';
  static const String fullName = 'Full Name';
  static const String mobileOptional = 'Mobile (optional)';
  static const String temporaryPassword = 'Temporary Password';
  static const String nameIsRequired = 'Name is required';
  static const String validEmailRequired = 'Valid email required';
  static const String min8Characters = 'Min 8 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String unlockAccountTooltip =
      'Use if account is locked due to too many failed login attempts';
  static const String unlockAccount = 'Unlock Account';
  static const String deactivateAdmin = 'Deactivate Admin';
  static const String groupAdminDeactivated = 'Group admin deactivated';
  static const String passwordResetSuccess = 'Password reset successfully';
  static const String groupAdminAssigned =
      'Group admin assigned successfully';
  static const String groupReport = 'Group Report';
  static const String groupSettings = 'Group Settings';
  static String copyLabel(String label) => 'Copy $label';
  static String labelCopied(String label, String value) =>
      '$label copied: $value';
  static const String groupCreated = 'Group created';
  static const String groupUpdated = 'Group updated';
  static const String groupName = 'Group Name';
  static const String groupNameHint = 'e.g. Delhi Public School';
  static const String slug = 'Slug';
  static const String slugHint = 'e.g. dpsgroup';

  // ── Super Admin Billing ───────────────────────────────────────────────────
  static const String searchBySchoolNameHint = 'Search by school name...';
  static const String expiring = 'Expiring';
  static const String editPlan = 'Edit Plan';
  static const String serverErrorOccurred = 'Server error occurred.';
  static const String resourceNotFound = 'Resource not found.';
  static const String accessDenied = 'Access denied.';
  static const String sessionExpiredBilling = 'Session expired. Please login again.';
  static const String connectionTimedOut = 'Connection timed out.';
  static const String couldNotConnectServer =
      'Could not connect to the server.';

  // ── Super Admin Features ──────────────────────────────────────────────────
  static const String globalFeatureFlags = 'Global Feature Flags';
  static const String featureFlagsSubtitle =
      'Platform-wide switches · Overrides per-school settings when OFF';
  static const String enableMaintenanceMode = 'Enable Maintenance Mode?';
  static const String maintenanceWarning =
      'All schools, parents, and staff will see a maintenance page.';
  static const String enableMaintenance = 'Enable Maintenance';
  static const String turnOffSmsGateway = 'Turn off SMS Gateway?';
  static const String smsGatewayWarning =
      'Turning off SMS will disable all OTP logins.';
  static const String turnOff = 'Turn Off';
  static String featureToggled(bool enabled, String key) =>
      '${enabled ? "Enabled" : "Disabled"} $key';
  static const String exportAsJson = 'Export as JSON';
  static const String exportAsCsv = 'Export as CSV';
  static const String exportState = 'Export State';
  static const String noPlatformFeatures = 'No platform features configured';
  static const String platformWideFeatures = 'Platform-Wide Features';
  static const String systemMaintenance = 'System & Maintenance';
  static const String featuresEnabledPerPlan =
      'Features enabled per plan — schools inherit unless toggled off globally.';

  // ── Super Admin Hardware ──────────────────────────────────────────────────
  static const String deviceResponded = 'Device responded';
  static const String deviceNotResponding = 'Device not responding';
  static const String schoolAdminNotified = 'School admin notified';
  static const String justNow = 'Just now';
  static String minutesAgo(int m) => '$m min ago';
  static String hoursAgo(int h) => '$h hrs ago';
  static const String trackDeviceSnack =
      'Track (opens school transport view)';
  static const String searchSchoolDeviceId = 'Search school, device ID...';
  static const String deviceIdRequired = 'Device ID is required';
  static const String deviceRegistered = 'Device registered';
  static const String deviceIdLabel = 'Device ID *';
  static const String deviceType = 'Device Type';
  static const String deviceTypeHint = 'rfid, gps, tablet, etc.';
  static const String location = 'Location';
  static const String register = 'Register';

  // ── Super Admin Security ──────────────────────────────────────────────────
  static const String activeThreats = 'Active Threats';
  static const String failedLogins24h = 'Failed Logins (24h)';
  static const String trustedDevices = 'Trusted Devices';
  static const String twoFaStatus = '2FA Status';
  static const String blockIpAddress = 'Block IP Address';
  static const String ipAddressRequired = 'IP Address *';
  static const String ipAddressHint = 'e.g. 192.168.1.1';
  static const String reason = 'Reason';
  static const String reasonHint = 'e.g. Suspicious activity';
  static const String block = 'Block';
  static const String enterIpAddress = 'Enter IP address';
  static const String ipBlocked = 'IP blocked';
  static const String revokeDeviceQuestion = 'Revoke Device?';
  static String revokeDeviceConfirm(String name) =>
      'Revoke $name? They will need to re-verify.';
  static const String revoke = 'Revoke';
  static const String deviceRevoked = 'Device revoked';
  static const String deviceIdNotFound = 'Device ID not found';
  static const String blockIp = 'Block IP';
  static const String blockAnIp = 'Block an IP address';
  static const String preventAccessIp = 'Prevent access from a specific IP';
  static const String recentSecurityEvents = 'Recent Security Events';
  static const String noRecentSecurityEvents = 'No recent security events';
  static const String noTrustedDevices = 'No trusted devices';
  static const String unknown = 'Unknown';
  static const String newPasswordLabel = 'New password (min 8 chars)';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String passwordMustMatch =
      'Password must match and be at least 8 characters';

  // ── Super Admin Audit Logs ────────────────────────────────────────────────
  static const String actor = 'Actor';
  static const String ip = 'IP';
  static const String entity = 'Entity';
  static const String auditType = 'Type';
  static const String auditDescription = 'Description';
  static const String date = 'Date';
  static const String oldData = 'Old data';
  static const String newData = 'New data';
  static const String noAuditLogs = 'No audit logs';
  static const String search = 'Search...';
  static const String from = 'From';
  static const String to = 'To';
  static const String clearDates = 'Clear dates';

  // ── Super Admin Admins ────────────────────────────────────────────────────
  static const String addAdmin = 'Add Admin';
  static const String noAdminUsers = 'No admin users';
  static const String resetPasswordQuestion = 'Reset Password?';
  static String resetPasswordConfirm(String name, String defaultPw) =>
      'Reset password for $name to $defaultPw?';
  static const String passwordResetToDefault = 'Password reset to Password@123';
  static const String cannotRemoveSelf = 'You cannot remove yourself';
  static const String removeAdminQuestion = 'Remove Admin?';
  static String removeAdminConfirm(String name) =>
      'Remove $name as Tech Admin?';
  static const String adminRemoved = 'Admin removed';
  static const String adminUpdated = 'Admin updated';
  static const String adminInvited = 'Admin invited';
  static const String nameAndEmailRequired = 'Name and email are required';
  static const String nameRequired2 = 'Name *';
  static const String emailRequired = 'Email *';
  static const String mobileLabel = 'Mobile';
  static const String mobileHint = 'e.g. +91 98765 43210';
  static const String tempPassword = 'Temp Password';
  static const String tempPasswordHint =
      'Optional — user will set password on first login';
  static const String role = 'Role';

  // ── Super Admin Notifications ─────────────────────────────────────────────
  static const String allNotificationsRead =
      'All notifications marked as read';
  static const String noNotifications = 'No notifications';

  // ── Super Admin Profile ───────────────────────────────────────────────────
  static const String signOutConfirmSuperAdmin =
      'You will be logged out of the Super Admin portal.';

  // ── Super Admin Dashboard ─────────────────────────────────────────────────
  static const String developmentInProgress = 'Development in progress';

  // ── Super Admin Infra ─────────────────────────────────────────────────────
  static const String infrastructureStatus = 'Infrastructure Status';
  static const String services = 'Services';
  static const String apiServer = 'API Server';
  static const String database = 'Database';
  static const String gpsWebSocket = 'GPS WebSocket';
  static const String smsGateway = 'SMS Gateway';
  static const String s3Storage = 'S3 Storage';
  static const String fcmPush = 'FCM Push';
  static const String thirtyDayUptime = '30-Day Uptime';
  static const String noInfraData = 'No infrastructure data available';

  // ── School Admin Shell / Nav ──────────────────────────────────────────────
  static const String schoolDashboard = 'School Dashboard';
  static const String classes = 'Classes';
  static const String attendance = 'Attendance';
  static const String fees = 'Fees';
  static const String timetable = 'Timetable';
  static const String notices = 'Notices';
  static const String nonTeachingStaff = 'Non-Teaching Staff';
  static const String ntAttendance = 'NT Attendance';
  static const String ntLeaves = 'NT Leaves';
  static const String staffRoles = 'Staff Roles';
  static const String signOutConfirmSchoolAdmin =
      'You will be logged out of the School Admin portal.';

  // ── School Admin Dashboard ────────────────────────────────────────────────
  static const String totalStudents = 'Total Students';
  static const String totalStaff = 'Total Staff';
  static const String activeNotices = 'Active Notices';
  static const String todaysAttendance = "Today's Attendance";
  static const String percentStudentsPresent = '% students present';
  static const String mark = 'Mark';
  static const String addStudent = 'Add Student';
  static const String collectFee = 'Collect Fee';
  static const String newNotice = 'New Notice';
  static const String quickActions = 'Quick Actions';
  static String sectionsCount(int count) => '$count sections';

  // ── School Admin Classes ──────────────────────────────────────────────────
  static const String addClass = 'Add Class';
  static const String noClassesFound = 'No classes found';
  static const String addFirstClass = 'Add First Class';
  static const String classNameHint = 'Class Name (e.g. Grade 1, LKG)';
  static const String className = 'Class Name';
  static const String sortOrder = 'Sort Order';
  static const String sortOrderHint = 'Sort Order (optional, numeric)';
  static const String editClass = 'Edit Class';
  static const String deleteClassQuestion = 'Delete Class?';
  static String addSectionTo(String name) => 'Add Section to $name';
  static const String sectionNameHint = 'Section Name (e.g. A, B, C)';
  static const String sectionCreated = 'Section created';
  static const String classCreated = 'Class created';
  static const String deleteSection = 'Delete Section?';
  static const String deleteSectionWarning =
      'This will remove the section and unassign its students.';
  static const String addSection = 'Add Section';
  static const String deleteClass = 'Delete Class';

  // ── School Admin Students ─────────────────────────────────────────────────
  static const String classLabel = 'Class';
  static const String section = 'Section';
  static const String selectClassFirst = 'Select a class first';
  static const String studentProfile = 'Student Profile';
  static const String personalInformation = 'Personal Information';
  static const String academicInformation = 'Academic Information';
  static const String parentGuardian = 'Parent / Guardian';
  static const String dateOfBirth = 'Date of Birth';
  static const String admissionDate = 'Admission Date';
  static const String gender = 'Gender';
  static const String academicYear = 'Academic Year';
  static const String studentAddedSuccess = 'Student added successfully';
  static const String studentUpdated = 'Student updated';
  static const String deleteStudentQuestion = 'Delete Student?';
  static const String studentDeleted = 'Student deleted';

  // ── School Admin Staff ────────────────────────────────────────────────────
  static const String addStaff = 'Add Staff';
  static const String designation = 'Designation';
  static const String staffProfile = 'Staff Profile';
  static const String editStaff = 'Edit Staff';
  static const String deactivateStaffTitle = 'Deactivate Staff';
  static const String reasonOptional = 'Reason (optional)';
  static const String staffMemberAdded = 'Staff member added';
  static const String staffMemberUpdated = 'Staff member updated';
  static const String deleteStaffQuestion = 'Delete Staff?';
  static String deleteStaffConfirm(String name, String empNo) =>
      'Remove $name ($empNo)?';
  static const String staffMemberDeleted = 'Staff member deleted';
  static const String qualifications = 'Qualifications';
  static const String documents = 'Documents';
  static const String subjectAssignments = 'Subject Assignments';
  static const String addDocument = 'Add Document';
  static const String documentTypeRequired = 'Document Type *';
  static const String documentNameRequired = 'Document Name *';
  static const String fileUrlRequired = 'File URL *';
  static const String fileUrlHint = 'https://...';
  static const String assignSubject = 'Assign Subject';
  static const String subjectRequired = 'Subject *';
  static const String classIdRequired = 'Class ID *';
  static const String classIdHint = 'Enter class UUID';
  static const String academicYearRequired = 'Academic Year *';
  static const String academicYearHint = '2025-2026';
  static const String removeAssignmentQuestion = 'Remove Assignment?';
  static const String deleteQualificationQuestion = 'Delete Qualification?';
  static const String deleteDocumentQuestion = 'Delete Document?';
  static const String markVerified = 'Mark Verified';
  static const String documentVerified = 'Document marked as verified';
  static const String period = 'Period';
  static const String leaveHistory = 'Leave History';
  static const String applyLeave = 'Apply Leave';
  static const String createLoginAccount = 'Create login account';
  static const String createLogin = 'Create Login';
  static const String empNoInUse = 'Employee number is already in use';
  static const String employeeNoRequired = 'Employee No. *';
  static const String employeeNoLabel = 'Employee No.';
  static const String autoFilledEditable = 'Auto-filled; editable';
  static const String autoSuggestedEditable = 'Auto-suggested; editable';
  static const String roleLabel = 'Role';
  static const String regenerateFromName = 'Regenerate from name';
  static const String genderRequired = 'Gender *';
  static const String bloodGroup = 'Blood Group';
  static const String notSpecified = 'Not specified';
  static const String employeeTypeRequired = 'Employee Type *';
  static const String joinDateRequired = 'Join Date *';
  static const String salaryGrade = 'Salary Grade';
  static const String yearsOfExperience = 'Years of Experience';
  static const String department = 'Department';
  static const String emergencyContactName = 'Name';
  static const String emergencyContactPhone = 'Phone';
  static const String passwordMin8Required = 'Password (min 8 characters) *';
  static const String passwordMin8Chars = 'Password (min 8 chars) *';
  static const String designationRequired = 'Designation *';
  static const String emailRequiredForLogin =
      'Email is required when creating login credentials';
  static const String highestQualification = 'Highest Qualification';
  static const String suggestEmployeeNo = 'Suggest employee number';
  static const String degreeRequired = 'Degree *';
  static const String institutionRequired = 'Institution *';
  static const String passingYear = 'Passing Year';
  static const String gradePercentage = 'Grade / Percentage';

  // ── School Admin Attendance ───────────────────────────────────────────────
  static const String attendanceSaved = 'Attendance saved successfully';
  static const String monthlyAttendanceReport = 'Monthly Attendance Report';
  static const String allClasses = 'All Classes';
  static const String allSections = 'All Sections';
  static const String totalDays = 'Total Days';
  static const String presentDays = 'Present Days';
  static const String absentDays = 'Absent Days';
  static const String noAttendanceData =
      'No attendance data for this month';
  static const String dailyBreakdown = 'Daily Breakdown';
  static const String dateColumn = 'Date';
  static const String present = 'Present';
  static const String absent = 'Absent';
  static const String late = 'Late';

  // ── School Admin Fees ─────────────────────────────────────────────────────
  static const String addFeeStructure = 'Add Fee Structure';
  static const String feeHeadHint = 'Fee Head (e.g. Tuition, Transport)';
  static const String feeHead = 'Fee Head';
  static const String feeHeadFieldHint = 'e.g. Tuition, Transport, Library';
  static const String amountLabel = 'Amount (₹)';
  static const String academicYearFieldHint = 'e.g. 2025-26';
  static const String academicYearDefault = '2025-26';
  static const String frequency = 'Frequency';
  static const String classOptional = 'Class (optional)';
  static const String feeStructureDeleted = 'Fee structure deleted';
  static const String failedToCreateFeeStructure =
      'Failed to create fee structure';
  static const String receiptNo = 'Receipt No.';
  static const String paymentMode = 'Payment Mode';
  static const String remarksOptional = 'Remarks (optional)';
  static const String selectStudent = 'Select Student';
  static const String searchStudentHint =
      'Search student by name or admission no...';
  static const String pleaseSelectStudent = 'Please select a student';
  static const String paymentRecordedSuccess =
      'Payment recorded successfully';
  static const String paymentDate = 'Payment Date';
  static const String cash = 'Cash';
  static const String upi = 'UPI';
  static const String bankTransfer = 'Bank Transfer';
  static const String cheque = 'Cheque';
  static String receiptGenerated(String no) => 'Receipt $no generated';
  static const String monthFilterHint = 'Month (e.g. 2025-06)';
  static const String filter = 'Filter';
  static const String dueDateLabel = 'Due Day';

  // ── School Admin Notices ──────────────────────────────────────────────────
  static const String searchNotices = 'Search notices...';
  static const String postFirstNotice = 'Post First Notice';
  static const String editNotice = 'Edit Notice';
  static const String title = 'Title';
  static const String content = 'Content';
  static const String targetAudience = 'Target Audience';
  static const String everyone = 'Everyone';
  static const String parents = 'Parents';
  static const String pinNotice = 'Pin Notice';
  static const String publish = 'Publish';
  static const String deleteNoticeQuestion = 'Delete Notice?';
  static String deleteNoticeConfirm(String title) =>
      'Remove "$title"?';
  static const String noticeDeleted = 'Notice deleted';

  // ── School Admin Profile ──────────────────────────────────────────────────
  static const String editPersonalInfo = 'Edit Personal Info';
  static const String editSchoolInfo = 'Edit School Info';
  static const String tapToChangePhoto = 'Tap to change photo';
  static const String schoolName = 'School Name';
  static String failedToPickImage(String e) => 'Failed to pick image: $e';
  static const String profileUpdated = 'Profile updated';

  // ── School Admin Settings ─────────────────────────────────────────────────
  static const String notificationPreferences = 'Notification Preferences';
  static const String notifPrefSubtitle =
      'Manage alerts and push notifications';
  static const String language = 'Language';
  static const String englishDefault = 'English (default)';
  static const String theme = 'Theme';
  static const String systemDefault = 'System default';
  static const String academicYearSetting = 'Academic Year';
  static const String currentAcademicYear = '2025–26 (current)';
  static const String dataExport = 'Data Export';
  static const String dataExportSubtitle = 'Export student and fee data';
  static const String additionalSettingsComingSoon =
      'Additional settings coming soon';
  static String settingComingSoon(String setting) =>
      '$setting — coming soon';

  // ── School Admin Leaves ───────────────────────────────────────────────────
  static const String noPendingLeaves = 'No pending leave requests';
  static const String reasonForRejection = 'Reason for rejection';
  static const String reasonForRejectionRequired = 'Reason for rejection *';
  static const String optionalRemarkStaff =
      'Optional remark for the staff member';
  static const String confirmRejection = 'Confirm Rejection';
  static const String statusColon = 'Status: ';
  static const String typeColon = 'Type: ';
  static const String all = 'All';
  static const String leaveOverview = 'Leave Overview';
  static const String total = 'Total';
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String cancelled = 'Cancelled';
  static const String byLeaveType = 'By Leave Type';
  static const String noLeaveRequestsFound = 'No leave requests found';
  static const String leaveTypeRequired = 'Leave Type *';
  static const String fromDateRequired = 'From Date *';
  static const String toDateRequired = 'To Date *';
  static const String reasonRequired = 'Reason *';
  static const String pleaseSelectDates = 'Please select both from and to dates';
  static const String leaveSubmitted = 'Leave request submitted successfully';
  static const String leaveApproved = 'Leave approved';
  static const String leaveRejected = 'Leave rejected';
  static const String failedToApprove = 'Failed to approve';
  static const String failedToReject = 'Failed to reject';
  static const String approveLeaveQuestion = 'Approve Leave?';
  static const String leaveWillBeApproved =
      'This leave request will be approved.';
  static const String rejectLeave = 'Reject Leave';

  // ── School Admin Non-Teaching Staff ───────────────────────────────────────
  static const String category = 'Category';
  static const String addCustomRole = 'Add Custom Role';
  static const String systemRoles = 'System Roles';
  static const String systemRolesSubtitle =
      'Built-in roles — read only, cannot be deleted';
  static const String customSchoolRoles = 'Custom School Roles';
  static const String customSchoolRolesSubtitle =
      'Roles specific to your school';
  static const String editRole = 'Edit Role';
  static const String roleCodeRequired = 'Role Code *';
  static const String roleCodeHint = 'e.g. SENIOR_CLERK';
  static const String displayNameRequired = 'Display Name *';
  static const String displayNameHint = 'e.g. Senior Clerk';
  static const String categoryRequired = 'Category *';
  static const String descriptionOptional = 'Description (optional)';
  static String toggleRoleTitle(String action) => '$action Role?';
  static const String cannotDelete = 'Cannot Delete';
  static const String roleInUse = 'This role is used by staff members.';
  static const String deleteRoleQuestion = 'Delete Role?';
  static const String statusUpdated = 'Status updated';
  static String deleteStaffNtConfirm(String name) =>
      'Remove $name? This cannot be undone.';
  static const String checkInTime = 'Check-in Time';
  static const String checkOutTime = 'Check-out Time';
  static const String hhMm = 'HH:MM';
  static String recordsCount(int count) => '$count records';
  static const String selectLabel = 'Select';
  static const String employeeType = 'Employee Type';
  static const String staffCanAccessSystem = 'Staff can access the system';
  static const String pleaseSelectRole = 'Please select a role';
  static const String anErrorOccurred = 'An error occurred';
  static const String qualificationRemoved =
      'This qualification will be removed.';
  static const String documentWillBeRemoved =
      'This document will be removed.';

  // ── School Admin Timetable ────────────────────────────────────────────────
  static const String selectClass = 'Select Class';
  static const String noTimetableEntries = 'No timetable entries yet';
  static const String time = 'Time';

  // ── School Admin Non-Teaching Attendance ───────────────────────────────────
  static const String noAttendanceRecords =
      'No attendance records this month';

  // ── Staff Shell / Nav ─────────────────────────────────────────────────────
  static const String signOutConfirmStaff =
      'You will be logged out of the Staff portal.';

  // ── Driver Module ─────────────────────────────────────────────────────────
  static const String driverDashboardTitle = 'Driver Dashboard';
  static const String driverProfileTitle = 'My Profile';
  static const String driverChangePasswordTitle = 'Change Password';
  static const String signOutConfirmDriver =
      'You will be logged out of the Driver portal.';
  static const String noVehicleAssigned = 'No vehicle assigned';
  static const String noRouteAssigned = 'No route assigned';
  static const String driverVehicle = 'Vehicle';
  static const String driverRoute = 'Route';
  static const String driverStudentCount = 'Students';
  static const String driverTripStatus = 'Trip Status';
  static const String tripStatusNotStarted = 'Not Started';
  static const String tripStatusInProgress = 'In Progress';
  static const String tripStatusCompleted = 'Completed';
  static const String driverEmployeeNo = 'Employee No.';
  static const String driverLicenseNumber = 'License Number';
  static const String driverLicenseExpiry = 'License Expiry';
  static const String driverEmergencyContact = 'Emergency Contact';
  static const String driverEditProfile = 'Edit Profile';
  static const String driverProfileDetails = 'Profile Details';
  static const String driverUpdatePassword = 'Update Password';
  static const String driverUpdatingPassword = 'Updating…';
  static const String driverEnterCurrentPassword = 'Enter current password';
  static const String driverEnterNewPassword = 'Enter new password';
  static const String driverConfirmNewPassword = 'Confirm new password';
  static const String driverPasswordsDoNotMatch = 'Passwords do not match';
  static const String driverPasswordMinLength = 'Password must be at least 8 characters';
  static const String driverLoginTitle = 'Driver Login';

  // ── Parent Portal Module ──────────────────────────────────────────────────
  static const String signOutConfirmParent =
      'You will be logged out of the Parent portal.';
  static const String parentDashboardTitle = 'Parent Dashboard';
  static const String parentDashboardSubtitle = 'Overview of your children and school updates';
  static const String parentProfileTitle = 'My Profile';
  static const String parentProfileSubtitle = 'View and edit your profile';
  static const String myChildren = 'My Children';
  static const String myChildrenSubtitle = 'View your linked children';
  static const String parentNoticesTitle = 'Notices';
  static const String parentNoticesSubtitle = 'School notices and announcements';
  static const String noChildrenLinked = 'No children linked';
  static const String noChildrenLinkedHint = 'Contact your school admin to link your children.';
  static const String noNotices = 'No notices';
  static const String noNoticesHint = 'No school notices at the moment.';
  static const String childDetails = 'Child Details';
  static const String childAttendance = 'Attendance';
  static const String childFees = 'Fees';
  static const String viewAttendance = 'View Attendance';
  static const String viewFees = 'View Fees';
  static const String attendanceThisMonth = 'Attendance this month';
  static const String noAttendanceThisMonth = 'No attendance recorded this month';
  static const String feeStructure = 'Fee Structure';
  static const String feePayments = 'Fee Payments';
  static const String noFeePayments = 'No fee payments recorded';
  static const String noFeeStructure = 'No fee structure';
  static const String viewFeesPerChild = 'View fees per child';
  static const String recentNotices = 'Recent Notices';
  static const String childrenCount = 'Children';
  static const String presentCount = 'Present';
  static const String absentCount = 'Absent';
  static const String parentLoginSuccess = 'Welcome!';
  static const String parentLoginFailed = 'Login failed';
  static const String parentResolveFailed = 'Could not find school for this number';
  static const String parentOtpFailed = 'Invalid OTP. Please try again.';
  static const String signingInto = 'Signing into';
  static String otpSentTo(String masked) => 'OTP sent to $masked';
  static const String mustBeRegisteredWithSchool = 'Must be registered with your child\'s school';
  static const String parentRelationLabel = 'Relation';
  static const String parentSchoolLabel = 'School';
  static const String parentColName = 'Name';
  static const String parentColClass = 'Class';
  static const String parentColAdmNo = 'Adm. No.';

  // ── Staff Dashboard ───────────────────────────────────────────────────────
  static String paymentsCount(int count) => '$count payments';
  static const String couldNotLoadDashboard = 'Could not load dashboard';

  // ── Staff Notices ─────────────────────────────────────────────────────────
  static const String notice = 'Notice';
  static const String pinnedNotice = 'Pinned Notice';

  // ── Staff My Leaves ───────────────────────────────────────────────────────
  static const String cancelLeaveQuestion = 'Cancel Leave?';
  static const String cancelLeave = 'Cancel Leave';
  static const String no = 'No';
  static const String leaveCancelled = 'Leave cancelled';
  static String leaveUsed(int taken, int total) => '$taken / $total used';

  // ── Staff Apply Leave ─────────────────────────────────────────────────────
  static const String applyForLeave = 'Apply for Leave';
  static const String leaveBalance = 'Leave Balance';
  static const String submitApplication = 'Submit Application';
  static const String toDateAfterFrom =
      'To date must be on or after from date';
  static const String leaveApplicationSubmitted =
      'Leave application submitted';

  // ── Staff Fees ────────────────────────────────────────────────────────────
  static const String studentColumn = 'Student';

  // ── Staff Profile ─────────────────────────────────────────────────────────
  static const String profileDetails = 'Profile Details';
  static const String editProfile = 'Edit Profile';

  // ── Staff Student Detail ──────────────────────────────────────────────────
  static const String personalInfo = 'Personal Info';
  static const String paymentHistory = 'Payment History';
  static const String noPaymentsRecorded = 'No payments recorded';

  // ── Staff Payslip ─────────────────────────────────────────────────────────
  static const String monthlySalarySlip = 'Monthly Salary Slip';
  static const String preview = 'Preview';

  // ── Group Admin Shell / Nav ───────────────────────────────────────────────
  static const String analytics = 'Analytics';
  static const String reports = 'Reports';
  static const String alerts = 'Alerts';
  static const String signOutConfirmGroupAdmin =
      'You will be logged out of the Group Admin portal.';

  // ── Group Admin Dashboard ─────────────────────────────────────────────────
  static String activeSchoolsCount(int count) => '$count active';
  static const String reviewSchools =
      'Review these schools to avoid service disruption.';
  static const String viewSchools = 'View Schools';
  static const String compareAllCampuses = 'Compare all campuses';
  static const String attendanceFinanceMore = 'Attendance, Finance & more';

  // ── Group Admin Analytics ─────────────────────────────────────────────────
  static const String searchByNameCodeCity =
      'Search by name, code or city...';
  static const String exportComingSoon = 'Export coming soon';
  static const String couldNotLoadAnalytics = 'Could not load analytics';

  // ── Group Admin Notices ───────────────────────────────────────────────────
  static const String noNoticesYet = 'No Notices Yet';
  static const String createFirstNotice = 'Create First Notice';
  static const String titleRequired = 'Title *';
  static const String messageRequired = 'Message *';
  static const String allRoles = 'All roles';
  static const String pinThisNotice = 'Pin this notice';
  static const String pinnedNoticesTop = 'Pinned notices appear at the top';
  static const String couldNotLoadNotices = 'Could not load notices';
  static String failedToDelete(String e) => 'Failed to delete: $e';

  // ── Group Admin Alerts ────────────────────────────────────────────────────
  static const String newAlert = 'New Alert';
  static const String couldNotLoadAlerts = 'Could not load alert rules';
  static const String deleteAlertRuleQuestion = 'Delete Alert Rule?';
  static const String alertRuleDeleteWarning =
      'This alert rule will be permanently deleted.';
  static const String noAlertRules = 'No Alert Rules';
  static const String createFirstAlert = 'Create First Alert';
  static const String ruleNameRequired = 'Rule Name *';
  static const String ruleNameHint = 'e.g., Low Attendance Warning';
  static const String metric = 'Metric';
  static const String condition = 'Condition';
  static const String thresholdPercent = 'Threshold (%)';
  static const String notifyViaEmail = 'Notify via Email';
  static const String notifyViaSms = 'Notify via SMS';

  // ── Group Admin Schools ───────────────────────────────────────────────────
  static const String sortBy = 'Sort by';
  static const String contactInformation = 'Contact Information';
  static const String academics = 'Academics';
  static const String users = 'Users';
  static const String schoolAdministrator = 'School Administrator';
  static const String subscription = 'Subscription';

  // ── Group Admin Edit Profile ──────────────────────────────────────────────
  static const String enterValidPhone = 'Enter a valid phone number';
  static const String verifyEmailPhoneFirst =
      'Please verify your email/phone with OTP first';
  static const String saveChanges = 'Save Changes';

  // ── Group Admin Reports ───────────────────────────────────────────────────
  static const String transportNotActivated =
      'Transport module not yet activated';
  static const String hrNotActivated = 'HR module not yet activated';

  // ── Group Admin Forgot Password ───────────────────────────────────────────
  // (reuses forgotPassword, emailAddress, sendResetInstructions, backToLogin)

  // ── Group Admin Students ──────────────────────────────────────────────────
  static const String couldNotLoadStudents = 'Could not load student data';

  // ── Teacher Shell / Nav ───────────────────────────────────────────────────
  static const String signOutConfirmTeacher =
      'You will be logged out of the Teacher portal.';

  // ── Teacher Dashboard ─────────────────────────────────────────────────────
  static String homeworkDueThisWeek(int count) => '$count due this week';
  static const String takeAction = 'Take Action';

  // ── Teacher Attendance ────────────────────────────────────────────────────
  static const String selectSection = 'Select Section';
  static const String dateLabel = 'Date';
  static const String selectSectionToMark =
      'Select a section to mark attendance';
  static const String locked = 'Locked';
  static const String markAllPresent = 'Mark All Present';
  static const String noStudentsFound = 'No students found';
  static const String saveAttendance = 'Save Attendance';
  static const String remarksOptionalHint = 'Remarks (optional)';
  static const String pLabel = 'P';
  static const String aLabel = 'A';
  static const String lLabel = 'L';
  static const String hLabel = 'H';

  // ── Teacher Attendance Report ─────────────────────────────────────────────
  static const String selectSectionToView =
      'Select a section to view report';
  static const String dateRange = 'Date Range';
  static const String workingDays = 'Working Days';
  static const String averageAttendance = 'Average Attendance';
  static const String noDataAvailable = 'No data available';
  static const String rollColumn = 'Roll';
  static const String nameColumn = 'Name';
  static const String percentColumn = '%';

  // ── Teacher Homework ──────────────────────────────────────────────────────
  static const String newHomework = 'New Homework';
  static const String noHomeworkFound = 'No homework found';
  static const String classSectionRequired = 'Class - Section *';
  static const String subjectLabel = 'Subject *';
  static const String titleRequired2 = 'Title *';
  static const String dueDateRequired = 'Due Date *';
  static const String pleaseSelectClassSectionSubject =
      'Please select class, section and subject';
  static const String homeworkDescription = 'Description';
  static const String attachments = 'Attachments';
  static const String markedAsReviewed = 'Marked as Reviewed';
  static const String markAsReviewed = 'Mark as Reviewed';
  static const String deleteHomeworkQuestion = 'Delete Homework?';

  // ── Teacher Diary ─────────────────────────────────────────────────────────
  static const String newEntry = 'New Entry';
  static const String noDiaryEntries = 'No diary entries found';
  static const String addFirstEntry = 'Add First Entry';
  static const String entryDeleted = 'Entry deleted';
  static const String deleteEntryQuestion = 'Delete Entry?';
  static const String deleteEntryConfirm =
      'Are you sure you want to delete this diary entry?';
  static const String diaryDateRequired = 'Date *';
  static const String topicCoveredRequired = 'Topic Covered *';
  static const String pageFrom = 'Page From';
  static const String pageTo = 'Page To';
  static const String homeworkGiven = 'Homework Given';

  // ── Teacher Profile ───────────────────────────────────────────────────────
  static const String contactAndDetails = 'Contact & Details';
  static const String noAssignments = 'No assignments';
  static const String school = 'School';

  // ── Widgets / Dialogs ─────────────────────────────────────────────────────
  static const String overdueResolved = 'Overdue resolved';
  static const String resolveOverdue = 'Resolve Overdue';
  static String daysOverdue(int days) => '$days days overdue';
  static const String markAsPaid = 'Mark as Paid';
  static const String markAsPaidSubtitle =
      'Payment received, extend subscription';
  static const String gracePeriod = 'Grace Period';
  static const String gracePeriodSubtitle = 'Give 7 days extension';
  static const String terminate = 'Terminate';
  static const String terminateSubtitle = 'Deactivate school';
  static const String paymentReference = 'Payment reference';
  static const String confirmResolution = 'Confirm Resolution';

  // ── Assign School Admin Dialog ────────────────────────────────────────────
  static const String assignSchoolAdmin = 'Assign School Admin';
  static const String adminNameIsRequired = 'Admin name is required';
  static const String adminEmailIsRequired = 'Admin email is required';
  static const String invalidEmailFormat = 'Invalid email format';
  static const String mobileMust10Digits = 'Mobile must be 10 digits';
  static const String passwordMin8 =
      'Password must be at least 8 characters';
  static const String adminAssignedSuccess = 'Admin assigned successfully';

  // ── Add School to Group Dialog ────────────────────────────────────────────
  static const String pleaseSelectSchool = 'Please select a school';
  static const String schoolAddedToGroup = 'School added to group';
  static const String noStandaloneSchools =
      'No standalone schools available to add.';

  // ── School Detail Dialog ──────────────────────────────────────────────────
  static const String schoolUpdated = 'School updated';
  static const String schoolSuspended = 'School suspended';
  static const String planUpdated = 'Plan updated';
  static String featureToggleMsg(String key, bool value) =>
      '$key ${value ? 'enabled' : 'disabled'}';
  static String urlCopied(String url) => 'URL copied: $url';
  static const String subdomainAlphanumeric =
      'Subdomain: alphanumeric and hyphens only';
  static const String subdomainTaken = 'Subdomain already taken';
  static const String changeSubdomainQuestion = 'Change Subdomain?';
  static const String change = 'Change';
  static const String subdomainUpdated = 'Subdomain updated';
  static const String passwordResetAdminNotified =
      'Password reset. Admin will be notified.';
  static const String basicInformation = 'Basic Information';
  static const String contact = 'Contact';
  static const String suspendSchool = 'Suspend School';
  static const String renewalDate = 'Renewal date';
  static const String estimatedMonthlyBill = 'Estimated monthly bill';
  static const String featureToggles = 'Feature Toggles';
  static const String noAdminAssigned = 'No admin assigned';
  static const String primaryAdmin = 'Primary Admin';
  static const String deactivateAdminQuestion = 'Deactivate Admin?';
  static const String adminLoseAccess =
      'This admin will lose access to the school.';
  static const String subdomain = 'Subdomain';
  static const String subdomainFieldHint = 'e.g. greenvalley';
  static const String loginUrl = 'Login URL';
  static const String copy = 'Copy';
  static const String changeSubdomain = 'Change Subdomain';
  static const String subscriptionDetails = 'Subscription Details';
  static const String selectPlanSection = 'Select Plan';

  // ── Searchable Dropdown ───────────────────────────────────────────────────
  static const String typeToSearch = 'Type to search...';
  static const String selectHint = 'Select';

  // ── School Identity Banner ────────────────────────────────────────────────
  // (reuses change)

  // ── Sidebar Menu ──────────────────────────────────────────────────────────
  static const String platform = 'Platform';
  static const String administration = 'Administration';
  static const String roles = 'Roles';
  static const String modules = 'Modules';
  static const String financials = 'Financials';
  static const String subscriptions = 'Subscriptions';
  static const String revenue = 'Revenue';
  static const String system = 'System';
  static const String systemHealth = 'System Health';

  // ── Extend Subscription ───────────────────────────────────────────────────
  static const String extendSubscription = 'Extend Subscription';
  static const String enterMonthsToExtend =
      'Enter number of months to extend:';

  // ── Assign Plan Widget Dialog ─────────────────────────────────────────────
  static String currentPlan(String name) => 'Current: $name';
  static String pricePerMonth(String price) => '₹$price/mo';
  static const String effectiveDate = 'Effective date';

  // ── Common Search ─────────────────────────────────────────────────────────
  static const String searchHint = 'Search…';

  // ── Student Portal ───────────────────────────────────────────────────────
  static const String studentDashboardTitle = 'Dashboard';
  static const String studentProfileTitle = 'Profile';
  static const String studentAttendanceTitle = 'Attendance';
  static const String studentFeesTitle = 'Fees';
  static const String studentTimetableTitle = 'Timetable';
  static const String studentNoticesTitle = 'Notices';
  static const String studentDocumentsTitle = 'Documents';
  static const String studentChangePasswordTitle = 'Change Password';
  static const String signOutConfirmStudent =
      'You will be logged out of the Student portal.';
  static const String couldNotLoadStudentDashboard =
      'Could not load dashboard';
  static const String noNoticesAvailable = 'No notices available';
  static const String noDocumentsAvailable = 'No documents available';
  static const String noFeeDues = 'No fee dues';
  static const String noPaymentsYet = 'No payments yet';
  static const String noTimetableSlots = 'No timetable slots';
  static const String presentDaysThisMonth = 'Present this month';
  static const String totalFeePaidThisYear = 'Fee paid this year';
  static const String upcomingDues = 'Upcoming dues';
  static const String todayTimetable = 'Today\'s timetable';
  static const String feeDues = 'Fee Dues';
  static const String selectMonth = 'Select month';
  static const String halfDay = 'Half Day';
  static const String admissionNo = 'Admission No.';
  static const String classSection = 'Class - Section';
  static const String rollNo = 'Roll No.';
  static const String parentContact = 'Parent Contact';
  static const String parentName = 'Parent Name';
  static const String account = 'ACCOUNT';
  static const String enterCurrentPassword = 'Enter current password';
  static const String enterNewPassword = 'Enter new password';
  static const String updatingPassword = 'Updating...';
  static const String updatePassword = 'Update Password';
  static const String changePasswordSubtitle =
      'Update your account password. Use a strong password with uppercase, lowercase, numbers, and special characters.';
  static const String viewReceipt = 'View Receipt';
  static const String openDocument = 'Open';
}
