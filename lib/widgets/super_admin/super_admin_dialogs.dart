// =============================================================================
// FILE: lib/widgets/super_admin/super_admin_dialogs.dart
// PURPOSE: Adaptive modal helper — Dialog on web, BottomSheet on mobile
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Max width for simple form dialogs (Group Settings, Assign Plan, etc.)
const double _kDialogMaxWidthSimple = 480;

/// Max width for large dialogs (Add School wizard, School Detail with tabs).
/// Use with [showAdaptiveModal] maxWidth parameter.
const double kDialogMaxWidthLarge = 900;

/// Shows content as Dialog on web/tablet, BottomSheet on mobile.
/// [maxWidth] constrains dialog width on web/tablet (default 480). Use
/// [kDialogMaxWidthLarge] for large dialogs like Add School or School Detail.
void showAdaptiveModal(
  BuildContext context,
  Widget content, {
  double? maxWidth,
}) {
  final effectiveMaxWidth = maxWidth ?? _kDialogMaxWidthSimple;
  if (kIsWeb || MediaQuery.of(context).size.width >= 768) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 48),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(child: content),
      ),
    );
  }
}
