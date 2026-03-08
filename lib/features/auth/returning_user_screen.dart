// =============================================================================
// FILE: lib/features/auth/returning_user_screen.dart
// PURPOSE: Returning user quick access — used by staff/admin portals when session valid
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../models/school_identity.dart';
import '../../widgets/school_identity_banner.dart';
import 'auth_screen_layout.dart';

class ReturningUserScreen extends StatelessWidget {
  const ReturningUserScreen({
    super.key,
    required this.contextLabel,
    this.identity,
    this.userName,
  });

  /// e.g. "Group Admin" or school name for school context
  final String contextLabel;
  final SchoolIdentity? identity;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (identity != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SchoolIdentityBanner(
                  identity: identity!,
                  showStats: false,
                  showChangeLink: false,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(AuthSizes.cardPadding),
              decoration: BoxDecoration(
                color: AuthColors.overlayLight(0.25),
                borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
                border: Border.all(color: AuthColors.overlayLight(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    'Welcome back',
                    style: AuthTextStyles.loginTitle,
                  ),
                  if (userName != null)
                    Text(
                      userName!,
                      style: AuthTextStyles.tagline,
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/dashboard'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AuthColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    child: Text('Continue to $contextLabel', style: AuthTextStyles.buttonPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign in as different user'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
