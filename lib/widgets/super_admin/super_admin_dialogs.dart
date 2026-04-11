// =============================================================================
// FILE: lib/widgets/super_admin/super_admin_dialogs.dart
// PURPOSE: Adaptive modal helper — Dialog on web, BottomSheet on mobile
// =============================================================================

import 'dart:ui' as ui;
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
  if (MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0A1628).withValues(alpha: 0.92)
                  : const Color(0xEBEFF6FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: SafeArea(top: false, child: content),
          ),
        ),
      ),
    );
  }
}
