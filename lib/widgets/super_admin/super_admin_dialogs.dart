// =============================================================================
// FILE: lib/widgets/super_admin/super_admin_dialogs.dart
// PURPOSE: Adaptive modal helper — Dialog on web, BottomSheet on mobile
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shows content as Dialog on web/tablet, BottomSheet on mobile
void showAdaptiveModal(BuildContext context, Widget content) {
  if (kIsWeb || MediaQuery.of(context).size.width >= 768) {
    showDialog(
      context: context,
      builder: (_) => Dialog(child: content),
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
