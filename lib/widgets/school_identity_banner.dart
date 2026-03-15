// =============================================================================
// FILE: lib/widgets/school_identity_banner.dart
// PURPOSE: School identity banner for school_admin, staff, returning_user screens
// NOT used by: super_admin, parent, student screens
// =============================================================================

import 'package:flutter/material.dart';
import '../models/school_identity.dart';
import '../core/constants/app_auth_constants.dart';
import '../design_system/tokens/app_spacing.dart';

class SchoolIdentityBanner extends StatelessWidget {
  const SchoolIdentityBanner({
    super.key,
    required this.identity,
    this.showStats = false,
    this.showChangeLink = false,
    this.onChangeTap,
  });

  final SchoolIdentity identity;
  final bool showStats;
  final bool showChangeLink;
  final VoidCallback? onChangeTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 500;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 14 : 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            border: Border.all(color: AuthColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNarrow)
                _buildMobileLayout()
              else
                _buildDesktopLayout(),
              if (showStats) ...[
                AppSpacing.vGapMd,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatChip('Students', identity.studentCount?.toString() ?? '—'),
                    _buildStatChip('Attendance', '—'),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AuthColors.success.withValues(alpha: 0.15),
        borderRadius: AppRadius.brXl2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AuthColors.success),
          const SizedBox(width: 6),
          Text(
            'Active on Vidyron',
            style: AuthTextStyles.tagline.copyWith(
              color: AuthColors.success,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.brLg,
              child: identity.logoUrl != null
                  ? Image.network(
                      identity.logoUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(48),
                    )
                  : _buildPlaceholderIcon(48),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    identity.name,
                    style: AuthTextStyles.loginTitle.copyWith(fontSize: 18),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (identity.code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      identity.code,
                      style: AuthTextStyles.inputHint.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildBadge(),
            if (showChangeLink)
              TextButton(
                onPressed: onChangeTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Change'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.brLg,
              child: identity.logoUrl != null
                  ? Image.network(
                      identity.logoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(52),
                    )
                  : _buildPlaceholderIcon(52),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    identity.name,
                    style: AuthTextStyles.loginTitle.copyWith(fontSize: 18),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (identity.code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      identity.code,
                      style: AuthTextStyles.inputHint.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (identity.board.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      identity.board,
                      style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildBadge(),
            if (showChangeLink)
              TextButton(
                onPressed: onChangeTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Change'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon([double size = 56]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AuthColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.brLg,
      ),
      child: Icon(Icons.school_rounded, color: AuthColors.primary, size: size * 0.5),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.3),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        '$label: $value',
        style: AuthTextStyles.tagline.copyWith(fontSize: 12),
      ),
    );
  }
}
