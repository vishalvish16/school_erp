// =============================================================================
// FILE: lib/shared/widgets/list_screen_layout.dart
// PURPOSE: Reusable layout for list/table screens — matches super_admin_schools_screen
//          patterns. Use for consistent UI across Schools, Students, Staff, etc.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Shared layout for list screens: header, search/filters card, content area.
/// Follows patterns from super_admin_schools_screen.dart.
class ListScreenLayout extends StatelessWidget {
  const ListScreenLayout({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.searchAndFilters,
    this.onRefresh,
  });

  final String title;
  final List<Widget> actions;
  final Widget? searchAndFilters;
  final Widget content;
  final Future<void> Function()? onRefresh;

  static double paddingNarrow(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? 16 : 24;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = paddingNarrow(context);

    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: title + actions
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, padding, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (actions.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                ],
              ),
            ),

            // Search + filters card (centered)
            if (searchAndFilters != null) ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: searchAndFilters,
                    ),
                  ),
                ),
              ),
              AppSpacing.vGapLg,
            ],

            // Content area (centered for table)
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, isNarrow ? 16 : 24),
                  child: content,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: body,
      );
    }
    return body;
  }
}
