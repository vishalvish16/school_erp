// =============================================================================
// FILE: lib/widgets/group_identity_banner.dart
// PURPOSE: Group identity banner for group_admin_login_screen
// =============================================================================

import 'package:flutter/material.dart';
import '../models/school_identity.dart';
import '../core/constants/app_auth_constants.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';

class GroupIdentityBanner extends StatelessWidget {
  const GroupIdentityBanner({
    super.key,
    required this.identity,
    this.showSchoolList = true,
    this.schoolNames = const [],
  });

  final SchoolIdentity identity;
  final bool showSchoolList;
  final List<String> schoolNames;

  static const Color _groupAccent = AppColors.primary600;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuthSizes.cardPadding),
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.25),
        borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
        border: Border.all(
          color: _groupAccent.withValues(alpha: 0.3),
          width: AuthSizes.glassBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _groupAccent.withValues(alpha: 0.15),
                  borderRadius: AppRadius.brLg,
                ),
                child: Icon(Icons.groups_rounded, color: _groupAccent, size: 28),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.name,
                      style: AuthTextStyles.loginTitle.copyWith(
                        fontSize: 20,
                        color: _groupAccent,
                      ),
                    ),
                    if (identity.studentCount != null)
                      Text(
                        '${identity.studentCount} Students',
                        style: AuthTextStyles.tagline,
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
                    Icon(Icons.verified, size: 16, color: AuthColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Verified Group',
                      style: AuthTextStyles.tagline.copyWith(
                        color: AuthColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showSchoolList && schoolNames.isNotEmpty) ...[
            AppSpacing.vGapLg,
            Text(
              'Schools in this group:',
              style: AuthTextStyles.tagline.copyWith(fontSize: 12),
            ),
            AppSpacing.vGapSm,
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...schoolNames.take(3).map((n) => _buildSchoolChip(n)),
                if (schoolNames.length > 3)
                  _buildSchoolChip('+ ${schoolNames.length - 3} more'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchoolChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.3),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        text,
        style: AuthTextStyles.tagline.copyWith(fontSize: 12),
      ),
    );
  }
}
