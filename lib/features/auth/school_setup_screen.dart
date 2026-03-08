// =============================================================================
// FILE: lib/features/auth/school_setup_screen.dart
// PURPOSE: First-time school setup for mobile — staff search or parent/student phone
// Shown ONCE on first install or after "Change School"
//
// USER EXPERIENCE:
//   FIRST INSTALL — STAFF:
//     Open app → SchoolSetupScreen → tap "School Staff"
//     → Type "Delhi Public" → see results → tap school
//     → Saved forever → StaffLoginScreen loads
//     → Login once → dashboard
//     → Next day: open app → straight to dashboard (session valid)
//     → After 30 days: open app → ReturningUserScreen → one tap → in
//
//   FIRST INSTALL — PARENT:
//     Open app → SchoolSetupScreen → tap "Parent"
//     → Enter mobile → school found → confirm
//     → OTP sent → verify → dashboard
//     → Next time: open app → phone pre-filled → OTP → in
//     → After 30 days: re-enter OTP once
//
//   CHANGE SCHOOL (staff transfers to new school):
//     Settings → Change School → confirm
//     → SchoolSetupScreen → search new school
//     → Login with new credentials
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/services/local_storage_service.dart';
import '../../models/school_identity.dart';
import 'auth_screen_layout.dart';
import 'school_setup_search_widget.dart';
import 'school_setup_phone_widget.dart' show SchoolSetupPhoneWidget, PhoneResolveResult;
import 'school_found_bottom_sheet.dart';

/// Role selection: staff (search), parent, student (phone)
enum _SetupRole { staff, parent, student }

class SchoolSetupScreen extends StatefulWidget {
  const SchoolSetupScreen({super.key});

  @override
  State<SchoolSetupScreen> createState() => _SchoolSetupScreenState();
}

class _SchoolSetupScreenState extends State<SchoolSetupScreen> {
  _SetupRole? _selectedRole;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AuthSizes.breakpointLogin;
    return AuthScreenLayout(
      loading: _isLoading,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Vidyron',
                style: AuthTextStyles.loginTitle.copyWith(
                  fontSize: isMobile ? 24 : 28,
                  color: AuthColors.textPrimary,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s find your school first',
                style: AuthTextStyles.screenSubtitle.copyWith(
                  fontSize: isMobile ? 13 : 14,
                  color: AuthColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 24 : 32),
              _buildWhoAreYouSection(isMobile),
              if (_selectedRole != null) ...[
                SizedBox(height: isMobile ? 20 : 24),
                _buildMethodWidget(isMobile),
              ],
              SizedBox(height: isMobile ? 24 : 32),
              _buildGroupAdminLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhoAreYouSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isMobile ? 4 : 0, bottom: isMobile ? 12 : 16),
          child: Text(
            'Who are you?',
            style: AuthTextStyles.tagline.copyWith(
              fontSize: isMobile ? 14 : 14,
              fontWeight: FontWeight.w600,
              color: AuthColors.textPrimary,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleCard(_SetupRole.staff, '🏫', 'School Staff', 'Teacher, Admin, Driver, Clerk', isMobile),
            SizedBox(height: isMobile ? 10 : 12),
            _buildRoleCard(_SetupRole.parent, '👨‍👩‍👧', 'Parent', 'Track your child\'s safety', isMobile),
            SizedBox(height: isMobile ? 10 : 12),
            _buildRoleCard(_SetupRole.student, '👨‍🎓', 'Student', 'Access your school portal', isMobile),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(_SetupRole role, String emoji, String title, String subtitle, bool isMobile) {
    final isSelected = _selectedRole == role;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(isMobile ? 16 : AuthSizes.glassRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 20,
            vertical: isMobile ? 18 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isSelected ? 0.95 : 0.92),
            borderRadius: BorderRadius.circular(isMobile ? 16 : AuthSizes.glassRadius),
            border: Border.all(
              color: isSelected ? AuthColors.primary : AuthColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 48 : 44,
                height: isMobile ? 48 : 44,
                decoration: BoxDecoration(
                  color: AuthColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: TextStyle(fontSize: isMobile ? 26 : 24)),
              ),
              SizedBox(width: isMobile ? 16 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AuthTextStyles.featurePoint.copyWith(
                        fontSize: isMobile ? 16 : 16,
                        color: AuthColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AuthTextStyles.tagline.copyWith(
                        fontSize: isMobile ? 12 : 12,
                        color: AuthColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AuthColors.primary, size: isMobile ? 24 : 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodWidget(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(isMobile ? 16 : AuthSizes.glassRadius),
        border: Border.all(color: AuthColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _selectedRole == _SetupRole.staff
          ? SchoolSetupSearchWidget(onSchoolSelected: _onSchoolSelected)
          : SchoolSetupPhoneWidget(
              userType: _selectedRole == _SetupRole.parent ? 'parent' : 'student',
              onResolved: _onPhoneResolved,
            ),
    );
  }

  Future<void> _onSchoolSelected(SchoolIdentity school) async {
    setState(() => _isLoading = true);
    final storage = LocalStorageService();
    await storage.saveSchool(school);
    await storage.setPortalType('staff');
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/login/staff');
    }
  }

  void _onPhoneResolved(PhoneResolveResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SchoolFoundBottomSheet(
        school: result.school,
        phone: result.phone,
        portalType: result.portalType,
        otpSessionId: result.otpSessionId,
        maskedPhone: result.maskedPhone,
        userName: result.userName,
        userRole: result.userRole,
        onConfirm: () async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          final storage = LocalStorageService();
          await storage.saveSchool(result.school);
          await storage.saveUserPhone(result.phone);
          await storage.setPortalType(result.portalType);
          if (mounted) {
            setState(() => _isLoading = false);
            context.go(result.portalType == 'parent' ? '/login/parent' : '/login/student');
          }
        },
      ),
    );
  }

  Widget _buildGroupAdminLink() {
    final isMobile = MediaQuery.of(context).size.width < AuthSizes.breakpointLogin;
    return Column(
      children: [
        Text(
          'Are you a Group Admin or Super Admin?',
          style: AuthTextStyles.tagline.copyWith(
            fontSize: isMobile ? 12 : 13,
            color: AuthColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
          ),
          child: const Text('Sign in here →'),
        ),
      ],
    );
  }
}
