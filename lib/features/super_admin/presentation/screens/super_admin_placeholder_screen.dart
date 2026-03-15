// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_placeholder_screen.dart
// PURPOSE: Placeholder for Super Admin screens under development
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SuperAdminPlaceholderScreen extends StatelessWidget {
  const SuperAdminPlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary),
            AppSpacing.vGapLg,
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapSm,
            Text(
              AppStrings.developmentInProgress,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
