// =============================================================================
// FILE: lib/features/auth/school_found_bottom_sheet.dart
// PURPOSE: Bottom sheet shown after phone resolves to school — confirm before proceeding
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../models/school_identity.dart';
import '../../design_system/tokens/app_spacing.dart';

class SchoolFoundBottomSheet extends StatelessWidget {
  const SchoolFoundBottomSheet({
    super.key,
    required this.school,
    required this.phone,
    required this.portalType,
    required this.onConfirm,
    this.otpSessionId,
    this.maskedPhone,
    this.userName,
    this.userRole,
    this.childName,
    this.classInfo,
  });

  final SchoolIdentity school;
  final String phone;
  final String portalType;
  final VoidCallback onConfirm;
  final String? otpSessionId;
  final String? maskedPhone;
  final String? userName;
  final String? userRole;
  final String? childName;
  final String? classInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuthColors.textHint.withValues(alpha: 0.5),
                    borderRadius: AppRadius.brXs,
                  ),
                ),
              ),
              AppSpacing.vGapXl,
              Text(
                AppStrings.weFoundYourSchool,
                style: AuthTextStyles.loginTitle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXl,
              _buildSchoolCard(),
              if (userName != null) ...[
                AppSpacing.vGapLg,
                _buildLinkedAccountCard(),
              ],
              AppSpacing.vGapXl,
              SizedBox(
                height: AuthSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AuthSizes.buttonRadius),
                    ),
                  ),
                  child: const Text(AppStrings.thisIsMySchool),
                ),
              ),
              AppSpacing.vGapMd,
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppStrings.wrongSchoolContactAdmin,
                  style: AuthTextStyles.tagline.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.25),
        borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
        border: Border.all(color: AuthColors.overlayLight(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AuthColors.primary.withValues(alpha: 0.1),
            backgroundImage: school.logoUrl != null ? NetworkImage(school.logoUrl!) : null,
            child: school.logoUrl == null
                ? Text(
                    school.name.isNotEmpty ? school.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AuthColors.primary),
                  )
                : null,
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school.name, style: AuthTextStyles.featurePoint.copyWith(fontSize: 18)),
                if (school.board.isNotEmpty || school.code.isNotEmpty)
                  Text(
                    [school.board, school.code].where((e) => e.isNotEmpty).join(' · '),
                    style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AuthColors.success.withValues(alpha: 0.15),
              borderRadius: AppRadius.brXl2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: AuthColors.success),
                const SizedBox(width: 6),
                Text(AppStrings.verifiedBadge, style: AuthTextStyles.tagline.copyWith(color: AuthColors.success, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedAccountCard() {
    String subtitle = '';
    if (portalType == 'parent' && childName != null) {
      subtitle = 'Parent of: $childName';
      if (classInfo != null) subtitle += ' · $classInfo';
    } else if (portalType == 'student' && classInfo != null) {
      subtitle = 'Class $classInfo';
      if (userRole != null) subtitle += ' · $userRole';
    } else if (userRole != null) {
      subtitle = userRole!;
    }

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.2),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AuthColors.overlayLight(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(userName ?? AppStrings.user, style: AuthTextStyles.featurePoint.copyWith(fontSize: 16)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: AuthTextStyles.tagline.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
