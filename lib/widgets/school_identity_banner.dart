// =============================================================================
// FILE: lib/widgets/school_identity_banner.dart
// PURPOSE: School identity banner for school_admin, staff, returning_user screens
// NOT used by: super_admin, parent, student screens
// =============================================================================

import 'package:flutter/material.dart';
import '../models/school_identity.dart';
import '../core/constants/app_auth_constants.dart';

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
          padding: EdgeInsets.all(isNarrow ? 16 : AuthSizes.cardPadding),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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

  Widget _buildMobileLayout() {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AuthColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
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
    final changeBtn = showChangeLink
        ? TextButton(
            onPressed: onChangeTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Change'),
          )
        : const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    identity.name,
                    style: AuthTextStyles.loginTitle.copyWith(fontSize: 18),
                    maxLines: 2,
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            badge,
            if (showChangeLink) changeBtn,
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: identity.logoUrl != null
              ? Image.network(
                  identity.logoUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                )
              : _buildPlaceholderIcon(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                identity.name,
                style: AuthTextStyles.loginTitle.copyWith(fontSize: 20),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (identity.code.isNotEmpty)
                Text(
                  identity.code,
                  style: AuthTextStyles.inputHint.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              if (identity.board.isNotEmpty)
                Text(
                  identity.board,
                  style: AuthTextStyles.tagline,
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AuthColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
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
        ),
        if (showChangeLink) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onChangeTap,
            child: const Text('Change'),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderIcon([double size = 56]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AuthColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.school_rounded, color: AuthColors.primary, size: size * 0.5),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: AuthTextStyles.tagline.copyWith(fontSize: 13),
      ),
    );
  }
}
